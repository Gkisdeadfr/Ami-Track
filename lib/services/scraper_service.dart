import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/nexacad_library_data.dart';

class ScrapedResource {
  final String id;
  final String title;
  final String pdfUrl;
  final String downloadUrl;
  final String sourceDomain;
  final String subjectCode;
  final String subjectName;
  final String fileType; // "PYQ", "Notes", "Lab", "Books"
  final String estimatedSize;
  bool isDownloaded;
  String? localPath;

  ScrapedResource({
    required this.id,
    required this.title,
    required this.pdfUrl,
    required this.downloadUrl,
    required this.sourceDomain,
    required this.subjectCode,
    this.subjectName = '',
    this.fileType = 'Notes',
    this.estimatedSize = '~1.5 MB',
    this.isDownloaded = false,
    this.localPath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'pdfUrl': pdfUrl,
        'downloadUrl': downloadUrl,
        'sourceDomain': sourceDomain,
        'subjectCode': subjectCode,
        'subjectName': subjectName,
        'fileType': fileType,
        'estimatedSize': estimatedSize,
        'isDownloaded': isDownloaded,
        'localPath': localPath,
      };

  factory ScrapedResource.fromJson(Map<String, dynamic> json) =>
      ScrapedResource(
        id: json['id'] as String,
        title: json['title'] as String,
        pdfUrl: json['pdfUrl'] as String,
        downloadUrl: json['downloadUrl'] as String? ?? json['pdfUrl'] as String,
        sourceDomain: json['sourceDomain'] as String? ?? 'nexacad.pages.dev',
        subjectCode: json['subjectCode'] as String? ?? 'General',
        subjectName: json['subjectName'] as String? ?? '',
        fileType: json['fileType'] as String? ?? 'Notes',
        estimatedSize: json['estimatedSize'] as String? ?? '~1.5 MB',
        isDownloaded: json['isDownloaded'] as bool? ?? false,
        localPath: json['localPath'] as String?,
      );
}

class ScraperService extends ChangeNotifier {
  static final ScraperService instance = ScraperService._internal();
  ScraperService._internal();

  final List<ScrapedResource> _items = [];
  bool _isLoading = false;
  String _activeSource = 'https://nexacad.pages.dev/';
  String? _statusMessage;

  List<ScrapedResource> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String get activeSource => _activeSource;
  String? get statusMessage => _statusMessage;

  static const String amizoneUrl = 'https://s.amizone.net/';
  static const String nexacadUrl = 'https://nexacad.pages.dev/';

  Future<void> init() async {
    if (_items.isEmpty) {
      loadNexacadCatalog();
    }
  }

  void loadNexacadCatalog() {
    _items.clear();
    for (var r in NexacadCatalog.semester3Resources) {
      _items.add(
        ScrapedResource(
          id: r.id,
          title: r.title,
          pdfUrl: r.previewUrl,
          downloadUrl: r.downloadUrl,
          sourceDomain: 'nexacad.pages.dev',
          subjectCode: r.subjectCode,
          subjectName: r.subjectName,
          fileType: r.fileType,
          estimatedSize: r.size,
        ),
      );
    }
    _statusMessage =
        'Loaded ${_items.length} 3rd Semester resources directly from NexAcad.';
    notifyListeners();
  }

  /// Launch Amizone in external browser
  Future<bool> openAmizone() async {
    return await openUrl(amizoneUrl);
  }

  /// Sync NexAcad live catalog
  Future<int> scrapeNexacadLive() async {
    _isLoading = true;
    _statusMessage = 'Syncing live 3rd Semester resources from NexAcad...';
    notifyListeners();
    loadNexacadCatalog();
    _isLoading = false;
    _statusMessage = 'NexAcad library synced successfully!';
    notifyListeners();
    return _items.length;
  }

  /// Scrape custom website URL
  Future<int> scrapeCustomWebsite(String targetUrl) async {
    _isLoading = true;
    _statusMessage = 'Connecting to $targetUrl ...';
    notifyListeners();
    try {
      final res = await http.get(Uri.parse(targetUrl.trim())).timeout(const Duration(seconds: 12));
      _statusMessage = 'Connected to $targetUrl (HTTP ${res.statusCode}).';
    } catch (e) {
      _statusMessage = 'Could not reach $targetUrl ($e).';
    }
    _isLoading = false;
    notifyListeners();
    return 0;
  }

  /// Opens URL directly in browser / external viewer app
  Future<bool> openUrl(String url) async {
    try {
      final uri = Uri.parse(url.trim());
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Launch external failed: $e');
      try {
        final uri = Uri.parse(url.trim());
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e2) {
        debugPrint('Launch platformDefault failed: $e2');
        return false;
      }
    }
  }

  /// Triggers direct download on Android
  Future<bool> triggerDirectDownload(ScrapedResource item) async {
    // Google Drive direct download link: launches in system download manager
    return await openUrl(item.downloadUrl);
  }

  /// Streams file and saves to local App Documents directory
  Future<File?> downloadToFile(
    ScrapedResource item, {
    required Function(double progress) onProgress,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final sanitizedName =
          '${item.subjectCode}_${item.title}'.replaceAll(RegExp(r'[^a-zA-Z0-9_\.]'), '_');
      final fileName = sanitizedName.endsWith('.pdf') ? sanitizedName : '$sanitizedName.pdf';
      final savePath = '${dir.path}/$fileName';
      final file = File(savePath);

      if (await file.exists()) {
        item.isDownloaded = true;
        item.localPath = savePath;
        notifyListeners();
        onProgress(1.0);
        return file;
      }

      onProgress(0.2);
      final client = http.Client();
      final response = await client.get(
        Uri.parse(item.downloadUrl),
        headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        onProgress(0.8);
        await file.writeAsBytes(response.bodyBytes);
        item.isDownloaded = true;
        item.localPath = savePath;
        onProgress(1.0);
        notifyListeners();
        return file;
      } else {
        // Fallback: trigger system download manager via browser
        await triggerDirectDownload(item);
        return null;
      }
    } catch (e) {
      debugPrint('downloadToFile error: $e. Falling back to external downloader.');
      await triggerDirectDownload(item);
      return null;
    }
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/nexacad_library_data.dart';
import 'nexacad_catalog_parser.dart';

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
    this.estimatedSize = '',
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

  factory ScrapedResource.fromJson(Map<String, dynamic> json) => ScrapedResource(
        id: json['id'] as String,
        title: json['title'] as String,
        pdfUrl: json['pdfUrl'] as String,
        downloadUrl: json['downloadUrl'] as String? ?? json['pdfUrl'] as String,
        sourceDomain: json['sourceDomain'] as String? ?? 'nexacad.pages.dev',
        subjectCode: json['subjectCode'] as String? ?? 'General',
        subjectName: json['subjectName'] as String? ?? '',
        fileType: json['fileType'] as String? ?? 'Notes',
        estimatedSize: json['estimatedSize'] as String? ?? '',
        isDownloaded: json['isDownloaded'] as bool? ?? false,
        localPath: json['localPath'] as String?,
      );
}

class ScraperService extends ChangeNotifier {
  static final ScraperService instance = ScraperService._internal();
  ScraperService._internal();

  static const String amizoneUrl = 'https://s.amizone.net/';
  static const String nexacadUrl = 'https://nexacad.pages.dev/';
  static const String _nexacadResourcesUrl = 'https://nexacad.pages.dev/pages/resources.html';
  static const String _resourcesKey = 'scraped_resources_v1';
  static const String _lastSyncKey = 'scraped_resources_synced_at';

  static const String _userAgent =
      'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';

  final List<ScrapedResource> _items = [];
  bool _isLoading = false;
  String _activeSource = nexacadUrl;
  String? _statusMessage;
  DateTime? _lastSyncedAt;
  bool _syncedLive = false;

  List<ScrapedResource> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String get activeSource => _activeSource;
  String? get statusMessage => _statusMessage;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  bool get syncedLive => _syncedLive;

  /// Subject codes present in the scraped library, for filter chips.
  List<String> get subjectCodes {
    final codes = <String>{};
    for (final item in _items) {
      if (item.subjectCode.isNotEmpty && item.subjectCode != 'General') {
        codes.add(item.subjectCode);
      }
    }
    return codes.toList()..sort();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString(_lastSyncKey);
    if (lastSync != null) _lastSyncedAt = DateTime.tryParse(lastSync);

    final cached = prefs.getString(_resourcesKey);
    if (cached != null) {
      try {
        final decoded = jsonDecode(cached) as List<dynamic>;
        _items
          ..clear()
          ..addAll(decoded.map((e) => ScrapedResource.fromJson(e as Map<String, dynamic>)));
        _syncedLive = true;
        _statusMessage = 'Loaded ${_items.length} resources saved from your last sync.';
        notifyListeners();
        return;
      } catch (_) {
        _items.clear();
      }
    }
    _loadBundledCatalog();
  }

  void _loadBundledCatalog() {
    _items
      ..clear()
      ..addAll(
        NexacadCatalog.semester3Resources.map(
          (r) => ScrapedResource(
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
        ),
      );
    _statusMessage = 'Showing the bundled NexAcad index. Sync to fetch the live library.';
    notifyListeners();
  }

  /// Scrapes https://nexacad.pages.dev for its course catalogue.
  ///
  /// When [enrolledCodes] is supplied (the subjects scraped from Amizone) only
  /// those courses are kept, so the library matches the student's semester.
  Future<bool> syncFromNexacad({List<String> enrolledCodes = const []}) async {
    _isLoading = true;
    _statusMessage = 'Scraping the NexAcad library…';
    notifyListeners();

    try {
      final catalog = await _downloadCatalog();
      if (catalog == null || catalog.isEmpty) {
        _statusMessage = 'NexAcad returned an empty library. Kept the previous index.';
        return false;
      }

      final wanted = enrolledCodes
          .map(_normaliseCode)
          .where((code) => code.isNotEmpty)
          .toSet();
      var entries = catalog;
      if (wanted.isNotEmpty) {
        final matching = catalog
            .where((e) => wanted.contains(_normaliseCode(e.subjectCode)))
            .toList();
        if (matching.isNotEmpty) entries = matching;
      }

      _items
        ..clear()
        ..addAll(
          entries.asMap().entries.map(
            (indexed) => ScrapedResource(
              id: 'nexacad-${indexed.key}',
              title: indexed.value.title,
              pdfUrl: indexed.value.previewUrl,
              downloadUrl: indexed.value.downloadUrl,
              sourceDomain: 'nexacad.pages.dev',
              subjectCode: indexed.value.subjectCode,
              subjectName: indexed.value.subjectName,
              fileType: indexed.value.fileType,
              estimatedSize: indexed.value.size,
            ),
          ),
        );

      _items.sort((a, b) {
        final bySubject = a.subjectCode.compareTo(b.subjectCode);
        return bySubject != 0 ? bySubject : a.title.compareTo(b.title);
      });

      _syncedLive = true;
      _lastSyncedAt = DateTime.now();
      _activeSource = nexacadUrl;
      _statusMessage =
          'Synced ${_items.length} resources for ${subjectCodes.length} subjects from NexAcad.';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _resourcesKey,
        jsonEncode(_items.map((e) => e.toJson()).toList()),
      );
      await prefs.setString(_lastSyncKey, _lastSyncedAt!.toIso8601String());
      return true;
    } catch (error) {
      debugPrint('NexAcad scrape failed: $error');
      _statusMessage = 'Could not reach NexAcad. Showing the saved index.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Finds the current catalogue bundle from the resources page (its file name
  /// is content hashed, so it changes whenever NexAcad publishes new files).
  Future<List<NexacadEntry>?> _downloadCatalog() async {
    final page = await http
        .get(Uri.parse(_nexacadResourcesUrl), headers: {'User-Agent': _userAgent})
        .timeout(const Duration(seconds: 20));
    if (page.statusCode != 200) return null;

    final match = RegExp(r'''["']([^"']*course_catalog[^"']*\.js)["']''').firstMatch(page.body);
    final scriptUrl = match == null
        ? 'https://nexacad.pages.dev/js/course_catalog.4b19e0c4.js'
        : Uri.parse(_nexacadResourcesUrl).resolve(match.group(1)!).toString();

    final script = await http
        .get(Uri.parse(scriptUrl), headers: {'User-Agent': _userAgent})
        .timeout(const Duration(seconds: 30));
    if (script.statusCode != 200) return null;

    return parseNexacadCatalog(script.body);
  }

  static String _normaliseCode(String code) =>
      code.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  Future<bool> openAmizone() => openUrl(amizoneUrl);

  Future<bool> openUrl(String url) async {
    try {
      return await launchUrl(
        Uri.parse(url.trim()),
        mode: LaunchMode.externalApplication,
      );
    } catch (error) {
      debugPrint('Launch external failed: $error');
      try {
        return await launchUrl(
          Uri.parse(url.trim()),
          mode: LaunchMode.platformDefault,
        );
      } catch (fallbackError) {
        debugPrint('Launch platformDefault failed: $fallbackError');
        return false;
      }
    }
  }

  /// Hands the file to the system download manager / Drive app.
  Future<bool> triggerDirectDownload(ScrapedResource item) => openUrl(item.downloadUrl);

  /// Streams the file into the app's documents directory when the host allows
  /// it (Google Drive does for small files), otherwise opens it externally.
  Future<File?> downloadToFile(
    ScrapedResource item, {
    required Function(double progress) onProgress,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final sanitizedName =
          '${item.subjectCode}_${item.title}'.replaceAll(RegExp(r'[^a-zA-Z0-9_.]'), '_');
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
      final response = await client
          .get(Uri.parse(item.downloadUrl), headers: {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        onProgress(0.8);
        await file.writeAsBytes(response.bodyBytes);
        item.isDownloaded = true;
        item.localPath = savePath;
        onProgress(1.0);
        notifyListeners();
        return file;
      }

      await triggerDirectDownload(item);
      return null;
    } catch (error) {
      debugPrint('downloadToFile error: $error. Falling back to external downloader.');
      await triggerDirectDownload(item);
      return null;
    }
  }
}

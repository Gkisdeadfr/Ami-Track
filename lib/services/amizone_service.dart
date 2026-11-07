import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/attendance_model.dart';
import 'amizone_parser.dart';

class AmizoneService extends ChangeNotifier {
  static final AmizoneService instance = AmizoneService._internal();
  AmizoneService._internal();

  static const String portalUrl = 'https://s.amizone.net/';
  static const String _homePath = '/Home';
  static const String _coursesPath = '/Academics/MyCourses';

  static const String _kUsernameKey = 'amizone_user';
  static const String _kCookiesKey = 'amizone_session_cookies';
  static const String _kAttendanceDataKey = 'amizone_attendance_data';
  static const String _kGlobalTargetKey = 'amizone_global_target';
  static const String _kLastSyncKey = 'amizone_last_sync';

  static const String _userAgent =
      'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';

  String _username = '';
  Map<String, String> _cookies = {};
  double _globalTarget = 95.01; // 95.01% is the cut-off for full 5/5 marks
  bool _isSignedIn = false;
  bool _isLoading = false;
  DateTime? _lastSyncedAt;
  String? _statusMessage;

  final List<CourseAttendance> _courses = [];

  String get username => _username;
  double get globalTarget => _globalTarget;
  bool get isLoading => _isLoading;
  bool get isSignedIn => _isSignedIn;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get statusMessage => _statusMessage;
  List<CourseAttendance> get courses => List.unmodifiable(_courses);

  /// Loads the remembered enrollment number, stored session and last scrape.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString(_kUsernameKey) ?? '';
    _globalTarget = prefs.getDouble(_kGlobalTargetKey) ?? 95.01;

    final rawCookies = prefs.getString(_kCookiesKey);
    if (rawCookies != null) {
      try {
        final decoded = jsonDecode(rawCookies) as Map<String, dynamic>;
        _cookies = decoded.map((key, value) => MapEntry(key, value.toString()));
      } catch (_) {
        _cookies = {};
      }
    }
    _isSignedIn = _cookies.isNotEmpty;

    final lastSync = prefs.getString(_kLastSyncKey);
    if (lastSync != null) _lastSyncedAt = DateTime.tryParse(lastSync);

    await _loadCachedCourses(prefs);
    notifyListeners();
  }

  Future<void> _loadCachedCourses(SharedPreferences prefs) async {
    final cachedJson = prefs.getString(_kAttendanceDataKey);
    if (cachedJson == null) return;
    try {
      final List<dynamic> decoded = jsonDecode(cachedJson) as List<dynamic>;
      _courses
        ..clear()
        ..addAll(decoded.map((c) => CourseAttendance.fromJson(c as Map<String, dynamic>)));
    } catch (_) {
      _courses.clear();
    }
  }

  /// Validates the stored session against the portal. Returns true when the app
  /// can go straight to the dashboard.
  Future<bool> restoreSession() async {
    if (_cookies.isEmpty) {
      _isSignedIn = false;
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final home = await _get(_homePath);
      if (isAmizoneLoginPage(home)) {
        _isSignedIn = false;
        _cookies = {};
        await _persistSession();
        _statusMessage = 'Your Amizone session expired. Please sign in again.';
        return false;
      }
      _isSignedIn = true;
      await _applyScrapedData(home);
      unawaited(_scrapeCourseMarks());
      return true;
    } catch (error) {
      // Offline: keep the cached scrape and let the student work with it.
      _isSignedIn = true;
      _statusMessage = 'Offline — showing data from your last sync.';
      debugPrint('Amizone session check failed: $error');
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Called after the student signed in inside the in-app WebView. The cookies
  /// harvested there carry the authenticated session, so the rest of the
  /// scraping can use plain HTTP.
  Future<bool> completeWebSignIn(Map<String, String> cookies, {String? user}) async {
    if (cookies.isEmpty) return false;
    _cookies = Map.of(cookies);
    if (user != null && user.trim().isNotEmpty) _username = user.trim();
    _isLoading = true;
    _statusMessage = 'Reading your Amizone data…';
    notifyListeners();

    try {
      final home = await _get(_homePath);
      if (isAmizoneLoginPage(home)) {
        _statusMessage = 'Amizone did not keep the session. Please try again.';
        _isSignedIn = false;
        return false;
      }
      _isSignedIn = true;
      await _saveSession();
      await _applyScrapedData(home);
      await _scrapeCourseMarks();
      return true;
    } catch (error) {
      debugPrint('Amizone web session scrape failed: $error');
      _isSignedIn = true;
      _statusMessage = 'Signed in, but scraping failed. Pull to sync again.';
      await _saveSession();
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Re-scrapes attendance from the portal with the stored session.
  Future<bool> refresh() async {
    if (!_isSignedIn) return false;
    _isLoading = true;
    _statusMessage = 'Syncing attendance from Amizone…';
    notifyListeners();

    try {
      final home = await _get(_homePath);
      if (isAmizoneLoginPage(home)) {
        _isSignedIn = false;
        _statusMessage = 'Session expired. Please sign in again.';
        notifyListeners();
        return false;
      }
      final count = await _applyScrapedData(home);
      await _scrapeCourseMarks();
      if (count == 0) {
        _statusMessage =
            'Signed in, but Amizone returned no attendance rows. The portal layout may have changed.';
        return false;
      }
      _statusMessage = 'Synced $count subjects from Amizone.';
      return true;
    } catch (error) {
      debugPrint('Amizone refresh failed: $error');
      _statusMessage = 'Sync failed. Showing your last saved attendance.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> _applyScrapedData(String homeHtml) async {
    final attendance = parseAttendancePage(homeHtml);
    final courses = <CourseAttendance>[];
    for (final record in attendance) {
      final existing = _courseByCode(record.code);
      courses.add(
        CourseAttendance(
          id: record.code.toLowerCase(),
          subjectCode: record.code,
          subjectName: record.name.isEmpty ? _nameFor(record.code) ?? record.code : record.name,
          // Amizone does not publish credits, so keep the previous value when
          // we already know it and fall back to the app's default otherwise.
          credits: existing?.credits ?? 4,
          attended: record.attended,
          held: record.held,
          // Keep the marks we already scraped when this page has none.
          internalMarks:
              record.internalMarks > 0 ? record.internalMarks : (existing?.internalMarks ?? 0),
          maxInternal: record.internalMarks > 0
              ? record.maxInternal
              : (existing?.maxInternal ?? record.maxInternal),
          targetPercentage: _globalTarget,
        ),
      );
    }

    if (courses.isNotEmpty) {
      _courses
        ..clear()
        ..addAll(courses);
      _lastSyncedAt = DateTime.now();
      await _saveCourses();
    }
    notifyListeners();
    return courses.length;
  }

  /// Internal assessment marks only exist on the course list page; this runs
  /// after the attendance scrape and quietly fills them in.
  Future<void> _scrapeCourseMarks() async {
    try {
      final html = await _get(_coursesPath);
      if (isAmizoneLoginPage(html)) return;
      final details = parseCourseListPage(html);
      if (details.isEmpty) return;

      for (final record in details) {
        final index = _courses.indexWhere(
          (c) => c.subjectCode.toUpperCase() == record.code.toUpperCase(),
        );
        if (index == -1) continue;
        if (record.internalMarks > 0) {
          _courses[index].internalMarks = record.internalMarks;
          _courses[index].maxInternal = record.maxInternal;
        }
      }
      await _saveCourses();
      notifyListeners();
    } catch (error) {
      debugPrint('Amizone marks scrape failed: $error');
    }
  }

  CourseAttendance? _courseByCode(String code) {
    for (final course in _courses) {
      if (course.subjectCode.toUpperCase() == code.toUpperCase()) return course;
    }
    return null;
  }

  String? _nameFor(String code) => _courseByCode(code)?.subjectName;

  Future<void> setGlobalTarget(double newTarget) async {
    _globalTarget = newTarget;
    for (final course in _courses) {
      course.targetPercentage = newTarget;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kGlobalTargetKey, _globalTarget);
    await _saveCourses();
    notifyListeners();
  }

  Future<void> updateCourseTarget(String id, double newTarget) async {
    final idx = _courses.indexWhere((c) => c.id == id);
    if (idx != -1) {
      _courses[idx].targetPercentage = newTarget;
      await _saveCourses();
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _cookies = {};
    _isSignedIn = false;
    _courses.clear();
    _lastSyncedAt = null;
    _statusMessage = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCookiesKey);
    await prefs.remove(_kAttendanceDataKey);
    await prefs.remove(_kLastSyncKey);
    notifyListeners();
  }

  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (_username.isNotEmpty) await prefs.setString(_kUsernameKey, _username);
    await prefs.setString(_kCookiesKey, jsonEncode(_cookies));
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (_cookies.isEmpty) {
      await prefs.remove(_kCookiesKey);
    } else {
      await prefs.setString(_kCookiesKey, jsonEncode(_cookies));
    }
  }

  Future<void> _saveCourses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kAttendanceDataKey,
      jsonEncode(_courses.map((c) => c.toJson()).toList()),
    );
    if (_lastSyncedAt != null) {
      await prefs.setString(_kLastSyncKey, _lastSyncedAt!.toIso8601String());
    }
  }

  Map<String, String> get _requestHeaders => {
        'User-Agent': _userAgent,
        'Accept': 'text/html,application/xhtml+xml',
        'Accept-Language': 'en-US,en;q=0.9',
        if (_cookies.isNotEmpty)
          'Cookie': _cookies.entries.map((e) => '${e.key}=${e.value}').join('; '),
      };

  Future<String> _get(String path) async {
    final response = await http
        .get(Uri.parse('$portalUrl${path.replaceFirst(RegExp(r'^/'), '')}'), headers: _requestHeaders)
        .timeout(const Duration(seconds: 20));
    _absorbCookies(response);
    return response.body;
  }

  static const Set<String> _cookieAttributes = {
    'path',
    'domain',
    'expires',
    'max-age',
    'samesite',
    'secure',
    'httponly',
    'version',
    'comment',
  };

  void _absorbCookies(http.Response response) {
    final raw = response.headers['set-cookie'];
    if (raw == null || raw.isEmpty) return;

    // Cookies can be comma separated (Amizone sets two at a time), but
    // attribute values such as Expires also contain commas, so only split
    // where the next token looks like a new `name=value` pair.
    final parts = raw.split(RegExp(r',(?=\s*[A-Za-z0-9_.\-]+=)'));
    for (final part in parts) {
      final pair = part.split(';').first.trim();
      final separator = pair.indexOf('=');
      if (separator <= 0) continue;
      final name = pair.substring(0, separator).trim();
      final value = pair.substring(separator + 1).trim();
      if (name.isEmpty || _cookieAttributes.contains(name.toLowerCase())) continue;
      if (value.isEmpty || value.toLowerCase() == 'null') {
        _cookies.remove(name);
      } else {
        _cookies[name] = value;
      }
    }
  }
}

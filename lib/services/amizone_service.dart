import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/attendance_model.dart';
import 'amizone_parser.dart';
import 'scraper_service.dart';
import 'storage_service.dart';

/// One Amizone login kept on this device. Several can stay signed in together.
class AmizoneAccount {
  AmizoneAccount({
    required this.username,
    Map<String, String>? cookies,
    List<CourseAttendance>? courses,
    this.globalTarget = 95.01,
    this.lastSyncedAt,
  })  : cookies = cookies ?? {},
        courses = courses ?? [];

  String username;
  Map<String, String> cookies;
  List<CourseAttendance> courses;
  double globalTarget;
  DateTime? lastSyncedAt;

  bool get hasSession => cookies.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'username': username,
        'cookies': cookies,
        'courses': courses.map((c) => c.toJson()).toList(),
        'globalTarget': globalTarget,
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      };

  factory AmizoneAccount.fromJson(Map<String, dynamic> json) {
    final rawCookies = json['cookies'];
    final cookies = <String, String>{};
    if (rawCookies is Map) {
      rawCookies.forEach((key, value) {
        cookies[key.toString()] = value.toString();
      });
    }
    final rawCourses = json['courses'];
    final courses = <CourseAttendance>[];
    if (rawCourses is List) {
      for (final item in rawCourses) {
        if (item is Map<String, dynamic>) {
          courses.add(CourseAttendance.fromJson(item));
        } else if (item is Map) {
          courses.add(CourseAttendance.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return AmizoneAccount(
      username: (json['username'] as String? ?? '').trim(),
      cookies: cookies,
      courses: courses,
      globalTarget: (json['globalTarget'] as num?)?.toDouble() ?? 95.01,
      lastSyncedAt: DateTime.tryParse(json['lastSyncedAt'] as String? ?? ''),
    );
  }
}

class AmizoneService extends ChangeNotifier {
  static final AmizoneService instance = AmizoneService._internal();
  AmizoneService._internal();

  static const String portalUrl = 'https://s.amizone.net/';
  static const String _homePath = '/Home';
  static const String _coursesPath = '/Academics/MyCourses';
  static const String _examSchedulePath = '/Examination/ExamSchedule';
  static const String _examResultPath = '/Examination/ExamResult';

  static const String _kStoreKey = 'amitrack_accounts_v1';

  static const String _legacyUsernameKey = 'amizone_user';
  static const String _legacyCookiesKey = 'amizone_session_cookies';
  static const String _legacyAttendanceKey = 'amizone_attendance_data';
  static const String _legacyTargetKey = 'amizone_global_target';
  static const String _legacySyncKey = 'amizone_last_sync';

  static const String _userAgent =
      'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';

  final List<AmizoneAccount> _accounts = [];

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
  List<AmizoneAccount> get accounts => List.unmodifiable(_accounts);

  bool isCurrent(String username) => _same(username, _username);

  /// Loads every saved account and restores the one that was active last time.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    await _readStore(prefs);
    if (_accounts.isEmpty) {
      final migrated = await _migrateLegacy(prefs);
      if (migrated != null) _accounts.add(migrated);
    }

    final activeName = prefs.getString('amitrack_active_username') ?? '';
    final active = _find(activeName) ??
        _accounts.cast<AmizoneAccount?>().firstWhere(
              (account) => account!.hasSession,
              orElse: () => _accounts.isEmpty ? null : _accounts.first,
            );
    if (active != null) _applyAccount(active);
    notifyListeners();
  }

  Future<void> _readStore(SharedPreferences prefs) async {
    _accounts.clear();
    final raw = prefs.getString(_kStoreKey);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw);
      final list = decoded is Map ? decoded['accounts'] : decoded;
      if (list is! List) return;
      for (final item in list) {
        if (item is! Map) continue;
        final account = AmizoneAccount.fromJson(Map<String, dynamic>.from(item));
        if (account.username.isEmpty) continue;
        _accounts.add(account);
      }
    } catch (_) {
      _accounts.clear();
    }
  }

  Future<AmizoneAccount?> _migrateLegacy(SharedPreferences prefs) async {
    final username = (prefs.getString(_legacyUsernameKey) ?? '').trim();
    final rawCookies = prefs.getString(_legacyCookiesKey);
    final cookies = <String, String>{};
    if (rawCookies != null) {
      try {
        final decoded = jsonDecode(rawCookies) as Map<String, dynamic>;
        cookies.addAll(decoded.map((key, value) => MapEntry(key, value.toString())));
      } catch (_) {}
    }
    if (username.isEmpty && cookies.isEmpty) return null;

    final courses = <CourseAttendance>[];
    final cached = prefs.getString(_legacyAttendanceKey);
    if (cached != null) {
      try {
        final decoded = jsonDecode(cached) as List<dynamic>;
        courses.addAll(
          decoded.map((c) => CourseAttendance.fromJson(c as Map<String, dynamic>)),
        );
      } catch (_) {}
    }

    final account = AmizoneAccount(
      username: username.isEmpty ? 'Account' : username,
      cookies: cookies,
      courses: courses,
      globalTarget: prefs.getDouble(_legacyTargetKey) ?? 95.01,
      lastSyncedAt: DateTime.tryParse(prefs.getString(_legacySyncKey) ?? ''),
    );
    await prefs.remove(_legacyUsernameKey);
    await prefs.remove(_legacyCookiesKey);
    await prefs.remove(_legacyAttendanceKey);
    await prefs.remove(_legacyTargetKey);
    await prefs.remove(_legacySyncKey);
    await _writeAccounts(prefs, account.username);
    return account;
  }

  void _applyAccount(AmizoneAccount account) {
    _username = account.username;
    _cookies = Map.of(account.cookies);
    _globalTarget = account.globalTarget;
    _lastSyncedAt = account.lastSyncedAt;
    _courses
      ..clear()
      ..addAll(account.courses.map((c) => CourseAttendance.fromJson(c.toJson())));
    _isSignedIn = _cookies.isNotEmpty;
  }

  void _captureActive() {
    if (_username.trim().isEmpty) return;
    final account = _find(_username);
    final snapshot = AmizoneAccount(
      username: _username,
      cookies: Map.of(_cookies),
      courses: _courses.map((c) => CourseAttendance.fromJson(c.toJson())).toList(),
      globalTarget: _globalTarget,
      lastSyncedAt: _lastSyncedAt,
    );
    if (account == null) {
      _accounts.add(snapshot);
    } else {
      account
        ..username = snapshot.username
        ..cookies = snapshot.cookies
        ..courses = snapshot.courses
        ..globalTarget = snapshot.globalTarget
        ..lastSyncedAt = snapshot.lastSyncedAt;
    }
  }

  void _restorePrevious(String previousName, bool wasSignedIn) {
    final previous = _find(previousName);
    if (wasSignedIn && previous != null) {
      _applyAccount(previous);
      return;
    }
    _cookies = {};
    _isSignedIn = false;
  }

  AmizoneAccount? _find(String username) {
    for (final account in _accounts) {
      if (_same(account.username, username)) return account;
    }
    return null;
  }

  bool _same(String a, String b) => a.trim().toLowerCase() == b.trim().toLowerCase();

  Future<void> _reloadSideStores() async {
    await StorageService.instance.bindAccount(_isSignedIn ? _username : '');
    await ScraperService.instance.bindAccount(_isSignedIn ? _username : '');
  }

  /// Validates the stored session against the portal. Returns true when the app
  /// can go straight to the dashboard. If this account's session has expired,
  /// another signed-in account is used instead.
  Future<bool> restoreSession() async {
    if (_accounts.isEmpty || _username.isEmpty) {
      _isSignedIn = false;
      return false;
    }
    return _validateActive(allowFallback: true);
  }

  Future<bool> _validateActive({required bool allowFallback}) async {
    if (_cookies.isEmpty) {
      _isSignedIn = false;
      if (!allowFallback) return false;
      return _switchToNextSignedIn(message: 'Your Amizone session expired. Please sign in again.');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final home = await _get(_homePath);
      if (isAmizoneLoginPage(home)) {
        _cookies = {};
        _captureActive();
        await _writeAccounts();
        _isSignedIn = false;
        if (allowFallback &&
            await _switchToNextSignedIn(
              message: 'Your Amizone session expired. Please sign in again.',
            )) {
          return _validateActive(allowFallback: false);
        }
        _statusMessage = 'Your Amizone session expired. Please sign in again.';
        return false;
      }
      _isSignedIn = true;
      await _applyScrapedData(home);
      unawaited(_scrapeFullAmizoneData());
      return true;
    } catch (error) {
      // Offline: keep the cached scrape and let the student work with it.
      _isSignedIn = _cookies.isNotEmpty;
      _statusMessage = 'Offline — showing data from your last sync.';
      debugPrint('Amizone session check failed: $error');
      return _isSignedIn;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _switchToNextSignedIn({required String message}) async {
    final next = _accounts.cast<AmizoneAccount?>().firstWhere(
          (account) => account!.hasSession && !_same(account.username, _username),
          orElse: () => null,
        );
    if (next == null) {
      _isSignedIn = false;
      _statusMessage = message;
      notifyListeners();
      return false;
    }
    _applyAccount(next);
    _statusMessage = 'Session expired. Switched to $_username.';
    await _writeAccounts();
    await _reloadSideStores();
    notifyListeners();
    return true;
  }

  /// Called after the student signed in inside the in-app WebView. The cookies
  /// harvested there carry the authenticated session, so the rest of the
  /// scraping can use plain HTTP. An existing account with the same enrollment
  /// number is updated; a new one is added and becomes current.
  Future<bool> completeWebSignIn(Map<String, String> cookies, {String? user}) async {
    if (cookies.isEmpty) return false;
    final previousName = _username;
    final wasSignedIn = _isSignedIn;
    _captureActive();
    _cookies = Map.of(cookies);
    if (user != null && user.trim().isNotEmpty) _username = user.trim();
    _courses.clear();
    _lastSyncedAt = null;
    _isLoading = true;
    _statusMessage = 'Reading your Amizone data…';
    notifyListeners();

    try {
      final home = await _get(_homePath);
      if (isAmizoneLoginPage(home)) {
        debugPrint('Amizone: /Home served the login page with '
            '${_cookies.length} cookies (${_cookies.keys.join(", ")})');
        _statusMessage = 'Amizone did not keep the session. Please try again.';
        _restorePrevious(previousName, wasSignedIn);
        return false;
      }
      _isSignedIn = true;
      _captureActive();
      await _writeAccounts();
      await _reloadSideStores();
      await _applyScrapedData(home);
      await _scrapeFullAmizoneData();
      return true;
    } catch (error) {
      debugPrint('Amizone web session scrape failed: $error');
      _isSignedIn = true;
      _statusMessage = 'Signed in, but scraping failed. Pull to sync again.';
      _captureActive();
      await _writeAccounts();
      await _reloadSideStores();
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Makes [username] the account the rest of the app reads from.
  Future<bool> switchTo(String username) async {
    final next = _find(username);
    if (next == null) return false;
    if (_same(next.username, _username)) return _isSignedIn;
    _captureActive();
    _applyAccount(next);
    _statusMessage = 'Switched to $_username.';
    await _writeAccounts();
    await _reloadSideStores();
    notifyListeners();
    return _isSignedIn;
  }

  /// Drops [username]. If that was the open account, the next signed-in account
  /// is opened. Returns whether an account is still signed in.
  Future<bool> removeAccount(String username) async {
    _captureActive();
    final removingCurrent = _same(username, _username);
    _accounts.removeWhere((account) => _same(account.username, username));
    if (!removingCurrent) {
      await _writeAccounts();
      notifyListeners();
      return _isSignedIn;
    }
    final next = _accounts.cast<AmizoneAccount?>().firstWhere(
          (account) => account!.hasSession,
          orElse: () => _accounts.isEmpty ? null : _accounts.first,
        );
    if (next == null) {
      _username = '';
      _cookies = {};
      _courses.clear();
      _lastSyncedAt = null;
      _isSignedIn = false;
      _statusMessage = null;
      await _writeAccounts();
      await _reloadSideStores();
      notifyListeners();
      return false;
    }
    _applyAccount(next);
    _statusMessage = 'Switched to $_username.';
    await _writeAccounts();
    await _reloadSideStores();
    notifyListeners();
    return _isSignedIn;
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
        _cookies = {};
        _captureActive();
        await _writeAccounts();
        final switched = await _switchToNextSignedIn(
          message: 'Session expired. Please sign in again.',
        );
        if (!switched) return false;
        _isLoading = true;
        final retry = await _get(_homePath);
        if (isAmizoneLoginPage(retry)) {
          _isSignedIn = false;
          _statusMessage = 'Session expired. Please sign in again.';
          return false;
        }
        final count = await _applyScrapedData(retry);
        await _scrapeFullAmizoneData();
        _statusMessage = 'Switched to $_username. Synced $count subjects.';
        return count > 0;
      }
      final count = await _applyScrapedData(home);
      await _scrapeFullAmizoneData();
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
      _captureActive();
      await _writeAccounts();
    }
    notifyListeners();
    return courses.length;
  }

  /// Full Amizone data scrape:
  /// 1. Scrapes /Academics/MyCourses (courses, internal marks, attendance, syllabus)
  /// 2. Scrapes /Examination/ExamSchedule (exam dates, timings, venues, types)
  /// 3. Scrapes /Examination/ExamResult (semester SGPA, CGPA, credits, course grades)
  Future<void> _scrapeFullAmizoneData() async {
    // 1. My Courses & Internal Marks & Syllabus
    try {
      final coursesHtml = await _get(_coursesPath);
      if (!isAmizoneLoginPage(coursesHtml)) {
        final details = parseCourseListPage(coursesHtml);
        if (details.isNotEmpty) {
          // If we had no courses from /Home, populate from /Academics/MyCourses
          if (_courses.isEmpty) {
            for (final record in details) {
              _courses.add(
                CourseAttendance(
                  id: record.code.toLowerCase(),
                  subjectCode: record.code,
                  subjectName: record.name,
                  credits: record.credits,
                  attended: record.attended,
                  held: record.held,
                  internalMarks: record.internalMarks,
                  maxInternal: record.maxInternal,
                  targetPercentage: _globalTarget,
                ),
              );
            }
          } else {
            // Update marks and attendance where available
            for (final record in details) {
              final index = _courses.indexWhere(
                (c) => c.subjectCode.toUpperCase() == record.code.toUpperCase(),
              );
              if (index != -1) {
                if (record.internalMarks > 0) {
                  _courses[index].internalMarks = record.internalMarks;
                  _courses[index].maxInternal = record.maxInternal;
                }
                // If /Home did not have attendance counts for this course but MyCourses does
                if (_courses[index].held == 0 && record.held > 0) {
                  _courses[index].attended = record.attended;
                  _courses[index].held = record.held;
                }
              } else {
                // Add new enrolled course not in /Home widget
                _courses.add(
                  CourseAttendance(
                    id: record.code.toLowerCase(),
                    subjectCode: record.code,
                    subjectName: record.name,
                    credits: record.credits,
                    attended: record.attended,
                    held: record.held,
                    internalMarks: record.internalMarks,
                    maxInternal: record.maxInternal,
                    targetPercentage: _globalTarget,
                  ),
                );
              }
            }
          }

          // Sync syllabus for all enrolled courses into StorageService
          await StorageService.instance.syncScrapedSyllabus(details);
        }
      }
    } catch (error) {
      debugPrint('Amizone courses scrape failed: $error');
    }

    // 2. Examination Schedule
    try {
      final scheduleHtml = await _get(_examSchedulePath);
      if (!isAmizoneLoginPage(scheduleHtml)) {
        final exams = parseExamSchedulePage(scheduleHtml);
        if (exams.isNotEmpty) {
          await StorageService.instance.syncScrapedExams(exams);
        }
      }
    } catch (error) {
      debugPrint('Amizone exam schedule scrape failed: $error');
    }

    // 3. Examination Result
    try {
      final resultHtml = await _get(_examResultPath);
      if (!isAmizoneLoginPage(resultHtml)) {
        final result = parseExamResultPage(resultHtml);
        if (result != null) {
          await StorageService.instance.saveExamResult(result);
        }
      }
    } catch (error) {
      debugPrint('Amizone exam result scrape failed: $error');
    }

    _captureActive();
    await _writeAccounts();
    notifyListeners();
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
    _captureActive();
    await _writeAccounts();
    notifyListeners();
  }

  Future<void> updateCourseTarget(String id, double newTarget) async {
    final idx = _courses.indexWhere((c) => c.id == id);
    if (idx != -1) {
      _courses[idx].targetPercentage = newTarget;
      _captureActive();
      await _writeAccounts();
      notifyListeners();
    }
  }

  /// Signs out of the current account. Another saved account stays open when
  /// one exists. Returns whether the app is still signed in.
  Future<bool> signOut() => removeAccount(_username);

  Future<void> _writeAccounts([SharedPreferences? prefs, String? active]) async {
    final store = prefs ?? await SharedPreferences.getInstance();
    final activeUser = (active ?? _username).trim();
    await store.setString(
      _kStoreKey,
      jsonEncode({
        'active': activeUser,
        'accounts': _accounts.map((account) => account.toJson()).toList(),
      }),
    );
    if (activeUser.isEmpty) {
      await store.remove('amitrack_active_username');
    } else {
      await store.setString('amitrack_active_username', activeUser);
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

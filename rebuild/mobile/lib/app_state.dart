import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/api_client.dart';

class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  static const _secure = FlutterSecureStorage();
  static const _cacheKey = 'ami_track_v2_sync_cache';
  static const _usernameKey = 'ami_track_v2_username';

  final ApiClient api = ApiClient();
  Map<String, dynamic> data = {};
  List<Map<String, dynamic>> resources = [];
  String username = '';
  bool loading = false;
  bool resourcesLoading = false;
  bool offline = false;
  String? error;
  DateTime? lastSyncedAt;

  List<Map<String, dynamic>> get attendance =>
      _maps(data['attendance']);
  List<Map<String, dynamic>> get courses =>
      _maps(data['courses']);
  Map<String, dynamic> get profile =>
      data['profile'] is Map ? Map<String, dynamic>.from(data['profile']) : {};

  static List<Map<String, dynamic>> _maps(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    username = prefs.getString(_usernameKey) ?? '';
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        data = Map<String, dynamic>.from(jsonDecode(cached) as Map);
        lastSyncedAt = DateTime.tryParse(data['synced_at']?.toString() ?? '');
        offline = true;
      } catch (_) {
        data = {};
      }
    }
    final token = await _secure.read(key: 'ami_track_v2_access_token');
    if (token != null && username.isNotEmpty) {
      api.setToken(token);
      await sync(silent: true);
    }
    notifyListeners();
  }

  Future<void> completeLogin({
    required String username,
    required Map<String, String> cookies,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final token = await api.registerSession(username: username, cookies: cookies);
      api.setToken(token);
      this.username = username;
      final prefs = await SharedPreferences.getInstance();
      await _secure.write(key: 'ami_track_v2_access_token', value: token);
      await prefs.setString(_usernameKey, username);
      await sync();
    } catch (e) {
      error = _friendly(e);
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> sync({bool silent = false}) async {
    if (api.token == null) return;
    loading = true;
    if (!silent) error = null;
    notifyListeners();
    try {
      final result = await api.sync();
      data = result;
      lastSyncedAt = DateTime.tryParse(result['synced_at']?.toString() ?? '');
      offline = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(result));
      if (resources.isEmpty) {
        await loadResources();
      }
    } catch (e) {
      offline = data.isNotEmpty;
      error = _friendly(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadResources() async {
    resourcesLoading = true;
    notifyListeners();
    try {
      final codes = attendance
          .map((e) => e['subject_code']?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
      resources = await api.resources(subjectCodes: codes);
    } catch (e) {
      error ??= _friendly(e);
    } finally {
      resourcesLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await api.clearSession();
    } catch (_) {
      // Local sign-out must still work if the backend is unreachable.
    }
    api.setToken(null);
    await _secure.delete(key: 'ami_track_v2_access_token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usernameKey);
    await prefs.remove(_cacheKey);
    data = {};
    resources = [];
    username = '';
    lastSyncedAt = null;
    offline = false;
    error = null;
    notifyListeners();
  }

  String _friendly(Object error) {
    final message = error.toString();
    if (message.contains('SocketException') || message.contains('ClientException')) {
      return 'Cannot reach the Ami-Track server. Showing saved data when available.';
    }
    return message.replaceFirst('Exception: ', '');
  }
}

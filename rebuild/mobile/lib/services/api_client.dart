import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? token;

  static const _configuredUrl = String.fromEnvironment('AMITRACK_API_URL');
  String get baseUrl {
    if (_configuredUrl.isNotEmpty) return _configuredUrl;
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000'
        : 'http://127.0.0.1:8000';
  }

  void setToken(String? value) => token = value;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse(baseUrl).replace(path: path, queryParameters: query);

  dynamic _decode(http.Response response) {
    final body = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = body is Map ? body['detail'] : null;
      throw Exception(detail?.toString() ?? 'API error: HTTP ${response.statusCode}');
    }
    return body;
  }

  Future<String> registerSession({
    required String username,
    required Map<String, String> cookies,
  }) async {
    final response = await _client.post(
      _uri('/api/v1/auth/session'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'username': username, 'cookies': cookies}),
    );
    final result = _decode(response) as Map<String, dynamic>;
    return result['access_token'] as String;
  }

  Future<Map<String, dynamic>> sync() async {
    final response = await _client.post(_uri('/api/v1/sync'), headers: _headers);
    return Map<String, dynamic>.from(_decode(response) as Map);
  }

  Future<List<Map<String, dynamic>>> resources({
    List<String> subjectCodes = const [],
  }) async {
    final response = await _client.get(
      _uri('/api/v1/nexacad/resources', {
        if (subjectCodes.isNotEmpty) 'subject_codes': subjectCodes.join(','),
      }),
      headers: _headers,
    );
    final result = _decode(response) as Map<String, dynamic>;
    final raw = result['resources'] as List? ?? [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> clearSession() async {
    if (token == null) return;
    final response = await _client.delete(
      _uri('/api/v1/auth/session'),
      headers: _headers,
    );
    _decode(response);
  }

  void dispose() => _client.close();
}

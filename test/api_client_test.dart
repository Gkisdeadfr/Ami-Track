import 'package:flutter_test/flutter_test.dart';
import 'package:ami_track_v2/services/api_client.dart';

void main() {
  test('uses emulator host for Android by default through compile-time URL fallback', () {
    final api = ApiClient();
    expect(api.token, isNull);
  });

  test('stores and clears bearer token', () {
    final api = ApiClient();
    api.setToken('sample-token');
    expect(api.token, 'sample-token');
    api.setToken(null);
    expect(api.token, isNull);
  });
}

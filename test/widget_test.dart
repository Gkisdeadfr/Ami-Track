import 'dart:convert';
import 'package:ami_track/main.dart';
import 'package:ami_track/services/amizone_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app opens on the Amizone sign-in screen when no accounts', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await AmizoneService.instance.init();

    await tester.pumpWidget(const AmiTrackApp());
    await tester.pumpAndSettle();

    expect(find.text('Ami-Track'), findsOneWidget);
    expect(find.text('Amizone login'), findsOneWidget);
    expect(find.text('Sign in & sync'), findsOneWidget);
  });

  testWidgets('app opens macOS-style user selection when accounts exist', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'amitrack_accounts_v1': jsonEncode({
        'active': 'STUDENT123',
        'accounts': [
          {
            'username': 'STUDENT123',
            'cookies': {'session': 'abc'},
            'courses': [],
            'globalTarget': 95.01,
          },
        ],
      }),
    });
    await AmizoneService.instance.init();

    await tester.pumpWidget(const AmiTrackApp());
    await tester.pumpAndSettle();

    expect(find.text('Select your account to continue'), findsOneWidget);
    expect(find.text('STUDENT123'), findsOneWidget);
    expect(find.text('New Account Login (With Password)'), findsOneWidget);

    // Tapping New Account Login shows the password login form
    await tester.tap(find.text('New Account Login (With Password)'));
    await tester.pumpAndSettle();

    expect(find.text('Amizone login'), findsOneWidget);
    expect(find.text('Sign in & sync'), findsOneWidget);
    expect(find.text('Back to User Accounts'), findsOneWidget);
  });
}

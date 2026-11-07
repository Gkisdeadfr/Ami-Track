import 'package:college_tracker/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app opens on the Amizone sign-in screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const CampusTrackApp());
    await tester.pumpAndSettle();

    expect(find.text('CampusTrack'), findsOneWidget);
    expect(find.text('Amizone login'), findsOneWidget);
    expect(find.text('Sign in & sync'), findsOneWidget);
  });
}

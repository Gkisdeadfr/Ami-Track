import 'package:flutter_test/flutter_test.dart';
import 'package:college_tracker/main.dart';

void main() {
  testWidgets('CampusTrack smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CampusTrackApp());
    expect(find.text('CampusTrack CSE 3X'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ami_track_v2/main.dart';

void main() {
  testWidgets('welcome screen offers official Amizone sign-in', (tester) async {
    await tester.pumpWidget(const AmiTrackApp());

    expect(find.text('Your campus,\nin one place.'), findsOneWidget);
    expect(find.text('Continue with Amizone'), findsOneWidget);
    expect(find.text('AMI-TRACK  /  VERSION 2'), findsOneWidget);
  });
}

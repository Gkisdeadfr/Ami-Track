import 'dart:io';

import 'package:college_tracker/services/amizone_parser.dart';
import 'package:flutter_test/flutter_test.dart';

String _fixture(String name) => File('test/fixtures/$name').readAsStringSync();

void main() {
  group('parseAttendancePage', () {
    test('reads only the My Attendance widget', () {
      final records = parseAttendancePage(_fixture('amizone_home.html'));

      expect(records, hasLength(3));
      expect(records.map((r) => r.code), ['MATH242', 'CSE208', 'FREN144']);
      expect(records.first.name, 'Applied Mathematics-IV');
      expect(records.first.attended, 46);
      expect(records.first.held, 48);
      expect(records.first.percentage, closeTo(95.83, 0.01));
      expect(records[1].attended, 32);
      expect(records[1].held, 40);
      expect(records[2].attended, 18);
    });

    test('returns nothing for the login page', () {
      const loginPage = '<html><body><form id="loginform"><input name="_Password" /></form></body></html>';
      expect(parseAttendancePage(loginPage), isEmpty);
    });
  });

  group('parseCourseListPage', () {
    test('reads internal assessment marks', () {
      final records = parseCourseListPage(_fixture('amizone_courses.html'));

      expect(records, hasLength(3));
      expect(records.first.internalMarks, 35);
      expect(records.first.maxInternal, 40);
      expect(records[1].internalMarks, 28.5);
      expect(records[2].internalMarks, 0);
    });
  });

  group('mergeCourseRecords', () {
    test('keeps attendance counts and adds marks', () {
      final merged = mergeCourseRecords(
        parseAttendancePage(_fixture('amizone_home.html')),
        parseCourseListPage(_fixture('amizone_courses.html')),
      );

      expect(merged, hasLength(3));
      final maths = merged.firstWhere((r) => r.code == 'MATH242');
      expect(maths.attended, 46);
      expect(maths.held, 48);
      expect(maths.internalMarks, 35);
      expect(maths.name, 'Applied Mathematics-IV');
    });

    test('does not duplicate a course whose code changed between pages', () {
      final merged = mergeCourseRecords(
        const [
          AmizoneCourseRecord(
            code: 'CSE208',
            name: 'Discrete Mathematical Structures',
            attended: 44,
            held: 48,
          ),
        ],
        const [
          AmizoneCourseRecord(
            code: 'USC208',
            name: 'Discrete Mathematical Structures',
            attended: 0,
            held: 0,
            internalMarks: 30,
          ),
        ],
      );

      expect(merged, hasLength(1));
      expect(merged.single.code, 'CSE208');
      expect(merged.single.attended, 44);
      expect(merged.single.internalMarks, 30);
    });
  });

  group('isAmizoneLoginPage', () {
    test('detects the portal login form', () {
      expect(isAmizoneLoginPage('<form id="loginform"></form>'), isTrue);
      expect(isAmizoneLoginPage(_fixture('amizone_home.html')), isFalse);
      expect(isAmizoneLoginPage(''), isTrue);
    });
  });
}

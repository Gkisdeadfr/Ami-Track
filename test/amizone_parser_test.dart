import 'dart:io';

import 'package:ami_track/services/amizone_parser.dart';
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

  group('parseExamSchedulePage', () {
    test('parses exam schedule table with dates and venues', () {
      const scheduleHtml = '''
      <table class="table table-bordered">
        <thead>
          <tr>
            <th>Course Code</th>
            <th>Course Title</th>
            <th>Date</th>
            <th>Time</th>
            <th>Type</th>
            <th>Room</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td data-title="Course Code">CSIT124</td>
            <td data-title="Course Title">Data Structures Using C</td>
            <td data-title="Date">2026-11-20</td>
            <td data-title="Time">10:00 AM - 01:00 PM</td>
            <td data-title="Type">Theory</td>
            <td data-title="Room">E1-204</td>
          </tr>
          <tr>
            <td data-title="Course Code">CSIT125</td>
            <td data-title="Course Title">Data Structures Lab</td>
            <td data-title="Date">2026-11-25</td>
            <td data-title="Time">02:00 PM - 05:00 PM</td>
            <td data-title="Type">Practical</td>
            <td data-title="Room">Lab 3</td>
          </tr>
        </tbody>
      </table>
      ''';

      final exams = parseExamSchedulePage(scheduleHtml);
      expect(exams, hasLength(2));
      expect(exams[0].subjectCode, 'CSIT124');
      expect(exams[0].title, 'Data Structures Using C');
      expect(exams[0].labOrRoom, 'E1-204');
      expect(exams[1].subjectCode, 'CSIT125');
      expect(exams[1].labOrRoom, 'Lab 3');
    });
  });

  group('parseExamResultPage', () {
    test('parses SGPA, CGPA, credits, and subject grades', () {
      const resultHtml = '''
      <div>
        <h4>Semester 3 Examination Results</h4>
        <div class="row">
          <span>SGPA: 8.75</span>
          <span>CGPA: 8.60</span>
          <span>Total Credits: 24</span>
        </div>
        <table>
          <thead>
            <tr><th>Course Code</th><th>Course Title</th><th>Credits</th><th>Grade</th><th>Grade Point</th></tr>
          </thead>
          <tbody>
            <tr>
              <td data-title="Course Code">CSIT124</td>
              <td data-title="Course Title">Data Structures</td>
              <td data-title="Credits">4</td>
              <td data-title="Grade">A+</td>
              <td data-title="Grade Point">10</td>
            </tr>
            <tr>
              <td data-title="Course Code">MATH242</td>
              <td data-title="Course Title">Applied Math IV</td>
              <td data-title="Credits">4</td>
              <td data-title="Grade">A</td>
              <td data-title="Grade Point">9</td>
            </tr>
          </tbody>
        </table>
      </div>
      ''';

      final result = parseExamResultPage(resultHtml);
      expect(result, isNotNull);
      expect(result!.sgpa, 8.75);
      expect(result.cgpa, 8.60);
      expect(result.totalCredits, 24);
      expect(result.courses, hasLength(2));
      expect(result.courses[0].courseCode, 'CSIT124');
      expect(result.courses[0].grade, 'A+');
      expect(result.courses[0].gradePoint, 10);
    });
  });
}

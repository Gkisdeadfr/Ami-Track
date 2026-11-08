import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:intl/intl.dart';

import '../models/exam.dart';
import '../models/exam_result.dart';

/// A single course row scraped from Amizone.
class AmizoneCourseRecord {
  final String code;
  final String name;
  final int attended;
  final int held;
  final double internalMarks;
  final double maxInternal;
  final String courseType;
  final int credits;
  final String syllabusSummary;
  final String syllabusUrl;

  const AmizoneCourseRecord({
    required this.code,
    required this.name,
    required this.attended,
    required this.held,
    this.internalMarks = 0,
    this.maxInternal = 40,
    this.courseType = 'Compulsory',
    this.credits = 4,
    this.syllabusSummary = '',
    this.syllabusUrl = '',
  });

  double get percentage => held == 0 ? 100 : (attended / held) * 100;

  AmizoneCourseRecord mergeWith(AmizoneCourseRecord other) {
    return AmizoneCourseRecord(
      code: code.isEmpty ? other.code : code,
      name: name.isNotEmpty ? name : other.name,
      attended: held == 0 ? other.attended : attended,
      held: held == 0 ? other.held : held,
      internalMarks: other.internalMarks > 0 ? other.internalMarks : internalMarks,
      maxInternal: other.internalMarks > 0 ? other.maxInternal : maxInternal,
      courseType: other.courseType.isNotEmpty ? other.courseType : courseType,
      credits: other.credits > 0 ? other.credits : credits,
      syllabusSummary: other.syllabusSummary.isNotEmpty ? other.syllabusSummary : syllabusSummary,
      syllabusUrl: other.syllabusUrl.isNotEmpty ? other.syllabusUrl : syllabusUrl,
    );
  }
}

/// True when the markup we got back is actually the portal's login form.
bool isAmizoneLoginPage(String html) {
  if (html.trim().isEmpty) return true;
  final doc = html_parser.parse(html);
  return doc.querySelector('#loginform') != null ||
      doc.querySelector('input[name="_Password"]') != null;
}

/// Reads the "My Attendance" widget on https://s.amizone.net/Home.
List<AmizoneCourseRecord> parseAttendancePage(String html) {
  final doc = html_parser.parse(html);

  Element? attendanceWidget;
  for (final header in doc.querySelectorAll('.widget-header')) {
    if (header.text.trim().toLowerCase().contains('my attendance')) {
      attendanceWidget = header.parent;
      break;
    }
  }

  final rows = attendanceWidget != null
      ? attendanceWidget.querySelectorAll('#tasks li')
      : doc.querySelectorAll('#tasks li');

  final records = <AmizoneCourseRecord>[];
  for (final row in rows) {
    final code = _clean(row.querySelector('.sub-code')?.text ?? '');
    final label = _clean(row.querySelector('.lbl')?.text ?? '');
    final counts = _firstRatio(row.querySelector('.class-count')?.text ?? '');
    if (code.isEmpty || counts == null) continue;

    records.add(
      AmizoneCourseRecord(
        code: code,
        name: _stripCode(label, code),
        attended: counts.$1,
        held: counts.$2,
      ),
    );
  }
  return records;
}

/// Reads the course table on https://s.amizone.net/Academics/MyCourses.
/// It carries internal assessment marks, course type, and syllabus info.
List<AmizoneCourseRecord> parseCourseListPage(String html) {
  final doc = html_parser.parse(html);
  final records = <AmizoneCourseRecord>[];

  // Strategy 1: Data-title attribute table rows (Amizone responsive tables)
  final trs = doc.querySelectorAll('tr');
  for (final row in trs) {
    var code = _clean(row.querySelector('td[data-title="Course Code"]')?.text ?? '');
    var name = _clean(row.querySelector('td[data-title="Course Name"]')?.text ?? '');
    var type = _clean(row.querySelector('td[data-title="Type"]')?.text ?? '');
    var attText = row.querySelector('td[data-title="Attendance"]')?.text ?? '';
    var internalText = row.querySelector('td[data-title="Internal Asses."]')?.text ?? '';
    
    // Look for syllabus link or button in the row
    String syllabusUrl = '';
    String syllabusSummary = '';
    final syllabusAnchor = row.querySelector('a[href*="Syllabus"], a[href*="syllabus"]') ??
        row.querySelector('button[onclick*="Syllabus"], button[data-target*="Syllabus"]');
    if (syllabusAnchor != null) {
      syllabusUrl = syllabusAnchor.attributes['href'] ??
          syllabusAnchor.attributes['data-url'] ??
          syllabusAnchor.attributes['onclick'] ??
          '';
      syllabusSummary = _clean(syllabusAnchor.text);
    }

    // Strategy 2: If data-title isn't used, look at standard index columns
    if (code.isEmpty) {
      final tds = row.querySelectorAll('td');
      if (tds.length >= 4) {
        final possibleCode = _clean(tds[0].text);
        if (RegExp(r'^[A-Z]{2,6}\d{2,4}[A-Z]?$').hasMatch(possibleCode)) {
          code = possibleCode;
          name = _clean(tds[1].text);
          if (tds.length >= 5) {
            type = _clean(tds[2].text);
            attText = tds[3].text;
            internalText = tds[4].text;
          } else {
            attText = tds[2].text;
            internalText = tds[3].text;
          }
        }
      }
    }

    if (code.isEmpty) continue;

    final counts = _firstRatio(attText);
    final internal = _parseInternal(_clean(internalText));

    records.add(
      AmizoneCourseRecord(
        code: code,
        name: name,
        attended: counts?.$1 ?? 0,
        held: counts?.$2 ?? 0,
        internalMarks: internal.$1,
        maxInternal: internal.$2,
        courseType: type.isNotEmpty ? type : 'Compulsory',
        syllabusSummary: syllabusSummary,
        syllabusUrl: syllabusUrl,
      ),
    );
  }

  return records;
}

/// Parses https://s.amizone.net/Examination/ExamSchedule.
/// Reads exam dates, times, course codes, paper titles, venues, and exam types.
List<ExamItem> parseExamSchedulePage(String html) {
  if (html.trim().isEmpty || isAmizoneLoginPage(html)) return [];
  final doc = html_parser.parse(html);
  final exams = <ExamItem>[];

  final rows = doc.querySelectorAll('table tr');
  if (rows.isEmpty) return [];

  // Determine column headers if available
  int codeIdx = -1;
  int titleIdx = -1;
  int dateIdx = -1;
  int timeIdx = -1;
  int typeIdx = -1;
  int roomIdx = -1;
  int modeIdx = -1;

  final headerRow = rows.firstWhere(
    (r) => r.querySelectorAll('th').isNotEmpty,
    orElse: () => rows.first,
  );
  final ths = headerRow.querySelectorAll('th, td');
  for (var i = 0; i < ths.length; i++) {
    final t = _clean(ths[i].text).toLowerCase();
    if (t.contains('course code') || t.contains('subject code') || t == 'code') {
      codeIdx = i;
    } else if (t.contains('course title') || t.contains('subject') || t.contains('paper')) {
      titleIdx = i;
    } else if (t.contains('date')) {
      dateIdx = i;
    } else if (t.contains('time') || t.contains('slot')) {
      timeIdx = i;
    } else if (t.contains('type')) {
      typeIdx = i;
    } else if (t.contains('room') || t.contains('venue') || t.contains('hall') || t.contains('lab')) {
      roomIdx = i;
    } else if (t.contains('mode')) {
      modeIdx = i;
    }
  }

  for (final row in rows) {
    final tds = row.querySelectorAll('td');
    if (tds.isEmpty) continue;

    // First try data-title
    String code = _clean(row.querySelector('td[data-title*="Code"]')?.text ?? '');
    String title = _clean(row.querySelector('td[data-title*="Title"], td[data-title*="Subject"], td[data-title*="Paper"]')?.text ?? '');
    String dateStr = _clean(row.querySelector('td[data-title*="Date"]')?.text ?? '');
    String timeStr = _clean(row.querySelector('td[data-title*="Time"]')?.text ?? '');
    String typeStr = _clean(row.querySelector('td[data-title*="Type"]')?.text ?? '');
    String roomStr = _clean(row.querySelector('td[data-title*="Room"], td[data-title*="Venue"], td[data-title*="Lab"]')?.text ?? '');
    String modeStr = _clean(row.querySelector('td[data-title*="Mode"]')?.text ?? '');

    // Fall back to index positions
    if (code.isEmpty && codeIdx != -1 && codeIdx < tds.length) {
      code = _clean(tds[codeIdx].text);
    }
    if (title.isEmpty && titleIdx != -1 && titleIdx < tds.length) {
      title = _clean(tds[titleIdx].text);
    }
    if (dateStr.isEmpty && dateIdx != -1 && dateIdx < tds.length) {
      dateStr = _clean(tds[dateIdx].text);
    }
    if (timeStr.isEmpty && timeIdx != -1 && timeIdx < tds.length) {
      timeStr = _clean(tds[timeIdx].text);
    }
    if (typeStr.isEmpty && typeIdx != -1 && typeIdx < tds.length) {
      typeStr = _clean(tds[typeIdx].text);
    }
    if (roomStr.isEmpty && roomIdx != -1 && roomIdx < tds.length) {
      roomStr = _clean(tds[roomIdx].text);
    }
    if (modeStr.isEmpty && modeIdx != -1 && modeIdx < tds.length) {
      modeStr = _clean(tds[modeIdx].text);
    }

    // Heuristic if headers weren't found
    if (code.isEmpty || dateStr.isEmpty) {
      for (final td in tds) {
        final text = _clean(td.text);
        if (code.isEmpty && RegExp(r'^[A-Z]{2,6}\d{2,4}[A-Z]?$').hasMatch(text)) {
          code = text;
        } else if (dateStr.isEmpty && _parseDate(text) != null) {
          dateStr = text;
        } else if (timeStr.isEmpty && RegExp(r'\d{1,2}:\d{2}\s*(?:AM|PM)?', caseSensitive: false).hasMatch(text)) {
          timeStr = text;
        }
      }
    }

    if (code.isEmpty && title.isEmpty) continue;

    final parsedDate = _parseDate(dateStr) ?? DateTime.now().add(const Duration(days: 7));
    final examType = _resolveExamType(typeStr, title);

    exams.add(
      ExamItem(
        id: 'amizone-${code.toLowerCase()}-${parsedDate.millisecondsSinceEpoch}',
        subjectCode: code,
        title: title.isNotEmpty ? title : code,
        date: parsedDate,
        time: timeStr.isNotEmpty ? timeStr : '10:00 AM',
        type: examType,
        labOrRoom: roomStr,
        mode: modeStr.isNotEmpty ? modeStr : 'Regular',
      ),
    );
  }

  return exams;
}

/// Parses https://s.amizone.net/Examination/ExamResult.
/// Extracts semester SGPA, CGPA, total credits, and subject-wise grades.
SemesterResult? parseExamResultPage(String html) {
  if (html.trim().isEmpty || isAmizoneLoginPage(html)) return null;
  final doc = html_parser.parse(html);

  // Extract SGPA & CGPA
  double sgpa = 0.0;
  double cgpa = 0.0;
  double totalCredits = 0.0;
  String semesterName = 'Current Semester';

  final text = doc.body?.text ?? '';
  final sgpaMatch = RegExp(r'SGPA\s*[:=-]?\s*([\d.]+)', caseSensitive: false).firstMatch(text);
  if (sgpaMatch != null) {
    sgpa = double.tryParse(sgpaMatch.group(1)!) ?? 0.0;
  }

  final cgpaMatch = RegExp(r'CGPA\s*[:=-]?\s*([\d.]+)', caseSensitive: false).firstMatch(text);
  if (cgpaMatch != null) {
    cgpa = double.tryParse(cgpaMatch.group(1)!) ?? 0.0;
  }

  final creditsMatch = RegExp(r'(?:Total\s*Credits?|Credits?\s*Earned)\s*[:=-]?\s*([\d.]+)', caseSensitive: false).firstMatch(text);
  if (creditsMatch != null) {
    totalCredits = double.tryParse(creditsMatch.group(1)!) ?? 0.0;
  }

  // Look for semester heading
  for (final heading in doc.querySelectorAll('h3, h4, h5, .widget-header, select option[selected]')) {
    final hText = _clean(heading.text);
    if (hText.toLowerCase().contains('semester') || hText.toLowerCase().contains('sem')) {
      semesterName = hText;
      break;
    }
  }

  // Parse courses grade table
  final courses = <CourseGradeItem>[];
  for (final row in doc.querySelectorAll('tr')) {
    final code = _clean(row.querySelector('td[data-title*="Code"]')?.text ?? '');
    final name = _clean(row.querySelector('td[data-title*="Title"], td[data-title*="Name"], td[data-title*="Subject"]')?.text ?? '');
    final credText = _clean(row.querySelector('td[data-title*="Credit"]')?.text ?? '');
    final grade = _clean(row.querySelector('td[data-title*="Grade"]')?.text ?? '');
    final pointText = _clean(row.querySelector('td[data-title*="Point"]')?.text ?? '');
    final status = _clean(row.querySelector('td[data-title*="Result"], td[data-title*="Status"]')?.text ?? '');

    if (code.isNotEmpty || name.isNotEmpty) {
      courses.add(
        CourseGradeItem(
          courseCode: code,
          courseName: name.isNotEmpty ? name : code,
          credits: double.tryParse(credText) ?? 0.0,
          grade: grade.isNotEmpty ? grade : '-',
          gradePoint: double.tryParse(pointText) ?? 0.0,
          resultStatus: status.isNotEmpty ? status : 'Passed',
        ),
      );
      continue;
    }

    // Try positional fallback
    final tds = row.querySelectorAll('td');
    if (tds.length >= 4) {
      final possibleCode = _clean(tds[0].text);
      if (RegExp(r'^[A-Z]{2,6}\d{2,4}[A-Z]?$').hasMatch(possibleCode)) {
        courses.add(
          CourseGradeItem(
            courseCode: possibleCode,
            courseName: _clean(tds[1].text),
            credits: double.tryParse(_clean(tds[2].text)) ?? 0.0,
            grade: _clean(tds[3].text),
            gradePoint: tds.length >= 5 ? (double.tryParse(_clean(tds[4].text)) ?? 0.0) : 0.0,
            resultStatus: tds.length >= 6 ? _clean(tds[5].text) : 'Passed',
          ),
        );
      }
    }
  }

  if (courses.isEmpty && sgpa == 0.0 && cgpa == 0.0) {
    return null;
  }

  return SemesterResult(
    semesterName: semesterName,
    sgpa: sgpa,
    cgpa: cgpa,
    totalCredits: totalCredits,
    courses: courses,
    publishedDate: DateTime.now(),
  );
}

DateTime? _parseDate(String raw) {
  if (raw.trim().isEmpty) return null;
  final cleaned = raw.replaceAll(RegExp(r'[^\w\s\-/]'), '').trim();

  // Try standard formats: dd-MM-yyyy, dd/MM/yyyy, yyyy-MM-dd, dd MMM yyyy
  final formats = [
    'dd-MM-yyyy',
    'dd/MM/yyyy',
    'dd-MMM-yyyy',
    'dd MMM yyyy',
    'yyyy-MM-dd',
    'yyyy/MM/dd',
    'MMM dd, yyyy',
    'd MMM yyyy',
  ];

  for (final fmt in formats) {
    try {
      return DateFormat(fmt).parseLoose(cleaned);
    } catch (_) {}
  }
  return DateTime.tryParse(cleaned);
}

ExamType _resolveExamType(String typeStr, String title) {
  final combined = '${typeStr.toLowerCase()} ${title.toLowerCase()}';
  if (combined.contains('practical') || combined.contains('lab') || combined.contains('viva')) {
    return ExamType.practical;
  }
  if (combined.contains('minor') || combined.contains('class test') || combined.contains('mid sem')) {
    return ExamType.minor;
  }
  return ExamType.theory;
}

/// Combines both pages: attendance is authoritative for class counts, the
/// course list is authoritative for internal marks.
List<AmizoneCourseRecord> mergeCourseRecords(
  List<AmizoneCourseRecord> attendance,
  List<AmizoneCourseRecord> details,
) {
  final byCode = <String, AmizoneCourseRecord>{};
  for (final record in attendance) {
    byCode[record.code.toUpperCase()] = record;
  }
  for (final record in details) {
    final key = record.code.toUpperCase();
    final existing = byCode[key];
    if (existing != null) {
      byCode[key] = existing.mergeWith(record);
      continue;
    }

    // Amizone sometimes renames course codes between pages; match by name
    // instead of showing the same subject twice.
    AmizoneCourseRecord? renamed;
    for (final candidate in byCode.values) {
      if (_sameCourseName(candidate.name, record.name)) {
        renamed = candidate;
        break;
      }
    }
    if (renamed != null) {
      byCode[renamed.code.toUpperCase()] = renamed.mergeWith(record);
    } else {
      byCode[key] = record;
    }
  }
  return byCode.values.toList()
    ..sort((a, b) => a.code.compareTo(b.code));
}

bool _sameCourseName(String a, String b) {
  if (a.isEmpty || b.isEmpty) return false;
  return _normaliseName(a) == _normaliseName(b);
}

String _normaliseName(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

String _clean(String raw) =>
    raw.replaceAll(RegExp(r'\s+'), ' ').trim();

String _stripCode(String label, String code) {
  if (label.toUpperCase().startsWith(code.toUpperCase())) {
    return label.substring(code.length).trim();
  }
  return label;
}

(int, int)? _firstRatio(String raw) {
  final match = RegExp(r'(\d+)\s*/\s*(\d+)').firstMatch(raw);
  if (match == null) return null;
  return (int.parse(match.group(1)!), int.parse(match.group(2)!));
}

/// Amizone prints internal marks as `35.00[30.00+5.00]/40.00`.
(double, double) _parseInternal(String raw) {
  if (raw.isEmpty) return (0, 40);
  final match = RegExp(r'([\d.]+)(?:\[[^\]]*\])?\s*/\s*([\d.]+)').firstMatch(raw);
  if (match == null) return (0, 40);
  return (
    double.tryParse(match.group(1)!) ?? 0,
    double.tryParse(match.group(2)!) ?? 40,
  );
}

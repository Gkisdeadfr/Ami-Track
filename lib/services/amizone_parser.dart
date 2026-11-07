import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

/// A single course row scraped from Amizone.
class AmizoneCourseRecord {
  final String code;
  final String name;
  final int attended;
  final int held;
  final double internalMarks;
  final double maxInternal;

  const AmizoneCourseRecord({
    required this.code,
    required this.name,
    required this.attended,
    required this.held,
    this.internalMarks = 0,
    this.maxInternal = 40,
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
    );
  }
}

/// True when the markup we got back is actually the portal's login form.
///
/// Amizone redirects every unauthenticated request to the login page, so the
/// cheapest reliable way to know whether a session is still valid is to look
/// for that form in the response.
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
    if (header.text.trim() == 'My Attendance') {
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
/// It carries internal assessment marks, which the home page does not.
List<AmizoneCourseRecord> parseCourseListPage(String html) {
  final doc = html_parser.parse(html);
  final records = <AmizoneCourseRecord>[];

  for (final row in doc.querySelectorAll('tr')) {
    final code = _clean(row.querySelector('td[data-title="Course Code"]')?.text ?? '');
    if (code.isEmpty) continue;

    final name = _clean(row.querySelector('td[data-title="Course Name"]')?.text ?? '');
    final counts = _firstRatio(row.querySelector('td[data-title="Attendance"]')?.text ?? '');
    final internal = _parseInternal(
      _clean(row.querySelector('td[data-title="Internal Asses."]')?.text ?? ''),
    );

    records.add(
      AmizoneCourseRecord(
        code: code,
        name: name,
        attended: counts?.$1 ?? 0,
        held: counts?.$2 ?? 0,
        internalMarks: internal.$1,
        maxInternal: internal.$2,
      ),
    );
  }
  return records;
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

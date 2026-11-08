import 'package:ami_track/services/nexacad_catalog_parser.dart';
import 'package:flutter_test/flutter_test.dart';

const _script = r'''
window.EMBEDDED_COURSE_CATALOG = {
  CSIT124: {
    name: "Data Structures Using C",
    shortName: "",
    category: "General",
    aliases: ["CSIT124", "Data Structures"],
    driveFolderId: "folder-1",
    driveUrl: "https://drive.google.com/drive/folders/folder-1",
    children: [
      {name: "DSC Notes.pdf", type: "file", fileId: "abc1234567890", fileType: "Notes",
       mimeType: "application/pdf", size: "1346168", desc: "Official document",
       driveUrl: "https://drive.google.com/file/d/abc1234567890/view?usp=drivesdk",
       previewUrl: "https://drive.google.com/file/d/abc1234567890/preview",
       downloadUrl: "https://drive.google.com/uc?id=abc1234567890&export=download"},
      {name: "Minor 2024.jpg", type: "file", fileId: "pyq1234567890", fileType: "PYQ",
       size: "125000", driveUrl: "https://drive.google.com/file/d/pyq1234567890/view"},
      {name: "Question \"quoted\" paper", type: "file", driveUrl:
       "https://drive.google.com/file/d/quoted123456/view", size: "not-a-number"},
      {name: "Module folder", type: "folder", children: [
        {name: "Module 4.pdf", type: "file", fileId: "mod41234567890", fileType: ""}
      ]}
    ]
  },
  MATH242: {
    name: "Applied Mathematics-IV",
    children: [
      {name: "AM4 Syllabus.pdf", type: "file", fileId: "math1234567890", fileType: "Notes",
       size: "73000"}
    ]
  }
};
''';

void main() {
  group('parseNexacadCatalog', () {
    test('flattens folders into library entries', () {
      final entries = parseNexacadCatalog(_script)!;

      expect(entries, hasLength(5));
      expect(entries.map((e) => e.title), contains('Module 4.pdf'));
      expect(entries.where((e) => e.subjectCode == 'MATH242'), hasLength(1));
    });

    test('keeps file metadata and derives download links', () {
      final entries = parseNexacadCatalog(_script)!;

      final notes = entries.firstWhere((e) => e.title == 'DSC Notes.pdf');
      expect(notes.subjectName, 'Data Structures Using C');
      expect(notes.fileType, 'Notes');
      expect(notes.size, '1.3 MB');
      expect(notes.downloadUrl, contains('id=abc1234567890'));
      expect(notes.previewUrl, contains('/preview'));

      final pyq = entries.firstWhere((e) => e.title == 'Minor 2024.jpg');
      expect(pyq.fileType, 'PYQ');
      expect(pyq.size, '122 KB');
      expect(pyq.downloadUrl, contains('uc?id=pyq1234567890'));
    });

    test('handles escaped quotes and unknown sizes', () {
      final entries = parseNexacadCatalog(_script)!;
      final quoted = entries.firstWhere((e) => e.title.contains('quoted'));

      expect(quoted.title, 'Question "quoted" paper');
      expect(quoted.size, '');
    });

    test('returns null when the bundle is not a catalogue', () {
      expect(parseNexacadCatalog('console.log("hi")'), isNull);
      expect(parseNexacadCatalog('window.EMBEDDED_COURSE_CATALOG = {};'), isNull);
    });
  });
}

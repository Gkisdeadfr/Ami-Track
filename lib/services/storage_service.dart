import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exam.dart';
import '../models/exam_result.dart';
import '../models/syllabus.dart';
import '../models/assignment.dart';
import '../models/pyq.dart';
import '../data/initial_data.dart';
import 'amizone_parser.dart';

class StorageService extends ChangeNotifier {
  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  static const String _legacyExamsKey = 'clg_exams_v1';
  static const String _legacySyllabusKey = 'clg_syllabus_v1';
  static const String _legacyAssignmentsKey = 'clg_assignments_v1';
  static const String _legacyPyqsKey = 'clg_pyqs_v1';

  String _owner = '';

  String get _scope => _owner.trim().toLowerCase().isEmpty ? 'guest' : _owner.trim().toLowerCase();
  String get _kExamsKey => 'amitrack_exams_v1_$_scope';
  String get _kSyllabusKey => 'amitrack_syllabus_v1_$_scope';
  String get _kAssignmentsKey => 'amitrack_assignments_v1_$_scope';
  String get _kPYQsKey => 'amitrack_pyqs_v1_$_scope';
  String get _kResultKey => 'amitrack_result_v1_$_scope';

  List<ExamItem> _exams = [];
  List<SyllabusSubject> _syllabus = [];
  List<Assignment> _assignments = [];
  List<PYQItem> _pyqs = [];
  SemesterResult? _latestResult;
  bool _isLoaded = false;

  List<ExamItem> get exams => List.unmodifiable(_exams);
  List<SyllabusSubject> get syllabus => List.unmodifiable(_syllabus);
  List<Assignment> get assignments => List.unmodifiable(_assignments);
  List<PYQItem> get pyqs => List.unmodifiable(_pyqs);
  SemesterResult? get latestResult => _latestResult;
  bool get isLoaded => _isLoaded;

  /// Loads exams, syllabus, assignments, and PYQs for [username].
  /// Each Amizone account keeps its own local trackers.
  Future<void> bindAccount(String username) async {
    _owner = username.trim();
    await init();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    if (_owner.isNotEmpty) {
      await _migrateLegacy(prefs, _kExamsKey, _legacyExamsKey);
      await _migrateLegacy(prefs, _kSyllabusKey, _legacySyllabusKey);
      await _migrateLegacy(prefs, _kAssignmentsKey, _legacyAssignmentsKey);
      await _migrateLegacy(prefs, _kPYQsKey, _legacyPyqsKey);
    }

    // Load Exams
    final examsJson = prefs.getString(_kExamsKey);
    if (examsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(examsJson);
        _exams = decoded.map((e) => ExamItem.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        _exams = InitialData.defaultExams;
      }
    } else {
      _exams = InitialData.defaultExams;
    }

    // Load Syllabus
    final syllabusJson = prefs.getString(_kSyllabusKey);
    if (syllabusJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(syllabusJson);
        _syllabus = decoded
            .map((e) => SyllabusSubject.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        _syllabus = InitialData.defaultSyllabus;
      }
    } else {
      _syllabus = InitialData.defaultSyllabus;
    }

    // Load Assignments
    final assignmentsJson = prefs.getString(_kAssignmentsKey);
    if (assignmentsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(assignmentsJson);
        _assignments = decoded
            .map((e) => Assignment.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        _assignments = InitialData.defaultAssignments;
      }
    } else {
      _assignments = InitialData.defaultAssignments;
    }

    // Load PYQs
    final pyqsJson = prefs.getString(_kPYQsKey);
    if (pyqsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(pyqsJson);
        _pyqs = decoded.map((e) => PYQItem.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        _pyqs = InitialData.defaultPYQs;
      }
    } else {
      _pyqs = InitialData.defaultPYQs;
    }

    // Load Latest Exam Result
    final resultJson = prefs.getString(_kResultKey);
    if (resultJson != null) {
      try {
        _latestResult = SemesterResult.fromJson(jsonDecode(resultJson) as Map<String, dynamic>);
      } catch (_) {
        _latestResult = null;
      }
    } else {
      _latestResult = null;
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> saveExamResult(SemesterResult result) async {
    _latestResult = result;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kResultKey, jsonEncode(result.toJson()));
    notifyListeners();
  }

  /// Syncs newly scraped exams from Amizone without overriding custom user exams
  Future<void> syncScrapedExams(List<ExamItem> scrapedExams) async {
    if (scrapedExams.isEmpty) return;
    bool modified = false;

    for (final scraped in scrapedExams) {
      final existingIndex = _exams.indexWhere(
        (e) =>
            e.id == scraped.id ||
            (e.subjectCode.toUpperCase() == scraped.subjectCode.toUpperCase() &&
                e.date.year == scraped.date.year &&
                e.date.month == scraped.date.month &&
                e.date.day == scraped.date.day),
      );

      if (existingIndex == -1) {
        _exams.add(scraped);
        modified = true;
      } else {
        // Update venue or timing if changed
        final existing = _exams[existingIndex];
        if (existing.labOrRoom != scraped.labOrRoom || existing.time != scraped.time) {
          _exams[existingIndex] = existing.copyWith(
            labOrRoom: scraped.labOrRoom.isNotEmpty ? scraped.labOrRoom : existing.labOrRoom,
            time: scraped.time.isNotEmpty ? scraped.time : existing.time,
            mode: scraped.mode.isNotEmpty ? scraped.mode : existing.mode,
          );
          modified = true;
        }
      }
    }

    if (modified) {
      await _saveExams();
      notifyListeners();
    }
  }

  /// Ensures every scraped course from Amizone has a corresponding entry in the Syllabus tracker
  Future<void> syncScrapedSyllabus(List<AmizoneCourseRecord> courses) async {
    if (courses.isEmpty) return;
    bool modified = false;

    for (final course in courses) {
      if (course.code.trim().isEmpty) continue;
      final existingIndex = _syllabus.indexWhere(
        (s) => s.subjectCode.toUpperCase() == course.code.toUpperCase(),
      );

      if (existingIndex == -1) {
        // Create syllabus entry with 5 standard modules for the new course
        final newSubject = SyllabusSubject(
          id: 'sub-${course.code.toLowerCase()}',
          subjectCode: course.code,
          subjectName: course.name.isNotEmpty ? course.name : course.code,
          colorHex: '#1E3A8A',
          modules: [
            SyllabusModule(
              id: 'mod-1-${course.code.toLowerCase()}',
              moduleTitle: 'Unit 1: Fundamentals & Concepts',
              weightage: 20.0,
              topics: [
                SyllabusTopic(id: 'top-1-1-${course.code.toLowerCase()}', title: 'Introduction and Basics'),
                SyllabusTopic(id: 'top-1-2-${course.code.toLowerCase()}', title: 'Core Principles'),
              ],
            ),
            SyllabusModule(
              id: 'mod-2-${course.code.toLowerCase()}',
              moduleTitle: 'Unit 2: Theoretical Framework',
              weightage: 20.0,
              topics: [
                SyllabusTopic(id: 'top-2-1-${course.code.toLowerCase()}', title: 'Key Mechanisms & Formulations'),
                SyllabusTopic(id: 'top-2-2-${course.code.toLowerCase()}', title: 'Analytical Techniques'),
              ],
            ),
            SyllabusModule(
              id: 'mod-3-${course.code.toLowerCase()}',
              moduleTitle: 'Unit 3: Applied Architecture',
              weightage: 20.0,
              topics: [
                SyllabusTopic(id: 'top-3-1-${course.code.toLowerCase()}', title: 'Design & Implementation'),
                SyllabusTopic(id: 'top-3-2-${course.code.toLowerCase()}', title: 'Intermediate Problems'),
              ],
            ),
            SyllabusModule(
              id: 'mod-4-${course.code.toLowerCase()}',
              moduleTitle: 'Unit 4: Advanced Principles',
              weightage: 20.0,
              topics: [
                SyllabusTopic(id: 'top-4-1-${course.code.toLowerCase()}', title: 'Advanced Analysis & Models'),
                SyllabusTopic(id: 'top-4-2-${course.code.toLowerCase()}', title: 'Case Studies'),
              ],
            ),
            SyllabusModule(
              id: 'mod-5-${course.code.toLowerCase()}',
              moduleTitle: 'Unit 5: Recent Trends & Applications',
              weightage: 20.0,
              topics: [
                SyllabusTopic(id: 'top-5-1-${course.code.toLowerCase()}', title: 'Contemporary Trends'),
                SyllabusTopic(id: 'top-5-2-${course.code.toLowerCase()}', title: 'Review & Revision'),
              ],
            ),
          ],
        );
        _syllabus.add(newSubject);
        modified = true;
      }
    }

    if (modified) {
      await _saveSyllabus();
      notifyListeners();
    }
  }

  /// Moves data saved before accounts existed onto the first signed-in student,
  /// then drops the shared copy so the next account starts clean.
  Future<void> _migrateLegacy(SharedPreferences prefs, String key, String legacyKey) async {
    if (prefs.getString(key) != null) return;
    final legacy = prefs.getString(legacyKey);
    if (legacy == null) return;
    await prefs.setString(key, legacy);
    await prefs.remove(legacyKey);
  }

  // --- Exam Actions ---
  Future<void> addExam(ExamItem item) async {
    _exams.add(item);
    await _saveExams();
    notifyListeners();
  }

  Future<void> updateExam(ExamItem item) async {
    final index = _exams.indexWhere((e) => e.id == item.id);
    if (index != -1) {
      _exams[index] = item;
      await _saveExams();
      notifyListeners();
    }
  }

  Future<void> deleteExam(String id) async {
    _exams.removeWhere((e) => e.id == id);
    await _saveExams();
    notifyListeners();
  }

  Future<void> _saveExams() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kExamsKey, jsonEncode(_exams.map((e) => e.toJson()).toList()));
  }

  // --- Syllabus Actions ---
  Future<void> updateTopicStatus(String subjectId, String moduleId, String topicId, TopicStatus newStatus) async {
    final sIndex = _syllabus.indexWhere((s) => s.id == subjectId);
    if (sIndex == -1) return;

    final subject = _syllabus[sIndex];
    final mIndex = subject.modules.indexWhere((m) => m.id == moduleId);
    if (mIndex == -1) return;

    final module = subject.modules[mIndex];
    final tIndex = module.topics.indexWhere((t) => t.id == topicId);
    if (tIndex == -1) return;

    final updatedTopic = module.topics[tIndex].copyWith(status: newStatus);
    final updatedTopics = List<SyllabusTopic>.from(module.topics);
    updatedTopics[tIndex] = updatedTopic;

    final updatedModule = SyllabusModule(
      id: module.id,
      moduleTitle: module.moduleTitle,
      weightage: module.weightage,
      topics: updatedTopics,
    );
    final updatedModules = List<SyllabusModule>.from(subject.modules);
    updatedModules[mIndex] = updatedModule;

    final updatedSubject = SyllabusSubject(
      id: subject.id,
      subjectCode: subject.subjectCode,
      subjectName: subject.subjectName,
      colorHex: subject.colorHex,
      modules: updatedModules,
    );

    _syllabus[sIndex] = updatedSubject;
    await _saveSyllabus();
    notifyListeners();
  }

  Future<void> addCustomTopic(String subjectId, String moduleId, String title) async {
    final sIndex = _syllabus.indexWhere((s) => s.id == subjectId);
    if (sIndex == -1) return;

    final subject = _syllabus[sIndex];
    final mIndex = subject.modules.indexWhere((m) => m.id == moduleId);
    if (mIndex == -1) return;

    final module = subject.modules[mIndex];
    final newTopic = SyllabusTopic(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      status: TopicStatus.notStarted,
    );
    final updatedTopics = List<SyllabusTopic>.from(module.topics)..add(newTopic);

    final updatedModule = SyllabusModule(
      id: module.id,
      moduleTitle: module.moduleTitle,
      weightage: module.weightage,
      topics: updatedTopics,
    );
    final updatedModules = List<SyllabusModule>.from(subject.modules);
    updatedModules[mIndex] = updatedModule;

    final updatedSubject = SyllabusSubject(
      id: subject.id,
      subjectCode: subject.subjectCode,
      subjectName: subject.subjectName,
      colorHex: subject.colorHex,
      modules: updatedModules,
    );

    _syllabus[sIndex] = updatedSubject;
    await _saveSyllabus();
    notifyListeners();
  }

  Future<void> _saveSyllabus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSyllabusKey, jsonEncode(_syllabus.map((s) => s.toJson()).toList()));
  }

  // --- Assignment Actions ---
  Future<void> addAssignment(Assignment assignment) async {
    _assignments.insert(0, assignment);
    await _saveAssignments();
    notifyListeners();
  }

  Future<void> updateAssignmentStatus(String id, AssignmentStatus status) async {
    final index = _assignments.indexWhere((a) => a.id == id);
    if (index != -1) {
      _assignments[index] = _assignments[index].copyWith(status: status);
      await _saveAssignments();
      notifyListeners();
    }
  }

  Future<void> deleteAssignment(String id) async {
    _assignments.removeWhere((a) => a.id == id);
    await _saveAssignments();
    notifyListeners();
  }

  Future<void> _saveAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kAssignmentsKey,
      jsonEncode(_assignments.map((a) => a.toJson()).toList()),
    );
  }

  // --- Reset to Default ---
  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kExamsKey);
    await prefs.remove(_kSyllabusKey);
    await prefs.remove(_kAssignmentsKey);
    await prefs.remove(_kPYQsKey);
    await init();
  }
}

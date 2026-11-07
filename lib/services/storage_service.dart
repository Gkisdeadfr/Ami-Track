import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exam.dart';
import '../models/syllabus.dart';
import '../models/assignment.dart';
import '../models/pyq.dart';
import '../data/initial_data.dart';

class StorageService extends ChangeNotifier {
  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  static const String _kExamsKey = 'clg_exams_v1';
  static const String _kSyllabusKey = 'clg_syllabus_v1';
  static const String _kAssignmentsKey = 'clg_assignments_v1';
  static const String _kPYQsKey = 'clg_pyqs_v1';

  List<ExamItem> _exams = [];
  List<SyllabusSubject> _syllabus = [];
  List<Assignment> _assignments = [];
  List<PYQItem> _pyqs = [];
  bool _isLoaded = false;

  List<ExamItem> get exams => List.unmodifiable(_exams);
  List<SyllabusSubject> get syllabus => List.unmodifiable(_syllabus);
  List<Assignment> get assignments => List.unmodifiable(_assignments);
  List<PYQItem> get pyqs => List.unmodifiable(_pyqs);
  bool get isLoaded => _isLoaded;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

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

    _isLoaded = true;
    notifyListeners();
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

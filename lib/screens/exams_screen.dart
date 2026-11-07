import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/exam.dart';
import '../models/syllabus.dart';
import '../services/storage_service.dart';

class ExamsScreen extends StatefulWidget {
  final int initialTabIndex;
  const ExamsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StorageService.instance,
      builder: (context, _) {
        final allExams = StorageService.instance.exams;
        final practicals =
            allExams.where((e) => e.type == ExamType.practical).toList();
        final theory =
            allExams.where((e) => e.type == ExamType.theory).toList();
        final minors =
            allExams.where((e) => e.type == ExamType.minor).toList();

        // Sort each by date ascending
        practicals.sort((a, b) => a.date.compareTo(b.date));
        theory.sort((a, b) => a.date.compareTo(b.date));
        allExams.toList().sort((a, b) => a.date.compareTo(b.date));

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.indigo.shade800,
            title: const Text(
              'Exam Schedule & Timings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 19,
                color: Colors.white,
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: Colors.amberAccent,
              indicatorWeight: 3,
              labelColor: Colors.amberAccent,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 6),
                      Text('All (${allExams.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.biotech, size: 16),
                      const SizedBox(width: 6),
                      Text('Practicals (${practicals.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book, size: 16),
                      const SizedBox(width: 6),
                      Text('Theory (${theory.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.history_edu, size: 16),
                      const SizedBox(width: 6),
                      Text('Minors (${minors.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildExamList(allExams, 'All Exams'),
              _buildExamList(
                practicals,
                'End Sem Practical Exams (3CSE3-X)',
                badgeColor: Colors.teal,
              ),
              _buildExamList(
                theory,
                'End Sem Theory Exams',
                badgeColor: Colors.indigo,
              ),
              _buildExamList(
                minors,
                'Minor Exams',
                badgeColor: Colors.orange,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddExamDialog(context),
            backgroundColor: Colors.indigo.shade800,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Add Exam',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExamList(
    List<ExamItem> exams,
    String header, {
    Color badgeColor = Colors.indigo,
  }) {
    if (exams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No exams found in this category',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: exams.length,
      itemBuilder: (context, index) {
        final exam = exams[index];
        final examDay = DateTime(exam.date.year, exam.date.month, exam.date.day);
        final diffDays = examDay.difference(today).inDays;

        String daysText;
        Color countdownColor;
        if (diffDays < 0) {
          daysText = 'Completed';
          countdownColor = Colors.grey;
        } else if (diffDays == 0) {
          daysText = 'TODAY!';
          countdownColor = Colors.red.shade700;
        } else if (diffDays == 1) {
          daysText = 'Tomorrow';
          countdownColor = Colors.deepOrange;
        } else {
          daysText = 'In $diffDays days';
          countdownColor = Colors.blue.shade700;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: diffDays == 0
                  ? Colors.red.shade300
                  : (diffDays > 0 && diffDays <= 7)
                      ? Colors.amber.shade400
                      : Colors.grey.shade200,
              width: diffDays == 0 || (diffDays > 0 && diffDays <= 7) ? 1.8 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Type Tag & Countdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: exam.type == ExamType.practical
                            ? Colors.teal.shade50
                            : exam.type == ExamType.theory
                                ? Colors.indigo.shade50
                                : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            exam.type == ExamType.practical
                                ? Icons.biotech
                                : exam.type == ExamType.theory
                                    ? Icons.menu_book
                                    : Icons.history_edu,
                            size: 14,
                            color: exam.type == ExamType.practical
                                ? Colors.teal.shade700
                                : exam.type == ExamType.theory
                                    ? Colors.indigo.shade700
                                    : Colors.orange.shade800,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            exam.type.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: exam.type == ExamType.practical
                                  ? Colors.teal.shade800
                                  : exam.type == ExamType.theory
                                      ? Colors.indigo.shade800
                                      : Colors.orange.shade900,
                            ),
                          ),
                          if (exam.subjectCode.isNotEmpty) ...[
                            Text(
                              ' • ${exam.subjectCode}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: countdownColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        daysText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: countdownColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  exam.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 10),

                // Date & Time Row
                Row(
                  children: [
                    Icon(Icons.event, size: 16, color: Colors.indigo.shade600),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('EEE, dd MMM yyyy').format(exam.date),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.schedule, size: 16, color: Colors.indigo.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        exam.time,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Room & Faculty Row
                if (exam.labOrRoom.isNotEmpty || exam.faculty.isNotEmpty) ...[
                  Row(
                    children: [
                      if (exam.labOrRoom.isNotEmpty) ...[
                        Icon(Icons.room, size: 16, color: Colors.red.shade400),
                        const SizedBox(width: 4),
                        Text(
                          exam.labOrRoom,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 14),
                      ],
                      if (exam.faculty.isNotEmpty) ...[
                        Icon(Icons.person, size: 16, color: Colors.blue.shade400),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            exam.faculty,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Exam mode & syllabus button
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        exam.mode,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _showSyllabusModal(context, exam),
                      icon: const Icon(Icons.library_books, size: 16),
                      label: const Text(
                        'View Syllabus',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSyllabusModal(BuildContext context, ExamItem exam) {
    // Check if we have linked subject syllabus
    final matchedSubject = StorageService.instance.syllabus.firstWhere(
      (s) =>
          s.subjectCode.toLowerCase() == exam.subjectCode.toLowerCase() ||
          exam.title.toLowerCase().contains(s.subjectName.toLowerCase()),
      orElse: () => StorageService.instance.syllabus.first,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          exam.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Time: ${exam.time} • Room: ${exam.labOrRoom.isEmpty ? "TBA" : exam.labOrRoom}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Divider(height: 24),
                  if (exam.syllabusSummary.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Syllabus Summary:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            exam.syllabusSummary,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade800,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'Detailed Modules & Topics:',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: matchedSubject.modules.length,
                      itemBuilder: (context, mIdx) {
                        final mod = matchedSubject.modules[mIdx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ExpansionTile(
                            initiallyExpanded: mIdx == 0,
                            title: Text(
                              mod.moduleTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              'Weightage: ${mod.weightage}% • ${mod.topics.length} topics',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            children: mod.topics.map((t) {
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: Colors.indigo.shade400,
                                ),
                                title: Text(
                                  t.title,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    t.status.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddExamDialog(BuildContext context) {
    final titleController = TextEditingController();
    final codeController = TextEditingController();
    final timeController = TextEditingController(text: '10:00 AM');
    final roomController = TextEditingController();
    final facultyController = TextEditingController();
    final syllabusController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    ExamType selectedType = ExamType.theory;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Add Exam / Test',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Subject / Exam Title *',
                        hintText: 'e.g. Operating Systems',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: codeController,
                            decoration: const InputDecoration(
                              labelText: 'Subject Code',
                              hintText: 'e.g. CS205',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<ExamType>(
                            value: selectedType,
                            decoration: const InputDecoration(labelText: 'Type'),
                            items: ExamType.values.map((t) {
                              return DropdownMenuItem(
                                value: t,
                                child: Text(t.name.toUpperCase()),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setDialogState(() => selectedType = v);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              DateFormat('dd MMM yyyy').format(selectedDate),
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2025),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setDialogState(() => selectedDate = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: timeController,
                            decoration: const InputDecoration(
                              labelText: 'Timing',
                              hintText: '10:00 AM',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: roomController,
                            decoration: const InputDecoration(
                              labelText: 'Room / Lab',
                              hintText: 'e.g. E1-1LA2',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: facultyController,
                            decoration: const InputDecoration(
                              labelText: 'Faculty / Invigilator',
                              hintText: 'e.g. Dr. Sharma',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: syllabusController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Syllabus Overview',
                        hintText: 'Units 1-4, key topics...',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade800,
                  ),
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) return;
                    final newExam = ExamItem(
                      id: 'exam-${DateTime.now().millisecondsSinceEpoch}',
                      title: titleController.text.trim(),
                      subjectCode: codeController.text.trim(),
                      date: selectedDate,
                      time: timeController.text.trim(),
                      type: selectedType,
                      labOrRoom: roomController.text.trim(),
                      faculty: facultyController.text.trim(),
                      syllabusSummary: syllabusController.text.trim(),
                    );
                    StorageService.instance.addExam(newExam);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Save Exam',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/exam.dart';
import '../models/exam_result.dart';
import '../models/syllabus.dart';
import '../services/amizone_service.dart';
import '../services/storage_service.dart';

enum ExamSortOption {
  nearestFirst,
  latestFirst,
  codeAsc,
  titleAsc,
  type,
}

class ExamsScreen extends StatefulWidget {
  final int initialTabIndex;
  const ExamsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ExamSortOption _sortOption = ExamSortOption.nearestFirst;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 4),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ExamItem> _sortExams(List<ExamItem> list) {
    final sorted = List<ExamItem>.from(list);
    switch (_sortOption) {
      case ExamSortOption.nearestFirst:
        sorted.sort((a, b) => a.date.compareTo(b.date));
        break;
      case ExamSortOption.latestFirst:
        sorted.sort((a, b) => b.date.compareTo(a.date));
        break;
      case ExamSortOption.codeAsc:
        sorted.sort((a, b) => a.subjectCode.compareTo(b.subjectCode));
        break;
      case ExamSortOption.titleAsc:
        sorted.sort((a, b) => a.title.compareTo(b.title));
        break;
      case ExamSortOption.type:
        sorted.sort((a, b) => a.type.index.compareTo(b.type.index));
        break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StorageService.instance,
      builder: (context, _) {
        final storage = StorageService.instance;
        final rawExams = storage.exams;
        final practicals = _sortExams(rawExams.where((e) => e.type == ExamType.practical).toList());
        final theory = _sortExams(rawExams.where((e) => e.type == ExamType.theory).toList());
        final minors = _sortExams(rawExams.where((e) => e.type == ExamType.minor).toList());
        final allExams = _sortExams(rawExams);
        final latestResult = storage.latestResult;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Exam Schedule & Results',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.sort, color: Colors.white),
                tooltip: 'Sort exams',
                onPressed: () => _showSortSheet(context),
              ),
              IconButton(
                icon: const Icon(Icons.sync, color: Colors.white),
                tooltip: 'Sync Exam Data',
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await AmizoneService.instance.refresh();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(AmizoneService.instance.statusMessage ?? 'Exams synced!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
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
                      const Icon(Icons.calendar_today, size: 15),
                      const SizedBox(width: 6),
                      Text('All (${allExams.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.biotech, size: 15),
                      const SizedBox(width: 6),
                      Text('Practicals (${practicals.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book, size: 15),
                      const SizedBox(width: 6),
                      Text('Theory (${theory.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.history_edu, size: 15),
                      const SizedBox(width: 6),
                      Text('Minors (${minors.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium, size: 15),
                      const SizedBox(width: 6),
                      Text(latestResult != null ? 'Results (${latestResult.courses.length})' : 'Results'),
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
              _buildExamList(practicals, 'Practical Exams', badgeColor: Colors.teal),
              _buildExamList(theory, 'Theory Exams', badgeColor: Colors.indigo),
              _buildExamList(minors, 'Minor Exams', badgeColor: Colors.orange),
              _buildResultsTab(context, latestResult),
            ],
          ),
          floatingActionButton: _tabController.index != 4
              ? FloatingActionButton.extended(
                  onPressed: () => _showAddExamDialog(context),
                  backgroundColor: const Color(0xFF1E3A8A),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Add Exam',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                )
              : null,
        );
      },
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sort Exams By',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.calendar_month, color: Colors.blue),
                  title: const Text('Earliest Date (Upcoming First)'),
                  trailing: _sortOption == ExamSortOption.nearestFirst
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() => _sortOption = ExamSortOption.nearestFirst);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.event_repeat, color: Colors.teal),
                  title: const Text('Furthest Date (Latest First)'),
                  trailing: _sortOption == ExamSortOption.latestFirst
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() => _sortOption = ExamSortOption.latestFirst);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Subject Code (A-Z)'),
                  trailing: _sortOption == ExamSortOption.codeAsc
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() => _sortOption = ExamSortOption.codeAsc);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.title),
                  title: const Text('Exam Title (A-Z)'),
                  trailing: _sortOption == ExamSortOption.titleAsc
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() => _sortOption = ExamSortOption.titleAsc);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.category),
                  title: const Text('Exam Type'),
                  trailing: _sortOption == ExamSortOption.type
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() => _sortOption = ExamSortOption.type);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultsTab(BuildContext context, SemesterResult? result) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (result == null || result.courses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.workspace_premium_outlined, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.6)),
              const SizedBox(height: 16),
              const Text(
                'No Exam Results Loaded Yet',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Amizone exam results are automatically scraped from /Examination/ExamResult when you sync with an active session.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.65)),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                ),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await AmizoneService.instance.refresh();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(AmizoneService.instance.statusMessage ?? 'Synced!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.sync, size: 18),
                label: const Text('Sync Results from Amizone'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // Semester summary banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    result.semesterName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${result.totalCredits.toInt()} Credits',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SGPA', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(
                            result.sgpa > 0 ? result.sgpa.toStringAsFixed(2) : '--',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CGPA', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(
                            result.cgpa > 0 ? result.cgpa.toStringAsFixed(2) : '--',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Course Grades (${result.courses.length} subjects)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),

        ...result.courses.map((c) {
          Color gradeColor;
          if (c.grade.startsWith('A')) {
            gradeColor = Colors.green;
          } else if (c.grade.startsWith('B')) {
            gradeColor = Colors.blue;
          } else if (c.grade.startsWith('C')) {
            gradeColor = Colors.orange;
          } else {
            gradeColor = Colors.red;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: gradeColor.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    c.grade,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: gradeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            c.courseCode,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          if (c.credits > 0) ...[
                            Text(
                              ' • ${c.credits.toInt()} Credits',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        c.courseName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (c.resultStatus.toLowerCase() == 'passed' ? Colors.green : Colors.blue).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    c.resultStatus,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: c.resultStatus.toLowerCase() == 'passed' ? Colors.green : Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildExamList(
    List<ExamItem> exams,
    String header, {
    Color badgeColor = Colors.indigo,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (exams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 56, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'No exams found in this category',
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 16),
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
          countdownColor = Colors.red;
        } else if (diffDays == 1) {
          daysText = 'Tomorrow';
          countdownColor = Colors.deepOrange;
        } else {
          daysText = 'In $diffDays days';
          countdownColor = Colors.blue;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: diffDays == 0
                  ? Colors.red.withValues(alpha: isDark ? 0.6 : 0.4)
                  : (diffDays > 0 && diffDays <= 7)
                      ? Colors.amber.withValues(alpha: isDark ? 0.6 : 0.4)
                      : theme.dividerColor,
              width: diffDays == 0 || (diffDays > 0 && diffDays <= 7) ? 1.8 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: exam.type == ExamType.practical
                            ? Colors.teal.withValues(alpha: 0.12)
                            : exam.type == ExamType.theory
                                ? Colors.indigo.withValues(alpha: 0.12)
                                : Colors.orange.withValues(alpha: 0.12),
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
                                ? Colors.teal
                                : exam.type == ExamType.theory
                                    ? Colors.indigoAccent
                                    : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            exam.type.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: exam.type == ExamType.practical
                                  ? Colors.teal
                                  : exam.type == ExamType.theory
                                      ? Colors.indigoAccent
                                      : Colors.orange,
                            ),
                          ),
                          if (exam.subjectCode.isNotEmpty) ...[
                            Text(
                              ' • ${exam.subjectCode}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: countdownColor.withValues(alpha: 0.12),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),

                // Date & Time Row
                Row(
                  children: [
                    Icon(Icons.event, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('EEE, dd MMM yyyy').format(exam.date),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.schedule, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        exam.time,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
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
                        const Icon(Icons.room, size: 16, color: Colors.redAccent),
                        const SizedBox(width: 4),
                        Text(
                          exam.labOrRoom,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(width: 14),
                      ],
                      if (exam.faculty.isNotEmpty) ...[
                        const Icon(Icons.person, size: 16, color: Colors.blueAccent),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            exam.faculty,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Exam mode & syllabus button
                Divider(height: 18, color: theme.dividerColor),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        exam.mode,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
    final matchedSubject = StorageService.instance.syllabus.firstWhere(
      (s) =>
          s.subjectCode.toLowerCase() == exam.subjectCode.toLowerCase() ||
          exam.title.toLowerCase().contains(s.subjectName.toLowerCase()),
      orElse: () => StorageService.instance.syllabus.first,
    );

    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                        color: theme.dividerColor,
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
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Divider(height: 24, color: theme.dividerColor),
                  if (exam.syllabusSummary.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
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
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            exam.syllabusSummary,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
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
                            border: Border.all(color: theme.dividerColor),
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
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            children: mod.topics.map((t) {
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: theme.colorScheme.primary,
                                ),
                                title: Text(
                                  t.title,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    t.status.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
                            initialValue: selectedType,
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
                    backgroundColor: const Color(0xFF1E3A8A),
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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/exam.dart';
import '../models/syllabus.dart';
import '../models/assignment.dart';
import '../services/amizone_service.dart';
import '../services/scraper_service.dart';
import '../services/storage_service.dart';

class HomeScreen extends StatelessWidget {
  final Function(int) onTabChange;
  final VoidCallback onSignOut;
  const HomeScreen({super.key, required this.onTabChange, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([StorageService.instance, AmizoneService.instance]),
      builder: (context, _) {
        final amizone = AmizoneService.instance;
        final exams = StorageService.instance.exams;
        final syllabus = StorageService.instance.syllabus;
        final assignments = StorageService.instance.assignments;

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Upcoming exams (future or today)
        final upcomingExams = exams
            .where((e) => !e.date.isBefore(today))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        final nextExam = upcomingExams.isNotEmpty ? upcomingExams.first : null;

        // Syllabus stats
        int totalTopics = 0;
        int completedTopics = 0;
        int revisionTopics = 0;
        for (var s in syllabus) {
          totalTopics += s.totalTopics;
          completedTopics += s.completedTopics;
          revisionTopics += s.revisionTopics;
        }
        final overallProgress =
            totalTopics > 0 ? (completedTopics / totalTopics) : 0.0;

        // Pending assignments
        final pendingAssignments =
            assignments.where((a) => a.status != AssignmentStatus.submitted).length;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.indigo.shade800,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CampusTrack',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                Text(
                  amizone.isSignedIn && amizone.username.isNotEmpty
                      ? '${amizone.username} • ${amizone.courses.length} subjects synced'
                      : 'Sign in to Amizone to sync your data',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.indigo.shade100,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.sync, color: Colors.white),
                tooltip: 'Sync from Amizone & NexAcad',
                onPressed: () => _sync(context),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) async {
                  if (value == 'sync') await _sync(context);
                  if (value == 'reset') await StorageService.instance.resetAll();
                  if (value == 'signout') onSignOut();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'sync', child: Text('Sync now')),
                  PopupMenuItem(value: 'reset', child: Text('Reset local trackers')),
                  PopupMenuItem(value: 'signout', child: Text('Sign out')),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // Next Exam Hero Card
              if (nextExam != null) ...[
                _buildNextExamCard(context, nextExam, today),
                const SizedBox(height: 18),
              ],

              // Quick Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Syllabus',
                      value: '${(overallProgress * 100).toInt()}%',
                      subtitle: '$completedTopics of $totalTopics done',
                      icon: Icons.pie_chart,
                      color: Colors.teal,
                      onTap: () => onTabChange(1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'To Revise',
                      value: '$revisionTopics',
                      subtitle: 'Topics marked',
                      icon: Icons.replay,
                      color: Colors.deepOrange,
                      onTap: () => onTabChange(1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Pending Asg',
                      value: '$pendingAssignments',
                      subtitle: 'Needs submission',
                      icon: Icons.assignment_late,
                      color: Colors.blue,
                      onTap: () => onTabChange(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Total Exams',
                      value: '${upcomingExams.length}',
                      subtitle: 'Upcoming dates',
                      icon: Icons.calendar_today,
                      color: Colors.purple,
                      onTap: () => onTabChange(0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Upcoming Practical Exams (Highlighting user's 3CSE3-X)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upcoming Practicals',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  TextButton(
                    onPressed: () => onTabChange(0),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...upcomingExams
                  .where((e) => e.type == ExamType.practical)
                  .take(3)
                  .map((e) => _buildExamRow(context, e, today)),

              const SizedBox(height: 18),

              // Upcoming Theory Exams
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upcoming Theory Exams',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  TextButton(
                    onPressed: () => onTabChange(0),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...upcomingExams
                  .where((e) => e.type == ExamType.theory)
                  .take(3)
                  .map((e) => _buildExamRow(context, e, today)),

              const SizedBox(height: 18),

              // Quick Revision Checklist
              _buildRevisionSection(context, syllabus),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sync(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final amizone = AmizoneService.instance;

    final attendanceOk = await amizone.refresh();
    final libraryOk = await ScraperService.instance.syncFromNexacad(
      enrolledCodes: amizone.courses.map((c) => c.subjectCode).toList(),
    );

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          [
            attendanceOk
                ? 'Attendance synced (${amizone.courses.length} subjects).'
                : amizone.statusMessage ?? 'Attendance sync failed.',
            libraryOk ? 'Library synced.' : 'Library kept from last sync.',
          ].join(' '),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildNextExamCard(
    BuildContext context,
    ExamItem exam,
    DateTime today,
  ) {
    final examDay = DateTime(exam.date.year, exam.date.month, exam.date.day);
    final daysLeft = examDay.difference(today).inDays;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.shade900,
            Colors.indigo.shade800,
            Colors.blue.shade900,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.shade900.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amberAccent.shade400,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    daysLeft == 0
                        ? '🔥 EXAM TODAY'
                        : daysLeft == 1
                            ? '⏰ EXAM TOMORROW'
                            : 'NEXT IN $daysLeft DAYS',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    exam.type.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              exam.title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.event, size: 15, color: Colors.amberAccent),
                const SizedBox(width: 6),
                Text(
                  DateFormat('EEE, dd MMM yyyy').format(exam.date),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(width: 14),
                const Icon(Icons.schedule, size: 15, color: Colors.amberAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    exam.time,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
            if (exam.labOrRoom.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.room, size: 15, color: Colors.pinkAccent),
                  const SizedBox(width: 6),
                  Text(
                    'Venue: ${exam.labOrRoom}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  if (exam.faculty.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Text(
                      '• ${exam.faculty}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
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
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                Icon(icon, size: 20, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamRow(
    BuildContext context,
    ExamItem exam,
    DateTime today,
  ) {
    final examDay = DateTime(exam.date.year, exam.date.month, exam.date.day);
    final days = examDay.difference(today).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: exam.type == ExamType.practical
                  ? Colors.teal.shade50
                  : Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('dd').format(exam.date),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: exam.type == ExamType.practical
                        ? Colors.teal.shade900
                        : Colors.indigo.shade900,
                  ),
                ),
                Text(
                  DateFormat('MMM').format(exam.date),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: exam.type == ExamType.practical
                        ? Colors.teal.shade800
                        : Colors.indigo.shade800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${exam.time} • ${exam.labOrRoom.isEmpty ? "Hall" : exam.labOrRoom}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: days <= 3 ? Colors.red.shade50 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              days == 0 ? 'Today' : 'in $days d',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: days <= 3 ? Colors.red.shade700 : Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevisionSection(
    BuildContext context,
    List<SyllabusSubject> subjects,
  ) {
    final List<Map<String, dynamic>> revisionList = [];
    for (var sub in subjects) {
      for (var mod in sub.modules) {
        for (var top in mod.topics) {
          if (top.status == TopicStatus.needsRevision) {
            revisionList.add({
              'subjectCode': sub.subjectCode,
              'topic': top.title,
              'subjectId': sub.id,
            });
          }
        }
      }
    }

    if (revisionList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Topics to Revise',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            Text(
              '${revisionList.length} items',
              style: TextStyle(fontSize: 12, color: Colors.deepOrange.shade700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...revisionList.take(4).map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.purple.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.replay, size: 16, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item['subjectCode'],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item['topic'],
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

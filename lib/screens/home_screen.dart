import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/exam.dart';
import '../models/syllabus.dart';
import '../models/assignment.dart';
import '../services/amizone_service.dart';
import '../services/scraper_service.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';
import '../widgets/account_switcher.dart';

class HomeScreen extends StatelessWidget {
  final Function(int) onTabChange;
  final VoidCallback onSignOut;
  final VoidCallback? onSwitchAccount;
  const HomeScreen({
    super.key,
    required this.onTabChange,
    required this.onSignOut,
    this.onSwitchAccount,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        StorageService.instance,
        AmizoneService.instance,
        ThemeService.instance,
      ]),
      builder: (context, _) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final amizone = AmizoneService.instance;
        final storage = StorageService.instance;
        final exams = storage.exams;
        final syllabus = storage.syllabus;
        final assignments = storage.assignments;
        final result = storage.latestResult;

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

        // Attendance stats
        int totalAttended = 0;
        int totalHeld = 0;
        for (var c in amizone.courses) {
          totalAttended += c.attended;
          totalHeld += c.held;
        }
        final attendancePercent = totalHeld > 0 ? (totalAttended / totalHeld) * 100 : 100.0;

        return Scaffold(
          appBar: AppBar(
            title: InkWell(
              onTap: onSwitchAccount ?? () => showAccountSwitcher(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ami-Track',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      amizone.isSignedIn && amizone.username.isNotEmpty
                          ? (amizone.name.isNotEmpty
                              ? '${amizone.name} (${amizone.displayEnrollment}) • ${amizone.courses.length} subjects'
                              : '${amizone.displayEnrollment} • ${amizone.courses.length} subjects')
                          : 'Sign in to Amizone to sync',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: Colors.white,
                ),
                tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                onPressed: () => ThemeService.instance.toggleTheme(),
              ),
              IconButton(
                icon: const Icon(Icons.switch_account_outlined, color: Colors.white),
                tooltip: 'Switch user account',
                onPressed: onSwitchAccount ?? () => showAccountSwitcher(context),
              ),
              IconButton(
                icon: const Icon(Icons.sync, color: Colors.white),
                tooltip: 'Sync data',
                onPressed: () => _sync(context),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) async {
                  if (value == 'theme') _showThemePicker(context);
                  if (value == 'accounts') {
                    if (onSwitchAccount != null) {
                      onSwitchAccount!();
                    } else if (context.mounted) {
                      await showAccountSwitcher(context);
                    }
                  }
                  if (value == 'sync' && context.mounted) await _sync(context);
                  if (value == 'reset') await StorageService.instance.resetAll();
                  if (value == 'signout') onSignOut();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'theme', child: Text('Theme options')),
                  const PopupMenuItem(value: 'accounts', child: Text('Switch account')),
                  const PopupMenuItem(value: 'sync', child: Text('Sync now')),
                  const PopupMenuItem(value: 'reset', child: Text('Reset local trackers')),
                  PopupMenuItem(
                    value: 'signout',
                    child: Text(
                      amizone.username.isEmpty
                          ? 'Sign out'
                          : 'Sign out ${amizone.displayName}',
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            children: [
              // Next Exam Hero Card
              if (nextExam != null) ...[
                _buildNextExamCard(context, nextExam, today),
                const SizedBox(height: 16),
              ],

              // Attendance Banner if synced
              if (amizone.courses.isNotEmpty) ...[
                _buildAttendanceBanner(context, attendancePercent, totalAttended, totalHeld, amizone.globalTarget),
                const SizedBox(height: 14),
              ],

              // Quick Exam Result Summary if available
              if (result != null) ...[
                _buildResultCard(context, result),
                const SizedBox(height: 14),
              ],

              // Quick Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      title: 'Syllabus',
                      value: '${(overallProgress * 100).toInt()}%',
                      subtitle: '$completedTopics of $totalTopics done',
                      icon: Icons.pie_chart_outline,
                      color: Colors.teal,
                      onTap: () => onTabChange(1), // Syllabus tab
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      title: 'To Revise',
                      value: '$revisionTopics',
                      subtitle: 'Topics flagged',
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
                      context,
                      title: 'Pending Tasks',
                      value: '$pendingAssignments',
                      subtitle: 'Due assignments',
                      icon: Icons.assignment_late_outlined,
                      color: Colors.blue,
                      onTap: () => onTabChange(2), // Tasks tab
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      title: 'Exams',
                      value: '${upcomingExams.length}',
                      subtitle: 'Upcoming dates',
                      icon: Icons.calendar_today_outlined,
                      color: Colors.purple,
                      onTap: () => onTabChange(0), // Exams tab
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Upcoming Practical Exams
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upcoming Practicals',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
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

              const SizedBox(height: 16),

              // Upcoming Theory Exams
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upcoming Theory Exams',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
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

  void _showThemePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final current = ThemeService.instance.themeMode;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose App Theme',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.brightness_auto),
                  title: const Text('System Default'),
                  trailing: current == ThemeMode.system ? const Icon(Icons.check, color: Colors.blue) : null,
                  onTap: () {
                    ThemeService.instance.setThemeMode(ThemeMode.system);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.light_mode),
                  title: const Text('Light Mode'),
                  trailing: current == ThemeMode.light ? const Icon(Icons.check, color: Colors.blue) : null,
                  onTap: () {
                    ThemeService.instance.setThemeMode(ThemeMode.light);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text('Dark Mode'),
                  trailing: current == ThemeMode.dark ? const Icon(Icons.check, color: Colors.blue) : null,
                  onTap: () {
                    ThemeService.instance.setThemeMode(ThemeMode.dark);
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

  Widget _buildAttendanceBanner(
    BuildContext context,
    double percent,
    int attended,
    int held,
    double target,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSafe = percent >= target;

    return InkWell(
      onTap: () {
        // Tab index for Attendance is handled directly in main navigation
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSafe
                ? Colors.green.withValues(alpha: isDark ? 0.4 : 0.25)
                : Colors.red.withValues(alpha: isDark ? 0.4 : 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isSafe ? Colors.green : Colors.red).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSafe ? Icons.verified : Icons.warning_amber,
                color: isSafe ? Colors.green : Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Overall Attendance',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        '${percent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSafe ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$attended attended of $held marked classes (Target: ${target.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, dynamic result) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium, color: Colors.amber.shade700, size: 24),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Latest Amizone Result',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${result.courses.length} courses graded',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              if (result.sgpa > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'SGPA: ${result.sgpa.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              if (result.cgpa > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'CGPA: ${result.cgpa.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
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
                ? 'Amizone synced (${amizone.courses.length} subjects).'
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
            const Color(0xFF1E3A8A),
            const Color(0xFF1E40AF),
            const Color(0xFF2563EB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                fontSize: 18,
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

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
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
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
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
    final theme = Theme.of(context);
    final examDay = DateTime(exam.date.year, exam.date.month, exam.date.day);
    final days = examDay.difference(today).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: exam.type == ExamType.practical
                  ? Colors.teal.withValues(alpha: 0.12)
                  : Colors.indigo.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('dd').format(exam.date),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: exam.type == ExamType.practical ? Colors.teal : Colors.indigoAccent,
                  ),
                ),
                Text(
                  DateFormat('MMM').format(exam.date),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: exam.type == ExamType.practical ? Colors.teal : Colors.indigoAccent,
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${exam.time} • ${exam.labOrRoom.isEmpty ? "Hall" : exam.labOrRoom}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (days <= 3 ? Colors.red : Colors.blue).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              days == 0 ? 'Today' : 'in $days d',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: days <= 3 ? Colors.red : Colors.blue,
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
    final theme = Theme.of(context);
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
            Text(
              'Topics to Revise',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
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
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.replay, size: 16, color: Colors.purple.shade400),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item['subjectCode'],
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.purpleAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item['topic'],
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface,
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
}

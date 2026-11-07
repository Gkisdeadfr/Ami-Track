import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../services/amizone_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final Map<String, int> _simulatedExtraBunks = {};

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AmizoneService.instance,
      builder: (context, _) {
        final amizone = AmizoneService.instance;
        final courses = amizone.courses;

        int totalAttended = 0;
        int totalHeld = 0;
        for (var c in courses) {
          totalAttended += c.attended;
          totalHeld += c.held;
        }

        final overallPercent =
            totalHeld > 0 ? (totalAttended / totalHeld) * 100.0 : 100.0;

        int overallMarks;
        if (overallPercent <= 75.00) {
          overallMarks = 0;
        } else if (overallPercent <= 80.00) {
          overallMarks = 1;
        } else if (overallPercent <= 85.00) {
          overallMarks = 2;
        } else if (overallPercent <= 90.00) {
          overallMarks = 3;
        } else if (overallPercent <= 95.00) {
          overallMarks = 4;
        } else {
          overallMarks = 5;
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.indigo.shade800,
            title: const Text(
              'Amizone Attendance & Bunk Planner',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.sync, color: Colors.white),
                tooltip: 'Sync Attendance',
                onPressed: () => _handleSync(context),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            children: [
              // 1. Target Attendance Selection
              _buildTargetSelector(context, amizone),
              const SizedBox(height: 12),

              // 2. Overall Attendance & Marks Overview
              _buildOverallSummary(overallPercent, overallMarks, totalAttended, totalHeld, amizone.globalTarget),
              const SizedBox(height: 14),

              if (courses.isEmpty) ...[
                _buildEmptyState(),
                const SizedBox(height: 14),
              ],

              if (amizone.isLoading) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 12),
              ],

              if (amizone.statusMessage != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.indigo.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.indigo.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          amizone.statusMessage!,
                          style: TextStyle(fontSize: 12, color: Colors.indigo.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 4. Section Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Subject-Wise Leave & Credit Calculations',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    '${courses.length} Subjects',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 5. Course Cards
              ...courses.map((course) => _buildCourseCard(context, course, amizone.globalTarget)),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_download_outlined, size: 34, color: Colors.indigo.shade300),
          const SizedBox(height: 8),
          const Text(
            'No attendance scraped yet',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap the sync icon to scrape your courses from s.amizone.net.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSelector(BuildContext context, AmizoneService amizone) {
    final targets = [
      {'val': 75.0, 'label': '75% (Min Eligibility)'},
      {'val': 80.0, 'label': '80% (1 Mark)'},
      {'val': 85.0, 'label': '85% (2 Marks)'},
      {'val': 90.0, 'label': '90% (3 Marks)'},
      {'val': 95.0, 'label': '95% (4 Marks)'},
      {'val': 95.01, 'label': '95.01%+ (5/5 Full)'},
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Target Attendance to Maintain:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                '${amizone.globalTarget.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.indigo.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: targets.map((t) {
                final double val = t['val'] as double;
                final bool isSelected =
                    (amizone.globalTarget - val).abs() < 0.1;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      t['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: Colors.indigo.shade800,
                    backgroundColor: Colors.grey.shade100,
                    onSelected: (selected) {
                      if (selected) {
                        amizone.setGlobalTarget(val);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallSummary(
    double overallPercent,
    int marks,
    int attended,
    int held,
    double target,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade900, Colors.indigo.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.shade900.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Overall Attendance',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                '${overallPercent.toStringAsFixed(2)}%',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '$attended attended out of $held marked by teachers',
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Text(
                  'Secured Marks',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
                const SizedBox(height: 4),
                Text(
                  '$marks / 5',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.amberAccent,
                  ),
                ),
                Text(
                  marks == 5 ? '⭐ Max Marks' : 'Target: 5/5',
                  style: const TextStyle(color: Colors.white70, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(
    BuildContext context,
    CourseAttendance course,
    double target,
  ) {
    final int extraBunks = _simulatedExtraBunks[course.id] ?? 0;
    // Denominator increases from held to held + extraBunks, attended stays attended
    final double simulatedPercent = course.simulateWithExtraLeaves(extraBunks);
    final int safeConsecutive = course.safeConsecutiveBunks(target);
    final int neededToRecover = course.classesNeededToReach(target);

    Color badgeColor;
    if (course.percentage > 95.00) {
      badgeColor = Colors.green.shade700;
    } else if (course.percentage > 85.00) {
      badgeColor = Colors.blue.shade700;
    } else if (course.percentage > 75.00) {
      badgeColor = Colors.orange.shade800;
    } else {
      badgeColor = Colors.red.shade700;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Code & Current Ratio
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    course.subjectCode,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${course.percentage.toStringAsFixed(2)}% (${course.attended}/${course.held})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              course.subjectName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),

            // Credit rule & Denominator explanation
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calculate, size: 14, color: Colors.indigo.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Credits: ${course.credits}  •  Minimum Scheduled: ${course.minCreditLectures} lectures (${course.credits}×15)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    course.held >= course.minCreditLectures
                        ? '• ${course.held} classes marked by teacher till date (exceeded ${course.minCreditLectures} min). Total only increases as new classes are marked.'
                        : '• ${course.held} classes marked so far. At least ${course.minCreditLectures - course.held} more classes scheduled to complete credit requirement.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                  Text(
                    '• Leaves already taken: ${course.leavesTaken} class${course.leavesTaken == 1 ? "" : "es"} missed.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Safe Bunks logic (Explaining that denominator increases)
            if (safeConsecutive > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'You can safely bunk $safeConsecutive upcoming class${safeConsecutive > 1 ? "es" : ""}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'If you miss $safeConsecutive classes, denominator increases from ${course.held} to ${course.held + safeConsecutive}, resulting in ${course.attended}/${course.held + safeConsecutive} (${course.simulateWithExtraLeaves(safeConsecutive).toStringAsFixed(2)}% >= ${target.toStringAsFixed(1)}%).',
                      style: TextStyle(fontSize: 11, color: Colors.green.shade800),
                    ),
                  ],
                ),
              ),
            ] else if (neededToRecover > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  '⚠️ Below target! You must attend the next $neededToRecover classes consecutively to recover above ${target.toStringAsFixed(1)}%.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'On edge: Bunking 1 more class (denominator becomes ${course.held + 1}) will drop you below ${target.toStringAsFixed(1)}%!',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Live Simulator Slider/Counter: Shows Denominator Increasing!
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Simulate Bunks:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: extraBunks > 0
                          ? () {
                              setState(() {
                                _simulatedExtraBunks[course.id] = extraBunks - 1;
                              });
                            }
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '+$extraBunks class${extraBunks == 1 ? "" : "es"}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _simulatedExtraBunks[course.id] = extraBunks + 1;
                        });
                      },
                    ),
                  ],
                ),
                Text(
                  '${course.attended}/${course.held + extraBunks} (${simulatedPercent.toStringAsFixed(2)}%)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: simulatedPercent < target ? Colors.red : Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleSync(BuildContext context) async {
    final amizone = AmizoneService.instance;
    final messenger = ScaffoldMessenger.of(context);
    await amizone.refresh();
    messenger.showSnackBar(
      SnackBar(
        content: Text(amizone.statusMessage ?? 'Synced!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

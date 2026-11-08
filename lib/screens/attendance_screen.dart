import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../services/amizone_service.dart';

enum AttendanceSortOrder {
  dangerFirst,
  highestFirst,
  lowestBunksFirst,
  highestBunksFirst,
  codeAsc,
  nameAsc,
}

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final Map<String, int> _simulatedExtraBunks = {};
  AttendanceSortOrder _sortOrder = AttendanceSortOrder.dangerFirst;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CourseAttendance> _sortAndFilterCourses(List<CourseAttendance> courses, double target) {
    var list = List<CourseAttendance>.from(courses);

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((c) =>
          c.subjectCode.toLowerCase().contains(q) ||
          c.subjectName.toLowerCase().contains(q)).toList();
    }

    switch (_sortOrder) {
      case AttendanceSortOrder.dangerFirst:
        list.sort((a, b) => a.percentage.compareTo(b.percentage));
        break;
      case AttendanceSortOrder.highestFirst:
        list.sort((a, b) => b.percentage.compareTo(a.percentage));
        break;
      case AttendanceSortOrder.lowestBunksFirst:
        list.sort((a, b) => a.safeConsecutiveBunks(target).compareTo(b.safeConsecutiveBunks(target)));
        break;
      case AttendanceSortOrder.highestBunksFirst:
        list.sort((a, b) => b.safeConsecutiveBunks(target).compareTo(a.safeConsecutiveBunks(target)));
        break;
      case AttendanceSortOrder.codeAsc:
        list.sort((a, b) => a.subjectCode.compareTo(b.subjectCode));
        break;
      case AttendanceSortOrder.nameAsc:
        list.sort((a, b) => a.subjectName.compareTo(b.subjectName));
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AmizoneService.instance,
      builder: (context, _) {
        final theme = Theme.of(context);
        final amizone = AmizoneService.instance;
        final rawCourses = amizone.courses;
        final courses = _sortAndFilterCourses(rawCourses, amizone.globalTarget);

        int totalAttended = 0;
        int totalHeld = 0;
        for (var c in rawCourses) {
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
          appBar: AppBar(
            title: const Text(
              'Attendance & Bunk Planner',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.sort, color: Colors.white),
                tooltip: 'Sort options',
                onPressed: () => _showSortModal(context),
              ),
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
              const SizedBox(height: 12),

              if (amizone.isLoading) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 12),
              ],

              if (amizone.statusMessage != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          amizone.statusMessage!,
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 3. Search and Sort Filter Bar
              _buildSearchAndSortBar(context, rawCourses.length),
              const SizedBox(height: 10),

              if (rawCourses.isEmpty) ...[
                _buildEmptyState(),
                const SizedBox(height: 14),
              ],

              // 4. Course Cards
              ...courses.map((course) => _buildCourseCard(context, course, amizone.globalTarget)),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchAndSortBar(BuildContext context, int totalCount) {
    final theme = Theme.of(context);
    String sortLabel;
    switch (_sortOrder) {
      case AttendanceSortOrder.dangerFirst:
        sortLabel = 'Danger First';
        break;
      case AttendanceSortOrder.highestFirst:
        sortLabel = 'Highest %';
        break;
      case AttendanceSortOrder.lowestBunksFirst:
        sortLabel = 'Lowest Bunks';
        break;
      case AttendanceSortOrder.highestBunksFirst:
        sortLabel = 'Highest Bunks';
        break;
      case AttendanceSortOrder.codeAsc:
        sortLabel = 'Code (A-Z)';
        break;
      case AttendanceSortOrder.nameAsc:
        sortLabel = 'Name (A-Z)';
        break;
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search subjects or codes...',
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _showSortModal(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sort, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      sortLabel,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showSortModal(BuildContext context) {
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
                  'Sort Attendance By',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.warning_amber, color: Colors.red),
                  title: const Text('Critically Low Attendance First (Danger First)'),
                  trailing: _sortOrder == AttendanceSortOrder.dangerFirst
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() => _sortOrder = AttendanceSortOrder.dangerFirst);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.trending_up, color: Colors.green),
                  title: const Text('Highest Attendance First'),
                  trailing: _sortOrder == AttendanceSortOrder.highestFirst
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() => _sortOrder = AttendanceSortOrder.highestFirst);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.hourglass_bottom, color: Colors.orange),
                  title: const Text('Lowest Safe Bunks First'),
                  trailing: _sortOrder == AttendanceSortOrder.lowestBunksFirst
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() => _sortOrder = AttendanceSortOrder.lowestBunksFirst);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.beach_access, color: Colors.teal),
                  title: const Text('Most Safe Bunks First'),
                  trailing: _sortOrder == AttendanceSortOrder.highestBunksFirst
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() => _sortOrder = AttendanceSortOrder.highestBunksFirst);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.sort_by_alpha),
                  title: const Text('Subject Code (A-Z)'),
                  trailing: _sortOrder == AttendanceSortOrder.codeAsc
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() => _sortOrder = AttendanceSortOrder.codeAsc);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.text_fields),
                  title: const Text('Subject Name (A-Z)'),
                  trailing: _sortOrder == AttendanceSortOrder.nameAsc
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() => _sortOrder = AttendanceSortOrder.nameAsc);
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

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_download_outlined, size: 40, color: theme.colorScheme.primary),
          const SizedBox(height: 10),
          const Text(
            'No attendance records found',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap the sync icon above to scrape your courses & attendance from s.amizone.net.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSelector(BuildContext context, AmizoneService amizone) {
    final theme = Theme.of(context);
    final targets = [
      {'val': 75.0, 'label': '75% (Min)'},
      {'val': 80.0, 'label': '80% (1 Mk)'},
      {'val': 85.0, 'label': '85% (2 Mks)'},
      {'val': 90.0, 'label': '90% (3 Mks)'},
      {'val': 95.0, 'label': '95% (4 Mks)'},
      {'val': 95.01, 'label': '95.01%+ (Full 5/5)'},
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Target Attendance to Maintain:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${amizone.globalTarget.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: theme.colorScheme.primary,
                  ),
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
                        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: theme.colorScheme.primary,
                    backgroundColor: theme.cardColor,
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
              color: Colors.white.withValues(alpha: 0.15),
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
    final theme = Theme.of(context);
    final int extraBunks = _simulatedExtraBunks[course.id] ?? 0;
    final double simulatedPercent = course.simulateWithExtraLeaves(extraBunks);
    final int safeConsecutive = course.safeConsecutiveBunks(target);
    final int neededToRecover = course.classesNeededToReach(target);

    Color badgeColor;
    if (course.percentage > 95.00) {
      badgeColor = Colors.green;
    } else if (course.percentage > 85.00) {
      badgeColor = Colors.blue;
    } else if (course.percentage > 75.00) {
      badgeColor = Colors.orange;
    } else {
      badgeColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
            // Code & Current Ratio & Internal Marks
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        course.subjectCode,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    if (course.internalMarks > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Internal: ${course.internalMarks.toStringAsFixed(1)}/${course.maxInternal.toInt()}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
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
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),

            // Credit rule explanation
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calculate, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Credits: ${course.credits} • Min Lectures: ${course.minCreditLectures} (${course.credits}×15)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    course.held >= course.minCreditLectures
                        ? '• ${course.held} classes marked by teacher till date (credit threshold reached).'
                        : '• ${course.held} classes marked so far. At least ${course.minCreditLectures - course.held} more classes scheduled.',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.65)),
                  ),
                  Text(
                    '• Missed classes: ${course.leavesTaken} class${course.leavesTaken == 1 ? "" : "es"}.',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.65)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Safe Bunks logic
            if (safeConsecutive > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: Colors.green),
                        const SizedBox(width: 6),
                        Text(
                          'You can safely bunk $safeConsecutive upcoming class${safeConsecutive > 1 ? "es" : ""}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'If you miss $safeConsecutive classes, ratio becomes ${course.attended}/${course.held + safeConsecutive} (${course.simulateWithExtraLeaves(safeConsecutive).toStringAsFixed(2)}% >= ${target.toStringAsFixed(1)}%).',
                      style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                    ),
                  ],
                ),
              ),
            ] else if (neededToRecover > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '⚠️ Below target! You must attend the next $neededToRecover classes consecutively to recover above ${target.toStringAsFixed(1)}%.',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'On edge: Bunking 1 more class will drop you below ${target.toStringAsFixed(1)}%!',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Live Simulator Slider/Counter
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
                    color: simulatedPercent < target ? Colors.red : Colors.green,
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

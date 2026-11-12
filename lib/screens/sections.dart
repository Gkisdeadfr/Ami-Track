import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';

class DashboardSection extends StatelessWidget {
  const DashboardSection({super.key, required this.onOpenAttendance});
  final VoidCallback onOpenAttendance;

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final items = state.attendance;
    final attended = items.fold<int>(0, (sum, e) => sum + ((e['attended'] as num?)?.toInt() ?? 0));
    final held = items.fold<int>(0, (sum, e) => sum + ((e['held'] as num?)?.toInt() ?? 0));
    final percent = held == 0 ? 0.0 : attended / held * 100;
    final name = state.profile['name']?.toString().trim();
    final display = (name == null || name.isEmpty) ? state.username : name;
    final warnings = state.data['warnings'] is List ? state.data['warnings'] as List : const [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
      children: [
        Text('GOOD DAY,', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: .45), letterSpacing: 2, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(display, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, letterSpacing: -.6)),
        const SizedBox(height: 20),
        _HeroCard(percent: percent, attended: attended, held: held, courses: items.length),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(child: Text('Attendance snapshot', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
            TextButton(onPressed: onOpenAttendance, child: const Text('View all')),
          ],
        ),
        if (items.isEmpty)
          const _EmptyState(title: 'No attendance data yet', subtitle: 'Sync your Amizone account to fetch your subjects.')
        else
          ...items.take(4).map((e) => _CourseTile(course: e)),
        const SizedBox(height: 18),
        if (warnings.isNotEmpty)
          _InfoCard(icon: Icons.info_outline, text: warnings.join('\n')),
        if (state.lastSyncedAt != null)
          Text('Last synced ${DateFormat('d MMM, h:mm a').format(state.lastSyncedAt!.toLocal())}', style: const TextStyle(fontSize: 11, color: Colors.white38)),
      ],
    );
  }
}

class AttendanceSection extends StatelessWidget {
  const AttendanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final items = AppState.instance.attendance;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text('Attendance', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Your subject-wise attendance from Amizone', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 18),
        if (items.isEmpty)
          const _EmptyState(title: 'Nothing to show', subtitle: 'Use Sync after signing in to load attendance.')
        else
          ...items.map((e) => _CourseTile(course: e, expanded: true)),
      ],
    );
  }
}

class LibrarySection extends StatelessWidget {
  const LibrarySection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final resources = state.resources;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text('Study library', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Resources from NexAcad, filtered by your subjects', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 16),
        if (state.resourcesLoading)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
        else if (resources.isEmpty)
          _EmptyState(title: 'No resources loaded', subtitle: 'Try syncing again when NexAcad is reachable.')
        else
          ...resources.map((item) => Card(
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFF263353), child: Icon(Icons.description_outlined, color: Color(0xFF9BA8FF))),
              title: Text(item['title']?.toString() ?? 'Untitled', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text('${item['subject_code'] ?? 'General'}  •  ${item['file_type'] ?? 'Notes'}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
              trailing: const Icon(Icons.open_in_new_rounded, size: 18),
              onTap: () async {
                final raw = item['preview_url']?.toString() ?? item['download_url']?.toString() ?? '';
                final uri = Uri.tryParse(raw);
                if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
            ),
          )),
      ],
    );
  }
}

class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final profile = state.profile;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text('Account', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile['name']?.toString().isNotEmpty == true ? profile['name'].toString() : state.username, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(profile['enrollment_number']?.toString() ?? state.username, style: const TextStyle(color: Colors.white54)),
                const SizedBox(height: 6),
                Text([profile['program'], profile['batch']].where((e) => e != null && e.toString().isNotEmpty).join(' • '), style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: state.loading ? null : () => state.sync(),
          icon: const Icon(Icons.sync),
          label: const Text('Sync academic data'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Sign out?'),
                content: const Text('Your local cached academic data will be cleared from this device.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign out')),
                ],
              ),
            );
            if (confirm == true) await state.signOut();
          },
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          label: const Text('Sign out', style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.percent, required this.attended, required this.held, required this.courses});
  final double percent;
  final int attended;
  final int held;
  final int courses;

  @override
  Widget build(BuildContext context) {
    final safePercent = percent.clamp(0, 100).toDouble();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF34447E), Color(0xFF202C50)]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('OVERALL ATTENDANCE', style: TextStyle(fontSize: 10, letterSpacing: 1.7, color: Colors.white70, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${safePercent.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 42, height: 1, fontWeight: FontWeight.w800, letterSpacing: -1.5)),
              const Spacer(),
              Text('$attended / $held classes', style: const TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(value: safePercent / 100, minHeight: 7, backgroundColor: Colors.white24, color: const Color(0xFFA7B1FF)),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 7),
              Text('$courses enrolled subjects', style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CourseTile extends StatelessWidget {
  const _CourseTile({required this.course, this.expanded = false});
  final Map<String, dynamic> course;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final attended = (course['attended'] as num?)?.toInt() ?? 0;
    final held = (course['held'] as num?)?.toInt() ?? 0;
    final pct = held == 0 ? 0.0 : attended / held * 100;
    final name = course['subject_name']?.toString() ?? course['subject_code']?.toString() ?? 'Subject';
    final code = course['subject_code']?.toString() ?? '';
    final color = pct >= 85 ? const Color(0xFF63D5A4) : pct >= 75 ? const Color(0xFFFFC66D) : const Color(0xFFFF7F8B);
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  if (code.isNotEmpty) Text(code, style: const TextStyle(fontSize: 10, color: Colors.white38)),
                ])),
                Text('${pct.toStringAsFixed(1)}%', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: (pct / 100).clamp(0, 1), minHeight: 5, backgroundColor: Colors.white10, color: color)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('$attended attended  •  $held held', style: const TextStyle(fontSize: 10, color: Colors.white54)),
                const Spacer(),
                if ((course['internal_marks'] as num?) != null)
                  Text('Internal ${course['internal_marks']}/${course['max_internal'] ?? 40}', style: const TextStyle(fontSize: 10, color: Colors.white54)),
              ],
            ),
            if (expanded && pct < 75)
              const Padding(padding: EdgeInsets.only(top: 8), child: Text('Below the usual 75% threshold. Check your course rules.', style: TextStyle(fontSize: 10, color: Color(0xFFFFA1AB)))),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(color: const Color(0xFF151D32), borderRadius: BorderRadius.circular(18)),
    child: Column(children: [
      const Icon(Icons.inbox_outlined, size: 30, color: Colors.white38),
      const SizedBox(height: 10),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.white54)),
    ]),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFF263353), borderRadius: BorderRadius.circular(12)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 17, color: const Color(0xFFAAB4FF)),
      const SizedBox(width: 9),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 11, color: Colors.white70))),
    ]),
  );
}


class AcademicSection extends StatelessWidget {
  const AcademicSection({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text('Academics', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          const TabBar(
            tabs: [
              Tab(text: 'Exams'),
              Tab(text: 'Results'),
              Tab(text: 'Internals'),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _ExamsTab(),
                _ResultsTab(),
                _InternalsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamsTab extends StatelessWidget {
  const _ExamsTab();

  @override
  Widget build(BuildContext context) {
    final exams = AppState.instance.exams;
    if (exams.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(18),
        child: _EmptyState(
          title: 'No exam schedule found',
          subtitle: 'The schedule will appear here when Amizone publishes it.',
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exams.length,
      itemBuilder: (context, index) {
        final exam = exams[index];
        final date = DateTime.tryParse(exam['date']?.toString() ?? '');
        final type = exam['type']?.toString() ?? 'theory';
        return Card(
          margin: const EdgeInsets.only(bottom: 9),
          child: ListTile(
            leading: Container(
              width: 45,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF263353),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(date == null ? '--' : DateFormat('dd').format(date),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  Text(date == null ? '---' : DateFormat('MMM').format(date).toUpperCase(),
                      style: const TextStyle(fontSize: 9, color: Colors.white60)),
                ],
              ),
            ),
            title: Text(exam['title']?.toString() ?? 'Exam',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            subtitle: Text(
              [
                exam['subject_code'],
                exam['time'],
                type.toUpperCase(),
                exam['room'],
              ].where((v) => v != null && v.toString().trim().isNotEmpty).join(' • '),
              style: const TextStyle(fontSize: 10, color: Colors.white54),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}

class _ResultsTab extends StatelessWidget {
  const _ResultsTab();

  @override
  Widget build(BuildContext context) {
    final results = AppState.instance.results;
    if (results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(18),
        child: _EmptyState(
          title: 'No results published',
          subtitle: 'Published semester grades and CGPA will show up here.',
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: results.map((result) {
        final courses = result['courses'] is List
            ? (result['courses'] as List).whereType<Map>().toList()
            : <Map>[];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result['semester_name']?.toString() ?? 'Semester',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Metric(label: 'SGPA', value: (result['sgpa'] ?? 0).toString()),
                    const SizedBox(width: 10),
                    _Metric(label: 'CGPA', value: (result['cgpa'] ?? 0).toString()),
                    const SizedBox(width: 10),
                    _Metric(label: 'Credits', value: (result['total_credits'] ?? 0).toString()),
                  ],
                ),
                if (courses.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Divider(),
                  ...courses.map((course) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(course['course_name']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              Text(course['course_code']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 10, color: Colors.white38)),
                            ],
                          ),
                        ),
                        Text(course['grade']?.toString() ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(width: 12),
                        Text((course['grade_point'] ?? '').toString(),
                            style: const TextStyle(fontSize: 11, color: Colors.white54)),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _InternalsTab extends StatelessWidget {
  const _InternalsTab();

  @override
  Widget build(BuildContext context) {
    final courses = AppState.instance.courses;
    if (courses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(18),
        child: _EmptyState(
          title: 'No course marks found',
          subtitle: 'Internal assessment marks will appear when the MyCourses page is available.',
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: courses.map((course) {
        final marks = (course['internal_marks'] as num?)?.toDouble() ?? 0;
        final maximum = (course['max_internal'] as num?)?.toDouble() ?? 40;
        final hasMarks = marks > 0;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(course['subject_name']?.toString() ?? course['subject_code']?.toString() ?? 'Subject',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            subtitle: Text(course['subject_code']?.toString() ?? '',
                style: const TextStyle(fontSize: 10, color: Colors.white38)),
            trailing: Text(
              hasMarks ? '${marks.toStringAsFixed(1)} / ${maximum.toStringAsFixed(0)}' : 'Not published',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: hasMarks ? const Color(0xFF9BA8FF) : Colors.white38,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFF222D4B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.white54)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ],
      ),
    ),
  );
}

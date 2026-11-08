import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/assignment.dart';
import '../services/storage_service.dart';

enum AssignmentSortOption {
  urgentFirst,
  latestFirst,
  subjectAsc,
  titleAsc,
}

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AssignmentSortOption _sortOption = AssignmentSortOption.urgentFirst;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Assignment> _sort(List<Assignment> list) {
    final sorted = List<Assignment>.from(list);
    switch (_sortOption) {
      case AssignmentSortOption.urgentFirst:
        sorted.sort((a, b) => a.submissionDate.compareTo(b.submissionDate));
        break;
      case AssignmentSortOption.latestFirst:
        sorted.sort((a, b) => b.submissionDate.compareTo(a.submissionDate));
        break;
      case AssignmentSortOption.subjectAsc:
        sorted.sort((a, b) => a.subject.compareTo(b.subject));
        break;
      case AssignmentSortOption.titleAsc:
        sorted.sort((a, b) => a.title.compareTo(b.title));
        break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StorageService.instance,
      builder: (context, _) {
        final assignments = _sort(StorageService.instance.assignments);
        final todoList =
            assignments.where((a) => a.status == AssignmentStatus.todo).toList();
        final ongoingList =
            assignments.where((a) => a.status == AssignmentStatus.ongoing).toList();
        final completedList = assignments
            .where((a) => a.status == AssignmentStatus.completed)
            .toList();
        final submittedList = assignments
            .where((a) => a.status == AssignmentStatus.submitted)
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Assignments Tracker',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.sort, color: Colors.white),
                tooltip: 'Sort assignments',
                onPressed: () => _showSortModal(context),
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
                Tab(text: 'All (${assignments.length})'),
                Tab(text: 'To Do (${todoList.length})'),
                Tab(text: 'Ongoing (${ongoingList.length})'),
                Tab(text: 'Completed (${completedList.length})'),
                Tab(text: 'Submitted (${submittedList.length})'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildList(assignments),
              _buildList(todoList),
              _buildList(ongoingList),
              _buildList(completedList),
              _buildList(submittedList),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddAssignmentDialog(context),
            backgroundColor: const Color(0xFF1E3A8A),
            icon: const Icon(Icons.add_task, color: Colors.white),
            label: const Text(
              'New Task',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
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
                  'Sort Assignments By',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.access_alarm, color: Colors.red),
                  title: const Text('Due Date (Urgent / Nearest First)'),
                  trailing: _sortOption == AssignmentSortOption.urgentFirst
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() => _sortOption = AssignmentSortOption.urgentFirst);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_month, color: Colors.blue),
                  title: const Text('Due Date (Furthest First)'),
                  trailing: _sortOption == AssignmentSortOption.latestFirst
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() => _sortOption = AssignmentSortOption.latestFirst);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.school, color: Colors.purple),
                  title: const Text('Subject (A-Z)'),
                  trailing: _sortOption == AssignmentSortOption.subjectAsc
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() => _sortOption = AssignmentSortOption.subjectAsc);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.title, color: Colors.teal),
                  title: const Text('Title (A-Z)'),
                  trailing: _sortOption == AssignmentSortOption.titleAsc
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() => _sortOption = AssignmentSortOption.titleAsc);
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

  Widget _buildList(List<Assignment> items) {
    final theme = Theme.of(context);
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 56, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'No assignments here!',
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
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final dueDay = DateTime(
          item.submissionDate.year,
          item.submissionDate.month,
          item.submissionDate.day,
        );
        final diff = dueDay.difference(today).inDays;

        Color badgeColor;
        switch (item.status) {
          case AssignmentStatus.todo:
            badgeColor = Colors.orange;
            break;
          case AssignmentStatus.ongoing:
            badgeColor = Colors.blue;
            break;
          case AssignmentStatus.completed:
            badgeColor = Colors.indigoAccent;
            break;
          case AssignmentStatus.submitted:
            badgeColor = Colors.green;
            break;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.subject,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    PopupMenuButton<AssignmentStatus>(
                      initialValue: item.status,
                      onSelected: (newStatus) {
                        StorageService.instance.updateAssignmentStatus(
                          item.id,
                          newStatus,
                        );
                      },
                      itemBuilder: (context) => AssignmentStatus.values.map((s) {
                        return PopupMenuItem(
                          value: s,
                          child: Text(s.label),
                        );
                      }).toList(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.status.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_drop_down, size: 16, color: badgeColor),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (item.notes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.notes,
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.65)),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 15,
                          color: diff < 0 && item.status != AssignmentStatus.submitted
                              ? Colors.red
                              : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Due: ${DateFormat('dd MMM yyyy').format(item.submissionDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: diff < 0 && item.status != AssignmentStatus.submitted
                                ? Colors.red
                                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        if (item.status != AssignmentStatus.submitted) ...[
                          const SizedBox(width: 6),
                          Text(
                            diff < 0
                                ? '(Overdue)'
                                : diff == 0
                                    ? '(Today!)'
                                    : '($diff d left)',
                            style: TextStyle(
                              fontSize: 11,
                              color: diff <= 1 ? Colors.red : Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                      onPressed: () => StorageService.instance.deleteAssignment(item.id),
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

  void _showAddAssignmentDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime pickedDate = DateTime.now().add(const Duration(days: 3));
    AssignmentStatus selectedStatus = AssignmentStatus.todo;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        hintText: 'e.g. Implement Graph BFS in C',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: subjectCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Subject *',
                        hintText: 'e.g. CSIT124 - Data Structures',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              DateFormat('dd MMM yyyy').format(pickedDate),
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: pickedDate,
                                firstDate: DateTime(2025),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setDialogState(() => pickedDate = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<AssignmentStatus>(
                            initialValue: selectedStatus,
                            decoration: const InputDecoration(labelText: 'Status'),
                            items: AssignmentStatus.values.map((s) {
                              return DropdownMenuItem(
                                value: s,
                                child: Text(s.label, style: const TextStyle(fontSize: 12)),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setDialogState(() => selectedStatus = v);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes / Instructions',
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
                    if (titleCtrl.text.trim().isEmpty) return;
                    final item = Assignment(
                      id: 'asg-${DateTime.now().millisecondsSinceEpoch}',
                      title: titleCtrl.text.trim(),
                      subject: subjectCtrl.text.trim().isEmpty
                          ? 'General'
                          : subjectCtrl.text.trim(),
                      submissionDate: pickedDate,
                      status: selectedStatus,
                      notes: notesCtrl.text.trim(),
                    );
                    StorageService.instance.addAssignment(item);
                    Navigator.pop(context);
                  },
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

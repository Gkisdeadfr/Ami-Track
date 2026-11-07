import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/assignment.dart';
import '../services/storage_service.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StorageService.instance,
      builder: (context, _) {
        final assignments = StorageService.instance.assignments;
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
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.indigo.shade800,
            title: const Text(
              'Assignments Tracker',
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
            backgroundColor: Colors.indigo.shade800,
            icon: const Icon(Icons.add_task, color: Colors.white),
            label: const Text(
              'New Assignment',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  Widget _buildList(List<Assignment> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No assignments here!',
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
            badgeColor = Colors.orange.shade700;
            break;
          case AssignmentStatus.ongoing:
            badgeColor = Colors.blue.shade700;
            break;
          case AssignmentStatus.completed:
            badgeColor = Colors.indigo.shade700;
            break;
          case AssignmentStatus.submitted:
            badgeColor = Colors.green.shade700;
            break;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.subject,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade800,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.12),
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
                            Icon(Icons.arrow_drop_down,
                                size: 16, color: badgeColor),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                if (item.notes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.notes,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Due: ${DateFormat('dd MMM yyyy').format(item.submissionDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: diff < 0 && item.status != AssignmentStatus.submitted
                                ? Colors.red.shade700
                                : Colors.grey.shade700,
                          ),
                        ),
                        if (item.status != AssignmentStatus.submitted) ...[
                          const SizedBox(width: 6),
                          Text(
                            diff < 0
                                ? '(Overdue)'
                                : diff == 0
                                    ? '(Today!)'
                                    : '($diff days left)',
                            style: TextStyle(
                              fontSize: 11,
                              color: diff <= 1 ? Colors.red.shade700 : Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
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
              title: const Text('Add Assignment'),
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
                            value: selectedStatus,
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
                    backgroundColor: Colors.indigo.shade800,
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

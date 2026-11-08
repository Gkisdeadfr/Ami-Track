import 'package:flutter/material.dart';
import '../models/syllabus.dart';
import '../services/amizone_service.dart';
import '../services/storage_service.dart';

enum SyllabusSubjectSort {
  defaultOrder,
  leastProgressFirst,
  mostProgressFirst,
  codeAsc,
}

class SyllabusScreen extends StatefulWidget {
  final String? initialSubjectId;
  const SyllabusScreen({super.key, this.initialSubjectId});

  @override
  State<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends State<SyllabusScreen> {
  int _selectedSubjectIndex = 0;
  TopicStatus? _statusFilter;
  SyllabusSubjectSort _subjectSort = SyllabusSubjectSort.defaultOrder;

  @override
  void initState() {
    super.initState();
    if (widget.initialSubjectId != null) {
      final index = StorageService.instance.syllabus
          .indexWhere((s) => s.id == widget.initialSubjectId);
      if (index != -1) {
        _selectedSubjectIndex = index;
      }
    }
  }

  List<SyllabusSubject> _getSortedSubjects(List<SyllabusSubject> list) {
    final sorted = List<SyllabusSubject>.from(list);
    switch (_subjectSort) {
      case SyllabusSubjectSort.defaultOrder:
        break;
      case SyllabusSubjectSort.leastProgressFirst:
        sorted.sort((a, b) => a.progressPercentage.compareTo(b.progressPercentage));
        break;
      case SyllabusSubjectSort.mostProgressFirst:
        sorted.sort((a, b) => b.progressPercentage.compareTo(a.progressPercentage));
        break;
      case SyllabusSubjectSort.codeAsc:
        sorted.sort((a, b) => a.subjectCode.compareTo(b.subjectCode));
        break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([StorageService.instance, AmizoneService.instance]),
      builder: (context, _) {
        final theme = Theme.of(context);
        final rawSubjects = StorageService.instance.syllabus;
        if (rawSubjects.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Syllabus Tracker')),
            body: const Center(child: Text('No subjects loaded.')),
          );
        }

        final subjects = _getSortedSubjects(rawSubjects);
        if (_selectedSubjectIndex >= subjects.length) {
          _selectedSubjectIndex = 0;
        }
        final currentSubject = subjects[_selectedSubjectIndex];

        // Check if Amizone has internal marks or attendance for this course
        final amizoneMatch = AmizoneService.instance.courses.cast().firstWhere(
          (c) => c.subjectCode.toUpperCase() == currentSubject.subjectCode.toUpperCase(),
          orElse: () => null,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Syllabus & Revision',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            actions: [
              PopupMenuButton<SyllabusSubjectSort>(
                icon: const Icon(Icons.sort, color: Colors.white),
                tooltip: 'Sort subjects',
                onSelected: (sort) => setState(() => _subjectSort = sort),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: SyllabusSubjectSort.defaultOrder,
                    child: Text('Default Order'),
                  ),
                  const PopupMenuItem(
                    value: SyllabusSubjectSort.leastProgressFirst,
                    child: Text('Least Progress First'),
                  ),
                  const PopupMenuItem(
                    value: SyllabusSubjectSort.mostProgressFirst,
                    child: Text('Most Progress First'),
                  ),
                  const PopupMenuItem(
                    value: SyllabusSubjectSort.codeAsc,
                    child: Text('Subject Code (A-Z)'),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.sync, color: Colors.white),
                tooltip: 'Sync with Amizone courses',
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
              ),
            ],
          ),
          body: Column(
            children: [
              // Horizontal subject picker
              Container(
                color: theme.cardColor,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: subjects.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final sub = entry.value;
                      final isSelected = idx == _selectedSubjectIndex;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            sub.subjectCode,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _selectedSubjectIndex = idx;
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Subject Summary Header Card
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            currentSubject.subjectName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(currentSubject.progressPercentage * 100).toInt()}% Done',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (amizoneMatch != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (amizoneMatch.internalMarks > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amberAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Internal: ${amizoneMatch.internalMarks.toStringAsFixed(1)}/${amizoneMatch.maxInternal.toInt()}',
                                style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            'Attendance: ${amizoneMatch.percentage.toStringAsFixed(1)}% (${amizoneMatch.attended}/${amizoneMatch.held})',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: currentSubject.progressPercentage,
                        minHeight: 7,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Quick stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatPill('Done', currentSubject.completedTopics, Colors.greenAccent),
                        _buildStatPill('Revise', currentSubject.revisionTopics, Colors.orangeAccent),
                        _buildStatPill('Ongoing', currentSubject.inProgressTopics, Colors.lightBlueAccent),
                        _buildStatPill('Total', currentSubject.totalTopics, Colors.white70),
                      ],
                    ),
                  ],
                ),
              ),

              // Filter Chips for Status
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All Topics', style: TextStyle(fontSize: 11)),
                      selected: _statusFilter == null,
                      onSelected: (_) => setState(() => _statusFilter = null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      avatar: const Icon(Icons.replay, size: 14, color: Colors.deepOrange),
                      label: const Text('Needs Revision', style: TextStyle(fontSize: 11)),
                      selected: _statusFilter == TopicStatus.needsRevision,
                      onSelected: (val) => setState(() =>
                          _statusFilter = val ? TopicStatus.needsRevision : null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      avatar: const Icon(Icons.timelapse, size: 14, color: Colors.blue),
                      label: const Text('In Progress', style: TextStyle(fontSize: 11)),
                      selected: _statusFilter == TopicStatus.inProgress,
                      onSelected: (val) => setState(() =>
                          _statusFilter = val ? TopicStatus.inProgress : null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      avatar: const Icon(Icons.check_circle, size: 14, color: Colors.green),
                      label: const Text('Done', style: TextStyle(fontSize: 11)),
                      selected: _statusFilter == TopicStatus.done,
                      onSelected: (val) => setState(() =>
                          _statusFilter = val ? TopicStatus.done : null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      avatar: const Icon(Icons.radio_button_unchecked, size: 14, color: Colors.grey),
                      label: const Text('Not Started', style: TextStyle(fontSize: 11)),
                      selected: _statusFilter == TopicStatus.notStarted,
                      onSelected: (val) => setState(() =>
                          _statusFilter = val ? TopicStatus.notStarted : null),
                    ),
                  ],
                ),
              ),

              // Modules and Topics List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                  itemCount: currentSubject.modules.length,
                  itemBuilder: (context, mIdx) {
                    final module = currentSubject.modules[mIdx];
                    final filteredTopics = _statusFilter == null
                        ? module.topics
                        : module.topics.where((t) => t.status == _statusFilter).toList();

                    if (filteredTopics.isEmpty && _statusFilter != null) {
                      return const SizedBox.shrink();
                    }

                    final modCompleted =
                        module.topics.where((t) => t.status == TopicStatus.done).length;

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
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          title: Text(
                            module.moduleTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            'Weightage: ${module.weightage.toInt()}% • $modCompleted/${module.topics.length} done',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 20),
                            tooltip: 'Add Topic',
                            onPressed: () => _showAddTopicDialog(
                              context,
                              currentSubject.id,
                              module.id,
                            ),
                          ),
                          children: [
                            Divider(height: 1, color: theme.dividerColor),
                            ...filteredTopics.map((topic) {
                              return _buildTopicRow(
                                context,
                                currentSubject.id,
                                module.id,
                                topic,
                              );
                            }),
                          ],
                        ),
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
  }

  Widget _buildStatPill(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$title: $count',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTopicRow(
    BuildContext context,
    String subjectId,
    String moduleId,
    SyllabusTopic topic,
  ) {
    final theme = Theme.of(context);
    Color statusBgColor;
    Color statusTextColor;
    IconData statusIcon;

    switch (topic.status) {
      case TopicStatus.notStarted:
        statusBgColor = Colors.grey.withValues(alpha: 0.1);
        statusTextColor = Colors.grey;
        statusIcon = Icons.radio_button_unchecked;
        break;
      case TopicStatus.inProgress:
        statusBgColor = Colors.blue.withValues(alpha: 0.12);
        statusTextColor = Colors.blue;
        statusIcon = Icons.timelapse;
        break;
      case TopicStatus.done:
        statusBgColor = Colors.green.withValues(alpha: 0.12);
        statusTextColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case TopicStatus.needsRevision:
        statusBgColor = Colors.purple.withValues(alpha: 0.12);
        statusTextColor = Colors.purpleAccent;
        statusIcon = Icons.replay;
        break;
    }

    return InkWell(
      onTap: () => _cycleTopicStatus(subjectId, moduleId, topic),
      onLongPress: () => _showStatusPicker(context, subjectId, moduleId, topic),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(statusIcon, size: 18, color: statusTextColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration: topic.status == TopicStatus.done
                          ? TextDecoration.lineThrough
                          : null,
                      color: topic.status == TopicStatus.done
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showStatusPicker(context, subjectId, moduleId, topic),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusTextColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  topic.status.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusTextColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _cycleTopicStatus(
    String subjectId,
    String moduleId,
    SyllabusTopic topic,
  ) {
    TopicStatus nextStatus;
    switch (topic.status) {
      case TopicStatus.notStarted:
        nextStatus = TopicStatus.inProgress;
        break;
      case TopicStatus.inProgress:
        nextStatus = TopicStatus.done;
        break;
      case TopicStatus.done:
        nextStatus = TopicStatus.needsRevision;
        break;
      case TopicStatus.needsRevision:
        nextStatus = TopicStatus.notStarted;
        break;
    }
    StorageService.instance.updateTopicStatus(
      subjectId,
      moduleId,
      topic.id,
      nextStatus,
    );
  }

  void _showStatusPicker(
    BuildContext context,
    String subjectId,
    String moduleId,
    SyllabusTopic topic,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...TopicStatus.values.map((status) {
                  final isSelected = topic.status == status;
                  return ListTile(
                    dense: true,
                    title: Text(status.label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
                    onTap: () {
                      StorageService.instance.updateTopicStatus(
                        subjectId,
                        moduleId,
                        topic.id,
                        status,
                      );
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddTopicDialog(
    BuildContext context,
    String subjectId,
    String moduleId,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Custom Topic'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Topic Title',
              hintText: 'e.g. Master Theorem or Radix Sort',
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
                if (controller.text.trim().isNotEmpty) {
                  StorageService.instance.addCustomTopic(
                    subjectId,
                    moduleId,
                    controller.text.trim(),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

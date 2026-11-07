import 'package:flutter/material.dart';
import '../models/syllabus.dart';
import '../services/storage_service.dart';

class SyllabusScreen extends StatefulWidget {
  final String? initialSubjectId;
  const SyllabusScreen({super.key, this.initialSubjectId});

  @override
  State<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends State<SyllabusScreen> {
  int _selectedSubjectIndex = 0;
  TopicStatus? _statusFilter;

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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StorageService.instance,
      builder: (context, _) {
        final subjects = StorageService.instance.syllabus;
        if (subjects.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('No subjects loaded.')),
          );
        }

        if (_selectedSubjectIndex >= subjects.length) {
          _selectedSubjectIndex = 0;
        }
        final currentSubject = subjects[_selectedSubjectIndex];

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.indigo.shade800,
            title: const Text(
              'Syllabus & Revision Tracker',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 19,
                color: Colors.white,
              ),
            ),
          ),
          body: Column(
            children: [
              // Horizontal subject picker
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                              color: isSelected ? Colors.white : Colors.grey.shade800,
                              fontSize: 13,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Colors.indigo.shade800,
                          backgroundColor: Colors.grey.shade100,
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
                  gradient: LinearGradient(
                    colors: [
                      Colors.indigo.shade900,
                      Colors.indigo.shade700,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.2),
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
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(currentSubject.progressPercentage * 100).toInt()}% Done',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: currentSubject.progressPercentage,
                        minHeight: 8,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                      ),
                    ),
                    const SizedBox(height: 14),
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
                      label: const Text('All Topics'),
                      selected: _statusFilter == null,
                      onSelected: (_) => setState(() => _statusFilter = null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      avatar: const Icon(Icons.replay, size: 14, color: Colors.deepOrange),
                      label: const Text('Needs Revision'),
                      selected: _statusFilter == TopicStatus.needsRevision,
                      onSelected: (val) => setState(() =>
                          _statusFilter = val ? TopicStatus.needsRevision : null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      avatar: const Icon(Icons.timelapse, size: 14, color: Colors.blue),
                      label: const Text('In Progress'),
                      selected: _statusFilter == TopicStatus.inProgress,
                      onSelected: (val) => setState(() =>
                          _statusFilter = val ? TopicStatus.inProgress : null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      avatar: const Icon(Icons.check_circle, size: 14, color: Colors.green),
                      label: const Text('Done'),
                      selected: _statusFilter == TopicStatus.done,
                      onSelected: (val) => setState(() =>
                          _statusFilter = val ? TopicStatus.done : null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      avatar: const Icon(Icons.radio_button_unchecked, size: 14, color: Colors.grey),
                      label: const Text('Not Started'),
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
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          title: Text(
                            module.moduleTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          subtitle: Text(
                            'Weightage: ${module.weightage.toInt()}% • $modCompleted/${module.topics.length} completed',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
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
                            const Divider(height: 1),
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
    Color statusBgColor;
    Color statusTextColor;
    IconData statusIcon;

    switch (topic.status) {
      case TopicStatus.notStarted:
        statusBgColor = Colors.grey.shade100;
        statusTextColor = Colors.grey.shade700;
        statusIcon = Icons.radio_button_unchecked;
        break;
      case TopicStatus.inProgress:
        statusBgColor = Colors.blue.shade50;
        statusTextColor = Colors.blue.shade800;
        statusIcon = Icons.timelapse;
        break;
      case TopicStatus.done:
        statusBgColor = Colors.green.shade50;
        statusTextColor = Colors.green.shade800;
        statusIcon = Icons.check_circle;
        break;
      case TopicStatus.needsRevision:
        statusBgColor = Colors.purple.shade50;
        statusTextColor = Colors.purple.shade800;
        statusIcon = Icons.replay;
        break;
    }

    return InkWell(
      onTap: () => _cycleTopicStatus(subjectId, moduleId, topic),
      onLongPress: () => _showStatusPicker(context, subjectId, moduleId, topic),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      decoration: topic.status == TopicStatus.done
                          ? TextDecoration.lineThrough
                          : null,
                      color: topic.status == TopicStatus.done
                          ? Colors.grey.shade500
                          : const Color(0xFF1E293B),
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
                  border: Border.all(color: statusTextColor.withOpacity(0.3)),
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
                  return ListTile(
                    dense: true,
                    title: Text(status.label),
                    leading: Radio<TopicStatus>(
                      value: status,
                      groupValue: topic.status,
                      onChanged: (val) {
                        if (val != null) {
                          StorageService.instance.updateTopicStatus(
                            subjectId,
                            moduleId,
                            topic.id,
                            val,
                          );
                          Navigator.pop(context);
                        }
                      },
                    ),
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
                backgroundColor: Colors.indigo.shade800,
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

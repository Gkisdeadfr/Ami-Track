enum TopicStatus { notStarted, inProgress, done, needsRevision }

extension TopicStatusExtension on TopicStatus {
  String get label {
    switch (this) {
      case TopicStatus.notStarted:
        return 'Not Started';
      case TopicStatus.inProgress:
        return 'In Progress';
      case TopicStatus.done:
        return 'Done';
      case TopicStatus.needsRevision:
        return 'Needs Revision';
    }
  }
}

class SyllabusTopic {
  final String id;
  final String title;
  final TopicStatus status;
  final String notes;

  SyllabusTopic({
    required this.id,
    required this.title,
    this.status = TopicStatus.notStarted,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'status': status.name,
        'notes': notes,
      };

  factory SyllabusTopic.fromJson(Map<String, dynamic> json) => SyllabusTopic(
        id: json['id'] as String,
        title: json['title'] as String,
        status: TopicStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => TopicStatus.notStarted,
        ),
        notes: json['notes'] as String? ?? '',
      );

  SyllabusTopic copyWith({
    String? id,
    String? title,
    TopicStatus? status,
    String? notes,
  }) {
    return SyllabusTopic(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}

class SyllabusModule {
  final String id;
  final String moduleTitle;
  final double weightage;
  final List<SyllabusTopic> topics;

  SyllabusModule({
    required this.id,
    required this.moduleTitle,
    this.weightage = 0.0,
    required this.topics,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'moduleTitle': moduleTitle,
        'weightage': weightage,
        'topics': topics.map((t) => t.toJson()).toList(),
      };

  factory SyllabusModule.fromJson(Map<String, dynamic> json) => SyllabusModule(
        id: json['id'] as String,
        moduleTitle: json['moduleTitle'] as String,
        weightage: (json['weightage'] as num?)?.toDouble() ?? 0.0,
        topics: (json['topics'] as List<dynamic>?)
                ?.map((t) => SyllabusTopic.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class SyllabusSubject {
  final String id;
  final String subjectCode;
  final String subjectName;
  final String colorHex;
  final List<SyllabusModule> modules;

  SyllabusSubject({
    required this.id,
    required this.subjectCode,
    required this.subjectName,
    this.colorHex = '#2563EB',
    required this.modules,
  });

  int get totalTopics {
    return modules.fold(0, (sum, m) => sum + m.topics.length);
  }

  int get completedTopics {
    return modules.fold(
      0,
      (sum, m) =>
          sum + m.topics.where((t) => t.status == TopicStatus.done).length,
    );
  }

  int get revisionTopics {
    return modules.fold(
      0,
      (sum, m) =>
          sum +
          m.topics.where((t) => t.status == TopicStatus.needsRevision).length,
    );
  }

  int get inProgressTopics {
    return modules.fold(
      0,
      (sum, m) =>
          sum +
          m.topics.where((t) => t.status == TopicStatus.inProgress).length,
    );
  }

  double get progressPercentage {
    if (totalTopics == 0) return 0.0;
    return (completedTopics / totalTopics).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectCode': subjectCode,
        'subjectName': subjectName,
        'colorHex': colorHex,
        'modules': modules.map((m) => m.toJson()).toList(),
      };

  factory SyllabusSubject.fromJson(Map<String, dynamic> json) =>
      SyllabusSubject(
        id: json['id'] as String,
        subjectCode: json['subjectCode'] as String,
        subjectName: json['subjectName'] as String,
        colorHex: json['colorHex'] as String? ?? '#2563EB',
        modules: (json['modules'] as List<dynamic>?)
                ?.map((m) => SyllabusModule.fromJson(m as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

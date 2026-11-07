enum AssignmentStatus {
  todo,
  ongoing,
  completed,
  submitted;

  String get label {
    switch (this) {
      case AssignmentStatus.todo:
        return 'To Do';
      case AssignmentStatus.ongoing:
        return 'Ongoing';
      case AssignmentStatus.completed:
        return 'Completed';
      case AssignmentStatus.submitted:
        return 'Submitted';
    }
  }

  String get description {
    switch (this) {
      case AssignmentStatus.todo:
        return 'Not started yet';
      case AssignmentStatus.ongoing:
        return 'Started but not completed';
      case AssignmentStatus.completed:
        return 'Completed (ready to submit)';
      case AssignmentStatus.submitted:
        return 'Submitted to faculty';
    }
  }
}

class Assignment {
  final String id;
  final String title;
  final String subject;
  final DateTime submissionDate;
  final AssignmentStatus status;
  final String notes;

  Assignment({
    required this.id,
    required this.title,
    required this.subject,
    required this.submissionDate,
    this.status = AssignmentStatus.todo,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'submissionDate': submissionDate.toIso8601String(),
        'status': status.name,
        'notes': notes,
      };

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
        id: json['id'] as String,
        title: json['title'] as String,
        subject: json['subject'] as String,
        submissionDate: DateTime.parse(json['submissionDate'] as String),
        status: AssignmentStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => AssignmentStatus.todo,
        ),
        notes: json['notes'] as String? ?? '',
      );

  Assignment copyWith({
    String? id,
    String? title,
    String? subject,
    DateTime? submissionDate,
    AssignmentStatus? status,
    String? notes,
  }) {
    return Assignment(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      submissionDate: submissionDate ?? this.submissionDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}

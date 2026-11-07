enum ExamType { theory, practical, minor, viva }

class ExamItem {
  final String id;
  final String subjectCode;
  final String title;
  final DateTime date;
  final String time;
  final ExamType type;
  final String labOrRoom;
  final String faculty;
  final String mode; // "Regular", "MCQ Regular", "External Practical", etc.
  final String syllabusSummary;
  final bool isCompleted;

  ExamItem({
    required this.id,
    required this.subjectCode,
    required this.title,
    required this.date,
    required this.time,
    required this.type,
    this.labOrRoom = '',
    this.faculty = '',
    this.mode = 'Regular',
    this.syllabusSummary = '',
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectCode': subjectCode,
        'title': title,
        'date': date.toIso8601String(),
        'time': time,
        'type': type.name,
        'labOrRoom': labOrRoom,
        'faculty': faculty,
        'mode': mode,
        'syllabusSummary': syllabusSummary,
        'isCompleted': isCompleted,
      };

  factory ExamItem.fromJson(Map<String, dynamic> json) => ExamItem(
        id: json['id'] as String,
        subjectCode: json['subjectCode'] as String? ?? '',
        title: json['title'] as String,
        date: DateTime.parse(json['date'] as String),
        time: json['time'] as String,
        type: ExamType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ExamType.theory,
        ),
        labOrRoom: json['labOrRoom'] as String? ?? '',
        faculty: json['faculty'] as String? ?? '',
        mode: json['mode'] as String? ?? 'Regular',
        syllabusSummary: json['syllabusSummary'] as String? ?? '',
        isCompleted: json['isCompleted'] as bool? ?? false,
      );

  ExamItem copyWith({
    String? id,
    String? subjectCode,
    String? title,
    DateTime? date,
    String? time,
    ExamType? type,
    String? labOrRoom,
    String? faculty,
    String? mode,
    String? syllabusSummary,
    bool? isCompleted,
  }) {
    return ExamItem(
      id: id ?? this.id,
      subjectCode: subjectCode ?? this.subjectCode,
      title: title ?? this.title,
      date: date ?? this.date,
      time: time ?? this.time,
      type: type ?? this.type,
      labOrRoom: labOrRoom ?? this.labOrRoom,
      faculty: faculty ?? this.faculty,
      mode: mode ?? this.mode,
      syllabusSummary: syllabusSummary ?? this.syllabusSummary,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

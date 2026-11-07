class PYQItem {
  final String id;
  final String title;
  final String subject;
  final String subjectCode;
  final String examType; // "End Sem 2025", "Minor 1 2025", etc.
  final String year;
  final String fileSize;
  final int pageCount;
  final List<String> questionsPreview;

  PYQItem({
    required this.id,
    required this.title,
    required this.subject,
    required this.subjectCode,
    required this.examType,
    required this.year,
    required this.fileSize,
    required this.pageCount,
    required this.questionsPreview,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'subjectCode': subjectCode,
        'examType': examType,
        'year': year,
        'fileSize': fileSize,
        'pageCount': pageCount,
        'questionsPreview': questionsPreview,
      };

  factory PYQItem.fromJson(Map<String, dynamic> json) => PYQItem(
        id: json['id'] as String,
        title: json['title'] as String,
        subject: json['subject'] as String,
        subjectCode: json['subjectCode'] as String,
        examType: json['examType'] as String,
        year: json['year'] as String,
        fileSize: json['fileSize'] as String,
        pageCount: json['pageCount'] as int? ?? 1,
        questionsPreview: (json['questionsPreview'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

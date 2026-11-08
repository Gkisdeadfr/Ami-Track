class CourseGradeItem {
  final String courseCode;
  final String courseName;
  final double credits;
  final String grade;
  final double gradePoint;
  final String resultStatus;

  const CourseGradeItem({
    required this.courseCode,
    required this.courseName,
    this.credits = 0.0,
    required this.grade,
    this.gradePoint = 0.0,
    this.resultStatus = 'Passed',
  });

  Map<String, dynamic> toJson() => {
        'courseCode': courseCode,
        'courseName': courseName,
        'credits': credits,
        'grade': grade,
        'gradePoint': gradePoint,
        'resultStatus': resultStatus,
      };

  factory CourseGradeItem.fromJson(Map<String, dynamic> json) => CourseGradeItem(
        courseCode: json['courseCode'] as String? ?? '',
        courseName: json['courseName'] as String? ?? '',
        credits: (json['credits'] as num?)?.toDouble() ?? 0.0,
        grade: json['grade'] as String? ?? '-',
        gradePoint: (json['gradePoint'] as num?)?.toDouble() ?? 0.0,
        resultStatus: json['resultStatus'] as String? ?? 'Passed',
      );
}

class SemesterResult {
  final String semesterName;
  final double sgpa;
  final double cgpa;
  final double totalCredits;
  final List<CourseGradeItem> courses;
  final DateTime? publishedDate;

  const SemesterResult({
    required this.semesterName,
    this.sgpa = 0.0,
    this.cgpa = 0.0,
    this.totalCredits = 0.0,
    required this.courses,
    this.publishedDate,
  });

  Map<String, dynamic> toJson() => {
        'semesterName': semesterName,
        'sgpa': sgpa,
        'cgpa': cgpa,
        'totalCredits': totalCredits,
        'courses': courses.map((c) => c.toJson()).toList(),
        'publishedDate': publishedDate?.toIso8601String(),
      };

  factory SemesterResult.fromJson(Map<String, dynamic> json) {
    final rawCourses = json['courses'];
    final courses = <CourseGradeItem>[];
    if (rawCourses is List) {
      for (final c in rawCourses) {
        if (c is Map) {
          courses.add(CourseGradeItem.fromJson(Map<String, dynamic>.from(c)));
        }
      }
    }
    return SemesterResult(
      semesterName: json['semesterName'] as String? ?? 'Current Semester',
      sgpa: (json['sgpa'] as num?)?.toDouble() ?? 0.0,
      cgpa: (json['cgpa'] as num?)?.toDouble() ?? 0.0,
      totalCredits: (json['totalCredits'] as num?)?.toDouble() ?? 0.0,
      courses: courses,
      publishedDate: DateTime.tryParse(json['publishedDate'] as String? ?? ''),
    );
  }
}

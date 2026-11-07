class CourseAttendance {
  final String id;
  final String subjectCode;
  final String subjectName;
  final int credits;
  int attended;
  int held;
  int expectedRemainingClasses;
  double internalMarks;
  double maxInternal;
  double targetPercentage; // e.g. 75.0, 85.0, 90.0, 95.01

  CourseAttendance({
    required this.id,
    required this.subjectCode,
    required this.subjectName,
    this.credits = 4,
    required this.attended,
    required this.held,
    int? expectedRemainingClasses,
    this.internalMarks = 0.0,
    this.maxInternal = 40.0,
    this.targetPercentage = 95.01,
  }) : expectedRemainingClasses = expectedRemainingClasses ??
            ((credits * 15 > held) ? (credits * 15 - held) : 0);

  /// Minimum classes required by credit structure (1 credit = 15 lectures)
  int get minCreditLectures => credits * 15;

  /// Total expected classes for the semester (minimum only increases, never reduces)
  int get totalSemesterLectures {
    final base = (credits * 15 > held) ? (credits * 15) : held;
    return base + (expectedRemainingClasses > 0 && held >= credits * 15 ? expectedRemainingClasses : 0);
  }

  /// Current percentage based on classes marked by teacher till date
  double get percentage {
    if (held == 0) return 100.0;
    return (attended / held) * 100.0;
  }

  int get leavesTaken => held - attended;

  /// Attendance Marks Calculation Rule:
  /// - < 70%: 0 marks (Debarred / Below B-Cap)
  /// - 70.00% to 75.00%: 0 marks (B-Cap)
  /// - > 75.00% to 80.00%: 1 mark / 5
  /// - > 80.00% to 85.00%: 2 marks / 5
  /// - > 85.00% to 90.00%: 3 marks / 5
  /// - > 90.00% to 95.00%: 4 marks / 5  (95.00% lies in 4 marks bracket)
  /// - > 95.00% to 100.00%: 5 marks / 5 (Full marks)
  int get attendanceMarks {
    final p = percentage;
    if (p <= 75.00) return 0;
    if (p <= 80.00) return 1;
    if (p <= 85.00) return 2;
    if (p <= 90.00) return 3;
    if (p <= 95.00) return 4;
    return 5;
  }

  String get attendanceMarksBracket {
    final p = percentage;
    if (p < 70.00) return 'Debarred (< 70%)';
    if (p <= 75.00) return 'B-Cap (70% - 75%)';
    if (p <= 80.00) return '1 Mark (75.01% - 80%)';
    if (p <= 85.00) return '2 Marks (80.01% - 85%)';
    if (p <= 90.00) return '3 Marks (85.01% - 90%)';
    if (p <= 95.00) return '4 Marks (90.01% - 95.00%)';
    return '5/5 Full Marks (95.01% - 100%)';
  }

  /// Calculates how many upcoming consecutive classes you can miss right now
  /// Formula: Attended stays A, Denominator becomes H + x
  /// A / (H + x) >= target / 100
  /// x <= (100 * A - target * H) / target
  int safeConsecutiveBunks(double target) {
    if (held == 0) return 0;
    final t = target / 100.0;
    if (percentage < target) return 0;

    final maxBunk = ((attended - (t * held)) / t).floor();
    return maxBunk < 0 ? 0 : maxBunk;
  }

  /// If below target, how many consecutive classes you must attend
  /// (A + y) / (H + y) >= target / 100
  /// y >= (target * H - 100 * A) / (100 - target)
  int classesNeededToReach(double target) {
    if (percentage >= target) return 0;
    final t = target / 100.0;
    if (t >= 1.0) return 0;
    final needed = (((t * held) - attended) / (1.0 - t)).ceil();
    return needed < 0 ? 0 : needed;
  }

  /// Total leaves allowed in the entire semester to still finish with >= target%
  int totalAllowedSemesterLeaves(double target) {
    final total = totalSemesterLectures;
    final maxAllowed = (total * (1.0 - (target / 100.0))).floor();
    return maxAllowed < 0 ? 0 : maxAllowed;
  }

  /// Remaining leaves you can take out of the full semester quota
  int remainingSemesterLeaves(double target) {
    final totalAllowed = totalAllowedSemesterLeaves(target);
    final remaining = totalAllowed - leavesTaken;
    return remaining < 0 ? 0 : remaining;
  }

  /// Simulates new attendance if you take k more leaves
  /// Denominator becomes H + k, Attended stays A
  double simulateWithExtraLeaves(int extraLeaves) {
    final newHeld = held + extraLeaves;
    if (newHeld == 0) return 100.0;
    return (attended / newHeld) * 100.0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectCode': subjectCode,
        'subjectName': subjectName,
        'credits': credits,
        'attended': attended,
        'held': held,
        'expectedRemainingClasses': expectedRemainingClasses,
        'internalMarks': internalMarks,
        'maxInternal': maxInternal,
        'targetPercentage': targetPercentage,
      };

  factory CourseAttendance.fromJson(Map<String, dynamic> json) => CourseAttendance(
        id: json['id'] as String,
        subjectCode: json['subjectCode'] as String,
        subjectName: json['subjectName'] as String,
        credits: json['credits'] as int? ?? 4,
        attended: json['attended'] as int,
        held: json['held'] as int,
        expectedRemainingClasses: json['expectedRemainingClasses'] as int? ?? 0,
        internalMarks: (json['internalMarks'] as num?)?.toDouble() ?? 0.0,
        maxInternal: (json['maxInternal'] as num?)?.toDouble() ?? 40.0,
        targetPercentage: (json['targetPercentage'] as num?)?.toDouble() ?? 95.01,
      );
}

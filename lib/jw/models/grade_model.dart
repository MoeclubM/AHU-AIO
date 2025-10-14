/// 成绩数据模型
class GradeModel {
  final String semester;
  final String courseName;
  final String score;
  final String courseCode;
  final String courseType;
  final String requiredType;
  final double credit;
  final double gpa;
  final String gradePoint;

  const GradeModel({
    required this.semester,
    required this.courseName,
    required this.score,
    required this.courseCode,
    required this.courseType,
    required this.requiredType,
    required this.credit,
    required this.gpa,
    required this.gradePoint,
  });

  factory GradeModel.fromJson(Map<String, dynamic> json) {
    // 根据实际API响应数据结构解析
    final semester = json['semester']?['nameZh']?.toString() ??
                     json['semesterName']?.toString() ??
                     json['semesterCode']?.toString() ?? '';

    final courseName = json['courseNameZh']?.toString() ??
                      json['courseName']?.toString() ?? '';

    final courseCode = json['courseCode']?.toString() ?? '';

    final courseType = json['courseType']?['nameZh']?.toString() ??
                      json['courseType']?.toString() ?? '';

    final requiredType = json['courseProperty']?['nameZh']?.toString() ??
                        json['requiredType']?.toString() ??
                        json['studyType']?['textZh']?.toString() ?? '';

    final finalGrade = json['finalGrade']?.toString() ??
                      json['score']?.toString() ?? '';

    final credits = _parseDouble(json['credits']) ?? 0.0;
    final gp = _parseDouble(json['gp']) ?? 0.0;

    return GradeModel(
      semester: semester,
      courseName: courseName,
      score: finalGrade,
      courseCode: courseCode,
      courseType: courseType,
      requiredType: requiredType,
      credit: credits,
      gpa: gp,
      gradePoint: gp.toString(),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// 获取等级成绩（如优秀、良好等）
  String get gradeLevel {
    if (score.contains('优秀')) return '优秀';
    if (score.contains('良好')) return '良好';
    if (score.contains('中等')) return '中等';
    if (score.contains('及格')) return '及格';
    if (score.contains('不及格')) return '不及格';
    return score; // 返回数字分数
  }

  /// 判断是否为通过
  bool get isPass {
    final level = gradeLevel;
    if (level == '优秀' || level == '良好' || level == '中等' || level == '及格') {
      return true;
    }

    // 对于数字分数，60分及以上为通过
    final numericScore = double.tryParse(score);
    if (numericScore != null) {
      return numericScore >= 60;
    }

    return false;
  }
}
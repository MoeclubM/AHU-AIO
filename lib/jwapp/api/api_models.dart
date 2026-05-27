/// 学期信息模型
class SemesterInfo {
  final int semesterId;
  final String semesterName;
  final String startDate;
  final String endDate;
  final int weekCount;
  final bool isCurrent;

  SemesterInfo({
    required this.semesterId,
    required this.semesterName,
    required this.startDate,
    required this.endDate,
    required this.weekCount,
    this.isCurrent = false,
  });

  factory SemesterInfo.fromJson(Map<String, dynamic> json) {
    return SemesterInfo(
      semesterId: json['semesterId'] ?? json['id'] ?? 0,
      semesterName: json['semesterName'] ?? json['name'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      weekCount: json['weekCount'] ?? 0,
      isCurrent: json['current'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'semesterId': semesterId,
      'semesterName': semesterName,
      'startDate': startDate,
      'endDate': endDate,
      'weekCount': weekCount,
      'isCurrent': isCurrent,
    };
  }
}

/// 考试信息模型
class ExamInfo {
  final String examId;
  final String courseName;
  final String examType;
  final String examDate;
  final String startTime;
  final String endTime;
  final String classroom;
  final String campus;
  final String building;
  final String seatNumber;

  ExamInfo({
    required this.examId,
    required this.courseName,
    required this.examType,
    required this.examDate,
    required this.startTime,
    required this.endTime,
    required this.classroom,
    required this.campus,
    required this.building,
    required this.seatNumber,
  });

  factory ExamInfo.fromJson(Map<String, dynamic> json) {
    return ExamInfo(
      examId: json['examId'] ?? json['id'] ?? '',
      courseName: json['courseName'] ?? json['name'] ?? '',
      examType: json['examType'] ?? '',
      examDate: json['examDate'] ?? json['date'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      classroom: json['classroom'] ?? json['roomName'] ?? '',
      campus: json['campusName'] ?? json['campus'] ?? '',
      building: json['buildingName'] ?? json['building'] ?? '',
      seatNumber: json['seatNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'examId': examId,
      'courseName': courseName,
      'examType': examType,
      'examDate': examDate,
      'startTime': startTime,
      'endTime': endTime,
      'classroom': classroom,
      'campus': campus,
      'building': building,
      'seatNumber': seatNumber,
    };
  }
}

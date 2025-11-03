// ignore_for_file: dangling_library_doc_comments
/// API数据模型定义

/// 用户信息模型
class UserInfo {
  final String userId;
  final String userName;
  final String studentNo;
  final String className;
  final String major;
  final String college;

  UserInfo({
    required this.userId,
    required this.userName,
    required this.studentNo,
    required this.className,
    required this.major,
    required this.college,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['userId'] ?? json['id'] ?? '',
      userName: json['userName'] ?? json['name'] ?? '',
      studentNo: json['studentNo'] ?? json['code'] ?? '',
      className: json['className'] ?? json['class'] ?? '',
      major: json['major'] ?? '',
      college: json['college'] ?? json['organizationName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'studentNo': studentNo,
      'className': className,
      'major': major,
      'college': college,
    };
  }
}

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

/// 课程信息模型
class CourseInfo {
  final String courseId;
  final String courseName;
  final String teacherName;
  final String classroom;
  final String campus;
  final String building;
  final String weekDay;
  final String startSection;
  final String endSection;
  final List<int> weekNumbers;

  CourseInfo({
    required this.courseId,
    required this.courseName,
    required this.teacherName,
    required this.classroom,
    required this.campus,
    required this.building,
    required this.weekDay,
    required this.startSection,
    required this.endSection,
    required this.weekNumbers,
  });

  factory CourseInfo.fromJson(Map<String, dynamic> json) {
    return CourseInfo(
      courseId: json['courseId'] ?? json['id'] ?? '',
      courseName: json['courseName'] ?? json['name'] ?? '',
      teacherName: json['teacherName'] ?? json['teacher'] ?? '',
      classroom: json['classroom'] ?? json['roomName'] ?? '',
      campus: json['campusName'] ?? json['campus'] ?? '',
      building: json['buildingName'] ?? json['building'] ?? '',
      weekDay: json['weekDay'] ?? '',
      startSection: json['startSection'] ?? '',
      endSection: json['endSection'] ?? '',
      weekNumbers: List<int>.from(json['weekNumbers'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'courseName': courseName,
      'teacherName': teacherName,
      'classroom': classroom,
      'campus': campus,
      'building': building,
      'weekDay': weekDay,
      'startSection': startSection,
      'endSection': endSection,
      'weekNumbers': weekNumbers,
    };
  }
}

/// 成绩信息模型
class GradeInfo {
  final String courseId;
  final String courseName;
  final String courseCode;
  final double score;
  final double credit;
  final double gpa;
  final String courseType;
  final String examType;
  final String semesterName;
  final String gradeLevel;

  GradeInfo({
    required this.courseId,
    required this.courseName,
    required this.courseCode,
    required this.score,
    required this.credit,
    required this.gpa,
    required this.courseType,
    required this.examType,
    required this.semesterName,
    required this.gradeLevel,
  });

  factory GradeInfo.fromJson(Map<String, dynamic> json) {
    return GradeInfo(
      courseId: json['courseId'] ?? json['id'] ?? '',
      courseName: json['courseName'] ?? json['name'] ?? '',
      courseCode: json['courseCode'] ?? json['code'] ?? '',
      score: (json['score'] ?? 0.0).toDouble(),
      credit: (json['credit'] ?? 0.0).toDouble(),
      gpa: (json['gpa'] ?? 0.0).toDouble(),
      courseType: json['courseType'] ?? '',
      examType: json['examType'] ?? '',
      semesterName: json['semesterName'] ?? '',
      gradeLevel: json['gradeLevel'] ?? json['level'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'courseName': courseName,
      'courseCode': courseCode,
      'score': score,
      'credit': credit,
      'gpa': gpa,
      'courseType': courseType,
      'examType': examType,
      'semesterName': semesterName,
      'gradeLevel': gradeLevel,
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

/// 通知信息模型
class NoticeInfo {
  final String noticeId;
  final String title;
  final String content;
  final String publishTime;
  final String publisher;
  final String category;
  bool isRead;

  NoticeInfo({
    required this.noticeId,
    required this.title,
    required this.content,
    required this.publishTime,
    required this.publisher,
    required this.category,
    this.isRead = false,
  });

  factory NoticeInfo.fromJson(Map<String, dynamic> json) {
    return NoticeInfo(
      noticeId: json['noticeId'] ?? json['id']?.toString() ?? '',
      title: json['title'] ?? json['headline'] ?? json['subject'] ?? '',
      content: json['content'] ?? json['body'] ?? json['message'] ?? '',
      publishTime: json['publishTime'] ?? json['createTime'] ?? json['publishDate'] ?? json['time'] ?? '',
      publisher: json['publisher'] ?? json['author'] ?? json['deptName'] ?? '系统',
      category: json['category'] ?? json['type'] ?? json['noticeType'] ?? '通知',
      isRead: json['isRead'] ?? json['read'] ?? json['status'] == 'read' ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'noticeId': noticeId,
      'title': title,
      'content': content,
      'publishTime': publishTime,
      'publisher': publisher,
      'category': category,
      'isRead': isRead,
    };
  }

  NoticeInfo copyWith({
    String? noticeId,
    String? title,
    String? content,
    String? publishTime,
    String? publisher,
    String? category,
    bool? isRead,
  }) {
    return NoticeInfo(
      noticeId: noticeId ?? this.noticeId,
      title: title ?? this.title,
      content: content ?? this.content,
      publishTime: publishTime ?? this.publishTime,
      publisher: publisher ?? this.publisher,
      category: category ?? this.category,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// 培养方案模型
class PlanModel {
  final String id;
  final String name;
  final String major;
  final String enrollmentYear;
  final bool isActive;

  PlanModel({
    required this.id,
    required this.name,
    required this.major,
    required this.enrollmentYear,
    required this.isActive,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id'] ?? json['planId'] ?? '',
      name: json['name'] ?? json['planName'] ?? '',
      major: json['major'] ?? json['majorName'] ?? '',
      enrollmentYear: json['enrollmentYear'] ?? json['year'] ?? '',
      isActive: json['isActive'] ?? json['active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'major': major,
      'enrollmentYear': enrollmentYear,
      'isActive': isActive,
    };
  }
}

/// 课程要求模型
class CourseRequirement {
  final String id;
  final String courseName;
  final List<String> courseIds;
  final int requiredCredits;
  final bool isRequired;
  final bool isCore;
  final String category;

  CourseRequirement({
    required this.id,
    required this.courseName,
    required this.courseIds,
    required this.requiredCredits,
    required this.isRequired,
    required this.isCore,
    required this.category,
  });

  factory CourseRequirement.fromJson(Map<String, dynamic> json) {
    return CourseRequirement(
      id: json['id'] ?? '',
      courseName: json['courseName'] ?? json['name'] ?? '',
      courseIds: (json['courseIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      requiredCredits: json['requiredCredits'] ?? json['credits'] ?? 0,
      isRequired: json['isRequired'] ?? json['required'] ?? false,
      isCore: json['isCore'] ?? json['core'] ?? false,
      category: json['category'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseName': courseName,
      'courseIds': courseIds,
      'requiredCredits': requiredCredits,
      'isRequired': isRequired,
      'isCore': isCore,
      'category': category,
    };
  }
}

/// 已完成课程模型
class CompletedCourse {
  final String courseId;
  final String courseName;
  final double credits;
  final double score;
  final String semester;
  final String category;

  CompletedCourse({
    required this.courseId,
    required this.courseName,
    required this.credits,
    required this.score,
    required this.semester,
    required this.category,
  });

  factory CompletedCourse.fromJson(Map<String, dynamic> json) {
    return CompletedCourse(
      courseId: json['courseId'] ?? json['id'] ?? '',
      courseName: json['courseName'] ?? json['name'] ?? '',
      credits: (json['credits'] ?? json['credit'] ?? 0.0).toDouble(),
      score: (json['score'] ?? 0.0).toDouble(),
      semester: json['semester'] ?? json['semesterName'] ?? '',
      category: json['category'] ?? json['courseType'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'courseName': courseName,
      'credits': credits,
      'score': score,
      'semester': semester,
      'category': category,
    };
  }
}

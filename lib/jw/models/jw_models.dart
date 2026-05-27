/// 新教务系统 (jw.ahu.edu.cn) 数据模型
/// 基于真实 API 响应格式
library;

// ============================================================
// 教学周
// ============================================================
class TeachWeekInfo {
  final String? currentSemester;
  final int? weekIndex;
  final int? dayIndex;
  final bool isInSemester;

  TeachWeekInfo({
    this.currentSemester,
    this.weekIndex,
    this.dayIndex,
    this.isInSemester = false,
  });

  factory TeachWeekInfo.fromJson(Map<String, dynamic> json) {
    return TeachWeekInfo(
      currentSemester: json['currentSemester']?.toString(),
      weekIndex: _toInt(json['weekIndex']),
      dayIndex: _toInt(json['dayIndex']),
      isInSemester: json['isInSemester'] == true,
    );
  }
}

// ============================================================
// 学期
// ============================================================
class JwSemester {
  final int? id;
  final String? nameZh;
  final String? nameEn;
  final String? code;
  final String? schoolYear;
  final String? startDate;
  final String? endDate;

  JwSemester({
    this.id,
    this.nameZh,
    this.nameEn,
    this.code,
    this.schoolYear,
    this.startDate,
    this.endDate,
  });

  factory JwSemester.fromJson(Map<String, dynamic> json) {
    return JwSemester(
      id: _toInt(json['id']),
      nameZh: json['nameZh']?.toString(),
      nameEn: json['nameEn']?.toString(),
      code: json['code']?.toString(),
      schoolYear: json['schoolYear']?.toString(),
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
    );
  }

  String get displayName => nameZh ?? nameEn ?? '学期 $id';
}

// ============================================================
// 成绩
// ============================================================
class GradeInfo {
  final int? id;
  final int? semesterId;
  final String? semesterName;
  final String? courseCode;
  final String? courseName;
  final String? courseNameEn;
  final double? credits;
  final String? courseType;
  final String? courseProperty;
  final String? courseTaxon;
  final String? gaGrade; // 成绩（字符串，如 "90" 或 "优秀"）
  final double? gp; // 绩点
  final bool passed;
  final bool compulsory;

  GradeInfo({
    this.id,
    this.semesterId,
    this.semesterName,
    this.courseCode,
    this.courseName,
    this.courseNameEn,
    this.credits,
    this.courseType,
    this.courseProperty,
    this.courseTaxon,
    this.gaGrade,
    this.gp,
    this.passed = false,
    this.compulsory = false,
  });

  factory GradeInfo.fromJson(Map<String, dynamic> json) {
    return GradeInfo(
      id: _toInt(json['id']),
      semesterId: _toInt(json['semesterId']),
      semesterName: json['semesterName']?.toString(),
      courseCode: json['courseCode']?.toString(),
      courseName: json['courseName']?.toString(),
      courseNameEn: json['courseNameEn']?.toString(),
      credits: _toDouble(json['credits']),
      courseType: json['courseType']?.toString(),
      courseProperty: json['courseProperty']?.toString(),
      courseTaxon: json['courseTaxon']?.toString(),
      gaGrade: json['gaGrade']?.toString(),
      gp: _toDouble(json['gp']),
      passed: json['passed'] == true,
      compulsory: json['compulsory'] == true,
    );
  }

  /// 尝试将 gaGrade 转为数字
  double? get numericGrade {
    if (gaGrade == null) return null;
    return double.tryParse(gaGrade!);
  }
}

// ============================================================
// 课表活动 (来自 print-data 的 activities)
// ============================================================
class CourseActivity {
  final int? lessonId;
  final String? courseCode;
  final String? courseName;
  final String? lessonName;
  final int? weekday; // 1=周一 ... 7=周日
  final int? startUnit; // 开始节次
  final int? endUnit; // 结束节次
  final List<int> weekIndexes; // 周次列表
  final String? weeksStr;
  final String? room;
  final String? building;
  final String? campus;
  final List<String> teachers;
  final double? credits;

  CourseActivity({
    this.lessonId,
    this.courseCode,
    this.courseName,
    this.lessonName,
    this.weekday,
    this.startUnit,
    this.endUnit,
    this.weekIndexes = const [],
    this.weeksStr,
    this.room,
    this.building,
    this.campus,
    this.teachers = const [],
    this.credits,
  });

  factory CourseActivity.fromJson(Map<String, dynamic> json) {
    List<int> parseWeeks(dynamic w) {
      if (w is List) return w.map((e) => _toInt(e) ?? 0).toList();
      return [];
    }

    List<String> parseTeachers(dynamic t) {
      if (t is List) return t.map((e) => e.toString()).toList();
      return [];
    }

    return CourseActivity(
      lessonId: _toInt(json['lessonId']),
      courseCode: json['courseCode']?.toString(),
      courseName: json['courseName']?.toString(),
      lessonName: json['lessonName']?.toString(),
      weekday: _toInt(json['weekday']),
      startUnit: _toInt(json['startUnit']),
      endUnit: _toInt(json['endUnit']),
      weekIndexes: parseWeeks(json['weekIndexes']),
      weeksStr: json['weeksStr']?.toString(),
      room: json['room']?.toString(),
      building: json['building']?.toString(),
      campus: json['campus']?.toString(),
      teachers: parseTeachers(json['teachers'] ?? json['teacherNames']),
      credits: _toDouble(json['credits']),
    );
  }

  static const _weekdays = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  String get weekdayStr => (weekday != null && weekday! >= 1 && weekday! <= 7)
      ? _weekdays[weekday!]
      : '';

  String get slotRange => '$startUnit~$endUnit 节';

  String get teacherStr => teachers.join('、');
}

/// 课表数据（从 print-data 解析）
class CourseTableData {
  final List<CourseActivity> activities;
  final int? studentId;
  final String? studentName;
  final String? studentCode;
  final String? department;
  final String? major;
  final String? adminclass;
  final double? totalCredits;

  CourseTableData({
    this.activities = const [],
    this.studentId,
    this.studentName,
    this.studentCode,
    this.department,
    this.major,
    this.adminclass,
    this.totalCredits,
  });

  factory CourseTableData.fromJson(Map<String, dynamic> json) {
    final vms = json['studentTableVms'] as List?;
    if (vms == null || vms.isEmpty) return CourseTableData();

    final vm = vms[0] as Map<String, dynamic>;
    final activities = <CourseActivity>[];
    final acts = vm['activities'] as List?;
    if (acts != null) {
      for (final a in acts) {
        if (a is Map<String, dynamic>) {
          activities.add(CourseActivity.fromJson(a));
        }
      }
    }

    return CourseTableData(
      activities: activities,
      studentId: _toInt(vm['id']),
      studentName: vm['name']?.toString(),
      studentCode: vm['code']?.toString(),
      department: vm['department']?.toString(),
      major: vm['major']?.toString(),
      adminclass: vm['adminclass']?.toString(),
      totalCredits: _toDouble(vm['credits']),
    );
  }
}

// ============================================================
// 培养方案
// ============================================================
class ProgramCourse {
  final int? id;
  final bool compulsory;
  final String? courseName;
  final String? courseCode;
  final double? credits;
  final List<String> terms;
  final String? courseType;

  ProgramCourse({
    this.id,
    this.compulsory = false,
    this.courseName,
    this.courseCode,
    this.credits,
    this.terms = const [],
    this.courseType,
  });

  factory ProgramCourse.fromJson(Map<String, dynamic> json) {
    final course = json['course'] as Map<String, dynamic>?;
    List<String> parseTerms(dynamic t) {
      if (t is List) return t.map((e) => e.toString()).toList();
      return [];
    }

    return ProgramCourse(
      id: _toInt(json['id']),
      compulsory: json['compulsory'] == true,
      courseName: course?['nameZh']?.toString() ?? course?['name']?.toString(),
      courseCode: course?['code']?.toString(),
      credits: _toDouble(course?['credits'] ?? json['credits']),
      terms: parseTerms(json['readableTerms'] ?? json['terms']),
      courseType: json['courseType'] is Map
          ? (json['courseType'] as Map)['nameZh']?.toString()
          : json['courseType']?.toString(),
    );
  }
}

class ProgramModule {
  final int? id;
  final String? name;
  final double? requiredCredits;
  final int? requiredCourseNum;
  final List<ProgramCourse> courses;
  final List<ProgramModule> children;

  ProgramModule({
    this.id,
    this.name,
    this.requiredCredits,
    this.requiredCourseNum,
    this.courses = const [],
    this.children = const [],
  });

  factory ProgramModule.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as Map<String, dynamic>?;
    final requireInfo = json['requireInfo'] as Map<String, dynamic>?;

    List<ProgramCourse> courses = [];
    final planCourses = json['planCourses'] as List?;
    if (planCourses != null) {
      courses = planCourses
          .map((e) => ProgramCourse.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    List<ProgramModule> children = [];
    final kids = json['children'] as List? ?? json['subModules'] as List?;
    if (kids != null) {
      children = kids
          .map((e) => ProgramModule.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return ProgramModule(
      id: _toInt(json['id']),
      name: type?['nameZh']?.toString() ?? type?['name']?.toString(),
      requiredCredits: _toDouble(requireInfo?['requiredCredits']),
      requiredCourseNum: _toInt(requireInfo?['requiredCourseNum']),
      courses: courses,
      children: children,
    );
  }
}

// ============================================================
// 通知
// ============================================================
class NoticeData {
  final List<dynamic> notices;
  final int? notificationCount;
  final int? noReadCount;
  final int? readCount;

  NoticeData({
    this.notices = const [],
    this.notificationCount,
    this.noReadCount,
    this.readCount,
  });

  factory NoticeData.fromJson(Map<String, dynamic> json) {
    final count = json['noticeCount'] as Map<String, dynamic>?;
    return NoticeData(
      notices: json['notices'] as List? ?? [],
      notificationCount: _toInt(count?['notificationCount']),
      noReadCount: _toInt(count?['noReadCount']),
      readCount: _toInt(count?['readCount']),
    );
  }
}

// ============================================================
// 工具函数（公开，供其他文件使用）
// ============================================================
int? toInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? toDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

// 内部别名（向后兼容模型类内部调用）
int? _toInt(dynamic value) => toInt(value);
double? _toDouble(dynamic value) => toDouble(value);

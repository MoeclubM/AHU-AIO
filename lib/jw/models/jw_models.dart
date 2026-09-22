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

  /// 原始周数是否在学期内且落在合法区间 [1, 25]
  bool get isWeekValid =>
      isInSemester && weekIndex != null && weekIndex! >= 1 && weekIndex! <= 25;

  /// 供 UI 使用的安全周数：
  /// - 学期内且 1..25 直接返回
  /// - 学期内但周数异常（负数/越界/null）回落到 1
  /// - 非学期返回 1（避免负数导致课表空白/显示异常），由 [weekLabel] 区分文案
  int get effectiveWeekIndex {
    if (!isInSemester) return 1;
    if (weekIndex == null || weekIndex! < 1) return 1;
    if (weekIndex! > 25) return 25;
    return weekIndex!;
  }

  /// 顶栏/卡片显示文案
  String get weekLabel {
    if (!isInSemester) return '假期中';
    return '第 $effectiveWeekIndex 周';
  }

  /// 副标题：学期内显示"教学进行中"，非学期显示"非教学周"，周数异常时追加提示
  String get statusLabel {
    if (!isInSemester) return '非教学周';
    if (weekIndex != null && (weekIndex! < 1 || weekIndex! > 25)) {
      return '教学进行中 · 周数已校正';
    }
    return '教学进行中';
  }

  /// 兼容旧调用：安全周数（等同 effectiveWeekIndex）
  int get sanitizedWeekIndex => effectiveWeekIndex;
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

// ============================================================
// 安大新教务（jw.ahu.edu.cn）排课与课表数据模型
// ============================================================

/// 学期元数据模型。
///
/// 注意：[id] 为官方后端整型 ID（如 132、72、52），请求课表时必须使用此 ID。
class JwSemesterInfo {
  final int id;
  final String code;
  final String schoolYear;
  final String nameZh;
  final String? startDate;
  final String? endDate;
  final String? season;

  const JwSemesterInfo({
    required this.id,
    required this.code,
    required this.schoolYear,
    required this.nameZh,
    this.startDate,
    this.endDate,
    this.season,
  });

  factory JwSemesterInfo.fromJson(Map<String, dynamic> json) {
    return JwSemesterInfo(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      code: json['code']?.toString() ?? '',
      schoolYear: json['schoolYear']?.toString() ?? '',
      nameZh: json['nameZh']?.toString() ?? json['name']?.toString() ?? '未知学期',
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
      season: json['season']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'schoolYear': schoolYear,
        'nameZh': nameZh,
        'startDate': startDate,
        'endDate': endDate,
        'season': season,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JwSemesterInfo &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => nameZh;
}

/// 单次排课活动数据模型（解析自 `/print-data` 返回的 `activities` 数组元素）。
class JwCourseActivity {
  final int lessonId;
  final String courseName;
  final String courseCode;
  final String room;
  final String building;
  final String campus;
  final int weekday; // 1 ~ 7 对应周一至周日
  final int startUnit; // 1 ~ 13
  final int endUnit; // 1 ~ 13
  final List<int> weekIndexes; // 该课程上课的教学周列表，如 [1, 2, 3, 4]
  final List<String> teachers;
  final num? credits;
  final String? courseTypeName;

  const JwCourseActivity({
    required this.lessonId,
    required this.courseName,
    required this.courseCode,
    required this.room,
    required this.building,
    required this.campus,
    required this.weekday,
    required this.startUnit,
    required this.endUnit,
    required this.weekIndexes,
    required this.teachers,
    this.credits,
    this.courseTypeName,
  });

  factory JwCourseActivity.fromJson(Map<String, dynamic> json) {
    final weeks = (json['weekIndexes'] as List?)
            ?.map((e) => int.tryParse('$e') ?? 0)
            .where((w) => w > 0)
            .toList() ??
        [];

    final tList = ((json['teacherNames'] ?? json['teachers']) as List?)
            ?.map((e) => e.toString().trim())
            .where((t) => t.isNotEmpty)
            .toList() ??
        [];

    String? typeName;
    if (json['courseType'] is Map) {
      typeName = json['courseType']['nameZh']?.toString();
    } else if (json['courseType'] != null) {
      typeName = json['courseType'].toString();
    }

    return JwCourseActivity(
      lessonId: json['lessonId'] is int
          ? json['lessonId'] as int
          : int.tryParse('${json['lessonId']}') ?? 0,
      courseName: json['courseName']?.toString() ?? '未知课程',
      courseCode: json['courseCode']?.toString() ?? '',
      room: json['room']?.toString() ?? '待定地点',
      building: json['building']?.toString() ?? '',
      campus: json['campus']?.toString() ?? '',
      weekday: json['weekday'] is int
          ? json['weekday'] as int
          : int.tryParse('${json['weekday']}') ?? 1,
      startUnit: json['startUnit'] is int
          ? json['startUnit'] as int
          : int.tryParse('${json['startUnit']}') ?? 1,
      endUnit: json['endUnit'] is int
          ? json['endUnit'] as int
          : int.tryParse('${json['endUnit']}') ?? 1,
      weekIndexes: weeks,
      teachers: tList,
      credits: json['credits'] is num ? json['credits'] as num : null,
      courseTypeName: typeName,
    );
  }

  Map<String, dynamic> toJson() => {
        'lessonId': lessonId,
        'courseName': courseName,
        'courseCode': courseCode,
        'room': room,
        'building': building,
        'campus': campus,
        'weekday': weekday,
        'startUnit': startUnit,
        'endUnit': endUnit,
        'weekIndexes': weekIndexes,
        'teachers': teachers,
        'credits': credits,
        'courseTypeName': courseTypeName,
      };

  bool hasWeek(int week) => weekIndexes.contains(week);
}

/// 课表格子排布渲染单元实体（支持重叠合并显示）。
class JwScheduleEntry {
  final int weekday;
  final int startUnit;
  final int endUnit;
  final String courseName;
  final String teacherName;
  final String roomName;
  final List<JwCourseActivity> activities;

  const JwScheduleEntry({
    required this.weekday,
    required this.startUnit,
    required this.endUnit,
    required this.courseName,
    required this.teacherName,
    required this.roomName,
    required this.activities,
  });

  /// 安徽大学作息标准开始时间
  String get startTime {
    return switch (startUnit) {
      1 => '08:00',
      2 => '08:50',
      3 => '09:55',
      4 => '10:45',
      5 => '11:35',
      6 => '14:00',
      7 => '14:50',
      8 => '15:55',
      9 => '16:45',
      10 => '17:35',
      11 => '19:00',
      12 => '19:50',
      13 => '20:40',
      _ => '08:00',
    };
  }

  /// 安徽大学作息标准结束时间
  String get endTime {
    return switch (endUnit) {
      1 => '08:45',
      2 => '09:35',
      3 => '10:40',
      4 => '11:30',
      5 => '12:20',
      6 => '14:45',
      7 => '15:35',
      8 => '16:40',
      9 => '17:30',
      10 => '18:20',
      11 => '19:45',
      12 => '20:35',
      13 => '21:25',
      _ => '09:35',
    };
  }
}

/// 全学期完整排课数据聚合对象。
class JwScheduleData {
  final int studentId;
  final String studentName;
  final String studentCode;
  final String? adminclass;
  final String? major;
  final List<JwCourseActivity> activities;

  const JwScheduleData({
    required this.studentId,
    required this.studentName,
    required this.studentCode,
    this.adminclass,
    this.major,
    required this.activities,
  });

  factory JwScheduleData.fromJson(Map<String, dynamic> json) {
    final vms = (json['studentTableVms'] as List?) ?? [];
    if (vms.isEmpty || vms.first is! Map) {
      return const JwScheduleData(
        studentId: 0,
        studentName: '',
        studentCode: '',
        activities: [],
      );
    }

    final stdMap = Map<String, dynamic>.from(vms.first as Map);
    final rawActs = (stdMap['activities'] as List?) ?? [];
    final actList = rawActs
        .whereType<Map>()
        .map((m) => JwCourseActivity.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    return JwScheduleData(
      studentId: stdMap['id'] is int
          ? stdMap['id'] as int
          : int.tryParse('${stdMap['id']}') ?? 0,
      studentName: stdMap['name']?.toString() ?? '',
      studentCode: stdMap['code']?.toString() ?? '',
      adminclass: stdMap['adminclass']?.toString(),
      major: stdMap['major']?.toString(),
      activities: actList,
    );
  }

  Map<String, dynamic> toJson() => {
        'studentTableVms': [
          {
            'id': studentId,
            'name': studentName,
            'code': studentCode,
            'adminclass': adminclass,
            'major': major,
            'activities': activities.map((a) => a.toJson()).toList(),
          }
        ],
      };

  /// 过滤指定教学周，并排布生成周一至周日（1~7）的排课列表。
  Map<int, List<JwScheduleEntry>> buildWeekSchedule(int week) {
    final result = <int, List<JwScheduleEntry>>{
      for (var d = 1; d <= 7; d++) d: <JwScheduleEntry>[],
    };

    final weekActs = activities.where((a) => a.hasWeek(week)).toList();

    for (var weekday = 1; weekday <= 7; weekday++) {
      final dayActs = weekActs.where((a) => a.weekday == weekday).toList();
      dayActs.sort((a, b) => a.startUnit.compareTo(b.startUnit));

      final entries = <JwScheduleEntry>[];
      for (final act in dayActs) {
        // 重叠时间合并处理
        final overlapIdx = entries.indexWhere(
          (e) => (act.startUnit <= e.endUnit && act.endUnit >= e.startUnit),
        );

        if (overlapIdx >= 0) {
          final existing = entries[overlapIdx];
          entries[overlapIdx] = JwScheduleEntry(
            weekday: weekday,
            startUnit: existing.startUnit < act.startUnit ? existing.startUnit : act.startUnit,
            endUnit: existing.endUnit > act.endUnit ? existing.endUnit : act.endUnit,
            courseName: '${existing.courseName} / ${act.courseName}',
            teacherName: '${existing.teacherName} / ${act.teachers.join(",")}',
            roomName: existing.roomName == act.room ? existing.roomName : '${existing.roomName} / ${act.room}',
            activities: [...existing.activities, act],
          );
        } else {
          entries.add(
            JwScheduleEntry(
              weekday: weekday,
              startUnit: act.startUnit,
              endUnit: act.endUnit,
              courseName: act.courseName,
              teacherName: act.teachers.join(', '),
              roomName: act.room,
              activities: [act],
            ),
          );
        }
      }
      result[weekday] = entries;
    }

    return result;
  }
}

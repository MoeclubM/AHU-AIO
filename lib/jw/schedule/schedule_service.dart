import 'package:flutter/material.dart';
import '../api/getclass.dart';
import '../../globals.dart' as globals;
import 'semester_config.dart';
import '../utils/time_utils.dart';

// 时间范围辅助类
class TimeRange {
  final String start;
  final String end;

  TimeRange(this.start, this.end);
}

// 时间段信息类
class TimeSlotInfo {
  final String startTime;
  final String endTime;
  final String weekday;
  final String courseName;
  final String teacherName;
  final String roomName;
  final String scheduleGroupId;
  final List<dynamic> details;
  final bool isCurrentWeek;

  TimeSlotInfo({
    required this.startTime,
    required this.endTime,
    required this.weekday,
    required this.courseName,
    required this.teacherName,
    required this.roomName,
    required this.scheduleGroupId,
    required this.details,
    required this.isCurrentWeek,
  });
}

class ScheduleService extends ChangeNotifier {
  List<dynamic>? _classes;
  bool _isLoading = false;

  List<dynamic>? get classes => _classes;
  bool get isLoading => _isLoading;

  /// 获取课表数据，支持传入学期ID
  Future<void> fetchData({String? semesterId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = globals.idToken;
      if (token == null) {
        throw Exception('未找到登录令牌');
      }

      // 如果没有传入 semesterId，获取当前学期ID
      String? actualSemesterId = semesterId;
      if (actualSemesterId == null) {
        actualSemesterId = await SemesterConfig.getCurrentSemesterId();
        if (actualSemesterId == null) {
          throw Exception('无法获取学期ID，请确保已正确登录');
        }
      }

      // 获取课程数据
      _classes = await getClass(token, semesterId: actualSemesterId);
    } catch (e) {
      _classes = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 根据学期名称和月份更新课表数据
  Future<void> updateScheduleData(String semesterName, String month) async {
    // 直接使用当前学期ID
    final semesterId = await SemesterConfig.getCurrentSemesterId();
      if (semesterId == null) {
        return;
      }

      await fetchData(semesterId: semesterId);
  }

  String formatTime(int time) {
    return TimeUtils.formatTime(time);
  }

  // 获取当前周数
  Future<int?> getCurrentWeek() async {
    try {
      final token = globals.idToken;
      if (token == null) return null;

      // 可以通过调用一个API获取当前教学周
      // 这里暂时返回一个默认值或基于日期计算
      final now = DateTime.now();
      // 假设学期第一周是9月1日所在周
      final semesterStart = DateTime(now.year, 9, 1);
      final startOfWeek = semesterStart.subtract(Duration(days: semesterStart.weekday - 1));
      final currentWeek = ((now.difference(startOfWeek).inDays) / 7).floor() + 1;
      return currentWeek > 0 ? currentWeek : 1;
    } catch (e) {
      return null;
    }
  }

  Map<String, Map<String, List<Map<String, dynamic>>>> processClasses({int? selectedWeek, int? currentWeek}) {
    final Map<String, Map<String, List<Map<String, dynamic>>>> processedClasses = {};

    // 检查_classes是否为空
    if (_classes == null || _classes!.isEmpty) {
      return processedClasses;
    }

    // 收集所有课程时间段，智能计算时间段划分
    final List<TimeSlotInfo> timeSlotInfos = [];

    // 扫描所有课程，收集时间信息
    for (var classItem in _classes!) {
      final schedules = classItem['schedules'];
      if (schedules == null || schedules.isEmpty) {
        continue;
      }

      for (var schedule in schedules) {
        // 安全处理时间格式转换
        final startTimeValue = schedule['startTime'];
        final endTimeValue = schedule['endTime'];

        String startTime, endTime;
        if (startTimeValue is int) {
          startTime = formatTime(startTimeValue);
        } else {
          startTime = startTimeValue?.toString() ?? '00:00';
        }

        if (endTimeValue is int) {
          endTime = formatTime(endTimeValue);
        } else {
          endTime = endTimeValue?.toString() ?? '00:00';
        }
        final weekdayValue = schedule['weekday'];

        // 安全处理星期数据转换，支持多种数据格式
        int weekdayNum = 1; // 默认周一
        if (weekdayValue is int) {
          weekdayNum = weekdayValue;
        } else if (weekdayValue is String) {
          weekdayNum = int.tryParse(weekdayValue) ?? 1;
        } else {
          weekdayNum = int.tryParse(weekdayValue.toString()) ?? 1;
        }

        // 确保星期数在有效范围内(1-7)
        if (weekdayNum < 1 || weekdayNum > 7) {
          weekdayNum = 1;
        }

        final weekday = '周$weekdayNum';

        // 根据课程日期判断是否在本周
        bool shouldIncludeCourse = true;
        bool isCurrentWeekCourse = true;

        if (selectedWeek != null) {
          // 从课程数据中获取课程日期
          final courseDate = schedule['date'] ?? classItem['date'];
          if (courseDate != null) {
            // 解析课程日期
            DateTime courseDateTime;
            if (courseDate is String) {
              try {
                courseDateTime = DateTime.parse(courseDate);
              } catch (e) {
                // 如果解析失败，尝试其他格式
                courseDateTime = DateTime.now();
              }
            } else {
              courseDateTime = DateTime.now();
            }

            // 计算当前周的开始和结束日期（周一到周日）
            final now = DateTime.now();
            final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
            final currentWeekEnd = currentWeekStart.add(const Duration(days: 6));

            // 计算选择周的开始和结束日期
            final selectedWeekStart = currentWeekStart.add(Duration(days: (selectedWeek - 1) * 7));
            final selectedWeekEnd = selectedWeekStart.add(const Duration(days: 6));

            // 判断课程是否在选择的周内
            shouldIncludeCourse = _isDateInWeek(courseDateTime, selectedWeekStart, selectedWeekEnd);

            // 判断课程是否在当前周内
            isCurrentWeekCourse = _isDateInWeek(courseDateTime, currentWeekStart, currentWeekEnd);
          } else {
            // 如果没有日期信息，则使用传统的周数判断方式
            final courseWeekIndices = classItem['weekIndices'];
            List<int> courseWeekList = [];
            if (courseWeekIndices != null && courseWeekIndices is List) {
              courseWeekList = courseWeekIndices.map((e) {
                if (e is int) return e;
                if (e is String) return int.tryParse(e) ?? 0;
                return int.tryParse(e.toString()) ?? 0;
              }).where((week) => week > 0).toList();
            }

            List<int> weekList = courseWeekList;
            if (weekList.isEmpty) {
              final scheduleWeekIndices = schedule['weekIndices'];
              if (scheduleWeekIndices != null && scheduleWeekIndices is List) {
                weekList = scheduleWeekIndices.map((e) {
                  if (e is int) return e;
                  if (e is String) return int.tryParse(e) ?? 0;
                  return int.tryParse(e.toString()) ?? 0;
                }).where((week) => week > 0).toList();
              }
            }

            if (weekList.isNotEmpty) {
              shouldIncludeCourse = weekList.contains(selectedWeek);
              if (currentWeek != null) {
                isCurrentWeekCourse = weekList.contains(currentWeek);
              }
            }
          }
        }

        // 检查是否应该包含课程（基于选择的周数）
        if (!shouldIncludeCourse) {
          continue;
        }

        // 保持课程完整性，不拆分课程
        timeSlotInfos.add(TimeSlotInfo(
          startTime: startTime,
          endTime: endTime,
          weekday: weekday,
          courseName: classItem['course']?['nameZh']?.toString() ?? '未知课程',
          teacherName: _getTeacherName(classItem['teacherAssignmentList']),
          roomName: schedule['room']?['nameZh']?.toString() ?? '未知教室',
          scheduleGroupId: schedule['scheduleGroupId']?.toString() ?? '',
          details: [schedule],
          isCurrentWeek: isCurrentWeekCourse,
        ));
      }
    }

    // 智能计算时间段
    final timeSlots = _calculateStandardTimeSlots(timeSlotInfos);

    // 将课程分配到对应时间段，保持课程完整性
    final Set<String> usedTimeSlots = {};

    for (var timeSlotInfo in timeSlotInfos) {
      final spanInfo = _calculateCourseSpan(timeSlotInfo, timeSlots);
      if (spanInfo != null) {
        final startSlotIndex = spanInfo['startIndex'] as int;
        final spanCount = spanInfo['spanCount'] as int;
        final startSlot = timeSlots[startSlotIndex];
        final timeKey = '${startSlotIndex + 1}\n${startSlot.startTime}-${startSlot.endTime}';

        // 标记使用的时间段
        usedTimeSlots.add(timeKey);
        for (int i = 1; i < spanCount; i++) {
          if (startSlotIndex + i < timeSlots.length) {
            final occupiedSlot = timeSlots[startSlotIndex + i];
            final occupiedKey = '${startSlotIndex + i + 1}\n${occupiedSlot.startTime}-${occupiedSlot.endTime}';
            usedTimeSlots.add(occupiedKey);
          }
        }
      }
    }

    // 只初始化有课程的时间段
    for (String timeKey in usedTimeSlots) {
      processedClasses[timeKey] = {};
      for (int j = 1; j <= 7; j++) {
        processedClasses[timeKey]!['周$j'] = [];
      }
    }

    // 重新分配课程到对应时间段
    for (var timeSlotInfo in timeSlotInfos) {
      final spanInfo = _calculateCourseSpan(timeSlotInfo, timeSlots);
      if (spanInfo != null) {
        final startSlotIndex = spanInfo['startIndex'] as int;
        final spanCount = spanInfo['spanCount'] as int;
        final startSlot = timeSlots[startSlotIndex];
        final timeKey = '${startSlotIndex + 1}\n${startSlot.startTime}-${startSlot.endTime}';

        // 只在起始时间段添加课程信息，但标记跨越数量
        processedClasses[timeKey]![timeSlotInfo.weekday]!.add({
          'courseName': timeSlotInfo.courseName,
          'teacherName': timeSlotInfo.teacherName,
          'roomName': timeSlotInfo.roomName,
          'scheduleGroupId': timeSlotInfo.scheduleGroupId,
          'details': timeSlotInfo.details,
          'isCurrentWeek': timeSlotInfo.isCurrentWeek,
          'periodIndex': startSlotIndex + 1,
          'spanCount': spanCount,
          'originalStartIndex': startSlotIndex,
          'courseStartTime': timeSlotInfo.startTime,
          'courseEndTime': timeSlotInfo.endTime,
        });

        // 在跨越的其他时间段标记为被占用
        for (int i = 1; i < spanCount; i++) {
          if (startSlotIndex + i < timeSlots.length) {
            final occupiedSlot = timeSlots[startSlotIndex + i];
            final occupiedKey = '${startSlotIndex + i + 1}\n${occupiedSlot.startTime}-${occupiedSlot.endTime}';

            processedClasses[occupiedKey]![timeSlotInfo.weekday]!.add({
              'isOccupied': true,
              'originalStartIndex': startSlotIndex,
              'occupiedBy': timeSlotInfo.courseName,
            });
          }
        }
      }
    }

    return processedClasses;
  }

  
  // 根据实际课程时间计算标准45分钟时间段列表
  List<TimeSlotInfo> _calculateStandardTimeSlots(List<TimeSlotInfo> courseInfos) {
    if (courseInfos.isEmpty) {
      return [];
    }

    // 定义标准的45分钟时间段，排除非课程时间
    final List<TimeSlotInfo> standardTimeSlots = [];

    // 上午时间段 (8:00-12:00)
    standardTimeSlots.addAll([
      TimeSlotInfo(startTime: '08:00', endTime: '08:45', weekday: '', courseName: '', teacherName: '', roomName: '', scheduleGroupId: '', details: [], isCurrentWeek: true),
      TimeSlotInfo(startTime: '08:50', endTime: '09:35', weekday: '', courseName: '', teacherName: '', roomName: '', scheduleGroupId: '', details: [], isCurrentWeek: true),
      // 跳过09:35-09:50课间休息
      TimeSlotInfo(startTime: '09:50', endTime: '10:35', weekday: '', courseName: '', teacherName: '', roomName: '', scheduleGroupId: '', details: [], isCurrentWeek: true),
      TimeSlotInfo(startTime: '10:50', endTime: '11:35', weekday: '', courseName: '', teacherName: '', roomName: '', scheduleGroupId: '', details: [], isCurrentWeek: true),
      TimeSlotInfo(startTime: '11:40', endTime: '12:25', weekday: '', courseName: '', teacherName: '', roomName: '', scheduleGroupId: '', details: [], isCurrentWeek: true),
    ]);

    // 下午时间段 (14:00-18:00) - 跳过12:15-14:00午休
    standardTimeSlots.addAll([
      TimeSlotInfo(startTime: '14:00', endTime: '14:45', weekday: '', courseName: '', teacherName: '', roomName: '', scheduleGroupId: '', details: [], isCurrentWeek: true),
      TimeSlotInfo(startTime: '14:55', endTime: '15:40', weekday: '', courseName: '', teacherName: '', roomName: '', scheduleGroupId: '', details: [], isCurrentWeek: true),
      // 跳过15:35-15:50课间休息
      TimeSlotInfo(startTime: '15:50', endTime: '16:35', weekday: '', courseName: '', teacherName: '', roomName: '', scheduleGroupId: '', details: [], isCurrentWeek: true),
      TimeSlotInfo(startTime: '16:45', endTime: '17:30', weekday: '', courseName: '', teacherName: '', roomName: '', scheduleGroupId: '', details: [], isCurrentWeek: true),
      TimeSlotInfo(startTime: '17:35', endTime: '18:20', weekday: '', courseName: '', teacherName: '', roomName: '', scheduleGroupId: '', details: [], isCurrentWeek: true),
    ]);

    // 晚上时间段 (19:00-21:00)
    standardTimeSlots.addAll([
      TimeSlotInfo(startTime: '19:00', endTime: '19:45', weekday: '', courseName: '', teacherName: '', roomName: '', scheduleGroupId: '', details: [], isCurrentWeek: true),
      TimeSlotInfo(startTime: '19:55', endTime: '20:40', weekday: '', courseName: '', teacherName: '', roomName: '', scheduleGroupId: '', details: [], isCurrentWeek: true),
      TimeSlotInfo(startTime: '20:50', endTime: '21:35', weekday: '', courseName: '', teacherName: '', roomName: '', scheduleGroupId: '', details: [], isCurrentWeek: true),
    ]);

    // 检查哪些时间段实际有课程，只返回有课程的时间段
    final List<TimeSlotInfo> usedTimeSlots = [];

    for (var timeSlot in standardTimeSlots) {
      final slotStart = _timeToMinutes(timeSlot.startTime);
      final slotEnd = _timeToMinutes(timeSlot.endTime);

      // 检查这个时间段是否有课程
      bool hasCourse = false;
      for (var course in courseInfos) {
        final courseStart = _timeToMinutes(course.startTime);
        final courseEnd = _timeToMinutes(course.endTime);

        // 如果课程与这个时间段有重叠，则认为这个时间段有课程
        if (courseStart < slotEnd && courseEnd > slotStart) {
          hasCourse = true;
          break;
        }
      }

      if (hasCourse) {
        usedTimeSlots.add(timeSlot);
      }
    }

    return usedTimeSlots;
  }

  
  // 计算课程跨越的45分钟时间段信息
  Map<String, dynamic>? _calculateCourseSpan(TimeSlotInfo courseInfo, List<TimeSlotInfo> timeSlots) {
    final courseStartMinutes = _timeToMinutes(courseInfo.startTime);
    final courseEndMinutes = _timeToMinutes(courseInfo.endTime);

    int? startIndex;
    int spanCount = 0;

    // 查找课程开始的时间段 - 找到第一个与课程时间重叠的时间段
    for (int i = 0; i < timeSlots.length; i++) {
      final timeSlot = timeSlots[i];
      final slotStartMinutes = _timeToMinutes(timeSlot.startTime);
      final slotEndMinutes = _timeToMinutes(timeSlot.endTime);

      // 如果课程与这个时间段有重叠，则认为是开始时间段
      if (courseStartMinutes < slotEndMinutes && courseEndMinutes > slotStartMinutes) {
        startIndex = i;
        spanCount = 1;
        break;
      }
    }

    if (startIndex == null) return null;

    // 计算课程跨越多少个时间段
    for (int i = startIndex + 1; i < timeSlots.length; i++) {
      final timeSlot = timeSlots[i];
      final slotStartMinutes = _timeToMinutes(timeSlot.startTime);
      final slotEndMinutes = _timeToMinutes(timeSlot.endTime);

      // 如果后续时间段与课程时间有重叠，则增加跨越数量
      if (courseEndMinutes > slotStartMinutes && courseStartMinutes < slotEndMinutes) {
        spanCount++;
      } else {
        break;
      }
    }

    return {
      'startIndex': startIndex,
      'spanCount': spanCount,
    };
  }

  
  // 时间转换为分钟
  int _timeToMinutes(String timeStr) {
    return TimeUtils.timeToMinutes(timeStr);
  }

  // 判断日期是否在指定周内（周一到周日）
  bool _isDateInWeek(DateTime date, DateTime weekStart, DateTime weekEnd) {
    // 将日期设置为当天的开始（00:00:00）进行比较
    final dateOnly = DateTime(date.year, date.month, date.day);
    final weekStartOnly = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final weekEndOnly = DateTime(weekEnd.year, weekEnd.month, weekEnd.day);

    return !dateOnly.isBefore(weekStartOnly) && !dateOnly.isAfter(weekEndOnly);
  }

  // 获取教师姓名
  String _getTeacherName(dynamic teacherAssignmentList) {
    if (teacherAssignmentList == null) {
      return '未知教师';
    }

    if (teacherAssignmentList is List && teacherAssignmentList.isNotEmpty) {
      final firstTeacher = teacherAssignmentList[0];
      if (firstTeacher is Map) {
        return firstTeacher['person']?['nameZh'] ?? firstTeacher['nameZh'] ?? '未知教师';
      } else {
        return firstTeacher?.toString() ?? '未知教师';
      }
    } else if (teacherAssignmentList is String) {
      return teacherAssignmentList;
    } else if (teacherAssignmentList is Map) {
      return teacherAssignmentList['person']?['nameZh'] ?? teacherAssignmentList['nameZh'] ?? '未知教师';
    }

    return '未知教师';
  }

  }
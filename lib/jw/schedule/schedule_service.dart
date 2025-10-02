import 'package:flutter/material.dart';
import '../api/getclass.dart';
import '../api/gettable.dart';
import '../../globals.dart' as globals;
import 'semester_config.dart';

class ScheduleService extends ChangeNotifier {
  List<dynamic>? _classes;
  List<dynamic>? _table;
  bool _isLoading = false;

  List<dynamic>? get classes => _classes;
  List<dynamic>? get table => _table;
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

      // 并行获取课程和课表数据
      final results = await Future.wait([
        getClass(token, semesterId: actualSemesterId),
        getTable(token, semesterId: actualSemesterId),
      ]);

      _classes = results[0];
      _table = results[1];

      print('Classes and table fetched successfully');
    } catch (e) {
      print('获取课表数据失败: $e');
      _classes = null;
      _table = null;
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
      print('未找到当前学期ID');
      return;
    }

    print('更新课表数据: $semesterName (ID: $semesterId), 月份: $month');
    await fetchData(semesterId: semesterId);
  }

  String formatTime(int time) {
    final hours = (time / 100).floor().toString().padLeft(2, '0');
    final minutes = (time % 100).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  Map<String, Map<String, List<Map<String, dynamic>>>> processClasses() {
    final Map<String, Map<String, List<Map<String, dynamic>>>> processedClasses = {};

    // 动态生成时间段映射，基于实际课表数据
    final Map<String, String> timeSlotMapping = _generateTimeSlotMapping();

    for (var classItem in _classes!) {
      final courseName = classItem['course']?['nameZh'] ?? '未知课程';
      final schedules = classItem['schedules'];
      // 处理教师信息，可能是列表或字符串
      final teacherAssignmentList = classItem['teacherAssignmentList'];
      String teacherName = '未知教师';
      if (teacherAssignmentList != null) {
        if (teacherAssignmentList is List && teacherAssignmentList.isNotEmpty) {
          // 如果是列表，取第一个教师的姓名
          final firstTeacher = teacherAssignmentList[0];
          if (firstTeacher is Map) {
            teacherName = firstTeacher['person']?['nameZh'] ?? firstTeacher['nameZh'] ?? '未知教师';
          } else {
            teacherName = firstTeacher?.toString() ?? '未知教师';
          }
        } else if (teacherAssignmentList is String) {
          teacherName = teacherAssignmentList;
        } else if (teacherAssignmentList is Map) {
          // 如果直接是一个Map对象
          teacherName = teacherAssignmentList['person']?['nameZh'] ?? teacherAssignmentList['nameZh'] ?? '未知教师';
        }
      }

      for (var schedule in schedules) {
        final startTime = formatTime(schedule['startTime']);
        final endTime = formatTime(schedule['endTime']);
        final originalTimeKey = '$startTime - $endTime';
        
        // 尝试映射到标准时间段，如果没有匹配则使用原始时间
        final timeKey = timeSlotMapping[originalTimeKey] ?? originalTimeKey;
        
        // 确保weekday是整数类型
        final weekdayValue = schedule['weekday'];
        final weekday = '周${weekdayValue is int ? weekdayValue : int.tryParse(weekdayValue.toString()) ?? 1}';
        final scheduleGroupId = schedule['scheduleGroupId'];

        if (!processedClasses.containsKey(timeKey)) {
          processedClasses[timeKey] = {};
        }

        if (!processedClasses[timeKey]!.containsKey(weekday)) {
          processedClasses[timeKey]![weekday] = [];
        }

        // 合并相同课程相同时段但日期不同的情况
        final existingClass = processedClasses[timeKey]![weekday]!.firstWhere(
          (classItem) => classItem['scheduleGroupId'] == scheduleGroupId,
          orElse: () => <String, dynamic>{},
        );

        if (existingClass.isNotEmpty) {
          existingClass['details'].add(schedule);
        } else {
          processedClasses[timeKey]![weekday]!.add({
            'courseName': courseName,
            'teacherName': teacherName,
            'roomName': schedule['room']?['nameZh'] ?? '未知教室',
            'scheduleGroupId': scheduleGroupId,
            'details': [schedule],
          });
        }
      }
    }

    return processedClasses;
  }

  /// 动态生成时间段映射，基于实际课表数据
  Map<String, String> _generateTimeSlotMapping() {
    final Map<String, String> mapping = {};
    final Set<String> timeSlots = {};
    
    // 收集所有时间段
    if (_classes != null) {
      for (var classItem in _classes!) {
        final schedules = classItem['schedules'];
        if (schedules != null) {
          for (var schedule in schedules) {
            final startTime = formatTime(schedule['startTime']);
            final endTime = formatTime(schedule['endTime']);
            final timeSlot = '$startTime - $endTime';
            timeSlots.add(timeSlot);
          }
        }
      }
    }
    
    // 将时间段按开始时间排序
    final sortedTimeSlots = timeSlots.toList()..sort((a, b) {
      final aStart = a.split(' - ')[0];
      final bStart = b.split(' - ')[0];
      return aStart.compareTo(bStart);
    });
    
    // 为每个时间段分配节次
    for (int i = 0; i < sortedTimeSlots.length; i++) {
      final timeSlot = sortedTimeSlots[i];
      final nodeNumber = _calculateNodeNumber(timeSlot, i);
      mapping[timeSlot] = nodeNumber;
    }
    
    return mapping;
  }

  /// 根据时间段计算节次
  String _calculateNodeNumber(String timeSlot, int index) {
    final startTime = timeSlot.split(' - ')[0];
    final endTime = timeSlot.split(' - ')[1];
    
    // 解析开始时间
    final startParts = startTime.split(':');
    final startHour = int.tryParse(startParts[0]) ?? 8;
    final startMinute = int.tryParse(startParts[1]) ?? 0;
    final startTotalMinutes = startHour * 60 + startMinute;
    
    // 解析结束时间
    final endParts = endTime.split(':');
    final endHour = int.tryParse(endParts[0]) ?? 8;
    final endMinute = int.tryParse(endParts[1]) ?? 0;
    final endTotalMinutes = endHour * 60 + endMinute;
    
    // 计算课程时长
    final duration = endTotalMinutes - startTotalMinutes;
    
    // 根据标准时间表计算节次
    // 第1节: 08:00-08:45
    // 第2节: 08:50-09:35
    // 大课间: 09:35-09:50
    // 第3节: 09:50-10:35
    // 第4节: 10:40-11:25
    // 第5节: 11:30-12:15
    // 午休
    // 第6节: 14:00-14:45
    // 第7节: 14:50-15:35
    // 大课间: 15:35-15:50
    // 第8节: 15:50-16:35
    // 第9节: 16:40-17:25
    // 第10节: 17:30-18:15
    // 晚上
    // 第11节: 19:00-19:45
    // 第12节: 19:50-20:35
    
    if (startTotalMinutes >= 480 && startTotalMinutes < 530) { // 8:00-8:50
      return duration > 45 ? '第1-2节' : '第1节';
    } else if (startTotalMinutes >= 530 && startTotalMinutes < 575) { // 8:50-9:35
      return '第2节';
    } else if (startTotalMinutes >= 590 && startTotalMinutes < 635) { // 9:50-10:35
      return duration > 45 ? '第3-4节' : '第3节';
    } else if (startTotalMinutes >= 640 && startTotalMinutes < 685) { // 10:40-11:25
      return '第4节';
    } else if (startTotalMinutes >= 690 && startTotalMinutes < 735) { // 11:30-12:15
      return '第5节';
    } else if (startTotalMinutes >= 840 && startTotalMinutes < 885) { // 14:00-14:45
      return duration > 45 ? '第6-7节' : '第6节';
    } else if (startTotalMinutes >= 890 && startTotalMinutes < 935) { // 14:50-15:35
      return '第7节';
    } else if (startTotalMinutes >= 950 && startTotalMinutes < 995) { // 15:50-16:35
      return duration > 45 ? '第8-9节' : '第8节';
    } else if (startTotalMinutes >= 1000 && startTotalMinutes < 1045) { // 16:40-17:25
      return '第9节';
    } else if (startTotalMinutes >= 1050 && startTotalMinutes < 1095) { // 17:30-18:15
      return '第10节';
    } else if (startTotalMinutes >= 1140 && startTotalMinutes < 1185) { // 19:00-19:45
      return duration > 45 ? '第11-12节' : '第11节';
    } else if (startTotalMinutes >= 1190 && startTotalMinutes < 1235) { // 19:50-20:35
      return '第12节';
    } else {
      // 如果时间不在标准范围内，根据时间段推算
      if (startHour < 10) {
        return '第1-2节';
      } else if (startHour < 12) {
        return '第3-5节';
      } else if (startHour < 18) {
        return '第6-10节';
      } else {
        return '第11-12节';
      }
    }
  }
}
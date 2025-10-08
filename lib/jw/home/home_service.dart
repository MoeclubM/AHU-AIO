import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/getschdules.dart';
import '../api/gettests.dart';
import '../../globals.dart' as globals;

class HomePageLogic extends ChangeNotifier {
  Map<String, dynamic>? _schedules;
  List<dynamic>? _tests;
  bool _isLoading = true;

  Map<String, dynamic>? get schedules => _schedules;
  List<dynamic>? get tests => _tests;
  bool get isLoading => _isLoading;

  HomePageLogic() {
    _fetchData();
  }

  Future<void> _fetchData([String? date]) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      // 如果没有指定日期，使用当前年月
      final currentDate = date ?? _getCurrentYearMonth();
      final schedules = await getSchedules(globals.idToken!, date: currentDate);
      final tests = await getTests(globals.idToken!);
      _schedules = schedules;
      _tests = tests;
      await prefs.setString('cachedSchedules', jsonEncode(schedules));
      await prefs.setString('cachedTests', jsonEncode(tests));
    } catch (e) {
      final cachedSchedules = prefs.getString('cachedSchedules');
      final cachedTests = prefs.getString('cachedTests');
      
      if (cachedSchedules != null) {
        _schedules = Map<String, dynamic>.from(jsonDecode(cachedSchedules));
      }
      if (cachedTests != null) {
        _tests = List<dynamic>.from(jsonDecode(cachedTests));
      }
    }
    if (hasListeners) {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _getCurrentYearMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  Future<void> refreshDataForDate(String date) async {
    _isLoading = true;
    notifyListeners();
    // 将完整日期格式（2024-01-15）转换为年月格式（2024-01）
    final yearMonth = date.substring(0, 7);
    await _fetchData(yearMonth);
  }

  Future<void> refreshData([String? date]) async {
    _isLoading = true;
    notifyListeners();
    await _fetchData(date);
  }

  int getTodayClassesCount() {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    // 使用合并后的课程数据计算
    final groupedSchedules = getGroupedSchedulesForDate(todayKey);
    int count = 0;
    groupedSchedules.forEach((timeSlot, courses) {
      count += courses.length;
    });
    return count;
  }

  int getRemainingClassesCount() {
    final now = DateTime.now();
    int count = 0;
    
    if (_schedules != null) {
      _schedules!.forEach((date, events) {
        final eventDate = DateTime.parse(date);
        if (eventDate.isAfter(now) || (eventDate.year == now.year && eventDate.month == now.month && eventDate.day == now.day)) {
          // 使用合并后的课程数据计算
          final groupedSchedules = getGroupedSchedulesForDate(date);
          groupedSchedules.forEach((timeSlot, courses) {
            count += courses.length;
          });
        }
      });
    }
    return count;
  }

  TextStyle getEventStyle(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(color: isDarkMode ? Colors.white : Colors.black);
  }

  String formatExamTime(int time) {
    final hours = (time / 100).floor().toString().padLeft(2, '0');
    final minutes = (time % 100).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  // 智能时间段划分
  String getTimeSlot(String? startTime, String? endTime) {
    if (startTime == null || endTime == null) {
      return '全天';
    }

    final start = _parseTime(startTime);

    // 根据开始时间判断时间段
    if (start < 800) {
      return '早晨 ($startTime-$endTime)';
    } else if (start < 1200) {
      return '上午 ($startTime-$endTime)';
    } else if (start < 1400) {
      return '中午 ($startTime-$endTime)';
    } else if (start < 1800) {
      return '下午 ($startTime-$endTime)';
    } else {
      return '晚上 ($startTime-$endTime)';
    }
  }

  int _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length == 2) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      return hours * 100 + minutes;
    }
    return 0;
  }

  // 获取指定日期的课程分组
  Map<String, List<Map<String, dynamic>>> getGroupedSchedulesForDate(String targetDate) {
    if (_schedules == null) return {};

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    final Map<String, Map<String, dynamic>> uniqueCourses = {}; // 用于去重

    // 只处理指定日期的课程
    if (_schedules!.containsKey(targetDate)) {
      final events = _schedules![targetDate];
      for (var event in events) {
        if (event['type'] == 1 && event['identification'] == true) {
          // 只处理有效的课程
          final timeSlot = getTimeSlot(event['startTime'], event['endTime']);
          
          // 创建唯一标识符，用于合并相同的课程
          final uniqueKey = '${event['context']}_${event['place']}_${event['startTime']}_${event['endTime']}';
          
          if (!uniqueCourses.containsKey(uniqueKey)) {
            final courseInfo = {
              'date': targetDate,
              'whatDay': event['whatDay'],
              'context': event['context'],
              'place': event['place'],
              'startTime': event['startTime'],
              'endTime': event['endTime'],
              'timeSlot': timeSlot,
            };
            
            uniqueCourses[uniqueKey] = courseInfo;
            
            if (!grouped.containsKey(timeSlot)) {
              grouped[timeSlot] = [];
            }
            grouped[timeSlot]!.add(courseInfo);
          }
        }
      }
    }

    // 按时间排序
    final sortedKeys = grouped.keys.toList()..sort((a, b) {
      final aTime = _parseTime(_extractStartTime(a));
      final bTime = _parseTime(_extractStartTime(b));
      return aTime.compareTo(bTime);
    });

    final Map<String, List<Map<String, dynamic>>> sortedGrouped = {};
    for (final key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }

    return sortedGrouped;
  }

  // 获取课程的智能分组（保留原方法用于课表页面）
  Map<String, List<Map<String, dynamic>>> getGroupedSchedules() {
    if (_schedules == null) return {};

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    final Map<String, Map<String, dynamic>> uniqueCourses = {}; // 用于去重

    _schedules!.forEach((date, events) {
      for (var event in events) {
        if (event['type'] == 1 && event['identification'] == true) {
          // 只处理有效的课程
          final timeSlot = getTimeSlot(event['startTime'], event['endTime']);
          
          // 创建唯一标识符，用于合并相同的课程
          final uniqueKey = '${event['context']}_${event['place']}_${event['startTime']}_${event['endTime']}_$date';
          
          if (!uniqueCourses.containsKey(uniqueKey)) {
            final courseInfo = {
              'date': date,
              'whatDay': event['whatDay'],
              'context': event['context'],
              'place': event['place'],
              'startTime': event['startTime'],
              'endTime': event['endTime'],
              'timeSlot': timeSlot,
            };
            
            uniqueCourses[uniqueKey] = courseInfo;

            if (!grouped.containsKey(timeSlot)) {
              grouped[timeSlot] = [];
            }
            grouped[timeSlot]!.add(courseInfo);
          }
        }
      }
    });

    // 按时间排序
    final sortedKeys = grouped.keys.toList()..sort((a, b) {
      final aTime = _parseTime(_extractStartTime(a));
      final bTime = _parseTime(_extractStartTime(b));
      return aTime.compareTo(bTime);
    });

    final Map<String, List<Map<String, dynamic>>> sortedGrouped = {};
    for (final key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }

    return sortedGrouped;
  }

  String _extractStartTime(String timeSlot) {
    // 从时间段字符串中提取开始时间，例如 "08:00-09:40" -> "08:00"
    if (timeSlot.contains('-')) {
      return timeSlot.split('-')[0].trim();
    }
    return timeSlot;
  }
}
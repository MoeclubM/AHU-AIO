import 'dart:convert';
import 'package:flutter/material.dart';
import '../api/sendrequest.dart';
import '../models/schedule_model.dart';
import '../../globals.dart' as globals;

/// 数据服务类 - 提供类型安全的数据获取和处理
class DataService {
  /// 获取课表数据
  static Future<List<ScheduleModel>> getSchedules(String? date) async {
    final url = date != null
        ? 'https://jwapp.ahu.edu.cn/eams-door/api/v1/protal-schedule/getSchedules?date=$date'
        : 'https://jwapp.ahu.edu.cn/eams-door/api/v1/protal-schedule/getSchedules';

    final response = await sendRequest(url, globals.idToken!);

    if (response == null) {
      throw Exception('网络请求失败');
    }

    if (response.statusCode != 200) {
      throw Exception('HTTP错误: ${response.statusCode}');
    }

    try {
      final data = jsonDecode(response.body);
      return _parseScheduleData(data);
    } catch (e) {
      throw Exception('数据解析失败: $e');
    }
  }

  /// 解析课表数据，处理多种可能的数据格式
  ///
  /// 支持两种API返回格式：
  /// 1. 按日期分组: { "2024-01-15": [ {...}, {...} ] }
  /// 2. 平铺列表: [ {...}, {...} ]
  ///
  /// 只添加type=1且identification=true的有效课程
  static List<ScheduleModel> _parseScheduleData(dynamic data) {
    final List<ScheduleModel> schedules = [];

    if (data is Map<String, dynamic>) {
      // 格式1: { "2024-01-15": [ {...}, {...} ] }
      // 按日期组织的课程数据，常见于月度/周度课表查询
      data.forEach((dateKey, events) {
        if (events is List) {
          for (var event in events) {
            if (event is Map<String, dynamic>) {
              try {
                final schedule = ScheduleModel.fromJson(event, dateKey);
                // 过滤只显示正式课程(type=1)且已确认的课程(identification=true)
                if (schedule.type == 1 && schedule.identification) {
                  schedules.add(schedule);
                }
              } catch (e) {
                debugPrint('解析课程数据失败: $e');
                continue; // 跳过解析失败的数据，不影响其他课程显示
              }
            }
          }
        }
      });
    } else if (data is List) {
      // 格式2: [ {...}, {...} ]
      // 直接的课程列表，常见于单日课表查询
      for (var event in data) {
        if (event is Map<String, dynamic>) {
          try {
            // 对于列表格式，优先使用事件中的日期，否则使用当前日期
            final dateKey =
                event['date']?.toString() ??
                DateTime.now().toString().substring(0, 10);
            final schedule = ScheduleModel.fromJson(event, dateKey);
            if (schedule.type == 1 && schedule.identification) {
              schedules.add(schedule);
            }
          } catch (e) {
            debugPrint('解析课程数据失败: $e');
            continue;
          }
        }
      }
    }

    return schedules;
  }

  /// 按日期分组课表数据
  static Map<String, List<ScheduleModel>> groupSchedulesByDate(
    List<ScheduleModel> schedules,
  ) {
    final Map<String, List<ScheduleModel>> grouped = {};

    for (final schedule in schedules) {
      if (!grouped.containsKey(schedule.date)) {
        grouped[schedule.date] = [];
      }
      grouped[schedule.date]!.add(schedule);
    }

    // 按日期排序
    final sortedKeys = grouped.keys.toList()..sort();
    final Map<String, List<ScheduleModel>> sortedGrouped = {};
    for (final key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }

    return sortedGrouped;
  }

  /// 按时间段分组课表数据（用于首页显示）
  ///
  /// 将指定日期的课程按时间段（早晨、上午、中午、下午、晚上）分组
  /// 自动去除重复课程（基于课程名、地点、时间的组合）
  /// 按时间顺序排序各时间段
  static Map<String, List<ScheduleModel>> groupSchedulesByTimeSlot(
    List<ScheduleModel> schedules,
    String targetDate,
  ) {
    final Map<String, List<ScheduleModel>> grouped = {};
    final Map<String, ScheduleModel> uniqueCourses = {};

    for (final schedule in schedules) {
      if (schedule.date == targetDate) {
        final uniqueKey = schedule.uniqueKey;

        // 使用uniqueKey去重，避免同一课程重复显示
        if (!uniqueCourses.containsKey(uniqueKey)) {
          uniqueCourses[uniqueKey] = schedule;

          // 按时间段分组（早晨、上午、中午、下午、晚上）
          if (!grouped.containsKey(schedule.timeSlot)) {
            grouped[schedule.timeSlot] = [];
          }
          grouped[schedule.timeSlot]!.add(schedule);
        }
      }
    }

    // 按时间顺序排序各个时间段
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final aTime = _extractStartTime(a);
        final bTime = _extractStartTime(b);
        return aTime.compareTo(bTime);
      });

    final Map<String, List<ScheduleModel>> sortedGrouped = {};
    for (final key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }

    return sortedGrouped;
  }

  /// 从时间段字符串中提取开始时间
  static int _extractStartTime(String timeSlot) {
    if (timeSlot.contains('(') && timeSlot.contains(')')) {
      final timeStr = timeSlot.split('(')[1].split(')')[0];
      if (timeStr.contains('-')) {
        final startStr = timeStr.split('-')[0];
        final parts = startStr.split(':');
        if (parts.length == 2) {
          final hours = int.tryParse(parts[0]) ?? 0;
          final minutes = int.tryParse(parts[1]) ?? 0;
          return hours * 100 + minutes;
        }
      }
    }
    return 0;
  }

  /// 获取指定日期的课程数量
  static int getClassesCountForDate(
    List<ScheduleModel> schedules,
    String targetDate,
  ) {
    return groupSchedulesByTimeSlot(
      schedules,
      targetDate,
    ).values.fold(0, (sum, courses) => sum + courses.length);
  }

  /// 获取本周剩余课程数量
  static int getRemainingClassesCount(List<ScheduleModel> schedules) {
    final now = DateTime.now();
    final currentTime = now.hour * 100 + now.minute;
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );

    return schedules.where((schedule) {
      final scheduleDate = DateTime.parse(schedule.date);

      // 只统计从现在到本周末的课程
      if (scheduleDate.isBefore(startOfWeek) ||
          scheduleDate.isAfter(endOfWeek)) {
        return false;
      }

      // 如果是今天的课程，需要检查时间是否还未开始
      if (scheduleDate.year == now.year &&
          scheduleDate.month == now.month &&
          scheduleDate.day == now.day) {
        // 解析课程开始时间
        final timeParts = schedule.startTime.split(':');
        if (timeParts.length == 2) {
          final courseTime =
              int.parse(timeParts[0]) * 100 + int.parse(timeParts[1]);
          return courseTime > currentTime;
        }
        return false;
      }

      // 未来几天的课程都算入
      return scheduleDate.isAfter(now);
    }).length;
  }
}

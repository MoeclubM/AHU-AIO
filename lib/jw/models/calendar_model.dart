import 'package:flutter/material.dart';

/// 学期模型
class SemesterModel {
  final int id;
  final String name;
  final String startDate;
  final String endDate;
  final bool isCurrent;

  const SemesterModel({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isCurrent = false,
  });

  factory SemesterModel.fromJson(Map<String, dynamic> json) {
    return SemesterModel(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      isCurrent: json['isCurrent'] ?? false,
    );
  }
}

/// 校历事件模型
class CalendarEventModel {
  final DateTime date;
  final String eventType;
  final String description;
  final int weekNumber;
  final bool isToday;

  const CalendarEventModel({
    required this.date,
    required this.eventType,
    required this.description,
    required this.weekNumber,
    this.isToday = false,
  });

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventModel(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      eventType: json['eventType']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      weekNumber: json['weekNumber'] ?? 0,
      isToday: json['isToday'] ?? false,
    );
  }

  /// 获取事件类型颜色
  Color getEventTypeColor() {
    switch (eventType.toLowerCase()) {
      case 'holiday':
      case '假期':
        return Colors.red;
      case 'exam':
      case '考试':
        return Colors.orange;
      case 'class':
      case '上课':
        return Colors.green;
      case 'break':
      case '休息':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

/// 校历布局表模型（周视图）
class CalendarLayoutModel {
  final int semesterId;
  final String semesterName;
  final Map<int, List<DayInfo>> weeklyLayout;
  final List<String> weekDays;

  const CalendarLayoutModel({
    required this.semesterId,
    required this.semesterName,
    required this.weeklyLayout,
    required this.weekDays,
  });

  factory CalendarLayoutModel.fromJson(Map<String, dynamic> json) {
    final Map<int, List<DayInfo>> layout = {};

    if (json['weeklyLayout'] != null) {
      final layoutData = json['weeklyLayout'] as Map<String, dynamic>;
      layoutData.forEach((weekKey, days) {
        final weekNum = int.tryParse(weekKey) ?? 0;
        final dayList = <DayInfo>[];
        if (days is List) {
          for (var day in days) {
            dayList.add(DayInfo.fromJson(day));
          }
        }
        layout[weekNum] = dayList;
      });
    }

    return CalendarLayoutModel(
      semesterId: json['semesterId'] ?? 0,
      semesterName: json['semesterName']?.toString() ?? '',
      weeklyLayout: layout,
      weekDays: List<String>.from(json['weekDays'] ?? ['一', '二', '三', '四', '五', '六', '日']),
    );
  }
}

/// 每日信息模型
class DayInfo {
  final DateTime date;
  final int weekNumber;
  final int dayOfWeek;
  final bool isToday;
  final bool isHoliday;
  final String? description;

  const DayInfo({
    required this.date,
    required this.weekNumber,
    required this.dayOfWeek,
    this.isToday = false,
    this.isHoliday = false,
    this.description,
  });

  factory DayInfo.fromJson(Map<String, dynamic> json) {
    return DayInfo(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      weekNumber: json['weekNumber'] ?? 0,
      dayOfWeek: json['dayOfWeek'] ?? 0,
      isToday: json['isToday'] ?? false,
      isHoliday: json['isHoliday'] ?? false,
      description: json['description']?.toString(),
    );
  }

  /// 获取日期字符串
  String getDateString() {
    return '${date.month}/${date.day}';
  }
}
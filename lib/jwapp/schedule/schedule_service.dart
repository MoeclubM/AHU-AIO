import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/getclass.dart';
import '../utils/time_utils.dart';
import '../../globals.dart' as globals;
import 'semester_config.dart';

class ScheduleEntry {
  ScheduleEntry({
    required this.weekday,
    required this.courseName,
    required this.teacherName,
    required this.roomName,
    required this.startTime,
    required this.endTime,
    required this.isCurrentWeek,
    required this.isHonorCourse,
    required this.details,
    this.startUnit,
    this.endUnit,
  });

  final int weekday;
  final String courseName;
  final String teacherName;
  final String roomName;
  final String startTime;
  final String endTime;
  final bool isCurrentWeek;
  final bool isHonorCourse;
  final List<dynamic> details;
  final int? startUnit;
  final int? endUnit;

  int get startMinutes => TimeUtils.timeToMinutes(startTime);
  int get endMinutes => TimeUtils.timeToMinutes(endTime);

  int get effectiveStartUnit =>
      startUnit ?? TimeUtils.resolveStartUnit(startTime);
  int get effectiveEndUnit =>
      endUnit ?? TimeUtils.resolveEndUnit(endTime, effectiveStartUnit);
  int get unitSpan =>
      (effectiveEndUnit - effectiveStartUnit + 1).clamp(1, 11);
}

class ScheduleService extends ChangeNotifier {
  List<dynamic>? _classes;
  bool _isLoading = false;
  bool _isCached = false;

  List<dynamic>? get classes => _classes;
  bool get isLoading => _isLoading;
  bool get isCached => _isCached;

  Future<void> loadCache({String? semesterId}) async {
    try {
      String? actualSemesterId = semesterId;
      if (actualSemesterId == null) {
        actualSemesterId = await SemesterConfig.getCurrentSemesterId();
        if (actualSemesterId == null) return;
      }
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'jwapp_schedule_cache_$actualSemesterId';
      final cachedStr = prefs.getString(cacheKey);
      if (cachedStr != null) {
        _classes = jsonDecode(cachedStr) as List<dynamic>;
        _isCached = true;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> fetchData({String? semesterId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = globals.idToken;
      if (token == null) {
        throw Exception('未找到登录令牌');
      }

      String? actualSemesterId = semesterId;
      if (actualSemesterId == null) {
        actualSemesterId = await SemesterConfig.getCurrentSemesterId();
        if (actualSemesterId == null) {
          throw Exception('无法获取学期ID，请确保已正确登录');
        }
      }

      final freshClasses = await getClass(token, semesterId: actualSemesterId);
      if (freshClasses != null) {
        _classes = freshClasses;
        _isCached = false;
        final prefs = await SharedPreferences.getInstance();
        final cacheKey = 'jwapp_schedule_cache_$actualSemesterId';
        await prefs.setString(cacheKey, jsonEncode(freshClasses));
      }
    } catch (e) {
      if (_classes == null || _classes!.isEmpty) {
        _classes = null;
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateScheduleData(String semesterName, String month) async {
    final semesterId = await SemesterConfig.getCurrentSemesterId();
    if (semesterId == null) {
      return;
    }

    await fetchData(semesterId: semesterId);
  }

  @visibleForTesting
  void replaceClassesForTest(List<dynamic>? classes) {
    _classes = classes;
  }

  String formatTime(int time) {
    return TimeUtils.formatTime(time);
  }

  Map<int, List<ScheduleEntry>> buildWeekSchedule({
    required int selectedWeek,
    int? currentWeek,
    DateTime? semesterStartDate,
  }) {
    final Map<int, List<ScheduleEntry>> result = {
      for (var weekday = 1; weekday <= 7; weekday++) weekday: <ScheduleEntry>[],
    };

    if (_classes == null || _classes!.isEmpty) {
      return result;
    }

    for (final rawClass in _classes!) {
      if (rawClass is! Map<String, dynamic>) continue;
      final schedules = rawClass['schedules'];
      if (schedules is! List) continue;

      final course = rawClass['course'] as Map<String, dynamic>?;
      final lesson = rawClass['lesson'] as Map<String, dynamic>?;
      final lessonCourse = lesson?['course'] as Map<String, dynamic>?;
      final classWeeks = _extractWeekIndices(rawClass['weekIndices']);
      final isHonorCourse =
          _isHonorCourse(course) ||
          _isHonorCourse(rawClass) ||
          _isHonorCourse(lesson) ||
          _isHonorCourse(lessonCourse);

      for (final schedule in schedules) {
        if (schedule is! Map<String, dynamic>) continue;
        final weekday = _parseWeekday(schedule['weekday']);
        if (weekday == null) continue;

        final startTime = _parseTime(schedule['startTime']);
        final endTime = _parseTime(schedule['endTime']);

        final scheduleWeeks = _extractWeekIndices(schedule['weekIndices']);
        final effectiveWeeks = scheduleWeeks.isNotEmpty
            ? scheduleWeeks
            : classWeeks;
        final courseDate = _parseDate(schedule['date'] ?? rawClass['date']);
        final weekFromDate = _calculateWeekNumber(
          courseDate,
          semesterStartDate,
        );

        final includeCourse = _shouldIncludeCourse(
          selectedWeek: selectedWeek,
          availableWeeks: effectiveWeeks,
          derivedWeek: weekFromDate,
        );
        if (!includeCourse) {
          continue;
        }

        final highlightCurrentWeek =
            currentWeek != null &&
            _shouldIncludeCourse(
              selectedWeek: currentWeek,
              availableWeeks: effectiveWeeks,
              derivedWeek: weekFromDate,
            );

        final teacherName = _getTeacherName(
          rawClass['teacherAssignmentList'] ??
              rawClass['teachers'] ??
              rawClass['teacher'] ??
              lesson?['teachers'] ??
              lesson?['teacher'],
        );
        final roomName = _resolveRoomName(schedule);

        final rawCourseName =
            _getNotEmpty(course?['nameZh']) ??
            _getNotEmpty(course?['name']) ??
            _getNotEmpty(lessonCourse?['nameZh']) ??
            _getNotEmpty(lessonCourse?['name']) ??
            _getNotEmpty(lesson?['nameZh']) ??
            _getNotEmpty(lesson?['name']) ??
            _getNotEmpty(lesson?['courseName']) ??
            _getNotEmpty(rawClass['courseNameZh']) ??
            _getNotEmpty(rawClass['courseName']) ??
            _getNotEmpty(rawClass['lessonNameZh']) ??
            _getNotEmpty(rawClass['lessonName']) ??
            _getNotEmpty(rawClass['nameZh']) ??
            '未知课程';

        if (rawCourseName == '未知课程' || rawCourseName.trim().isEmpty) {
          continue;
        }

        final rawStartUnit = _tryParseInt(
          schedule['startUnit'] ??
              schedule['startSection'] ??
              schedule['startSlot'] ??
              schedule['unit'] ??
              rawClass['startUnit'],
        );
        final rawEndUnit = _tryParseInt(
          schedule['endUnit'] ??
              schedule['endSection'] ??
              schedule['endSlot'] ??
              rawClass['endUnit'],
        );

        result[weekday]!.add(
          ScheduleEntry(
            weekday: weekday,
            courseName: rawCourseName,
            teacherName: teacherName,
            roomName: roomName,
            startTime: startTime,
            endTime: endTime,
            isCurrentWeek: highlightCurrentWeek,
            isHonorCourse: isHonorCourse || _isHonorCourse(schedule),
            details: [schedule],
            startUnit: rawStartUnit,
            endUnit: rawEndUnit,
          ),
        );
      }
    }

    for (final entries in result.values) {
      entries.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    }

    return result;
  }

  bool _shouldIncludeCourse({
    required int selectedWeek,
    required List<int> availableWeeks,
    int? derivedWeek,
  }) {
    if (availableWeeks.isNotEmpty) {
      return availableWeeks.contains(selectedWeek);
    }
    if (derivedWeek != null) {
      return derivedWeek == selectedWeek;
    }
    return true;
  }

  List<int> _extractWeekIndices(dynamic value) {
    if (value == null) {
      return const [];
    }

    if (value is List) {
      return value
          .expand<int>((item) => _extractWeekIndices(item))
          .toSet()
          .where((week) => week > 0)
          .toList()
        ..sort();
    }

    if (value is Map) {
      final start = _tryParseInt(value['startWeek']);
      final end = _tryParseInt(value['endWeek']);
      if (start != null && end != null && start > 0 && end >= start) {
        return [for (var week = start; week <= end; week++) week];
      }
      return const [];
    }

    if (value is int) {
      return value > 0 ? <int>[value] : const [];
    }

    if (value is String) {
      return _parseWeekIndexString(value);
    }

    return _extractWeekIndices(value.toString());
  }

  int? _tryParseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return int.tryParse(value.toString());
  }

  List<int> _parseWeekIndexString(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    final wantsOdd = trimmed.contains('单');
    final wantsEven = trimmed.contains('双');

    String normalized = trimmed
        .replaceAll(RegExp(r'[（）()\[\]]'), '')
        .replaceAll(RegExp(r'周|星期|节|课|次'), '')
        .replaceAll(RegExp(r'[~～－—–]'), '-')
        .replaceAll(RegExp(r'[、，;；]'), ',');

    // 保留数字、逗号和连接符号，其他字符替换为逗号分隔
    normalized = normalized.replaceAll(RegExp(r'[^0-9,\-]'), ',');

    final segments = normalized
        .split(RegExp(r'[\s,]+'))
        .where((segment) => segment.isNotEmpty)
        .toList();

    bool includeWeek(int week) {
      if (wantsOdd && !wantsEven) {
        return week.isOdd;
      }
      if (wantsEven && !wantsOdd) {
        return week.isEven;
      }
      return true;
    }

    final weeks = <int>{};
    for (final segment in segments) {
      if (segment.contains('-')) {
        final parts = segment
            .split('-')
            .where((part) => part.isNotEmpty)
            .toList();
        if (parts.length == 2) {
          final start = int.tryParse(parts[0]);
          final end = int.tryParse(parts[1]);
          if (start != null && end != null && start > 0 && end >= start) {
            for (var week = start; week <= end; week++) {
              if (includeWeek(week)) {
                weeks.add(week);
              }
            }
          }
        }
      } else {
        final week = int.tryParse(segment);
        if (week != null && week > 0 && includeWeek(week)) {
          weeks.add(week);
        }
      }
    }

    final sortedWeeks = weeks.toList()..sort();
    return sortedWeeks;
  }

  int? _parseWeekday(dynamic value) {
    if (value is int) {
      if (value < 1 || value > 7) return null;
      return value;
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      if (trimmed.startsWith('周') || trimmed.startsWith('星期')) {
        final chineseWeekdays = {
          '一': 1,
          '二': 2,
          '三': 3,
          '四': 4,
          '五': 5,
          '六': 6,
          '日': 7,
          '天': 7,
        };
        final lastChar = trimmed.substring(trimmed.length - 1);
        final index = chineseWeekdays[lastChar];
        if (index != null) {
          return index;
        }
      }
      final numeric = int.tryParse(trimmed);
      if (numeric != null && numeric >= 1 && numeric <= 7) {
        return numeric;
      }
    }

    return null;
  }

  String _parseTime(dynamic value) {
    if (value is int) {
      return formatTime(value);
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.contains(':')) {
        return trimmed;
      }
      final numeric = int.tryParse(trimmed);
      if (numeric != null) {
        return formatTime(numeric);
      }
    }

    return '00:00';
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      // Check if it's a millisecond timestamp (13 digits, > 1000000000000)
      // or a second timestamp (10 digits, > 1000000000)
      if (value > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
    }
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  int? _calculateWeekNumber(DateTime? courseDate, DateTime? semesterStartDate) {
    if (courseDate == null || semesterStartDate == null) {
      return null;
    }

    final startOfSemesterWeek = semesterStartDate.subtract(
      Duration(days: semesterStartDate.weekday - DateTime.monday),
    );
    final difference = courseDate.difference(startOfSemesterWeek).inDays;
    if (difference < 0) {
      return null;
    }
    return difference ~/ 7 + 1;
  }

  bool _isHonorCourse(Map<String, dynamic>? data) {
    if (data == null) {
      return false;
    }

    const honorKeys = <String>[
      'isHonor',
      'isHonorCourse',
      'honorCourse',
      'isHonoursCourse',
      'honoursCourse',
    ];

    for (final key in honorKeys) {
      final value = data[key];
      if (value is bool && value) return true;
      if (value is int && value == 1) return true;
      if (value is String) {
        final lower = value.toLowerCase();
        if (lower == 'true' || lower == '1' || lower.contains('honor')) {
          return true;
        }
        if (value.contains('荣誉')) {
          return true;
        }
      }
    }

    final possibleType = data['courseType'] ?? data['type'] ?? data['level'];
    if (possibleType is String && possibleType.contains('荣誉')) {
      return true;
    }

    final tags = data['tags'];
    if (tags is List) {
      for (final tag in tags) {
        if (tag is String &&
            (tag.contains('荣誉') || tag.toLowerCase().contains('honor'))) {
          return true;
        }
      }
    }

    return false;
  }

  String _resolveRoomName(Map<String, dynamic> schedule) {
    final room = schedule['room'];
    if (room is Map) {
      return room['nameZh']?.toString() ?? room['name']?.toString() ?? '未知教室';
    }
    final roomName = schedule['roomName'];
    if (roomName is String && roomName.isNotEmpty) {
      return roomName;
    }
    return '未知教室';
  }

  String _getTeacherName(dynamic teacherAssignmentList) {
    if (teacherAssignmentList == null) {
      return '未知教师';
    }

    if (teacherAssignmentList is List && teacherAssignmentList.isNotEmpty) {
      final firstTeacher = teacherAssignmentList.first;
      if (firstTeacher is Map) {
        return firstTeacher['person']?['nameZh'] ??
            firstTeacher['nameZh'] ??
            firstTeacher['name'] ??
            '未知教师';
      }
      return firstTeacher?.toString() ?? '未知教师';
    }

    if (teacherAssignmentList is Map) {
      return teacherAssignmentList['person']?['nameZh'] ??
          teacherAssignmentList['nameZh'] ??
          teacherAssignmentList['name'] ??
          '未知教师';
    }

    if (teacherAssignmentList is String && teacherAssignmentList.isNotEmpty) {
      return teacherAssignmentList;
    }

    return '未知教师';
  }

  String? _getNotEmpty(dynamic val) {
    if (val == null) return null;
    final s = val.toString().trim();
    return s.isEmpty ? null : s;
  }
}

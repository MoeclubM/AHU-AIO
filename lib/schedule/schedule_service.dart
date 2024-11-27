import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/getclass.dart';
import '../api/gettable.dart';
import '../globals.dart' as globals;

class ScheduleService extends ChangeNotifier {
  List<dynamic>? _classes;
  List<dynamic>? _table;
  bool _isLoading = true;

  List<dynamic>? get classes => _classes;
  List<dynamic>? get table => _table;
  bool get isLoading => _isLoading;

  ScheduleService() {
    _fetchData();
  }

  Future<void> _fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final classes = await getClass(globals.idToken!);
      final table = await getTable(globals.idToken!);
      _classes = classes;
      _table = table;
      await prefs.setString('cachedClasses', jsonEncode(classes));
      await prefs.setString('cachedTable', jsonEncode(table));
      print('Classes and table fetched successfully');
    } catch (e) {
      print('Error fetching data: $e');
      final cachedClasses = prefs.getString('cachedClasses');
      final cachedTable = prefs.getString('cachedTable');
      if (cachedClasses != null) {
        _classes = jsonDecode(cachedClasses);
        print('Loaded cached classes');
      }
      if (cachedTable != null) {
        _table = jsonDecode(cachedTable);
        print('Loaded cached table');
      }
    }
    if (hasListeners) {
      _isLoading = false;
      notifyListeners();
    }
  }

  String formatTime(int time) {
    final hours = (time / 100).floor().toString().padLeft(2, '0');
    final minutes = (time % 100).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  Map<String, Map<String, List<Map<String, dynamic>>>> processClasses() {
    final Map<String, Map<String, List<Map<String, dynamic>>>> processedClasses = {};

    for (var classItem in _classes!) {
      final courseName = classItem['course']?['nameZh'] ?? '未知课程';
      final schedules = classItem['schedules'];

      for (var schedule in schedules) {
        final startTime = formatTime(schedule['startTime']);
        final endTime = formatTime(schedule['endTime']);
        final timeKey = '$startTime - $endTime';
        final weekday = '周${schedule['weekday']}';
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
            'roomName': schedule['room']?['nameZh'] ?? '未知教室',
            'scheduleGroupId': scheduleGroupId,
            'details': [schedule],
          });
        }
      }
    }

    return processedClasses;
  }
}
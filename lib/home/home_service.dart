import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/getschdules.dart';
import '../api/gettests.dart';
import '../globals.dart' as globals;

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

  Future<void> _fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final schedules = await getSchedules(globals.idToken!);
      final tests = await getTests(globals.idToken!);
      _schedules = schedules;
      _tests = tests;
      await prefs.setString('cachedSchedules', jsonEncode(schedules));
      await prefs.setString('cachedTests', jsonEncode(tests));
      print('Schedules and tests fetched successfully');
    } catch (e) {
      print('Error fetching data: $e');
      final cachedSchedules = prefs.getString('cachedSchedules');
      final cachedTests = prefs.getString('cachedTests');
      if (cachedSchedules != null) {
        _schedules = jsonDecode(cachedSchedules);
        print('Loaded cached schedules');
      }
      if (cachedTests != null) {
        _tests = jsonDecode(cachedTests);
        print('Loaded cached tests');
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  int getTodayClassesCount() {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    if (_schedules != null && _schedules!.containsKey(todayKey)) {
      return _schedules![todayKey].length;
    }
    return 0;
  }

  int getRemainingClassesCount() {
    final now = DateTime.now();
    int count = 0;
    if (_schedules != null) {
      _schedules!.forEach((date, events) {
        final eventDate = DateTime.parse(date);
        if (eventDate.isAfter(now) || (eventDate.year == now.year && eventDate.month == now.month && eventDate.day == now.day)) {
          count += (events.length as int);
        }
      });
    }
    return count;
  }



  String formatExamTime(int time) {
    final hours = (time / 100).floor().toString().padLeft(2, '0');
    final minutes = (time % 100).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
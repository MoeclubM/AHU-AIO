import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/gettests.dart';
import '../services/data_service.dart';
import '../models/schedule_model.dart';
import '../utils/time_utils.dart';
import '../../globals.dart' as globals;

class HomePageLogic extends ChangeNotifier {
  List<ScheduleModel>? _schedules;
  List<dynamic>? _tests;
  bool _isLoading = true;
  String? _currentError;

  List<ScheduleModel>? get schedules => _schedules;
  List<dynamic>? get tests => _tests;
  bool get isLoading => _isLoading;
  String? get currentError => _currentError;

  HomePageLogic() {
    _fetchData();
  }

  /// 获取数据，支持缓存和错误处理
  ///
  /// 数据获取策略：
  /// 1. 优先从网络获取最新数据
  /// 2. 网络请求失败时自动降级到缓存数据
  /// 3. 缓存课表和考试数据以提升离线体验
  ///
  /// 参数说明：
  /// - date: 可选日期参数，格式为 YYYY-MM，默认为当前年月
  Future<void> _fetchData([String? date]) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      _currentError = null;

      // 如果没有指定日期，使用当前年月（格式：2024-01）
      final currentDate = date ?? _getCurrentYearMonth();

      // 并行获取课表和考试数据以提升性能
      final schedules = await DataService.getSchedules(currentDate);
      final tests = await getTests(globals.idToken!);

      _schedules = schedules;
      _tests = tests;

      // 缓存数据以支持离线访问和快速启动
      await prefs.setString(
        'cachedSchedules',
        jsonEncode(schedules.map((s) => s.toJson()).toList()),
      );
      await prefs.setString('cachedTests', jsonEncode(tests));
    } catch (e) {
      _currentError = e.toString();
      debugPrint('数据获取失败: $e');

      // 网络请求失败时，尝试使用本地缓存数据
      // 这确保了应用在无网络环境下仍能显示历史数据
      try {
        final cachedSchedules = prefs.getString('cachedSchedules');
        final cachedTests = prefs.getString('cachedTests');

        if (cachedSchedules != null) {
          final schedulesList = jsonDecode(cachedSchedules) as List;
          _schedules = schedulesList
              .map(
                (item) =>
                    ScheduleModel.fromJson(item as Map<String, dynamic>, ''),
              )
              .where((schedule) => schedule.date.isNotEmpty) // 过滤无效日期数据
              .toList();
        }
        if (cachedTests != null) {
          _tests = List<dynamic>.from(jsonDecode(cachedTests));
        }
      } catch (cacheError) {
        debugPrint('缓存数据加载失败: $cacheError');
        // 缓存也失败时，用户将看到错误状态
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

  /// 刷新显示状态（不重新请求数据），用于更新即将开始课程的高亮
  void refreshDisplay() {
    if (hasListeners) {
      notifyListeners();
    }
  }

  /// 获取今日课程数量
  int getTodayClassesCount() {
    if (_schedules == null) return 0;

    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return DataService.getClassesCountForDate(_schedules!, todayKey);
  }

  /// 获取本周剩余课程数量
  int getRemainingClassesCount() {
    if (_schedules == null) return 0;

    return DataService.getRemainingClassesCount(_schedules!);
  }

  TextStyle getEventStyle(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(color: isDarkMode ? Colors.white : Colors.black);
  }

  String formatExamTime(int time) {
    return TimeUtils.formatTime(time);
  }

  /// 获取指定日期的课程分组，返回时间段分组的课程列表
  Map<String, List<Map<String, dynamic>>> getGroupedSchedulesForDate(
    String targetDate,
  ) {
    if (_schedules == null) return {};

    final groupedSchedules = DataService.groupSchedulesByTimeSlot(
      _schedules!,
      targetDate,
    );

    // 转换为原来的格式以保持UI兼容性
    final Map<String, List<Map<String, dynamic>>> result = {};

    groupedSchedules.forEach((timeSlot, schedules) {
      result[timeSlot] = schedules
          .map((schedule) => schedule.toJson())
          .toList();
    });

    return result;
  }

  /// 检查课程是否正在进行或即将进行（30分钟内）
  bool isCourseOngoingOrUpcoming(
    Map<String, dynamic> course,
    String targetDate,
  ) {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // 只检查今天的课程
    if (targetDate != today) {
      return false;
    }

    final startTime = course['startTime']?.toString() ?? '';
    final endTime = course['endTime']?.toString() ?? '';

    if (startTime.isEmpty || endTime.isEmpty) {
      return false;
    }

    try {
      final startParts = startTime.split(':');
      final endParts = endTime.split(':');

      if (startParts.length != 2 || endParts.length != 2) {
        return false;
      }

      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);

      final courseStart = DateTime(
        now.year,
        now.month,
        now.day,
        startHour,
        startMinute,
      );
      final courseEnd = DateTime(
        now.year,
        now.month,
        now.day,
        endHour,
        endMinute,
      );
      final upcomingThreshold = now.add(const Duration(minutes: 30));

      // 正在进行：当前时间在课程开始和结束之间
      // 即将进行：课程在30分钟内开始
      return (now.isAfter(courseStart) || now.isAtSameMomentAs(courseStart)) &&
              now.isBefore(courseEnd) ||
          (courseStart.isAfter(now) && courseStart.isBefore(upcomingThreshold));
    } catch (e) {
      return false;
    }
  }

  /// 检查时间段是否包含正在进行或即将进行的课程
  bool hasOngoingOrUpcomingCourse(
    List<Map<String, dynamic>> courses,
    String targetDate,
  ) {
    return courses.any(
      (course) => isCourseOngoingOrUpcoming(course, targetDate),
    );
  }
}

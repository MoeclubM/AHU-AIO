import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/api_manager.dart';
import '../api/course_selection.dart';
import '../api/api_models.dart';
import '../../globals.dart' as globals;

/// 统一服务管理器 - 提供数据缓存、批量请求和状态管理
class UnifiedServiceManager {
  static final UnifiedServiceManager _instance = UnifiedServiceManager._internal();
  factory UnifiedServiceManager() => _instance;
  UnifiedServiceManager._internal();

  // 缓存管理
  final Map<String, CacheItem> _cache = {};
  final Map<String, StreamController> _streamControllers = {};

  // 用户信息缓存
  UserInfo? _cachedUserInfo;
  DateTime? _userInfoCacheTime;

  // 当前学期缓存
  SemesterInfo? _cachedCurrentSemester;
  DateTime? _currentSemesterCacheTime;

  // 静态常量
  static const Duration _cacheTimeout = Duration(minutes: 5);
  static const Duration _userInfoCacheTimeout = Duration(minutes: 30);
  static const Duration _semesterCacheTimeout = Duration(hours: 1);

  /// 获取用户信息（带缓存）
  Future<UserInfo> getUserInfo({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedUserInfo != null && _userInfoCacheTime != null) {
      final age = DateTime.now().difference(_userInfoCacheTime!);
      if (age < _userInfoCacheTimeout) {
        return _cachedUserInfo!;
      }
    }

    try {
      final userData = await ApiManager.getUserInfo(globals.idToken!);
      final userInfo = UserInfo.fromJson(userData);

      _cachedUserInfo = userInfo;
      _userInfoCacheTime = DateTime.now();

      _notifyDataChange('userInfo', userInfo);
      return userInfo;
    } catch (e) {
      if (_cachedUserInfo != null) {
        debugPrint('获取用户信息失败，使用缓存数据: $e');
        return _cachedUserInfo!;
      }
      rethrow;
    }
  }

  /// 获取当前学期信息（带缓存）
  Future<SemesterInfo> getCurrentSemester({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCurrentSemester != null && _currentSemesterCacheTime != null) {
      final age = DateTime.now().difference(_currentSemesterCacheTime!);
      if (age < _semesterCacheTimeout) {
        return _cachedCurrentSemester!;
      }
    }

    try {
      final semesterData = await ApiManager.getCurrentSemester(globals.idToken!);
      final semester = SemesterInfo.fromJson(semesterData);

      _cachedCurrentSemester = semester;
      _currentSemesterCacheTime = DateTime.now();

      _notifyDataChange('currentSemester', semester);
      return semester;
    } catch (e) {
      if (_cachedCurrentSemester != null) {
        debugPrint('获取当前学期失败，使用缓存数据: $e');
        return _cachedCurrentSemester!;
      }
      rethrow;
    }
  }

  /// 获取完整的学生仪表板数据
  Future<StudentDashboardData> getStudentDashboard({bool forceRefresh = false}) async {
    final cacheKey = 'student_dashboard';

    if (!forceRefresh && _hasValidCache(cacheKey)) {
      return _getFromCache<StudentDashboardData>(cacheKey)!;
    }

    try {
      final currentSemester = await getCurrentSemester(forceRefresh: forceRefresh);

      final results = await Future.wait([
        // 基础信息
        getUserInfo(forceRefresh: forceRefresh),
        ApiManager.getStudentGrades(globals.idToken!),
        ApiManager.getStudentExams(globals.idToken!),
        ApiManager.getNotices(globals.idToken!),
        ApiManager.getTodos(globals.idToken!),
        // 课表相关
        ApiManager.getCurrentWeek(globals.idToken!, currentSemester.semesterId),
        // 学业统计
        _calculateAcademicStats(),
      ]);

      final userInfo = results[0] as UserInfo;
      final grades = (results[1] as List).map((g) => GradeInfo.fromJson(g)).toList();
      final exams = (results[2] as Map)['exams']?.map((e) => ExamInfo.fromJson(e)).toList() ?? [];
      final notices = (results[3] as Map)['notices']?.map((n) => NoticeInfo.fromJson(n)).toList() ?? [];
      final todos = (results[4] as Map)['todos']?.map((t) => NoticeInfo.fromJson(t)).toList() ?? [];
      final currentWeek = results[5] as Map<String, dynamic>;
      final academicStats = results[6] as Map<String, dynamic>;

      final dashboardData = StudentDashboardData(
        userInfo: userInfo,
        currentSemester: currentSemester,
        grades: grades,
        exams: exams,
        notices: notices,
        todos: todos,
        currentWeek: currentWeek,
        academicStats: academicStats,
        lastUpdated: DateTime.now(),
      );

      _setCache(cacheKey, dashboardData);
      _notifyDataChange('dashboard', dashboardData);

      return dashboardData;
    } catch (e) {
      if (_hasValidCache(cacheKey)) {
        debugPrint('获取仪表板数据失败，使用缓存: $e');
        return _getFromCache<StudentDashboardData>(cacheKey)!;
      }
      rethrow;
    }
  }

  /// 批量获取课程相关数据
  Future<CourseDataBundle> getCourseDataBundle({bool forceRefresh = false}) async {
    final cacheKey = 'course_data_bundle';

    if (!forceRefresh && _hasValidCache(cacheKey)) {
      return _getFromCache<CourseDataBundle>(cacheKey)!;
    }

    try {
      final currentSemester = await getCurrentSemester(forceRefresh: forceRefresh);

      final results = await Future.wait([
        // 可选课程
        CourseSelectionApi.getAvailableCourses(globals.idToken!, semesterId: currentSemester.semesterId.toString()),
        // 已选课程
        CourseSelectionApi.getSelectedCourses(globals.idToken!, semesterId: currentSemester.semesterId.toString()),
        // 选课计划
        CourseSelectionApi.getSelectionPlan(globals.idToken!, currentSemester.semesterId.toString()),
        // 选课统计
        CourseSelectionApi.getSelectionStats(globals.idToken!, currentSemester.semesterId.toString()),
        // 学生课表
        ApiManager.getStudentSchedule(globals.idToken!, currentSemester.semesterId.toString()),
      ]);

      final availableCourses = (results[0] as List).map((c) => _convertToCourseItem(c)).toList();
      final selectedCourses = (results[1] as List).map((c) => _convertToCourseItem(c)).toList();
      final selectionPlan = results[2] as Map<String, dynamic>;
      final selectionStats = results[3] as Map<String, dynamic>;
      final schedule = results[4];

      final bundle = CourseDataBundle(
        availableCourses: availableCourses,
        selectedCourses: selectedCourses,
        selectionPlan: selectionPlan,
        selectionStats: selectionStats,
        schedule: schedule,
        currentSemester: currentSemester,
        lastUpdated: DateTime.now(),
      );

      _setCache(cacheKey, bundle);
      _notifyDataChange('courseData', bundle);

      return bundle;
    } catch (e) {
      if (_hasValidCache(cacheKey)) {
        debugPrint('获取课程数据失败，使用缓存: $e');
        return _getFromCache<CourseDataBundle>(cacheKey)!;
      }
      rethrow;
    }
  }

  /// 批量获取学业相关数据
  Future<AcademicDataBundle> getAcademicDataBundle({bool forceRefresh = false}) async {
    final cacheKey = 'academic_data_bundle';

    if (!forceRefresh && _hasValidCache(cacheKey)) {
      return _getFromCache<AcademicDataBundle>(cacheKey)!;
    }

    try {
      final currentSemester = await getCurrentSemester(forceRefresh: forceRefresh);

      final results = await Future.wait([
        // 成绩数据
        ApiManager.getStudentGrades(globals.idToken!),
        ApiManager.getGradesBySemester(globals.idToken!, currentSemester.semesterId),
        ApiManager.getGpaStats(globals.idToken!),
        // 考试数据
        ApiManager.getStudentExams(globals.idToken!),
        // 培养方案
        _getPlanData(),
        // 学业预警
        _analyzeAcademicWarnings(),
      ]);

      final allGrades = (results[0] as List).map((g) => GradeInfo.fromJson(g)).toList();
      final currentSemesterGrades = (results[1] as List).map((g) => GradeInfo.fromJson(g)).toList();
      final gpaStats = results[2] as Map<String, dynamic>;
      final exams = (results[3] as Map)['exams']?.map((e) => ExamInfo.fromJson(e)).toList() ?? [];
      final planData = results[4] as Map<String, dynamic>;
      final warnings = results[5] as List;

      final bundle = AcademicDataBundle(
        allGrades: allGrades,
        currentSemesterGrades: currentSemesterGrades,
        gpaStats: gpaStats,
        exams: exams,
        planData: planData,
        warnings: warnings,
        currentSemester: currentSemester,
        lastUpdated: DateTime.now(),
      );

      _setCache(cacheKey, bundle);
      _notifyDataChange('academicData', bundle);

      return bundle;
    } catch (e) {
      if (_hasValidCache(cacheKey)) {
        debugPrint('获取学业数据失败，使用缓存: $e');
        return _getFromCache<AcademicDataBundle>(cacheKey)!;
      }
      rethrow;
    }
  }

  /// 获取实时通知数据
  Future<NotificationData> getNotificationData({bool forceRefresh = false}) async {
    final cacheKey = 'notification_data';

    if (!forceRefresh && _hasValidCache(cacheKey)) {
      return _getFromCache<NotificationData>(cacheKey)!;
    }

    try {
      final results = await Future.wait([
        ApiManager.getNotices(globals.idToken!),
        ApiManager.getTodos(globals.idToken!),
        ApiManager.getSchedules(globals.idToken!),
      ]);

      final noticesData = results[0] as Map<String, dynamic>;
      final todosData = results[1] as Map<String, dynamic>;
      final schedulesData = results[2] as Map<String, dynamic>;

      final notices = (noticesData['notices'] as List? ?? [])
          .map((n) => NoticeInfo.fromJson(n))
          .toList();
      final todos = (todosData['todos'] as List? ?? [])
          .map((t) => NoticeInfo.fromJson(t))
          .toList();
      final schedules = (schedulesData['schedules'] as List? ?? [])
          .map((s) => NoticeInfo.fromJson(s))
          .toList();

      final notificationData = NotificationData(
        notices: notices,
        todos: todos,
        schedules: schedules,
        unreadCount: notices.where((n) => !n.isRead).length +
                     todos.where((t) => !t.isRead).length,
        lastUpdated: DateTime.now(),
      );

      _setCache(cacheKey, notificationData);
      _notifyDataChange('notifications', notificationData);

      return notificationData;
    } catch (e) {
      if (_hasValidCache(cacheKey)) {
        debugPrint('获取通知数据失败，使用缓存: $e');
        return _getFromCache<NotificationData>(cacheKey)!;
      }
      rethrow;
    }
  }

  /// 清除所有缓存
  void clearAllCache() {
    _cache.clear();
    _cachedUserInfo = null;
    _userInfoCacheTime = null;
    _cachedCurrentSemester = null;
    _currentSemesterCacheTime = null;

    _notifyDataChange('cacheCleared', true);
  }

  /// 清除特定缓存
  void clearCache(String key) {
    _cache.remove(key);

    if (key == 'userInfo') {
      _cachedUserInfo = null;
      _userInfoCacheTime = null;
    } else if (key == 'currentSemester') {
      _cachedCurrentSemester = null;
      _currentSemesterCacheTime = null;
    }

    _notifyDataChange('cacheCleared', key);
  }

  /// 获取数据流
  Stream<T> getDataStream<T>(String key) {
    if (!_streamControllers.containsKey(key)) {
      _streamControllers[key] = StreamController<T>.broadcast();
    }
    return _streamControllers[key]!.stream.cast<T>();
  }

  /// 缓存管理私有方法
  bool _hasValidCache(String key) {
    final cacheItem = _cache[key];
    if (cacheItem == null) return false;

    final age = DateTime.now().difference(cacheItem.timestamp);
    return age < _cacheTimeout;
  }

  T? _getFromCache<T>(String key) {
    final cacheItem = _cache[key];
    return cacheItem?.data as T?;
  }

  void _setCache<T>(String key, T data) {
    _cache[key] = CacheItem(
      data: data,
      timestamp: DateTime.now(),
    );
  }

  void _notifyDataChange<T>(String key, T data) {
    final controller = _streamControllers[key];
    if (controller != null && !controller.isClosed) {
      controller.add(data);
    }
  }

  /// 辅助方法
  Future<Map<String, dynamic>> _calculateAcademicStats() async {
    try {
      final grades = await ApiManager.getStudentGrades(globals.idToken!);

      if (grades.isEmpty) {
        return {
          'totalCourses': 0,
          'averageScore': 0.0,
          'totalCredits': 0.0,
          'failedCourses': 0,
        };
      }

      double totalScore = 0;
      double totalCredits = 0;
      int failedCount = 0;

      for (final grade in grades) {
        totalScore += (grade['score'] ?? 0) * (grade['credit'] ?? 0);
        totalCredits += grade['credit'] ?? 0;
        if ((grade['score'] ?? 0) < 60) {
          failedCount++;
        }
      }

      return {
        'totalCourses': grades.length,
        'averageScore': totalCredits > 0 ? totalScore / totalCredits : 0.0,
        'totalCredits': totalCredits,
        'failedCourses': failedCount,
      };
    } catch (e) {
      debugPrint('计算学业统计失败: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getPlanData() async {
    // 这里应该调用实际的培养方案API
    // 简化实现
    return {
      'totalRequiredCredits': 160,
      'completedCredits': 80,
      'requiredCourses': [],
      'completedCourses': [],
    };
  }

  Future<List> _analyzeAcademicWarnings() async {
    // 这里应该实现学业预警分析逻辑
    // 简化实现
    return [];
  }

  CourseItem _convertToCourseItem(dynamic data) {
    return CourseItem(
      courseId: data['courseId'] ?? data['id'] ?? '',
      courseName: data['courseName'] ?? data['name'] ?? '',
      courseCode: data['courseCode'] ?? data['code'] ?? '',
      credits: (data['credits'] ?? data['credit'] ?? 0.0).toDouble(),
      teacherName: data['teacherName'] ?? data['teacher'] ?? '',
      campus: data['campus'] ?? '',
      category: data['category'] ?? '',
      schedule: data['schedule'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      hasConflict: data['hasConflict'] ?? false,
      selectionId: data['selectionId'],
    );
  }
}

/// 缓存项
class CacheItem {
  final dynamic data;
  final DateTime timestamp;

  CacheItem({
    required this.data,
    required this.timestamp,
  });
}

/// 学生仪表板数据
class StudentDashboardData {
  final UserInfo userInfo;
  final SemesterInfo currentSemester;
  final List<GradeInfo> grades;
  final List<ExamInfo> exams;
  final List<NoticeInfo> notices;
  final List<NoticeInfo> todos;
  final Map<String, dynamic> currentWeek;
  final Map<String, dynamic> academicStats;
  final DateTime lastUpdated;

  StudentDashboardData({
    required this.userInfo,
    required this.currentSemester,
    required this.grades,
    required this.exams,
    required this.notices,
    required this.todos,
    required this.currentWeek,
    required this.academicStats,
    required this.lastUpdated,
  });
}

/// 课程数据包
class CourseDataBundle {
  final List<CourseItem> availableCourses;
  final List<CourseItem> selectedCourses;
  final Map<String, dynamic> selectionPlan;
  final Map<String, dynamic> selectionStats;
  final dynamic schedule;
  final SemesterInfo currentSemester;
  final DateTime lastUpdated;

  CourseDataBundle({
    required this.availableCourses,
    required this.selectedCourses,
    required this.selectionPlan,
    required this.selectionStats,
    required this.schedule,
    required this.currentSemester,
    required this.lastUpdated,
  });
}

/// 学业数据包
class AcademicDataBundle {
  final List<GradeInfo> allGrades;
  final List<GradeInfo> currentSemesterGrades;
  final Map<String, dynamic> gpaStats;
  final List<ExamInfo> exams;
  final Map<String, dynamic> planData;
  final List warnings;
  final SemesterInfo currentSemester;
  final DateTime lastUpdated;

  AcademicDataBundle({
    required this.allGrades,
    required this.currentSemesterGrades,
    required this.gpaStats,
    required this.exams,
    required this.planData,
    required this.warnings,
    required this.currentSemester,
    required this.lastUpdated,
  });
}

/// 通知数据
class NotificationData {
  final List<NoticeInfo> notices;
  final List<NoticeInfo> todos;
  final List<NoticeInfo> schedules;
  final int unreadCount;
  final DateTime lastUpdated;

  NotificationData({
    required this.notices,
    required this.todos,
    required this.schedules,
    required this.unreadCount,
    required this.lastUpdated,
  });
}

/// 课程项目（简化版）
class CourseItem {
  final String courseId;
  final String courseName;
  final String courseCode;
  final double credits;
  final String teacherName;
  final String campus;
  final String category;
  final String schedule;
  final bool isAvailable;
  final bool hasConflict;
  final String? selectionId;

  CourseItem({
    required this.courseId,
    required this.courseName,
    required this.courseCode,
    required this.credits,
    required this.teacherName,
    required this.campus,
    required this.category,
    required this.schedule,
    required this.isAvailable,
    this.hasConflict = false,
    this.selectionId,
  });
}
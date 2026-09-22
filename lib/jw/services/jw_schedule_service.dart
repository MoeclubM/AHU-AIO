import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/jw_api.dart';
import '../models/jw_models.dart';

/// 安大新教务系统课表状态与数据管理服务（对接 jw.ahu.edu.cn）。
class JwScheduleService extends ChangeNotifier {
  final JwApi _api = JwApi();

  bool isLoading = false;
  bool isCached = false;
  bool isOfflineCache = false;
  String? errorMessage;

  List<JwSemesterInfo> allSemesters = [];
  JwSemesterInfo? selectedSemester;
  int currentWeek = 1;
  int selectedWeek = 1;
  bool isInSemester = true;

  JwScheduleData? scheduleData;

  /// 获取当前选中周次下的周一到周日（1~7）排课映射
  Map<int, List<JwScheduleEntry>> get currentWeekSchedule {
    if (scheduleData == null) {
      return {for (var d = 1; d <= 7; d++) d: <JwScheduleEntry>[]};
    }
    return scheduleData!.buildWeekSchedule(selectedWeek);
  }

  /// 预设官方已知学期元数据列表（作为兜底）
  static const List<JwSemesterInfo> fallbackSemesters = [
    JwSemesterInfo(
      id: 132,
      code: '26271',
      schoolYear: '2026-2027',
      nameZh: '2026-2027-1',
      season: 'AUTUMN',
      startDate: '2026-09-07',
      endDate: '2027-01-24',
    ),
    JwSemesterInfo(
      id: 112,
      code: '25262',
      schoolYear: '2025-2026',
      nameZh: '2025-2026-2',
      season: 'SPRING',
      startDate: '2026-03-02',
      endDate: '2026-07-19',
    ),
    JwSemesterInfo(
      id: 92,
      code: '25261',
      schoolYear: '2025-2026',
      nameZh: '2025-2026-1',
      season: 'AUTUMN',
      startDate: '2025-09-08',
      endDate: '2026-01-18',
    ),
    JwSemesterInfo(
      id: 72,
      code: '24252',
      schoolYear: '2024-2025',
      nameZh: '2024-2025-2',
      season: 'SPRING',
      startDate: '2025-02-17',
      endDate: '2025-07-11',
    ),
    JwSemesterInfo(
      id: 52,
      code: '24251',
      schoolYear: '2024-2025',
      nameZh: '2024-2025-1',
      season: 'AUTUMN',
      startDate: '2024-09-02',
      endDate: '2025-01-26',
    ),
  ];

  /// 初始化并加载学期、教学周和排课数据（优先命中缓存，随后异步静默拉取最新）
  Future<void> initAndLoad() async {
    await _loadCache();
    await fetchSemestersAndTeachWeek();
    if (selectedSemester != null) {
      await fetchScheduleData(selectedSemester!.id);
    }
  }

  /// 读取本地持久化缓存
  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final cachedSem = prefs.getString('jw_sys_semesters_cache');
      if (cachedSem != null) {
        final list = jsonDecode(cachedSem) as List;
        final seen = <int>{};
        allSemesters = list
            .whereType<Map>()
            .map((m) => JwSemesterInfo.fromJson(Map<String, dynamic>.from(m)))
            .where((s) => seen.add(s.id))
            .toList();
      } else {
        allSemesters = List.from(fallbackSemesters);
      }

      final savedSemId = prefs.getInt('jw_sys_selected_sem_id');
      if (savedSemId != null && allSemesters.isNotEmpty) {
        selectedSemester = allSemesters.firstWhere(
          (s) => s.id == savedSemId,
          orElse: () => allSemesters.first,
        );
      } else if (allSemesters.isNotEmpty) {
        selectedSemester = allSemesters.first;
      }

      final savedWeek = prefs.getInt('jw_sys_selected_week');
      if (savedWeek != null && savedWeek > 0 && savedWeek <= 25) {
        selectedWeek = savedWeek;
      }

      if (selectedSemester != null) {
        final cachedData =
            prefs.getString('jw_sys_schedule_cache_${selectedSemester!.id}');
        if (cachedData != null) {
          scheduleData = JwScheduleData.fromJson(jsonDecode(cachedData));
          isCached = true;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  /// 获取当前教学周与在线学期配置
  Future<void> fetchSemestersAndTeachWeek() async {
    try {
      // 1. 请求当前教学周
      try {
        final weekRaw = await _api.getCurrentTeachWeek();
        final w = int.tryParse('${weekRaw['weekIndex']}');
        if (w != null && w > 0) {
          currentWeek = w;
          if (selectedWeek == 1 || selectedWeek == currentWeek) {
            selectedWeek = currentWeek;
          }
        }
        isInSemester = weekRaw['isInSemester'] == true;
      } catch (_) {}

      // 2. 尝试获取学期列表
      try {
        final semList = await _api.getSemesters();
        if (semList.isNotEmpty) {
          final seen = <int>{};
          allSemesters = semList
              .map((m) => JwSemesterInfo.fromJson(m))
              .where((s) => seen.add(s.id))
              .toList();
        }
      } catch (_) {}

      if (allSemesters.isEmpty) {
        allSemesters = List.from(fallbackSemesters);
      }

      if (selectedSemester == null ||
          !allSemesters.any((s) => s.id == selectedSemester!.id)) {
        selectedSemester = allSemesters.first;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'jw_sys_semesters_cache',
        jsonEncode(allSemesters.map((s) => s.toJson()).toList()),
      );
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 拉取指定学期对应的结构化排课活动
  Future<void> fetchScheduleData(int semesterId) async {
    isLoading = true;
    errorMessage = null;
    isOfflineCache = false;
    notifyListeners();

    try {
      final raw = await _api.getCourseTablePrintData(semesterId);
      scheduleData = JwScheduleData.fromJson(raw);
      isCached = false;
      isOfflineCache = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'jw_sys_schedule_cache_$semesterId',
        jsonEncode(raw),
      );
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('jw_sys_schedule_cache_$semesterId');
      if (cached != null) {
        scheduleData = JwScheduleData.fromJson(jsonDecode(cached));
      }

      if (scheduleData != null && scheduleData!.activities.isNotEmpty) {
        // 有缓存可看：网络失败不打断浏览，标记为离线缓存展示
        isCached = true;
        isOfflineCache = true;
        errorMessage = null;
      } else {
        isCached = false;
        isOfflineCache = false;
        errorMessage = e.toString();
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// 切换学期
  Future<void> selectSemester(JwSemesterInfo sem) async {
    if (selectedSemester?.id == sem.id) return;
    selectedSemester = sem;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('jw_sys_selected_sem_id', sem.id);

    // 优先展示新学期的本地缓存
    final cached = prefs.getString('jw_sys_schedule_cache_${sem.id}');
    if (cached != null) {
      scheduleData = JwScheduleData.fromJson(jsonDecode(cached));
      isCached = true;
      notifyListeners();
    } else {
      scheduleData = null;
      isCached = false;
    }

    await fetchScheduleData(sem.id);
  }

  /// 切换周次
  Future<void> selectWeek(int week) async {
    if (selectedWeek == week) return;
    selectedWeek = week;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('jw_sys_selected_week', week);
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/jw_api.dart';
import '../models/jw_models.dart';
import '../../schedule_cache_bootstrap.dart';

/// 安大新教务系统课表状态与数据管理服务（对接 jw.ahu.edu.cn）。
class JwScheduleService extends ChangeNotifier {
  final JwApi _api = JwApi();

  bool isLoading = false;
  bool isInitializing = false;
  bool isCached = false;
  bool isOfflineCache = false;
  String? errorMessage;

  List<JwSemesterInfo> allSemesters = [];
  JwSemesterInfo? selectedSemester;
  int currentWeek = 1;
  int selectedWeek = 1;
  int? currentSemesterId;
  bool isInSemester = true;

  JwScheduleData? scheduleData;

  bool get isCurrentSemesterSelected =>
      currentSemesterId != null && selectedSemester?.id == currentSemesterId;

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
    isInitializing = true;
    try {
      await _loadCache();
      await fetchSemestersAndTeachWeek();
      if (selectedSemester != null) {
        await fetchScheduleData(selectedSemester!.id);
      }
    } finally {
      isInitializing = false;
    }
  }

  /// 读取本地持久化缓存
  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final cachedSem = prefs.getString('jw_sys_semesters_cache');
      if (ScheduleCacheBootstrap.jwSemesters != null) {
        allSemesters = List.from(ScheduleCacheBootstrap.jwSemesters!);
      } else if (cachedSem != null) {
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

      currentSemesterId =
          _findSemesterForToday(allSemesters)?.id ??
          prefs.getInt('jw_sys_current_sem_id') ??
          ScheduleCacheBootstrap.jwCurrentSemesterId;
      final savedSemId =
          prefs.getInt('jw_sys_selected_sem_id') ??
          ScheduleCacheBootstrap.jwSelectedSemesterId;
      if (currentSemesterId != null && allSemesters.isNotEmpty) {
        selectedSemester =
            _semesterById(currentSemesterId) ?? allSemesters.first;
      } else if (savedSemId != null && allSemesters.isNotEmpty) {
        selectedSemester = allSemesters.firstWhere(
          (s) => s.id == savedSemId,
          orElse: () => _semesterById(currentSemesterId) ?? allSemesters.first,
        );
      } else if (allSemesters.isNotEmpty) {
        selectedSemester = allSemesters.first;
      }

      final savedWeek =
          prefs.getInt('jw_sys_selected_week') ??
          ScheduleCacheBootstrap.jwSelectedWeek;
      if (savedWeek != null && savedWeek > 0 && savedWeek <= 25) {
        selectedWeek = savedWeek;
      }

      final currentSemester = _semesterById(currentSemesterId);
      if (currentSemester != null) {
        currentWeek = _weekForDate(currentSemester, DateTime.now());
        isInSemester = _dateIsInsideSemester(currentSemester, DateTime.now());
        if (selectedSemester?.id == currentSemester.id) {
          selectedWeek = currentWeek;
        }
      }

      if (selectedSemester != null) {
        final cachedModel =
            ScheduleCacheBootstrap.jwSchedules[selectedSemester!.id];
        final cachedData = prefs.getString(
          'jw_sys_schedule_cache_${selectedSemester!.id}',
        );
        if (cachedModel != null || cachedData != null) {
          scheduleData =
              cachedModel ?? JwScheduleData.fromJson(jsonDecode(cachedData!));
          isCached = true;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  /// 获取当前教学周与在线学期配置
  Future<void> fetchSemestersAndTeachWeek() async {
    try {
      final previousCurrentSemesterId = currentSemesterId;
      Map<String, dynamic>? weekRaw;
      // 1. 请求当前教学周
      try {
        weekRaw = await _api.getCurrentTeachWeek();
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

      currentSemesterId = _resolveCurrentSemesterId(
        weekRaw?['currentSemester']?.toString(),
        allSemesters,
      );
      final currentSemester = _semesterById(currentSemesterId);
      final onlineInSemester = weekRaw?['isInSemester'] == true;
      isInSemester =
          onlineInSemester ||
          (weekRaw == null &&
              currentSemester != null &&
              _dateIsInsideSemester(currentSemester, DateTime.now()));
      final onlineWeek = int.tryParse('${weekRaw?['weekIndex']}');
      currentWeek = onlineInSemester && onlineWeek != null && onlineWeek > 0
          ? onlineWeek.clamp(1, 25).toInt()
          : currentSemester == null
          ? 1
          : _weekForDate(currentSemester, DateTime.now());

      if (selectedSemester == null ||
          selectedSemester?.id == previousCurrentSemesterId ||
          !allSemesters.any((s) => s.id == selectedSemester!.id)) {
        selectedSemester =
            _semesterById(currentSemesterId) ?? allSemesters.first;
      }
      if (selectedSemester?.id == currentSemesterId) {
        selectedWeek = currentWeek;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'jw_sys_semesters_cache',
        jsonEncode(allSemesters.map((s) => s.toJson()).toList()),
      );
      if (currentSemesterId != null) {
        await prefs.setInt('jw_sys_current_sem_id', currentSemesterId!);
      }
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
      ScheduleCacheBootstrap.jwSchedules[semesterId] = scheduleData!;
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
    selectedWeek = sem.id == currentSemesterId ? currentWeek : 1;
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

  Future<void> refreshData() async {
    if (isInitializing || isLoading) return;
    await fetchSemestersAndTeachWeek();
    if (selectedSemester != null) {
      await fetchScheduleData(selectedSemester!.id);
    }
  }

  Future<void> activate() async {
    if (isInitializing || isLoading) return;
    final current = _semesterById(currentSemesterId);
    if (current != null && selectedSemester?.id != current.id) {
      await selectSemester(current);
      return;
    }
    if (current != null) {
      currentWeek = _weekForDate(current, DateTime.now());
      selectedWeek = currentWeek;
      isInSemester = _dateIsInsideSemester(current, DateTime.now());
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('jw_sys_selected_week', selectedWeek);
    }
    await refreshData();
  }

  JwSemesterInfo? _semesterById(int? id) {
    if (id == null) return null;
    for (final semester in allSemesters) {
      if (semester.id == id) return semester;
    }
    return null;
  }

  int? _resolveCurrentSemesterId(
    String? apiName,
    List<JwSemesterInfo> semesters,
  ) {
    if (apiName != null && apiName.isNotEmpty) {
      for (final semester in semesters) {
        if (semester.nameZh == apiName || semester.code == apiName) {
          return semester.id;
        }
      }
    }
    return _findSemesterForToday(semesters)?.id ?? currentSemesterId;
  }

  JwSemesterInfo? _findSemesterForToday(List<JwSemesterInfo> semesters) {
    final today = DateTime.now();
    final active = semesters.where((semester) {
      final start = DateTime.tryParse(semester.startDate ?? '');
      final end = DateTime.tryParse(semester.endDate ?? '');
      return start != null &&
          end != null &&
          !_dateOnly(today).isBefore(_dateOnly(start)) &&
          !_dateOnly(today).isAfter(_dateOnly(end));
    }).toList();
    if (active.isNotEmpty) return active.first;

    final started =
        semesters.where((semester) {
          final start = DateTime.tryParse(semester.startDate ?? '');
          return start != null && !_dateOnly(start).isAfter(_dateOnly(today));
        }).toList()..sort(
          (a, b) => DateTime.parse(
            b.startDate!,
          ).compareTo(DateTime.parse(a.startDate!)),
        );
    return started.isEmpty ? null : started.first;
  }

  int _weekForDate(JwSemesterInfo semester, DateTime date) {
    final start = DateTime.tryParse(semester.startDate ?? '');
    if (start == null) return 1;
    final firstMonday = _dateOnly(
      start,
    ).subtract(Duration(days: start.weekday - DateTime.monday));
    final week = _dateOnly(date).difference(firstMonday).inDays ~/ 7 + 1;
    return week.clamp(1, 25).toInt();
  }

  bool _dateIsInsideSemester(JwSemesterInfo semester, DateTime date) {
    final start = DateTime.tryParse(semester.startDate ?? '');
    final end = DateTime.tryParse(semester.endDate ?? '');
    return start != null &&
        end != null &&
        !_dateOnly(date).isBefore(_dateOnly(start)) &&
        !_dateOnly(date).isAfter(_dateOnly(end));
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// 切换周次
  Future<void> selectWeek(int week) async {
    if (selectedWeek == week) return;
    selectedWeek = week;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('jw_sys_selected_week', week);
  }
}

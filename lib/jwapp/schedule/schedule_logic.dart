import 'dart:async';
import 'package:get/get.dart';
import 'schedule_service.dart';
import 'semester_config.dart';
import '../api/getallsemesters.dart';

class ScheduleLogic extends GetxController {
  final ScheduleService _scheduleService = ScheduleService();

  // 课程数据
  var scheduleData = <String, dynamic>{}.obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var isCached = false.obs;

  /// 网络失败但有本地缓存：安静回退到缓存展示，用横幅提示而非错误卡片
  var isOfflineCache = false.obs;

  // 防抖定时器
  Timer? _debounceTimer;

  // 学期和周数选择
  var allSemesters = <SemesterInfo>[].obs;
  var selectedSemester = Rxn<SemesterInfo>();
  var currentSemesterInfo = Rxn<CurrentSemesterInfo>();
  var selectedWeek = 1.obs;
  var availableWeeks = <int>[].obs;
  bool _isInitializing = false;

  @override
  void onInit() {
    super.onInit();
    initializeData();
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
  }

  // 初始化数据
  Future<void> initializeData() async {
    _isInitializing = true;
    try {
      await SemesterConfig.loadDiskCache();
      _applyCachedSemesterData();
      await loadScheduleData();
      final loadedSemesterId = selectedSemester.value?.id;
      await _refreshSemesterData();
      if (selectedSemester.value?.id != loadedSemesterId) {
        await loadScheduleData();
      }
    } finally {
      _isInitializing = false;
    }
  }

  void _applyCachedSemesterData() {
    allSemesters.value = SemesterConfig.cachedSemesters ?? [];
    var current = SemesterConfig.cachedCurrentSemester;
    final today = DateTime.now();
    final cachedCurrentIsActive =
        current != null &&
        _isDateInsideSemester(today, current.startDate, current.endDate);
    if (!cachedCurrentIsActive && allSemesters.isNotEmpty) {
      final active = allSemesters.firstWhereOrNull((semester) {
        return _isDateInsideSemester(
          today,
          semester.startDate,
          semester.endDate,
        );
      });
      final latestStarted = allSemesters.where((semester) {
        final start = DateTime.tryParse(semester.startDate);
        return start != null && !_dateOnly(start).isAfter(_dateOnly(today));
      }).toList()..sort((a, b) => b.id.compareTo(a.id));
      final semester =
          active ?? (latestStarted.isEmpty ? null : latestStarted.first);
      if (semester != null) {
        current = CurrentSemesterInfo(
          id: semester.id,
          code: semester.code,
          nameZh: semester.nameZh,
          nameEn: semester.nameEn,
          schoolYear: semester.schoolYear,
          startDate: semester.startDate,
          endDate: semester.endDate,
          season: semester.season,
          weekIndices: const [],
        );
      }
    }

    if (current == null) return;
    currentSemesterInfo.value = current;
    selectedSemester.value =
        allSemesters.firstWhereOrNull(
          (semester) => semester.id == current!.id,
        ) ??
        SemesterInfo(
          id: current.id,
          code: current.code,
          nameZh: current.nameZh,
          nameEn: current.nameEn,
          schoolYear: current.schoolYear,
          startDate: current.startDate,
          endDate: current.endDate,
          season: current.season,
        );
    availableWeeks.value = _weeksFor(current);
    selectedWeek.value = _getCurrentWeek(current);
  }

  Future<void> _refreshSemesterData() async {
    final oldCurrentId = currentSemesterInfo.value?.id;
    await SemesterConfig.refresh();
    allSemesters.value = SemesterConfig.cachedSemesters ?? allSemesters;
    final current = SemesterConfig.cachedCurrentSemester;
    if (current == null) return;
    currentSemesterInfo.value = current;
    if (oldCurrentId != current.id ||
        selectedSemester.value?.id == oldCurrentId) {
      selectedSemester.value =
          allSemesters.firstWhereOrNull(
            (semester) => semester.id == current.id,
          ) ??
          SemesterInfo(
            id: current.id,
            code: current.code,
            nameZh: current.nameZh,
            nameEn: current.nameEn,
            schoolYear: current.schoolYear,
            startDate: current.startDate,
            endDate: current.endDate,
            season: current.season,
          );
      availableWeeks.value = _weeksFor(current);
      selectedWeek.value = _getCurrentWeek(current);
    }
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool _isDateInsideSemester(DateTime date, String startRaw, String endRaw) {
    final start = DateTime.tryParse(startRaw);
    final end = DateTime.tryParse(endRaw);
    return start != null &&
        end != null &&
        !_dateOnly(date).isBefore(_dateOnly(start)) &&
        !_dateOnly(date).isAfter(_dateOnly(end));
  }

  // 加载学期数据
  Future<void> loadSemesterData() async {
    try {
      // 获取所有学期
      final semesters = await SemesterConfig.getAllSemesters();
      if (semesters != null) {
        allSemesters.value = semesters;
      }

      // 获取当前学期信息
      final currentSemester = await SemesterConfig.getCurrentSemesterInfo();
      if (currentSemester != null) {
        currentSemesterInfo.value = currentSemester;

        // 只有在没有选中任何学期时，才设置默认选中当前学期
        if (selectedSemester.value == null) {
          final currentSemesterData = allSemesters.firstWhereOrNull(
            (semester) => semester.id == currentSemester.id,
          );
          if (currentSemesterData != null) {
            selectedSemester.value = currentSemesterData;
          }

          // 设置可用周数
          availableWeeks.value = _weeksFor(currentSemester);
          selectedWeek.value = _getCurrentWeek(currentSemester);
        } else {
          // 如果已经有选中的学期，更新该学期的周数信息
          if (currentSemesterInfo.value != null &&
              selectedSemester.value!.id == currentSemesterInfo.value!.id) {
            // 当前学期，使用真实的周数信息
            availableWeeks.value = _weeksFor(currentSemesterInfo.value!);
            selectedWeek.value = _getCurrentWeek(currentSemesterInfo.value!);
          } else {
            // 其他学期，使用默认的周数（1-20周）
            availableWeeks.value = List.generate(20, (index) => index + 1);
          }
        }
      }
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }

  // 加载课程数据
  Future<void> loadScheduleData() async {
    // 取消之前的防抖定时器
    _debounceTimer?.cancel();

    try {
      isLoading.value = true;
      errorMessage.value = '';
      isOfflineCache.value = false;

      final semesterId = selectedSemester.value?.id;
      final semIdStr = semesterId?.toString();

      // 1. 先尝试加载缓存并立即展示
      await _scheduleService.loadCache(semesterId: semIdStr);
      final cachedClasses = _scheduleService.classes;
      if (cachedClasses != null && cachedClasses.isNotEmpty) {
        scheduleData.assignAll({'classes': cachedClasses});
        isCached.value = true;
        update();
      } else {
        // 该学期没有本地缓存时必须清空旧学期残留，避免误导用户
        scheduleData.assignAll({'classes': <dynamic>[]});
        isCached.value = false;
      }

      // 2. 发起 API 请求拉取最新数据
      if (semIdStr != null) {
        await _scheduleService.fetchData(semesterId: semIdStr);
      } else {
        await _scheduleService.fetchData();
      }
      scheduleData.assignAll({'classes': _scheduleService.classes ?? []});
      isCached.value = false;
      isOfflineCache.value = false;
    } catch (e) {
      final classes = scheduleData['classes'];
      final hasDisplayedCache = classes is List && classes.isNotEmpty;
      if (hasDisplayedCache) {
        // 有缓存可看：网络失败不打断浏览，由视图层展示离线缓存横幅
        isOfflineCache.value = true;
        errorMessage.value = '';
      } else {
        errorMessage.value = e.toString();
      }
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // 选择学期
  Future<void> selectSemester(SemesterInfo semester) async {
    selectedSemester.value = semester;

    // 如果选择的是当前学期，使用当前学期的周数信息
    if (currentSemesterInfo.value != null &&
        semester.id == currentSemesterInfo.value!.id) {
      availableWeeks.value = currentSemesterInfo.value!.weekIndices;
    } else {
      // 对于其他学期，生成默认的周数（1-20周）
      availableWeeks.value = List.generate(20, (index) => index + 1);
    }

    // 重置选中的周数
    if (availableWeeks.isNotEmpty) {
      if (currentSemesterInfo.value != null &&
          semester.id == currentSemesterInfo.value!.id) {
        // 如果是当前学期，设置为当前周
        selectedWeek.value = _getCurrentWeek(currentSemesterInfo.value!);
      } else {
        // 其他学期设置为第一周
        selectedWeek.value = availableWeeks.first;
      }
    }

    // 重新加载课程数据，但不重新加载学期数据
    await loadScheduleData();
    // 强制更新UI
    update();
  }

  // 选择周数
  Future<void> selectWeek(int week) async {
    if (selectedWeek.value == week) {
      return;
    }

    selectedWeek.value = week;
    // 不重新请求后端数据，直接刷新界面即可
    update();
  }

  // 获取真实的当前周，如果不在当前学期则返回null
  int? get realCurrentWeek {
    if (currentSemesterInfo.value != null &&
        selectedSemester.value?.id == currentSemesterInfo.value!.id) {
      return _getCurrentWeek(currentSemesterInfo.value!);
    }
    return null;
  }

  // 格式化时间
  String formatTime(int time) {
    return _scheduleService.formatTime(time);
  }

  /// 处理指定周数的课程数据
  Map<int, List<ScheduleEntry>> processClassesForWeek(int week) {
    int? currentWeekNumber;
    if (currentSemesterInfo.value != null &&
        selectedSemester.value?.id == currentSemesterInfo.value!.id) {
      currentWeekNumber = _getCurrentWeek(currentSemesterInfo.value!);
    }

    final semesterStartDate = _resolveSemesterStartDate();

    return _scheduleService.buildWeekSchedule(
      selectedWeek: week,
      currentWeek: currentWeekNumber,
      semesterStartDate: semesterStartDate,
    );
  }

  /// 处理课程数据，根据当前选择的周数过滤课程
  Map<int, List<ScheduleEntry>> processClasses() {
    return processClassesForWeek(selectedWeek.value);
  }

  // 刷新数据
  Future<void> refreshData() async {
    if (_isInitializing || isLoading.value) return;
    await _refreshSemesterData();
    await loadScheduleData();
  }

  /// 计算当前周数
  int _getCurrentWeek(CurrentSemesterInfo semesterInfo) {
    final now = DateTime.now();
    final startDate = DateTime.tryParse(semesterInfo.startDate);
    if (startDate == null) return 1;

    final firstMonday = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    ).subtract(Duration(days: startDate.weekday - DateTime.monday));
    final today = DateTime(now.year, now.month, now.day);
    final currentWeek = today.difference(firstMonday).inDays ~/ 7 + 1;

    if (semesterInfo.weekIndices.isEmpty) {
      return currentWeek.clamp(1, 25).toInt();
    }

    // 确保周数在有效范围内
    if (semesterInfo.weekIndices.contains(currentWeek)) {
      return currentWeek;
    } else {
      // 如果计算的周数不在有效范围内，返回最接近的有效周数
      if (currentWeek < semesterInfo.weekIndices.first) {
        return semesterInfo.weekIndices.first;
      } else if (currentWeek > semesterInfo.weekIndices.last) {
        return semesterInfo.weekIndices.last;
      } else {
        // 找到最接近的周数
        return semesterInfo.weekIndices.reduce(
          (a, b) => (currentWeek - a).abs() < (currentWeek - b).abs() ? a : b,
        );
      }
    }
  }

  List<int> _weeksFor(CurrentSemesterInfo semesterInfo) =>
      semesterInfo.weekIndices.isNotEmpty
      ? semesterInfo.weekIndices
      : List.generate(25, (index) => index + 1);

  DateTime? get semesterStartDate => _resolveSemesterStartDate();

  DateTime? _resolveSemesterStartDate() {
    final semester = selectedSemester.value;
    if (semester != null && semester.startDate.isNotEmpty) {
      return DateTime.tryParse(semester.startDate);
    }

    final currentInfo = currentSemesterInfo.value;
    if (currentInfo != null && currentInfo.startDate.isNotEmpty) {
      return DateTime.tryParse(currentInfo.startDate);
    }

    return null;
  }
}

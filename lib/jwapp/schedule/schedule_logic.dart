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

  // 防抖定时器
  Timer? _debounceTimer;

  // 学期和周数选择
  var allSemesters = <SemesterInfo>[].obs;
  var selectedSemester = Rxn<SemesterInfo>();
  var currentSemesterInfo = Rxn<CurrentSemesterInfo>();
  var selectedWeek = 1.obs;
  var availableWeeks = <int>[].obs;

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
    await loadSemesterData();
    await loadScheduleData();
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
          availableWeeks.value = currentSemester.weekIndices;
          if (availableWeeks.isNotEmpty) {
            // 设置为当前周，而不是第一周
            selectedWeek.value = _getCurrentWeek(currentSemester);
          }
        } else {
          // 如果已经有选中的学期，更新该学期的周数信息
          if (currentSemesterInfo.value != null &&
              selectedSemester.value!.id == currentSemesterInfo.value!.id) {
            // 当前学期，使用真实的周数信息
            availableWeeks.value = currentSemesterInfo.value!.weekIndices;
            if (availableWeeks.isNotEmpty) {
              selectedWeek.value = _getCurrentWeek(currentSemesterInfo.value!);
            }
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

      final semesterId = selectedSemester.value?.id;
      final semIdStr = semesterId?.toString();

      // 1. 先尝试加载缓存并立即展示
      await _scheduleService.loadCache(semesterId: semIdStr);
      scheduleData.assignAll({'classes': _scheduleService.classes ?? []});
      isCached.value = _scheduleService.isCached;
      if (scheduleData['classes'] != null &&
          scheduleData['classes'].isNotEmpty) {
        update();
      }

      // 2. 发起 API 请求拉取最新数据
      if (semIdStr != null) {
        await _scheduleService.fetchData(semesterId: semIdStr);
      } else {
        await _scheduleService.fetchData();
      }
      scheduleData.assignAll({'classes': _scheduleService.classes ?? []});
      isCached.value = false;
    } catch (e) {
      errorMessage.value = e.toString();
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

  /// 处理课程数据，根据选择的周数过滤课程
  Map<int, List<ScheduleEntry>> processClasses() {
    int? currentWeekNumber;
    if (currentSemesterInfo.value != null &&
        selectedSemester.value?.id == currentSemesterInfo.value!.id) {
      currentWeekNumber = _getCurrentWeek(currentSemesterInfo.value!);
    }

    final semesterStartDate = _resolveSemesterStartDate();

    return _scheduleService.buildWeekSchedule(
      selectedWeek: selectedWeek.value,
      currentWeek: currentWeekNumber,
      semesterStartDate: semesterStartDate,
    );
  }

  // 刷新数据
  Future<void> refreshData() async {
    // 重新加载学期数据和课程数据
    await loadSemesterData();
    await loadScheduleData();
  }

  /// 计算当前周数
  int _getCurrentWeek(CurrentSemesterInfo semesterInfo) {
    final now = DateTime.now();
    final startDate = DateTime.parse(semesterInfo.startDate);

    // 计算从学期开始到现在的天数
    final daysDifference = now.difference(startDate).inDays;

    // 计算当前是第几周（从1开始）
    final currentWeek = (daysDifference / 7).floor() + 1;

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

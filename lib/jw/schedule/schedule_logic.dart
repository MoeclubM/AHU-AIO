import 'package:get/get.dart';
import 'schedule_service.dart';
import 'semester_config.dart';
import '../api/getallsemesters.dart';
import '../api/getcurrentsemester.dart';

class ScheduleLogic extends GetxController {
  final ScheduleService _scheduleService = ScheduleService();
  
  // 课程数据
  var scheduleData = <String, dynamic>{}.obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  
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
        
        // 设置默认选中的学期
        final currentSemesterData = allSemesters.firstWhereOrNull(
          (semester) => semester.id == currentSemester.id
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
      }
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }
  
  // 加载课程数据
  Future<void> loadScheduleData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      // 使用选中的学期ID
      final semesterId = selectedSemester.value?.id;
      if (semesterId != null) {
        await _scheduleService.fetchData(semesterId: semesterId.toString());
      } else {
        await _scheduleService.fetchData();
      }
      
      // 构建课程数据结构
      scheduleData.value = {
        'classes': _scheduleService.classes ?? [],
        'table': _scheduleService.table ?? [],
      };
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
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
    
    // 重新加载课程数据
    await loadScheduleData();
  }
  
  // 选择周数
  Future<void> selectWeek(int week) async {
    selectedWeek.value = week;
    // 重新加载课程数据
    await loadScheduleData();
  }
  
  // 格式化时间
  String formatTime(int time) {
    return _scheduleService.formatTime(time);
  }
  
  /// 处理课程数据，根据选择的周数过滤课程
  Map<String, Map<String, List<Map<String, dynamic>>>> processClasses() {
    final currentWeek = currentSemesterInfo.value != null 
        ? _getCurrentWeek(currentSemesterInfo.value!) 
        : null;
    return _scheduleService.processClasses(
      selectedWeek: selectedWeek.value,
      currentWeek: currentWeek,
    );
  }

  /// 处理课程数据，支持显示所有学期课程并标记非当前周课程
  Map<String, Map<String, List<Map<String, dynamic>>>> processAllClasses() {
    final currentWeek = currentSemesterInfo.value != null 
        ? _getCurrentWeek(currentSemesterInfo.value!) 
        : null;
    return _scheduleService.processAllClasses(currentWeek: currentWeek);
  }
  
  // 刷新数据
  Future<void> refreshData() async {
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
        return semesterInfo.weekIndices.reduce((a, b) => 
          (currentWeek - a).abs() < (currentWeek - b).abs() ? a : b);
      }
    }
  }
}
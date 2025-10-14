import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'schedule_logic.dart';
import '../api/getcurrentsemester.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> with TickerProviderStateMixin {
  final ScheduleLogic logic = Get.put(ScheduleLogic());
  bool _isInitialized = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // 初始化动画控制器
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    // 初始化ScheduleLogic
    Get.put(ScheduleLogic());
    _loadInitialData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isInitialized = false;
    });

    final logic = Get.find<ScheduleLogic>();
    await logic.refreshData();

    setState(() {
      _isInitialized = true;
    });

    // 启动动画
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 如果数据还未初始化，显示加载界面
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        appBar: AppBar(
          title: const Text(
            '课程表',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.blue.shade800,
                        Colors.blue.shade600,
                        Colors.indigo.shade700,
                      ]
                    : [
                        Colors.blue.shade600,
                        Colors.blue.shade700,
                        Colors.indigo.shade600,
                      ],
              ),
            ),
          ),
        ),
        body: Center(
          child: Card.filled(
            color: isDark ? Colors.grey.shade800 : Colors.white,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? Colors.blue.shade300 : Colors.blue.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '正在加载课表信息...',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return GetBuilder<ScheduleLogic>(
      builder: (logic) {
        return Scaffold(
          backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
          appBar: AppBar(
            title: const Text(
              '课程表',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.blue.shade800,
                          Colors.blue.shade600,
                          Colors.indigo.shade700,
                        ]
                      : [
                          Colors.blue.shade600,
                          Colors.blue.shade700,
                          Colors.indigo.shade600,
                        ],
                ),
              ),
            ),
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // 选择区域
                  _buildSelectionArea(),
                  // 课表内容区域
                  Expanded(
                    child: _buildScheduleContent(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  
  Widget _buildScheduleContent() {
    return GetBuilder<ScheduleLogic>(
      builder: (logic) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        if (logic.isLoading.value) {
          return Center(
            child: Card.filled(
              color: isDark ? Colors.grey.shade800 : Colors.white,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? Colors.blue.shade300 : Colors.blue.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '正在加载课表...',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '学期：${logic.selectedSemester.value?.nameZh ?? "加载中..."}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (logic.scheduleData.isEmpty || logic.errorMessage.isNotEmpty) {
          return Center(
            child: Card.filled(
              color: isDark ? Colors.grey.shade800 : Colors.orange.shade50,
              elevation: 0,
              margin: const EdgeInsets.all(32),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.orange.shade900.withValues(alpha: 0.3)
                            : Colors.orange.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 48,
                        color: isDark ? Colors.orange.shade300 : Colors.orange.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '暂无课表数据',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey.shade200 : Colors.orange.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      logic.errorMessage.isNotEmpty
                          ? logic.errorMessage.value
                          : '请检查网络连接或稍后重试',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey.shade400 : Colors.orange.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [Colors.blue.shade400, Colors.blue.shade600]
                              : [Colors.blue.shade500, Colors.blue.shade700],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? Colors.blue.shade400 : Colors.blue.shade600).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final logic = Get.find<ScheduleLogic>();
                          await logic.refreshData();
                        },
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text('重新加载', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return _buildScheduleTable(logic);
      },
    );
  }

  Widget _buildScheduleTable(ScheduleLogic logic) {
    return Obx(() {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;

      // 从scheduleData中获取课程数据
      final processedClasses = logic.processClasses();

      // 如果没有课程数据，显示空状态
      if (processedClasses.isEmpty) {
        return Center(
          child: Card.filled(
            color: isDark ? Colors.grey.shade800 : Colors.blue.shade50,
            elevation: 0,
            margin: const EdgeInsets.all(32),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.blue.shade900.withValues(alpha: 0.3)
                          : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.calendar_today_outlined,
                      size: 48,
                      color: isDark ? Colors.blue.shade300 : Colors.blue.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '暂无课程安排',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade200 : Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '请选择其他学期或周数查看',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey.shade400 : Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      final timeKeys = _sortTimeSlotsByTime(processedClasses.keys.toList());

      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Card(
          margin: const EdgeInsets.all(8),
          elevation: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 表头
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Colors.grey.shade700, Colors.grey.shade600]
                        : [Colors.blue.shade500, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60.0,
                      child: _buildHeaderCell('第${logic.selectedWeek.value}周', isDark),
                    ),
                    ...List.generate(7, (index) => Expanded(
                      child: _buildHeaderCell(
                        '${['周一', '周二', '周三', '周四', '周五', '周六', '周日'][index]}\n${_getWeekdayDate(index + 1, logic)}',
                        isDark
                      ),
                    )),
                  ],
                ),
              ),
              // 课程表内容
              _buildScheduleGrid(timeKeys, processedClasses, logic, isDark),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildScheduleGrid(List<String> timeKeys, Map<String, Map<String, List<Map<String, dynamic>>>> processedClasses, ScheduleLogic logic, bool isDark) {
    // 创建一个二维数组来跟踪哪些位置已被占用
    final List<List<bool>> occupiedPositions = List.generate(
      timeKeys.length,
      (index) => List.filled(7, false)
    );

    // 收集所有需要跨越显示的课程，包含位置信息
    final List<Map<String, dynamic>> spanningCoursesData = [];

    // 标记所有被课程跨越的位置并收集跨行课程
    for (int timeIndex = 0; timeIndex < timeKeys.length; timeIndex++) {
      final timeKey = timeKeys[timeIndex];
      final weekdays = processedClasses[timeKey]!;

      for (int weekdayIndex = 0; weekdayIndex < 7; weekdayIndex++) {
        final weekday = '周${weekdayIndex + 1}';
        final classes = weekdays[weekday] ?? [];

        if (classes.isNotEmpty) {
          final mainCourse = classes.firstWhere(
            (c) => !(c['isOccupied'] ?? false),
            orElse: () => {},
          );

          if (mainCourse.isNotEmpty) {
            final spanCount = (mainCourse['spanCount'] as int?) ?? 1;
            final originalStartIndex = (mainCourse['originalStartIndex'] as int?) ?? timeIndex;

            // 如果这是课程的起始时间段
            if (originalStartIndex == timeIndex && spanCount > 1) {
              // 标记跨越的位置
              for (int i = 0; i < spanCount && (timeIndex + i) < timeKeys.length; i++) {
                occupiedPositions[timeIndex + i][weekdayIndex] = true;
              }

              // 存储课程数据
              spanningCoursesData.add({
                'course': mainCourse,
                'weekdayIndex': weekdayIndex,
                'timeIndex': timeIndex,
                'spanCount': spanCount,
              });
            }
          }
        }
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算每列的宽度
        final availableWidth = constraints.maxWidth - 60.0; // 减去时间列宽度
        final columnWidth = availableWidth / 7.0;

        // 创建跨行课程Widget
        final updatedSpanningCourses = spanningCoursesData.map((courseData) {
          final weekdayIndex = courseData['weekdayIndex'] as int;
          final timeIndex = courseData['timeIndex'] as int;
          final spanCount = courseData['spanCount'] as int;
          final course = courseData['course'] as Map<String, dynamic>;

          final cellHeight = spanCount * 80.0;
          final leftPosition = 60.0 + weekdayIndex * columnWidth;
          final topPosition = timeIndex * 80.0;

          return Positioned(
            left: leftPosition + 2,
            top: topPosition + 2,
            width: columnWidth - 4,
            height: cellHeight - 4,
            child: _buildClassCell([course], context, isDark),
          );
        }).toList();

        return SizedBox(
          width: double.infinity,
          child: Stack(
            children: [
              // 背景网格
              Column(
                children: timeKeys.asMap().entries.map((entry) {
                  final timeKey = entry.value;
                  final rowIndex = entry.key;
                  final weekdays = processedClasses[timeKey]!;
                  final isEvenRow = rowIndex % 2 == 0;

                  return Row(
                    children: [
                      // 时间列
                      SizedBox(
                        width: 60.0,
                        height: 80,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade700 : Colors.grey.shade50,
                            border: Border(
                              right: BorderSide(
                                color: isDark ? Colors.grey.shade600 : Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                          ),
                          child: _buildTimeCell(timeKey, logic, isDark),
                        ),
                      ),
                      // 周一到周日的背景格子
                      ...List.generate(7, (weekdayIndex) {
                        final weekday = '周${weekdayIndex + 1}';
                        final classes = weekdays[weekday] ?? [];

                        // 检查是否有非跨行课程
                        final hasNonSpanningCourse = classes.any((c) =>
                          !(c['isOccupied'] ?? false) &&
                          ((c['spanCount'] as int?) ?? 1) == 1
                        );

                        return Expanded(
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: isDark && weekdayIndex % 2 == 0
                                  ? Colors.grey.shade800.withValues(alpha: 0.2)
                                  : (isEvenRow && !isDark ? Colors.grey.shade50 : null),
                              border: Border(
                                right: weekdayIndex < 6 ? BorderSide(
                                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                                  width: 1,
                                ) : BorderSide.none,
                                bottom: BorderSide(
                                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: hasNonSpanningCourse
                                ? _buildSingleClassCell(classes, isDark)
                                : null,
                          ),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
              // 跨行课程覆盖层
              ...updatedSpanningCourses,
            ],
          ),
        );
      },
    );
  }

  Widget _buildSingleClassCell(List<Map<String, dynamic>> classes, bool isDark) {
    final mainCourse = classes.isNotEmpty && !(classes.first['isOccupied'] ?? false) ? classes.first : null;

    if (mainCourse == null) return const SizedBox.shrink();

    return _buildClassCell([mainCourse], context, isDark);
  }

  Widget _buildHeaderCell(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.2),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // 根据周数和星期几获取日期
  String _getWeekdayDate(int weekday, ScheduleLogic logic) {
    if (logic.currentSemesterInfo.value == null) {
      return '';
    }

    final startDate = DateTime.parse(logic.currentSemesterInfo.value!.startDate);
    final selectedWeek = logic.selectedWeek.value;

    // 计算目标日期：学期开始日期 + (selectedWeek-1)周 + (weekday-1)天
    final targetDate = startDate.add(Duration(days: (selectedWeek - 1) * 7 + (weekday - 1)));

    return '${targetDate.month}/${targetDate.day}';
  }

  // 根据时间对时间段进行排序
  List<String> _sortTimeSlotsByTime(List<String> timeSlots) {
    // 新的时间段格式为：序号\n时间-时间
    // 按时间段序号排序
    timeSlots.sort((a, b) {
      final partsA = a.split('\n');
      final partsB = b.split('\n');

      if (partsA.isNotEmpty && partsB.isNotEmpty) {
        // 优先按序号排序
        final periodA = int.tryParse(partsA[0]) ?? 999;
        final periodB = int.tryParse(partsB[0]) ?? 999;

        if (periodA != periodB) {
          return periodA.compareTo(periodB);
        }

        // 如果序号相同，按时间排序
        if (partsA.length > 1 && partsB.length > 1) {
          final timeA = partsA[1].split('-')[0];
          final timeB = partsB[1].split('-')[0];
          return _compareTimeStrings(timeA, timeB);
        }
      }

      return a.compareTo(b);
    });

    return timeSlots;
  }

  // 比较时间字符串
  int _compareTimeStrings(String timeA, String timeB) {
    final partsA = timeA.split(':');
    final partsB = timeB.split(':');

    if (partsA.length >= 2 && partsB.length >= 2) {
      final hourA = int.tryParse(partsA[0]) ?? 0;
      final minuteA = int.tryParse(partsA[1]) ?? 0;
      final hourB = int.tryParse(partsB[0]) ?? 0;
      final minuteB = int.tryParse(partsB[1]) ?? 0;

      final totalMinutesA = hourA * 60 + minuteA;
      final totalMinutesB = hourB * 60 + minuteB;

      return totalMinutesA.compareTo(totalMinutesB);
    }

    return timeA.compareTo(timeB);
  }

  Widget _buildTimeCell(String timeSlot, ScheduleLogic logic, bool isDark) {
    final parts = timeSlot.split('\n');
    String displayText = timeSlot;

    // 新格式：序号\n时间-时间
    if (parts.length >= 2) {
      final period = parts[0];
      final timeRange = parts[1];
      // 将时间段拆分为开始和结束时间
      final times = timeRange.split('-');
      String timeDisplay = timeRange;
      if (times.length >= 2) {
        timeDisplay = '${times[0]}\n${times[1]}';
      }
      displayText = '$period\n$timeDisplay';
    }

    return Container(
      height: 80, // 固定高度
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Center(
        child: Text(
          displayText,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.grey.shade200 : Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildClassCell(List<Map<String, dynamic>> classes, BuildContext context, bool isDark) {
    if (classes.isEmpty) {
      return const SizedBox.shrink();
    }

    final classItem = classes.first;
    final isCurrentWeek = classItem['isCurrentWeek'] ?? true;
    final spanCount = (classItem['spanCount'] as int?) ?? 1;
    final courseName = classItem['courseName'] as String? ?? '未知课程';
    final roomName = classItem['roomName'] as String?;
    final courseStartTime = classItem['courseStartTime'] as String? ?? '';
    final courseEndTime = classItem['courseEndTime'] as String? ?? '';

    // 获取课程颜色
    final courseColor = _getCourseColor(courseName, isCurrentWeek, isDark);

    return Card.filled(
      margin: const EdgeInsets.all(1),
      elevation: isCurrentWeek ? 3 : 1,
      color: isCurrentWeek
          ? courseColor.withValues(alpha: 0.9)
          : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isCurrentWeek
              ? courseColor
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showClassDetails(context, classItem, Get.find<ScheduleLogic>(), isDark),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  courseName,
                  style: TextStyle(
                    fontSize: spanCount > 1 ? 13 : 11,
                    fontWeight: FontWeight.w700,
                    color: isCurrentWeek
                        ? (isDark ? Colors.white : Colors.white)
                        : (isDark ? Colors.grey.shade200 : Colors.grey.shade700),
                  ),
                  textAlign: TextAlign.left,
                  maxLines: spanCount > 1 ? 4 : 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (roomName != null) ...[
                const SizedBox(height: 2),
                Text(
                  roomName,
                  style: TextStyle(
                    fontSize: spanCount > 1 ? 10 : 8,
                    color: isCurrentWeek
                        ? (isDark ? Colors.white.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.85))
                        : (isDark ? Colors.grey.shade300 : Colors.grey.shade600),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (courseStartTime.isNotEmpty && courseEndTime.isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(
                  '$courseStartTime-$courseEndTime',
                  style: TextStyle(
                    fontSize: 7,
                    color: isCurrentWeek
                        ? (isDark ? Colors.white.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.75))
                        : (isDark ? Colors.grey.shade400 : Colors.grey.shade500),
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.left,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showClassDetails(BuildContext context, Map<String, dynamic> classItem, ScheduleLogic logic, bool isDark) {
    final courseName = classItem['courseName'] as String? ?? '课程详情';
    final teacherName = classItem['teacherName'] as String? ?? '未知';
    final roomName = classItem['roomName'] as String? ?? '未知';
    final courseStartTime = classItem['courseStartTime'] as String? ?? '';
    final courseEndTime = classItem['courseEndTime'] as String? ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: isDark ? Colors.blue.shade700 : Colors.blue.shade100,
                child: Icon(
                  Icons.school,
                  color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  courseName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          content: Card.filled(
            color: isDark ? Colors.grey.shade700.withValues(alpha: 0.5) : Colors.grey.shade50,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.person, size: 20, color: isDark ? Colors.grey.shade300 : Colors.grey.shade600),
                  title: Text('教师', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade200 : Colors.grey.shade700)),
                  subtitle: Text(teacherName, style: TextStyle(color: isDark ? Colors.grey.shade100 : Colors.black87)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                ),
                if (roomName != '未知') ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.location_on, size: 20, color: isDark ? Colors.grey.shade300 : Colors.grey.shade600),
                    title: Text('教室', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade200 : Colors.grey.shade700)),
                    subtitle: Text(roomName, style: TextStyle(color: isDark ? Colors.grey.shade100 : Colors.black87)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                ],
                if (courseStartTime.isNotEmpty && courseEndTime.isNotEmpty) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.schedule, size: 20, color: isDark ? Colors.grey.shade300 : Colors.grey.shade600),
                    title: Text('时间', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade200 : Colors.grey.shade700)),
                    subtitle: Text('$courseStartTime - $courseEndTime', style: TextStyle(color: isDark ? Colors.grey.shade100 : Colors.black87)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.blue.shade400, Colors.blue.shade600]
                      : [Colors.blue.shade500, Colors.blue.shade700],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.blue.shade400 : Colors.blue.shade600).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
                label: const Text('关闭', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 构建学期和周数选择区域
  Widget _buildSelectionArea() {
    return GetBuilder<ScheduleLogic>(
      builder: (logic) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          margin: const EdgeInsets.all(8),
          child: Row(
            children: [
              // 学期选择
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Card.filled(
                    color: isDark ? Colors.grey.shade800 : Colors.blue.shade50,
                    elevation: 0,
                    child: InkWell(
                      onTap: () => _showSemesterSelector(context, logic),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isDark ? Colors.blue.shade600 : Colors.blue.shade500,
                              radius: 20,
                              child: const Icon(
                                Icons.school,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '学期',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.grey.shade400 : Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Obx(() {
                                          if (logic.allSemesters.isEmpty) {
                                            return Text(
                                              '加载中...',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? Colors.white : Colors.blue.shade900,
                                              ),
                                            );
                                          }
                                          return Text(
                                            logic.selectedSemester.value?.nameZh ?? '选择学期',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white : Colors.blue.shade900,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: isDark ? Colors.blue.shade400 : Colors.blue.shade600,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 周数选择
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Card.filled(
                    color: isDark ? Colors.grey.shade800 : Colors.green.shade50,
                    elevation: 0,
                    child: InkWell(
                      onTap: () => _showWeekSelector(context, logic),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isDark ? Colors.green.shade600 : Colors.green.shade500,
                              radius: 20,
                              child: const Icon(
                                Icons.calendar_today,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '周数',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.grey.shade400 : Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Obx(() {
                                          if (logic.availableWeeks.isEmpty) {
                                            return Text(
                                              '暂无周数',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? Colors.white : Colors.green.shade900,
                                              ),
                                            );
                                          }
                                          return Text(
                                            '第${logic.selectedWeek.value}周',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white : Colors.green.shade900,
                                            ),
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: isDark ? Colors.green.shade400 : Colors.green.shade600,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 显示学期选择器
  void _showSemesterSelector(BuildContext context, ScheduleLogic logic) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [Colors.blue.shade700, Colors.blue.shade800]
                          : [Colors.blue.shade500, Colors.blue.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.school,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '选择学期',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Obx(() {
                    if (logic.allSemesters.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: logic.allSemesters.length,
                      itemBuilder: (context, index) {
                        final semester = logic.allSemesters[index];
                        final isSelected = logic.selectedSemester.value?.id == semester.id;

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          elevation: isSelected ? 4 : 1,
                          color: isSelected
                              ? (isDark ? Colors.blue.shade700 : Colors.blue.shade100)
                              : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isSelected
                                  ? (isDark ? Colors.blue.shade500 : Colors.blue.shade600)
                                  : (isDark ? Colors.grey.shade600 : Colors.grey.shade300),
                              child: Icon(
                                Icons.calendar_today,
                                color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade600),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              semester.nameZh,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? (isDark ? Colors.white : Colors.blue.shade900)
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                            subtitle: Text(
                              semester.nameEn,
                              style: TextStyle(
                                color: isSelected
                                    ? (isDark ? Colors.blue.shade100 : Colors.blue.shade700)
                                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                              ),
                            ),
                            onTap: () async {
                              Navigator.of(context).pop();
                              await logic.selectSemester(semester);
                            },
                          ),
                        );
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // 显示周数选择器
  void _showWeekSelector(BuildContext context, ScheduleLogic logic) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 450),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [Colors.green.shade700, Colors.green.shade800]
                          : [Colors.green.shade500, Colors.green.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '选择周数',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Obx(() {
                    if (logic.availableWeeks.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 48,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '暂无可选周数',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: logic.availableWeeks.length,
                      itemBuilder: (context, index) {
                        final week = logic.availableWeeks[index];
                        final isSelected = logic.selectedWeek.value == week;

                        return Card(
                          elevation: isSelected ? 6 : 2,
                          color: isSelected
                              ? (isDark ? Colors.green.shade600 : Colors.green.shade500)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isSelected
                                ? BorderSide(color: isDark ? Colors.green.shade400 : Colors.green.shade300, width: 2)
                                : BorderSide.none,
                          ),
                          child: InkWell(
                            onTap: () async {
                              Navigator.of(context).pop();
                              await logic.selectWeek(week);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: isSelected
                                  ? BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: LinearGradient(
                                        colors: isDark
                                            ? [Colors.green.shade500, Colors.green.shade600]
                                            : [Colors.green.shade400, Colors.green.shade500],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    )
                                  : null,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '第$week周',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark ? Colors.white : Colors.black87),
                                      ),
                                    ),
                                    if (logic.currentSemesterInfo.value != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        _getWeekDates(week, logic.currentSemesterInfo.value!),
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: isSelected
                                              ? Colors.white.withValues(alpha: 0.8)
                                              : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // 获取周数对应的日期范围
  String _getWeekDates(int week, CurrentSemesterInfo semesterInfo) {
    final startDate = DateTime.parse(semesterInfo.startDate);
    final weekStart = startDate.add(Duration(days: (week - 1) * 7));
    final weekEnd = weekStart.add(const Duration(days: 6));

    return '${weekStart.month}/${weekStart.day}-${weekEnd.month}/${weekEnd.day}';
  }

  // 简单的课程颜色生成方法
  Color _getCourseColor(String courseName, bool isCurrentWeek, bool isDark) {
    // 预设的课程颜色列表（蓝色系）
    final colors = [
      const Color(0xFF2196F3), // Blue
      const Color(0xFF1976D2), // Blue Dark
      const Color(0xFF42A5F5), // Blue Light
      const Color(0xFF1E88E5), // Blue Accent
      const Color(0xFF1565C0), // Blue Darker
    ];

    // 根据课程名称计算颜色索引
    int hash = courseName.hashCode.abs();
    int colorIndex = hash % colors.length;
    Color baseColor = colors[colorIndex];

    // 如果不是本周，调暗颜色
    if (!isCurrentWeek) {
      return isDark
          ? baseColor.withValues(alpha: 0.6)
          : baseColor.withValues(alpha: 0.7);
    }

    return baseColor;
  }
}
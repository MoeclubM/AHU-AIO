import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'schedule_logic.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final ScheduleLogic logic = Get.put(ScheduleLogic());
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // 初始化ScheduleLogic
    Get.put(ScheduleLogic());
    _loadInitialData();
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
          title: Text(
            '课程表',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: isDark ? Colors.grey.shade800 : Colors.blue.shade600,
          elevation: 0,
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.grey.shade800, Colors.grey.shade700]
                    : [Colors.blue.shade600, Colors.blue.shade700],
                ),
              ),
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
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
              ],
            ),
          ),
        );
    }

    return GetBuilder<ScheduleLogic>(
      builder: (logic) {
        return Scaffold(
          backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
          appBar: AppBar(
            title: Text(
              '课程表',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: isDark ? Colors.grey.shade800 : Colors.blue.shade600,
            elevation: 0,
            centerTitle: true,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.grey.shade800, Colors.grey.shade700]
                      : [Colors.blue.shade600, Colors.blue.shade700],
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              // 学期和周数选择区域
              _buildSelectionArea(),
              // 课表内容区域
              Expanded(
                child: _buildScheduleContent(),
              ),
            ],
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
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
              ],
            ),
          );
        }

        if (logic.scheduleData.isEmpty || logic.errorMessage.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.orange.shade900.withValues(alpha: 0.3) : Colors.orange.shade50,
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
                          color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        logic.errorMessage.isNotEmpty
                            ? logic.errorMessage.value
                            : '请检查网络连接或稍后重试',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
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
              ],
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
          child: Card(
            margin: const EdgeInsets.all(16),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_note,
                    size: 64,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无课程数据',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade200 : Colors.grey.shade700,
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
                      width: 60.0, // 减少宽度
                      child: _buildHeaderCell('第${logic.selectedWeek.value}周', isDark),
                    ),
                    ...List.generate(7, (index) => Expanded(
                      child: _buildHeaderCell(
                        ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][index] +
                        '\n${_getWeekdayDate(index + 1, logic)}',
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
                        width: 60.0, // 减少宽度
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
            fontSize: 12, // 进一步增大字号
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

    return Card(
      margin: const EdgeInsets.all(1), // 减少边距给文字更多空间
      elevation: isCurrentWeek ? 3 : 1,
      color: isCurrentWeek
          ? (isDark ? Colors.blue.shade700 : Colors.blue.shade100)
          : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6), // 减小圆角
        side: BorderSide(
          color: isCurrentWeek
              ? (isDark ? Colors.blue.shade500 : Colors.blue.shade300)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showClassDetails(context, classItem, Get.find<ScheduleLogic>(), isDark),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4), // 减少内边距
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start, // 从顶部开始
            crossAxisAlignment: CrossAxisAlignment.start, // 左对齐
            children: [
              Flexible(
                child: Text(
                  courseName,
                  style: TextStyle(
                    fontSize: spanCount > 1 ? 13 : 11, // 进一步增大字号
                    fontWeight: FontWeight.w700,
                    color: isCurrentWeek
                        ? (isDark ? Colors.white : Colors.blue.shade900)
                        : (isDark ? Colors.grey.shade200 : Colors.grey.shade700),
                  ),
                  textAlign: TextAlign.left, // 左对齐
                  maxLines: spanCount > 1 ? 4 : 3, // 增加最大行数
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (roomName != null) ...[
                const SizedBox(height: 2),
                Text(
                  roomName,
                  style: TextStyle(
                    fontSize: spanCount > 1 ? 10 : 8, // 增大教室名称字号
                    color: isCurrentWeek
                        ? (isDark ? Colors.blue.shade100 : Colors.blue.shade700)
                        : (isDark ? Colors.grey.shade300 : Colors.grey.shade600),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.left,
                  maxLines: 2, // 允许教室名称换行
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (courseStartTime.isNotEmpty && courseEndTime.isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(
                  '$courseStartTime-$courseEndTime',
                  style: TextStyle(
                    fontSize: 6,
                    color: isCurrentWeek
                        ? (isDark ? Colors.blue.shade200 : Colors.blue.shade600)
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: isDark ? Colors.grey.shade700.withValues(alpha: 0.5) : Colors.grey.shade50,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.person, size: 20, color: isDark ? Colors.grey.shade300 : Colors.grey.shade600),
                      title: Text('教师', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade200 : Colors.grey.shade700)),
                      subtitle: Text(teacherName, style: TextStyle(color: isDark ? Colors.grey.shade100 : Colors.black87)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.location_on, size: 20, color: isDark ? Colors.grey.shade300 : Colors.grey.shade600),
                      title: Text('教室', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade200 : Colors.grey.shade700)),
                      subtitle: Text(roomName, style: TextStyle(color: isDark ? Colors.grey.shade100 : Colors.black87)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    ),
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: isDark ? Colors.blue.shade600 : Colors.blue.shade500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '关闭',
                style: TextStyle(fontWeight: FontWeight.w600),
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // 学期选择
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700.withValues(alpha: 0.5) : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.blue.shade600 : Colors.blue.shade500,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.school, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '学期',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey.shade200 : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Obx(() {
                          if (logic.allSemesters.isEmpty) {
                            return Text(
                              '加载中...',
                              style: TextStyle(
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                              ),
                            );
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade600 : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark ? Colors.grey.shade500 : Colors.grey.shade300,
                              ),
                            ),
                            child: DropdownButton<int>(
                              value: logic.selectedSemester.value?.id,
                              isExpanded: true,
                              underline: Container(),
                              dropdownColor: isDark ? Colors.grey.shade700 : Colors.white,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              items: logic.allSemesters.map((semester) {
                                return DropdownMenuItem<int>(
                                  value: semester.id,
                                  child: Text(semester.nameZh, style: const TextStyle(fontSize: 12)),
                                );
                              }).toList(),
                              onChanged: (int? semesterId) {
                                if (semesterId != null) {
                                  final semester = logic.allSemesters.firstWhereOrNull(
                                    (s) => s.id == semesterId,
                                  );
                                  if (semester != null) {
                                    logic.selectSemester(semester);
                                  }
                                }
                              },
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 周数选择
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.green.shade900.withValues(alpha: 0.3) : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.green.shade600 : Colors.green.shade500,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '周数',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey.shade200 : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Obx(() {
                          if (logic.availableWeeks.isEmpty) {
                            return Text(
                              '暂无周数信息',
                              style: TextStyle(
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                              ),
                            );
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade600 : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark ? Colors.grey.shade500 : Colors.grey.shade300,
                              ),
                            ),
                            child: DropdownButton<int>(
                              value: logic.selectedWeek.value,
                              isExpanded: true,
                              underline: Container(),
                              dropdownColor: isDark ? Colors.grey.shade700 : Colors.white,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              items: logic.availableWeeks.map((week) {
                                return DropdownMenuItem<int>(
                                  value: week,
                                  child: Text('第$week周', style: const TextStyle(fontSize: 12)),
                                );
                              }).toList(),
                              onChanged: (int? week) {
                                if (week != null) {
                                  logic.selectWeek(week);
                                }
                              },
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
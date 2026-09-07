import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/getallsemesters.dart';
import '../utils/time_utils.dart';
import 'schedule_logic.dart';
import 'schedule_service.dart';

class SchedulePage extends StatefulWidget {
  final bool embed;
  const SchedulePage({super.key, this.embed = false});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  late final ScheduleLogic _logic;
  double _slotHeight = 50.0;
  double _baseScaleSlotHeight = 50.0;
  bool _isManualScaled = false;
  static const _weekdays = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  @override
  void initState() {
    super.initState();
    _logic = Get.put(ScheduleLogic());
    _loadSavedHeight();
  }

  Future<void> _loadSavedHeight() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedHeight = prefs.getDouble('jwapp_schedule_slot_height_v2');
      if (savedHeight != null) {
        setState(() {
          _slotHeight = savedHeight;
          _baseScaleSlotHeight = savedHeight;
          _isManualScaled = true;
        });
      }
    } catch (_) {}
  }

  /// 自动计算契合屏幕视口高度的节次高度（避免纵向过度拉长）
  double _getEffectiveSlotHeight(BuildContext context) {
    if (_isManualScaled) return _slotHeight;
    final screenH = MediaQuery.sizeOf(context).height;
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    // 自动适配屏幕：扣除状态栏、顶栏/AppBar、学期选择下拉框、表头以及底部两排导航栏 (约 225px)
    final available = screenH - topPadding - bottomPadding - 225;
    if (available > 0) {
      final calculated = available / 11;
      return calculated.clamp(44.0, 68.0);
    }
    return 48.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embed
          ? null
          : AppBar(
              toolbarHeight: 52,
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              flexibleSpace: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: MediaQuery.highContrastOf(context) ? 0 : 12,
                        sigmaY: MediaQuery.highContrastOf(context) ? 0 : 12,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface
                              .withOpacity(
                                MediaQuery.highContrastOf(context)
                                    ? 0.96
                                    : 0.68,
                              ),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant
                                .withOpacity(
                                  MediaQuery.highContrastOf(context)
                                      ? 0.9
                                      : 0.5,
                                ),
                            width: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              title: const Text(
                '课程表',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
      body: Obx(() {
        final scheduleByDay = _logic.processClasses();
        final isLoading = _logic.isLoading.value;
        final errorText = _logic.errorMessage.value;
        final hasData = scheduleByDay.values.any(
          (entries) => entries.isNotEmpty,
        );

        return RefreshIndicator(
          onRefresh: _logic.refreshData,
          child: GestureDetector(
            onScaleStart: (details) {
              _baseScaleSlotHeight = _getEffectiveSlotHeight(context);
            },
            onScaleUpdate: (details) {
              final newHeight = (_baseScaleSlotHeight * details.verticalScale)
                  .clamp(40.0, 160.0);
              setState(() {
                _slotHeight = newHeight;
                _isManualScaled = true;
              });
              SharedPreferences.getInstance().then((prefs) {
                prefs.setDouble('jwapp_schedule_slot_height_v2', newHeight);
              });
            },
            onDoubleTap: () {
              // 双击快速恢复为自适应全览高度
              setState(() {
                _isManualScaled = false;
              });
              SharedPreferences.getInstance().then((prefs) {
                prefs.remove('jwapp_schedule_slot_height_v2');
              });
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  Obx(() {
                    if (_logic.isCached.value) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 16,
                        ),
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withOpacity(0.7),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '当前为本地缓存数据，正在加载最新数据...',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  _buildSelectionArea(isLoading),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: LinearProgressIndicator(),
                    ),
                  if (errorText.isNotEmpty) _buildErrorNotice(errorText),
                  if (!isLoading && errorText.isEmpty && !hasData)
                    _buildEmptyNotice(),
                  if (hasData) _buildScheduleTable(scheduleByDay),
                  const SizedBox(height: 148),
                ],
              ),
            ),
          ),
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Obx(() {
        final isLoading = _logic.isLoading.value;
        final hasData = _logic.processClasses().values.any(
          (entries) => entries.isNotEmpty,
        );
        return isLoading || !hasData
            ? const SizedBox.shrink()
            : _buildFloatingWeekSelector();
      }),
    );
  }

  Widget _buildFloatingWeekSelector() {
    final selectedWeek = _logic.selectedWeek.value;
    final highContrast = MediaQuery.highContrastOf(context);
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 148),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: highContrast ? 0 : 14,
              sigmaY: highContrast ? 0 : 14,
            ),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: highContrast
                    ? colorScheme.surface.withOpacity(0.96)
                    : Colors.black.withOpacity(0.22),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: highContrast
                      ? colorScheme.outline
                      : Colors.white.withOpacity(0.35),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    color: highContrast ? colorScheme.onSurface : Colors.white,
                    onPressed: selectedWeek > 1
                        ? () => _logic.selectWeek(selectedWeek - 1)
                        : null,
                  ),
                  GestureDetector(
                    onTap: _showWeekPicker,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 96),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.center,
                      child: Text(
                        '第 $selectedWeek 周',
                        style:
                            const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ).copyWith(
                              color: highContrast
                                  ? colorScheme.onSurface
                                  : Colors.white,
                            ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    color: highContrast ? colorScheme.onSurface : Colors.white,
                    onPressed: selectedWeek < 20
                        ? () => _logic.selectWeek(selectedWeek + 1)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showWeekPicker() async {
    final currentWeek = _logic.selectedWeek.value;
    final realCurrent = _logic.realCurrentWeek;
    final selectedWeek = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).viewPadding.bottom;
        return Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(20, (index) {
              final week = index + 1;
              final isSelected = week == currentWeek;
              final isRealCurrent = week == realCurrent;
              return ChoiceChip(
                avatar: isRealCurrent
                    ? Icon(
                        Icons.star,
                        size: 14,
                        color: isSelected
                            ? Theme.of(ctx).colorScheme.onPrimary
                            : Theme.of(ctx).colorScheme.primary,
                      )
                    : null,
                label: Text(
                  isRealCurrent ? '第 $week 周(本周)' : '第 $week 周',
                  style: TextStyle(
                    fontWeight: isRealCurrent
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => Navigator.pop(ctx, week),
              );
            }),
          ),
        );
      },
    );

    if (selectedWeek != null && mounted) {
      _logic.selectWeek(selectedWeek);
    }
  }

  Widget _buildSelectionArea(bool isLoading) {
    final semesters = _logic.allSemesters.toList();
    final selectedSemester = _logic.selectedSemester.value;

    final semesterValue = semesters.firstWhereOrNull(
      (semester) => semester.id == selectedSemester?.id,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withOpacity(0.5),
            width: 0.5,
          ),
        ),
      ),
      child: DropdownButton<SemesterInfo>(
        value: semesterValue,
        isExpanded: true,
        hint: const Text('请选择学期'),
        onChanged: isLoading
            ? null
            : (value) {
                if (value != null) {
                  _logic.selectSemester(value);
                }
              },
        items: semesters
            .map(
              (semester) => DropdownMenuItem<SemesterInfo>(
                value: semester,
                child: Text(semester.nameZh),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildErrorNotice(String message) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('加载课表失败', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _logic.refreshData(),
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyNotice() {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('本周暂无课程', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('请选择其他周次或稍后再试。', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  /// 构建 WakeUp 风格的连续时间轴与纵向长条课程表
  Widget _buildScheduleTable(Map<int, List<ScheduleEntry>> scheduleByDay) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final slotHeight = _getEffectiveSlotHeight(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const timeColWidth = 38.0;
        final dayWidth = (totalWidth - timeColWidth) / 7;

        return Column(
          children: [
            // 1. 顶部表头：月份 + 周一至周日及日期 (当天高亮加深)
            _buildHeader(theme, dayWidth, timeColWidth),
            // 2. 连续 1..11 节次时间轴 + 7 列纵向长条卡片网格 (自适应视口高度)
            _buildTimelineGrid(
              scheduleByDay,
              dayWidth,
              timeColWidth,
              slotHeight,
              theme,
              isDark,
            ),
          ],
        );
      },
    );
  }

  /// 构建顶部星期与日期行 (WakeUp 经典表头)
  Widget _buildHeader(ThemeData theme, double dayWidth, double timeColWidth) {
    final selectedWeek = _logic.selectedWeek.value;
    final startDate = _logic.semesterStartDate;
    final realCurrentWeek = _logic.realCurrentWeek;
    final isDark = theme.brightness == Brightness.dark;

    DateTime? mondayDate;
    if (startDate != null) {
      final daysOffset = (selectedWeek - 1) * 7;
      mondayDate = startDate.add(Duration(days: daysOffset));
    }

    final int month = mondayDate?.month ?? DateTime.now().month;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.45),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          // 左上角月份指示
          Container(
            width: timeColWidth,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                  width: 0.6,
                ),
              ),
            ),
            child: Text(
              '$month\n月',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.15,
              ),
            ),
          ),
          // 周一至周日 7 列
          ...List.generate(7, (i) {
            final weekday = i + 1;
            final dayDate = mondayDate?.add(Duration(days: i));
            final isToday = DateTime.now().weekday == weekday &&
                selectedWeek == realCurrentWeek;

            return Container(
              width: dayWidth,
              height: 48,
              decoration: BoxDecoration(
                color: isToday
                    ? (isDark
                        ? theme.colorScheme.primary.withOpacity(0.24)
                        : theme.colorScheme.primary.withOpacity(0.18))
                    : null,
                border: Border(
                  right: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(isToday ? 0.65 : 0.4),
                    width: isToday ? 0.8 : 0.5,
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekdays[weekday],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                      color: isToday
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (dayDate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: isToday
                          ? BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(0.35),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            )
                          : null,
                      child: Text(
                        '${dayDate.day}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isToday ? FontWeight.bold : FontWeight.normal,
                          color: isToday
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant.withOpacity(
                                  0.75,
                                ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 构建连续作息时间网格与纵向长条课程
  Widget _buildTimelineGrid(
    Map<int, List<ScheduleEntry>> scheduleByDay,
    double dayWidth,
    double timeColWidth,
    double slotHeight,
    ThemeData theme,
    bool isDark,
  ) {
    const totalSlots = 11;
    final totalHeight = totalSlots * slotHeight;
    final selectedWeek = _logic.selectedWeek.value;
    final realCurrentWeek = _logic.realCurrentWeek;

    return SizedBox(
      height: totalHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧连续时间轴 (1..11 节)
          Container(
            width: timeColWidth,
            height: totalHeight,
            decoration: BoxDecoration(
              color: theme.cardColor.withOpacity(0.7),
              border: Border(
                right: BorderSide(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.45),
                  width: 0.8,
                ),
              ),
            ),
            child: Column(
              children: List.generate(totalSlots, (idx) {
                final slot = idx + 1;
                final startTime =
                    TimeUtils.standardUnitStartTimes[slot] ?? '';

                return Container(
                  height: slotHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: (slot == 4 || slot == 8)
                            ? theme.colorScheme.primary.withOpacity(0.55)
                            : theme.colorScheme.outlineVariant.withOpacity(0.45),
                        width: (slot == 4 || slot == 8) ? 1.2 : 0.6,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$slot',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        startTime,
                        style: TextStyle(
                          fontSize: 8.0,
                          color: theme.colorScheme.onSurfaceVariant
                              .withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),

          // 右侧周一至周日 7 列网格
          ...List.generate(7, (dayIdx) {
            final weekday = dayIdx + 1;
            final entries = scheduleByDay[weekday] ?? [];
            final isToday = DateTime.now().weekday == weekday &&
                selectedWeek == realCurrentWeek;

            return Container(
              width: dayWidth,
              height: totalHeight,
              decoration: BoxDecoration(
                color: isToday
                    ? (isDark
                        ? theme.colorScheme.primary.withOpacity(0.14)
                        : theme.colorScheme.primary.withOpacity(0.10))
                    : null,
                border: Border(
                  right: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(isToday ? 0.65 : 0.45),
                    width: isToday ? 0.8 : 0.6,
                  ),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 背景每节分割线（加深明显）
                  ...List.generate(totalSlots, (slotIdx) {
                    final slot = slotIdx + 1;
                    return Positioned(
                      top: slotIdx * slotHeight,
                      left: 0,
                      right: 0,
                      height: slotHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: (slot == 4 || slot == 8)
                                  ? (isToday
                                      ? theme.colorScheme.primary.withOpacity(0.7)
                                      : theme.colorScheme.primary.withOpacity(0.5))
                                  : theme.colorScheme.outlineVariant
                                      .withOpacity(isToday ? 0.5 : 0.4),
                              width: (slot == 4 || slot == 8) ? 1.2 : 0.6,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  // 纵向长条课程卡片
                  ...entries.map((entry) {
                    final start =
                        entry.effectiveStartUnit.clamp(1, totalSlots);
                    final end = entry.effectiveEndUnit.clamp(start, totalSlots);
                    final span = (end - start + 1).clamp(1, totalSlots);
                    final top = (start - 1) * slotHeight + 1.5;
                    final cardHeight =
                        (span * slotHeight - 3.0).clamp(24.0, double.infinity);

                    return Positioned(
                      top: top,
                      left: 1.5,
                      right: 1.5,
                      height: cardHeight,
                      child: _buildWakeUpCourseCard(
                        entry,
                        span,
                        theme,
                        isDark,
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 构建纵向长条课程卡片 (WakeUp 经典风格)
  Widget _buildWakeUpCourseCard(
    ScheduleEntry entry,
    int span,
    ThemeData theme,
    bool isDark,
  ) {
    final bg = _getCourseBgColor(entry.courseName, isDark);
    final textColor = _getCourseTextColor(entry.courseName, isDark);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showCourseDetailsModal(entry, context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 3.5, vertical: 4.0),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: textColor.withOpacity(isDark ? 0.35 : 0.22),
              width: 0.6,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 课程名称 (根据跨节长度自适应行数)
              Text(
                entry.courseName,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  height: 1.15,
                ),
                maxLines: span >= 3 ? 5 : (span >= 2 ? 3 : 2),
                overflow: TextOverflow.ellipsis,
              ),
              if (entry.roomName.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  '@ ${entry.roomName}',
                  style: TextStyle(
                    fontSize: 9.0,
                    fontWeight: FontWeight.w500,
                    color: textColor.withOpacity(0.85),
                    height: 1.1,
                  ),
                  maxLines: span >= 3 ? 3 : (span >= 2 ? 2 : 1),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (span >= 2 && entry.teacherName.isNotEmpty) ...[
                const SizedBox(height: 1.5),
                Text(
                  entry.teacherName,
                  style: TextStyle(
                    fontSize: 8.5,
                    color: textColor.withOpacity(0.7),
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 点击长条卡片弹出详细信息底栏
  void _showCourseDetailsModal(ScheduleEntry entry, BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bg = _getCourseBgColor(entry.courseName, isDark);
    final textColor = _getCourseTextColor(entry.courseName, isDark);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Material(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4.5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2.25),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: textColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          '${entry.effectiveStartUnit}-${entry.effectiveEndUnit}节',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (entry.isHonorCourse) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '荣誉课程',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    entry.courseName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem(
                    Icons.place_outlined,
                    '上课教室',
                    entry.roomName,
                  ),
                  _buildDetailItem(
                    Icons.person_outline,
                    '任课教师',
                    entry.teacherName,
                  ),
                  _buildDetailItem(
                    Icons.access_time,
                    '具体时间',
                    '${entry.startTime} - ${entry.endTime}',
                  ),
                  _buildDetailItem(
                    Icons.calendar_today_outlined,
                    '星期与周次',
                    '${_weekdays[entry.weekday]} · 第${_logic.selectedWeek.value}周',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Text(
            '$title: ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCourseBgColor(String name, bool isDark) {
    final hash = name.hashCode.abs();
    final lightColors = [
      const Color(0xFFE8F0FE),
      const Color(0xFFE6F4EA),
      const Color(0xFFFEF7E0),
      const Color(0xFFFCE8E6),
      const Color(0xFFF3E8FD),
      const Color(0xFFE0F2F1),
      const Color(0xFFFFF0F5),
      const Color(0xFFEFEBE9),
      const Color(0xFFE1F5FE),
      const Color(0xFFF9FBE7),
    ];
    final darkColors = [
      const Color(0xFF1E3A5F),
      const Color(0xFF1B4332),
      const Color(0xFF4A3E1B),
      const Color(0xFF4A2028),
      const Color(0xFF38234D),
      const Color(0xFF1B3D3B),
      const Color(0xFF4A2A38),
      const Color(0xFF36322F),
      const Color(0xFF1E3747),
      const Color(0xFF363D1F),
    ];
    final list = isDark ? darkColors : lightColors;
    return list[hash % list.length];
  }

  Color _getCourseTextColor(String name, bool isDark) {
    final hash = name.hashCode.abs();
    final lightTextColors = [
      const Color(0xFF1A56DB),
      const Color(0xFF0D6832),
      const Color(0xFF946200),
      const Color(0xFFB42318),
      const Color(0xFF6B21A8),
      const Color(0xFF0E7090),
      const Color(0xFF9D174D),
      const Color(0xFF5D4037),
      const Color(0xFF0284C7),
      const Color(0xFF556B2F),
    ];
    final darkTextColors = [
      const Color(0xFF93C5FD),
      const Color(0xFF86EFAC),
      const Color(0xFFFDE047),
      const Color(0xFFFCA5A5),
      const Color(0xFFD8B4FE),
      const Color(0xFF67E8F9),
      const Color(0xFFF472B6),
      const Color(0xFFD7CCC8),
      const Color(0xFF7DD3FC),
      const Color(0xFFBEF264),
    ];
    final list = isDark ? darkTextColors : lightTextColors;
    return list[hash % list.length];
  }
}

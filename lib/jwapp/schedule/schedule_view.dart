import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  double _slotHeight = 80.0;
  double _baseScaleSlotHeight = 80.0;

  @override
  void initState() {
    super.initState();
    _logic = Get.put(ScheduleLogic());
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
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withOpacity(0.68),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withOpacity(0.5),
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
              _baseScaleSlotHeight = _slotHeight;
            },
            onScaleUpdate: (details) {
              setState(() {
                _slotHeight = (_baseScaleSlotHeight * details.verticalScale)
                    .clamp(50.0, 240.0);
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSelectionArea(bool isLoading) {
    final semesters = _logic.allSemesters.toList();
    final selectedSemester = _logic.selectedSemester.value;
    final weeks = _logic.availableWeeks.toList();
    final selectedWeek = _logic.selectedWeek.value;

    final semesterValue = semesters.firstWhereOrNull(
      (semester) => semester.id == selectedSemester?.id,
    );

    final weekValue = weeks.contains(selectedWeek) ? selectedWeek : null;

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
      child: Row(
        children: [
          Expanded(
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
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButton<int>(
              value: weekValue,
              isExpanded: true,
              hint: const Text('请选择周次'),
              onChanged: isLoading || weeks.isEmpty
                  ? null
                  : (value) {
                      if (value != null) {
                        _logic.selectWeek(value);
                      }
                    },
              items: weeks
                  .map(
                    (week) => DropdownMenuItem<int>(
                      value: week,
                      child: Text('第$week周'),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
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

  /// 构建课表表格
  Widget _buildScheduleTable(Map<int, List<ScheduleEntry>> scheduleByDay) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 收集所有时间段，构建节次表
    final timeSlots = _buildTimeSlots(scheduleByDay);

    if (timeSlots.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = constraints.maxWidth;
          const timeColumnWidth = 56.0;
          final courseColumnWidth = (tableWidth - timeColumnWidth) / 7;

          return Table(
            columnWidths: {
              0: const FixedColumnWidth(timeColumnWidth),
              for (var index = 1; index <= 7; index++)
                index: FixedColumnWidth(courseColumnWidth),
            },
            border: TableBorder(
              horizontalInside: BorderSide(
                color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                width: 0.5,
              ),
              verticalInside: BorderSide(
                color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                width: 0.5,
              ),
            ),
            children: [
              // 表头：时间 | 周一 | 周二 | ... | 周日
              _buildHeaderRow(theme, isDark),
              // 每个时间段一行
              ...timeSlots.map(
                (slot) => _buildTimeSlotRow(slot, scheduleByDay, theme, isDark),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 构建时间段列表
  List<_TimeSlot> _buildTimeSlots(Map<int, List<ScheduleEntry>> scheduleByDay) {
    final allSlots = <_TimeSlot>{};

    for (final entries in scheduleByDay.values) {
      for (final entry in entries) {
        allSlots.add(
          _TimeSlot(startTime: entry.startTime, endTime: entry.endTime),
        );
      }
    }

    final slots = allSlots.toList();

    // 按开始时间的分钟数排序，避免字符串比较问题（如 "8:00" vs "10:00"）
    slots.sort((a, b) {
      final aMinutes = TimeUtils.timeToMinutes(a.startTime);
      final bMinutes = TimeUtils.timeToMinutes(b.startTime);
      return aMinutes.compareTo(bMinutes);
    });

    return slots;
  }

  /// 构建表头行
  TableRow _buildHeaderRow(ThemeData theme, bool isDark) {
    final headerStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );
    final headerBgColor = isDark ? Colors.grey.shade800 : Colors.grey.shade100;

    final weekdays = ['时间', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    return TableRow(
      decoration: BoxDecoration(color: headerBgColor),
      children: weekdays.map((day) {
        return TableCell(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            alignment: Alignment.center,
            child: Text(day, style: headerStyle),
          ),
        );
      }).toList(),
    );
  }

  String _getSectionLabel(String start, String end) {
    final startMin = _timeToMinutes(start);
    if (startMin >= 460 && startMin <= 500) return '1-2节';
    if (startMin >= 580 && startMin <= 625) return '3-4节';
    if (startMin >= 820 && startMin <= 880) return '5-6节';
    if (startMin >= 940 && startMin <= 1000) return '7-8节';
    if (startMin >= 1090 && startMin <= 1160) return '9-10节';
    return '';
  }

  int _timeToMinutes(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        return hours * 60 + minutes;
      }
    } catch (_) {}
    return 0;
  }

  /// 构建时间段行
  TableRow _buildTimeSlotRow(
    _TimeSlot slot,
    Map<int, List<ScheduleEntry>> scheduleByDay,
    ThemeData theme,
    bool isDark,
  ) {
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    final timeStyle = theme.textTheme.labelSmall?.copyWith(
      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
      fontSize: 9,
    );
    final sectionLabel = _getSectionLabel(slot.startTime, slot.endTime);

    return TableRow(
      children: [
        // 时间列
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Container(
            constraints: BoxConstraints(minHeight: _slotHeight),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (sectionLabel.isNotEmpty) ...[
                  Text(sectionLabel, style: labelStyle),
                  const SizedBox(height: 2),
                ],
                Text(slot.startTime, style: timeStyle),
                Text('-', style: timeStyle),
                Text(slot.endTime, style: timeStyle),
              ],
            ),
          ),
        ),
        // 周一到周日的课程
        ...List.generate(7, (index) {
          final weekday = index + 1;
          final entries = scheduleByDay[weekday] ?? [];
          final matchingEntries = entries.where(
            (e) => e.startTime == slot.startTime && e.endTime == slot.endTime,
          );

          if (matchingEntries.isEmpty) {
            return TableCell(
              child: Container(
                constraints: BoxConstraints(minHeight: _slotHeight),
                padding: const EdgeInsets.all(2),
              ),
            );
          }

          return TableCell(
            child: _buildCourseCell(matchingEntries.toList(), theme, isDark),
          );
        }),
      ],
    );
  }

  Color _courseColor(String name) {
    const colors = [
      Color(0xFF2563EB),
      Color(0xFF059669),
      Color(0xFFEA580C),
      Color(0xFF7C3AED),
      Color(0xFF0891B2),
      Color(0xFFDB2777),
      Color(0xFF4F46E5),
    ];
    var sum = 0;
    for (final unit in name.codeUnits) {
      sum += unit;
    }
    return colors[sum % colors.length];
  }

  /// 构建课程单元格
  Widget _buildCourseCell(
    List<ScheduleEntry> entries,
    ThemeData theme,
    bool isDark,
  ) {
    final maxLines = _slotHeight > 100
        ? (_slotHeight / 22).floor().clamp(3, 12)
        : 3;
    return Container(
      constraints: BoxConstraints(minHeight: _slotHeight),
      padding: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: entries.map((entry) {
          final color = _courseColor(entry.courseName);
          final double alpha = entry.isCurrentWeek ? 0.13 : 0.04;
          final double borderAlpha = entry.isCurrentWeek ? 0.45 : 0.15;

          return Container(
            width: double.infinity,
            margin: entries.length > 1
                ? const EdgeInsets.only(bottom: 2)
                : null,
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(alpha),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: color.withOpacity(borderAlpha),
                width: entry.isCurrentWeek ? 1.2 : 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 课程名称
                Text(
                  entry.courseName,
                  style: TextStyle(
                    color: entry.isCurrentWeek ? color : color.withOpacity(0.6),
                    fontWeight: FontWeight.w800,
                    fontSize: 11.0,
                    height: 1.1,
                  ),
                  softWrap: true,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.roomName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.roomName,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        entry.isCurrentWeek ? 0.9 : 0.5,
                      ),
                      fontSize: 9.5,
                      height: 1.1,
                    ),
                    softWrap: true,
                    maxLines: _slotHeight > 160
                        ? 3
                        : (_slotHeight > 110 ? 2 : 1),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (entry.teacherName.isNotEmpty) ...[
                  const SizedBox(height: 1.5),
                  Text(
                    entry.teacherName,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        entry.isCurrentWeek ? 0.9 : 0.5,
                      ),
                      fontSize: 9.5,
                      height: 1.1,
                    ),
                    softWrap: true,
                    maxLines: _slotHeight > 160
                        ? 3
                        : (_slotHeight > 110 ? 2 : 1),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 时间段数据类
class _TimeSlot {
  final String startTime;
  final String endTime;

  _TimeSlot({required this.startTime, required this.endTime});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TimeSlot &&
          startTime == other.startTime &&
          endTime == other.endTime;

  @override
  int get hashCode => startTime.hashCode ^ endTime.hashCode;
}

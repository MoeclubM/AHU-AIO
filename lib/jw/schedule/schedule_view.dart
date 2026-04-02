import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../api/getallsemesters.dart';
import '../utils/time_utils.dart';
import 'schedule_logic.dart';
import 'schedule_service.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  late final ScheduleLogic _logic;

  @override
  void initState() {
    super.initState();
    _logic = Get.put(ScheduleLogic());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('课程表')),
      body: Obx(() {
        final scheduleByDay = _logic.processClasses();
        final isLoading = _logic.isLoading.value;
        final errorText = _logic.errorMessage.value;
        final hasData = scheduleByDay.values.any(
          (entries) => entries.isNotEmpty,
        );

        return RefreshIndicator(
          onRefresh: _logic.refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
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

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      ),
    );
  }

  Widget _buildErrorNotice(String message) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      clipBehavior: Clip.antiAlias,
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
            border: TableBorder.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              width: 0.5,
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
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            alignment: Alignment.center,
            child: Text(day, style: headerStyle),
          ),
        );
      }).toList(),
    );
  }

  /// 构建时间段行
  TableRow _buildTimeSlotRow(
    _TimeSlot slot,
    Map<int, List<ScheduleEntry>> scheduleByDay,
    ThemeData theme,
    bool isDark,
  ) {
    final timeStyle = theme.textTheme.labelSmall?.copyWith(
      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
    );

    return TableRow(
      children: [
        // 时间列
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                constraints: const BoxConstraints(minHeight: 88),
                padding: const EdgeInsets.all(4),
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

  /// 构建课程单元格
  Widget _buildCourseCell(
    List<ScheduleEntry> entries,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.all(4),
      child: Column(
        children: entries.map((entry) {
          final bgColor = isDark
              ? theme.colorScheme.surfaceContainerHighest
              : theme.colorScheme.surfaceContainerLow;

          final borderColor = entry.isCurrentWeek
              ? theme.colorScheme.primary
              : (isDark ? Colors.grey.shade600 : Colors.grey.shade300);

          return Container(
            width: double.infinity,
            margin: entries.length > 1
                ? const EdgeInsets.only(bottom: 2)
                : null,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: borderColor,
                width: entry.isCurrentWeek ? 1.5 : 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 课程名称
                Text(
                  entry.courseName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  softWrap: true,
                ),
                const SizedBox(height: 4),
                // 教室
                Text(
                  entry.roomName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 10,
                  ),
                  softWrap: true,
                ),
                const SizedBox(height: 2),
                // 教师
                Text(
                  entry.teacherName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 10,
                  ),
                  softWrap: true,
                ),
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

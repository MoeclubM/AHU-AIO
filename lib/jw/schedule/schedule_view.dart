import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../api/getallsemesters.dart';
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
      appBar: AppBar(
        title: const Text('课程表'),
      ),
      body: Obx(() {
        final scheduleByDay = _logic.processClasses();
        final isLoading = _logic.isLoading.value;
        final errorText = _logic.errorMessage.value;
        final hasData = scheduleByDay.values.any((entries) => entries.isNotEmpty);

        return RefreshIndicator(
          onRefresh: _logic.refreshData,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            physics: const AlwaysScrollableScrollPhysics(),
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
              ..._buildDaySections(scheduleByDay),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSelectionArea(bool isLoading) {
    final theme = Theme.of(context);
    final semesters = _logic.allSemesters.toList();
    final selectedSemester = _logic.selectedSemester.value;
    final weeks = _logic.availableWeeks.toList();
    final selectedWeek = _logic.selectedWeek.value;

    final semesterValue = semesters.firstWhereOrNull(
      (semester) => semester.id == selectedSemester?.id,
    );

    final weekValue = weeks.contains(selectedWeek) ? selectedWeek : null;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                          _logic.refreshData();
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
                          _logic.refreshData();
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
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '加载课表失败',
              style: theme.textTheme.titleMedium,
            ),
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
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '本周暂无课程',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '请选择其他周次或稍后再试。',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDaySections(Map<int, List<ScheduleEntry>> scheduleByDay) {
    final widgets = <Widget>[];
    for (var weekday = 1; weekday <= 7; weekday++) {
      final entries = scheduleByDay[weekday] ?? <ScheduleEntry>[];
      widgets.add(_buildDayCard(weekday, entries));
    }
    return widgets;
  }

  Widget _buildDayCard(int weekday, List<ScheduleEntry> entries) {
    final theme = Theme.of(context);
    final children = <Widget>[];

    if (entries.isEmpty) {
      children.add(
        Text(
          '本周无课程安排',
          style: theme.textTheme.bodyMedium,
        ),
      );
    } else {
      for (var i = 0; i < entries.length; i++) {
        children.add(_buildCourseTile(entries[i]));
        if (i != entries.length - 1) {
          children.add(const Divider(height: 24));
        }
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _weekdayLabel(weekday),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildCourseTile(ScheduleEntry entry) {
    final theme = Theme.of(context);
    final chips = <Widget>[];

    if (entry.isCurrentWeek) {
      chips.add(_buildStatusChip('当前周', theme.colorScheme.primary));
    }
    if (entry.isHonorCourse) {
      chips.add(_buildStatusChip('荣誉课程', theme.colorScheme.secondary));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.courseName,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          '${entry.startTime} - ${entry.endTime} · ${entry.roomName}',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          entry.teacherName,
          style: theme.textTheme.bodySmall,
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: chips,
          ),
        ],
      ],
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
      side: BorderSide(color: color.withValues(alpha: 0.6)),
      backgroundColor: color.withValues(alpha: 0.1),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String _weekdayLabel(int weekday) {
    const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final baseLabel = labels[weekday - 1];
    final startDate = _resolveSelectedWeekStartDate();
    if (startDate == null) {
      return baseLabel;
    }
    final dateForWeekday = startDate.add(Duration(days: weekday - 1));
    final month = dateForWeekday.month.toString().padLeft(2, '0');
    final day = dateForWeekday.day.toString().padLeft(2, '0');
    return '$baseLabel（$month-$day）';
  }

  DateTime? _resolveSelectedWeekStartDate() {
    final semesterStart = _resolveSemesterStartDate();
    if (semesterStart == null) {
      return null;
    }
    final weekOffset = (_logic.selectedWeek.value - 1) * 7;
    return semesterStart.add(Duration(days: weekOffset));
  }

  DateTime? _resolveSemesterStartDate() {
    final semester = _logic.selectedSemester.value;
    if (semester != null && semester.startDate.isNotEmpty) {
      return DateTime.tryParse(semester.startDate);
    }
    final currentInfo = _logic.currentSemesterInfo.value;
    if (currentInfo != null && currentInfo.startDate.isNotEmpty) {
      return DateTime.tryParse(currentInfo.startDate);
    }
    return null;
  }
}

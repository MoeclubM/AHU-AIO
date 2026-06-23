import 'dart:ui';

import 'package:flutter/material.dart';
import '../api/jw_api.dart';
import '../models/jw_models.dart';

class JwSchedulePage extends StatefulWidget {
  final bool embed;
  const JwSchedulePage({super.key, this.embed = false});

  @override
  State<JwSchedulePage> createState() => _JwSchedulePageState();
}

class _JwSchedulePageState extends State<JwSchedulePage> {
  final _api = JwApi();
  CourseTableData? _tableData;
  int _currentWeek = 1;
  bool _isLoading = true;
  String? _error;

  static const _weekdays = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  static const _maxSlots = 11;
  double _slotHeight = 65.0;
  double _baseScaleSlotHeight = 65.0;
  static const _timeColumnWidth = 48.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final weekRaw = await _api.getCurrentTeachWeek();
      final weekInfo = TeachWeekInfo.fromJson(weekRaw);
      _currentWeek = weekInfo.weekIndex ?? 1;

      // 从成绩 API 获取学期列表，匹配当前学期名
      final semList = await _api.getSemesters();
      final currentName = weekInfo.currentSemester ?? '';
      int? semId;
      for (final s in semList) {
        if (s['nameZh']?.toString() == currentName ||
            s['nameEn']?.toString() == currentName) {
          semId = toInt(s['id']);
          break;
        }
      }
      // 降级：使用最大 ID 的学期（通常是最新的）
      semId ??= semList.isNotEmpty ? toInt(semList.last['id']) : null;
      // 再降级：尝试已知的当前学期 ID
      semId ??= 112;

      final raw = await _api.getCourseTablePrintData(semId);
      setState(() {
        _tableData = CourseTableData.fromJson(raw);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embed
          ? null
          : AppBar(
              toolbarHeight: 52,
              centerTitle: false,
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
              title: Text(
                _tableData?.studentName != null
                    ? '${_tableData!.studentName}的课表'
                    : '我的课表',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _isLoading || _tableData == null
          ? null
          : _buildFloatingWeekSelector(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _tableData == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadData, child: const Text('重试')),
                ],
              ),
            )
          : _buildSchedule(),
    );
  }

  Widget _buildSchedule() {
    final activities =
        _tableData?.activities
            .where((a) => a.weekIndexes.contains(_currentWeek))
            .toList() ??
        [];

    return Column(
      children: [
        if (widget.embed) _buildStudentInfo(activities),
        Expanded(child: _buildGrid(activities)),
      ],
    );
  }

  Widget _buildStudentInfo(List<CourseActivity> activities) {
    final t = _tableData;
    if (t == null) return const SizedBox();
    final colorScheme = Theme.of(context).colorScheme;
    final profile = [
      t.major,
      t.adminclass,
    ].whereType<String>().where((e) => e.isNotEmpty).join(' · ');
    final todayCount = activities
        .where((a) => a.weekday == DateTime.now().weekday)
        .length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.55),
          borderRadius: BorderRadius.zero,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  child: const Icon(Icons.calendar_month_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.studentName ?? '我的课表',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (profile.isNotEmpty)
                        Text(
                          profile,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (t.totalCredits != null)
                  Text(
                    '${t.totalCredits} 学分',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _infoPill(Icons.view_week_outlined, '第 $_currentWeek 周'),
                _infoPill(Icons.school_outlined, '本周 ${activities.length} 节'),
                _infoPill(Icons.today_outlined, '今日 $todayCount 节'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoPill(IconData icon, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colorScheme.primary),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildFloatingWeekSelector() {
    return SafeArea(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  color: Colors.white,
                  onPressed: _currentWeek > 1
                      ? () => setState(() => _currentWeek--)
                      : null,
                ),
                GestureDetector(
                  onTap: _showWeekPicker,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 96),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    child: Text(
                      '第 $_currentWeek 周',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  color: Colors.white,
                  onPressed: _currentWeek < 20
                      ? () => setState(() => _currentWeek++)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showWeekPicker() async {
    final selectedWeek = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).viewPadding.bottom;
        return Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(20, (index) {
              final week = index + 1;
              final isSelected = week == _currentWeek;
              return ChoiceChip(
                label: Text('第$week周'),
                selected: isSelected,
                onSelected: (_) => Navigator.pop(ctx, week),
              );
            }),
          ),
        );
      },
    );

    if (selectedWeek != null && mounted) {
      setState(() => _currentWeek = selectedWeek);
    }
  }

  Widget _buildGrid(List<CourseActivity> weekActivities) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final timeColumnWidth = _timeColumnWidth;
        final dayWidth = (totalWidth - timeColumnWidth) / 7;

        return GestureDetector(
          onScaleStart: (details) {
            _baseScaleSlotHeight = _slotHeight;
          },
          onScaleUpdate: (details) {
            setState(() {
              _slotHeight = (_baseScaleSlotHeight * details.verticalScale)
                  .clamp(45.0, 240.0);
            });
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 92),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: timeColumnWidth,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                        ),
                      ),
                      child: const Text(
                        '节次',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...List.generate(7, (dayIdx) {
                      final wd = dayIdx + 1;
                      final isToday = DateTime.now().weekday == wd;
                      final count = weekActivities
                          .where((a) => a.weekday == wd)
                          .length;
                      return Container(
                        width: dayWidth,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isToday
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: dayIdx == 6
                              ? const BorderRadius.only(
                                  topRight: Radius.circular(16),
                                )
                              : BorderRadius.zero,
                          border: Border(
                            left: BorderSide(
                              color: colorScheme.outlineVariant,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _weekdays[wd],
                              style: TextStyle(
                                color: isToday
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              isToday ? '今天 · $count 节' : '$count 节',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: List.generate(_maxSlots, (i) {
                        return Container(
                          width: timeColumnWidth,
                          height: _slotHeight,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.55),
                            border: Border(
                              top: BorderSide(
                                color: colorScheme.outlineVariant,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      }),
                    ),
                    ...List.generate(
                      7,
                      (dayIdx) =>
                          _buildDayColumn(dayIdx + 1, weekActivities, dayWidth),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayColumn(
    int weekday,
    List<CourseActivity> weekActivities,
    double dayWidth,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final dayActivities =
        weekActivities
            .where(
              (a) =>
                  a.weekday == weekday &&
                  a.startUnit != null &&
                  a.endUnit != null,
            )
            .toList()
          ..sort((a, b) => a.startUnit!.compareTo(b.startUnit!));

    return SizedBox(
      width: dayWidth,
      height: _slotHeight * _maxSlots,
      child: Stack(
        children: [
          Column(
            children: List.generate(_maxSlots, (index) {
              return Container(
                height: _slotHeight,
                decoration: BoxDecoration(
                  color: index.isEven
                      ? colorScheme.surface
                      : colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.18,
                        ),
                  border: Border(
                    left: BorderSide(
                      color: colorScheme.outlineVariant,
                      width: 0.5,
                    ),
                    top: BorderSide(
                      color: colorScheme.outlineVariant,
                      width: 0.5,
                    ),
                  ),
                ),
              );
            }),
          ),
          ...dayActivities.map((a) {
            final top = (a.startUnit! - 1) * _slotHeight;
            final height = (a.endUnit! - a.startUnit! + 1) * _slotHeight;
            return Positioned(
              left: 2,
              right: 2,
              top: top + 3,
              height: height - 6,
              child: _buildActivityCard(a),
            );
          }),
        ],
      ),
    );
  }

  Color _courseColor(CourseActivity a) {
    const colors = [
      Color(0xFF2563EB),
      Color(0xFF059669),
      Color(0xFFEA580C),
      Color(0xFF7C3AED),
      Color(0xFF0891B2),
      Color(0xFFDB2777),
      Color(0xFF4F46E5),
    ];
    final key = a.courseCode ?? a.courseName ?? '';
    var sum = 0;
    for (final unit in key.codeUnits) {
      sum += unit;
    }
    return colors[sum % colors.length];
  }

  Widget _buildActivityCard(CourseActivity a) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = _courseColor(a);
    final duration = (a.endUnit ?? 0) - (a.startUnit ?? 0) + 1;
    final maxLines = duration > 1
        ? duration * 3
        : (_slotHeight > 160
              ? 8
              : (_slotHeight > 100 ? 5 : (_slotHeight > 70 ? 4 : 3)));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showCourseDetail(a),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                a.courseName ?? '',
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              if (a.room != null)
                Text(
                  a.room!,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 9.0,
                  ),
                  maxLines: _slotHeight > 160 ? 3 : (duration > 1 ? 2 : 1),
                  overflow: TextOverflow.ellipsis,
                ),
              if (a.teacherStr.isNotEmpty)
                Text(
                  a.teacherStr,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 9.0,
                  ),
                  maxLines: _slotHeight > 160 ? 3 : (duration > 1 ? 2 : 1),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCourseDetail(CourseActivity a) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                a.courseName ?? '课程详情',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              _detailRow('课程代码', a.courseCode),
              _detailRow('教师', a.teacherStr.isNotEmpty ? a.teacherStr : null),
              _detailRow('教室', a.room),
              _detailRow('校区', a.campus),
              _detailRow('上课时间', '${a.weekdayStr} ${a.slotRange}'),
              _detailRow('周次', a.weeksStr ?? a.weekIndexes.join(', ')),
              if (a.credits != null)
                _detailRow('学分', a.credits!.toStringAsFixed(1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text('$label:', style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

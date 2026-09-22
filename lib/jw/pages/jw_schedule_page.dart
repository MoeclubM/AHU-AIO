import 'package:flutter/material.dart';
import '../models/jw_models.dart';
import '../services/jw_schedule_service.dart';
import '../../adaptive_ui.dart';
import '../../adaptive_dropdown.dart';
import '../../miuix/liquid_glass_app_bar.dart';

/// 安大新教务系统课表页面（jw.ahu.edu.cn 数据源）。
///
/// 支持独立全屏页面或二级标签栏嵌入模式（[embed] = true）。
/// 包含 1~25 周横向滑动 PageView、安徽大学 13 节次作息时间轴、
/// 公历月日表头（当天高亮）、双向联动选择器以及 150ms 快速弹出的课程详情底栏。
class JwSchedulePage extends StatefulWidget {
  final bool embed;
  const JwSchedulePage({super.key, this.embed = false});

  @override
  State<JwSchedulePage> createState() => _JwSchedulePageState();
}

class _JwSchedulePageState extends State<JwSchedulePage>
    with AutomaticKeepAliveClientMixin {
  late final JwScheduleService _service;
  late final PageController _pageController;
  bool _isAnimating = false;
  static const _weekdays = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  static const int _maxWeeks = 25;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _service = JwScheduleService();
    final initWeek = (_service.selectedWeek - 1).clamp(0, _maxWeeks - 1);
    _pageController = PageController(initialPage: initWeek);
    _service.addListener(_onServiceUpdate);
    _service.initAndLoad();
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    _pageController.dispose();
    _service.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (!mounted) return;
    final curWeek = _service.selectedWeek;
    if (_pageController.hasClients && !_isAnimating) {
      final curPage = _pageController.page?.round();
      if (curPage != null && curPage != curWeek - 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients &&
              !_isAnimating &&
              _pageController.page?.round() != curWeek - 1) {
            _pageController.jumpToPage(curWeek - 1);
          }
        });
      }
    }
    setState(() {});
  }

  /// 自动计算契合视口高度的单节高度
  double _getSlotHeight(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    final topP = MediaQuery.paddingOf(context).top;
    final botP = MediaQuery.paddingOf(context).bottom;
    final available = screenH - topP - botP - (widget.embed ? 220 : 120);
    if (available > 0) {
      return (available / 13 * 1.25).clamp(48.0, 78.0);
    }
    return 58.0;
  }

  Future<void> _animateToWeek(int week) async {
    final targetPage = (week - 1).clamp(0, _maxWeeks - 1);
    if (!_pageController.hasClients) {
      _service.selectWeek(week);
      return;
    }
    _isAnimating = true;
    try {
      await _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOutCubic,
      );
    } finally {
      _isAnimating = false;
      _service.selectWeek(week);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPad = adaptiveBottomPadding(context, withSubBar: widget.embed);

    return Scaffold(
      appBar: widget.embed
          ? null
          : LiquidGlassAppBar(
              title: Text(
                _service.scheduleData?.studentName.isNotEmpty == true
                    ? '${_service.scheduleData!.studentName}的课表'
                    : '安大教务课表',
              ),
            ),
      body: SafeArea(
        top: !widget.embed,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            if (_service.selectedSemester != null) {
              await _service.fetchScheduleData(_service.selectedSemester!.id);
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildTopSelectors(theme, isDark),
                _buildWeekCapsules(theme),
                if (_service.isLoading) const LinearProgressIndicator(),
                if (_service.isCached)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 16,
                    ),
                    color: theme.colorScheme.primaryContainer.withOpacity(0.7),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '当前为本地缓存数据，正在加载最新数据...',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_service.errorMessage != null &&
                    _service.scheduleData == null)
                  _buildErrorCard(theme),
                _buildGridContent(theme, isDark),
                SizedBox(height: bottomPad > 20 ? bottomPad : 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(
            '加载课表失败: ${_service.errorMessage}',
            style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              if (_service.selectedSemester != null) {
                _service.fetchScheduleData(_service.selectedSemester!.id);
              }
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 顶部学期与周次下拉选择区
  Widget _buildTopSelectors(ThemeData theme, bool isDark) {
    final semesters = _service.allSemesters;
    final selSem = _service.selectedSemester;
    final curWeek = _service.selectedWeek;

    final selectedSemValue = semesters.any((s) => s.id == selSem?.id)
        ? selSem
        : (semesters.isNotEmpty ? semesters.first : null);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.cardColor,
      child: Row(
        children: [
          // 学期下拉
          Expanded(
            flex: 6,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                  width: 0.6,
                ),
              ),
              child: AdaptiveDropdown<JwSemesterInfo>(
                value: selectedSemValue,
                isExpanded: true,
                items: semesters.map((s) {
                  return AdaptiveDropdownItem<JwSemesterInfo>(
                    value: s,
                    label: s.nameZh,
                  );
                }).toList(),
                onChanged: (s) {
                  if (s != null) _service.selectSemester(s);
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 周次下拉
          Expanded(
            flex: 4,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                  width: 0.6,
                ),
              ),
              child: AdaptiveDropdown<int>(
                value: curWeek.clamp(1, _maxWeeks),
                isExpanded: true,
                items: List.generate(_maxWeeks, (i) {
                  final w = i + 1;
                  final isNow = w == _service.currentWeek;
                  return AdaptiveDropdownItem<int>(
                    value: w,
                    label: isNow ? '第$w周(本周)' : '第$w周',
                  );
                }),
                onChanged: (w) {
                  if (w != null) _animateToWeek(w);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 水平滑动周次胶囊条
  Widget _buildWeekCapsules(ThemeData theme) {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _maxWeeks,
        itemBuilder: (context, i) {
          final w = i + 1;
          final isSel = w == _service.selectedWeek;
          final isCur = w == _service.currentWeek;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.5),
            child: ChoiceChip(
              label: Text('第$w周'),
              selected: isSel,
              onSelected: (_) => _animateToWeek(w),
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                color: isSel ? theme.colorScheme.onPrimary : null,
              ),
              selectedColor: theme.colorScheme.primary,
              backgroundColor: isCur
                  ? theme.colorScheme.primary.withOpacity(0.12)
                  : null,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
            ),
          );
        },
      ),
    );
  }

  /// 课表主体网格区域（支持 1~25 周横向平滑翻页）
  Widget _buildGridContent(ThemeData theme, bool isDark) {
    final slotH = _getSlotHeight(context);
    const totalSlots = 13;
    final totalGridH = totalSlots * slotH;
    const headerH = 48.0;
    final tableH = totalGridH + headerH + 2.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalW = constraints.maxWidth;
        const timeColW = 34.0;
        final dayW = (totalW - timeColW) / 7.0;

        return SizedBox(
          height: tableH,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _maxWeeks,
            onPageChanged: (page) {
              final newW = page + 1;
              if (_service.selectedWeek != newW) {
                _service.selectWeek(newW);
              }
            },
            itemBuilder: (context, page) {
              final week = page + 1;
              final weekData =
                  _service.scheduleData?.buildWeekSchedule(week) ?? {};

              return Column(
                children: [
                  _buildHeader(theme, dayW, timeColW, week),
                  _buildTimeline(
                    theme,
                    isDark,
                    weekData,
                    dayW,
                    timeColW,
                    slotH,
                    totalSlots,
                    totalGridH,
                    week,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// 顶部星期与公历日期表头
  Widget _buildHeader(ThemeData theme, double dayW, double timeColW, int week) {
    final sem = _service.selectedSemester;
    DateTime? monday;
    if (sem?.startDate != null) {
      try {
        final start = DateTime.parse(sem!.startDate!);
        monday = start.add(Duration(days: (week - 1) * 7));
      } catch (_) {}
    }
    final month = monday?.month ?? DateTime.now().month;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.4),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: timeColW,
            child: Center(
              child: Text(
                '$month\n月',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ...List.generate(7, (i) {
            final weekday = i + 1;
            final dayDate = monday?.add(Duration(days: i));
            final isToday = DateTime.now().weekday == weekday &&
                week == _service.currentWeek;

            return Container(
              width: dayW,
              height: 47,
              decoration: BoxDecoration(
                color: isToday
                    ? theme.colorScheme.primary.withOpacity(isDark ? 0.22 : 0.16)
                    : null,
                border: Border(
                  right: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                    width: 0.5,
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
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? theme.colorScheme.primary : null,
                    ),
                  ),
                  if (dayDate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: isToday
                          ? BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            )
                          : null,
                      child: Text(
                        '${dayDate.day}',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: isToday ? theme.colorScheme.onPrimary : null,
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

  /// 绘制 13 节次时间轴与纵向课程卡片
  Widget _buildTimeline(
    ThemeData theme,
    bool isDark,
    Map<int, List<JwScheduleEntry>> weekData,
    double dayW,
    double timeColW,
    double slotH,
    int totalSlots,
    double totalH,
    int week,
  ) {
    return SizedBox(
      height: totalH,
      child: Row(
        children: [
          // 左侧节次
          Container(
            width: timeColW,
            height: totalH,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                ),
              ),
            ),
            child: Column(
              children: List.generate(totalSlots, (slotIdx) {
                final slot = slotIdx + 1;
                return Container(
                  height: slotH,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color:
                            theme.colorScheme.outlineVariant.withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Text(
                    '$slot',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),
            ),
          ),
          // 7 列
          ...List.generate(7, (dIdx) {
            final weekday = dIdx + 1;
            final entries = weekData[weekday] ?? [];
            final isToday = DateTime.now().weekday == weekday &&
                week == _service.currentWeek;

            return Container(
              width: dayW,
              height: totalH,
              decoration: BoxDecoration(
                color: isToday
                    ? theme.colorScheme.primary.withOpacity(isDark ? 0.12 : 0.08)
                    : null,
                border: Border(
                  right: BorderSide(
                    color:
                        theme.colorScheme.outlineVariant.withOpacity(0.35),
                    width: 0.5,
                  ),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ...List.generate(totalSlots, (sIdx) {
                    return Positioned(
                      top: sIdx * slotH,
                      left: 0,
                      right: 0,
                      height: slotH,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: theme.colorScheme.outlineVariant
                                  .withOpacity(0.2),
                              width: 0.5,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  ...entries.map((entry) {
                    final start = entry.startUnit.clamp(1, totalSlots);
                    final end = entry.endUnit.clamp(start, totalSlots);
                    final span = (end - start + 1).clamp(1, totalSlots);
                    final top = (start - 1) * slotH + 1.5;
                    final h = span * slotH - 3.0;

                    return Positioned(
                      top: top,
                      left: 1.5,
                      right: 1.5,
                      height: h,
                      child: _buildCourseCard(entry, theme, isDark),
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

  Widget _buildCourseCard(
    JwScheduleEntry entry,
    ThemeData theme,
    bool isDark,
  ) {
    final hash = entry.courseName.hashCode.abs();
    final hue = (hash % 360).toDouble();
    final bg = isDark
        ? HSLColor.fromAHSL(0.35, hue, 0.65, 0.28).toColor()
        : HSLColor.fromAHSL(0.22, hue, 0.70, 0.85).toColor();
    final textColor = isDark
        ? HSLColor.fromAHSL(1.0, hue, 0.75, 0.80).toColor()
        : HSLColor.fromAHSL(1.0, hue, 0.75, 0.30).toColor();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDetailModal(entry),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: textColor.withOpacity(0.25),
              width: 0.6,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.courseName,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  height: 1.1,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (entry.roomName.isNotEmpty) ...[
                const SizedBox(height: 1.5),
                Text(
                  '@ ${entry.roomName}',
                  style: TextStyle(
                    fontSize: 8.0,
                    color: textColor.withOpacity(0.85),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 遵循 AGENTS.md 约束，使用 sheetAnimationStyle 控制 150ms 进场与 120ms 退场
  void _showDetailModal(JwScheduleEntry entry) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 150),
        reverseDuration: Duration(milliseconds: 120),
      ),
      builder: (ctx) {
        return Material(
          color: theme.colorScheme.surface,
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
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    entry.courseName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Chip(
                        label: Text(
                          '${_weekdays[entry.weekday]} 第${entry.startUnit}-${entry.endUnit}节 (${entry.startTime}~${entry.endTime})',
                        ),
                      ),
                      if (entry.roomName.isNotEmpty)
                        Chip(label: Text(entry.roomName)),
                      if (entry.teacherName.isNotEmpty)
                        Chip(label: Text(entry.teacherName)),
                    ],
                  ),
                  const Divider(height: 24),
                  ...entry.activities.map(
                    (act) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• ${act.courseCode} ${act.room} (第${act.weekIndexes.join(",")}周)',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

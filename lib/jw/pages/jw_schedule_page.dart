import 'package:flutter/material.dart';
import '../models/jw_models.dart';
import '../services/jw_schedule_service.dart';
import '../../adaptive_ui.dart';
import '../../adaptive_dropdown.dart';
import '../../miuix/adaptive_top_app_bar.dart';

/// 安大新教务系统课表页面（jw.ahu.edu.cn 数据源）。
///
/// 支持独立全屏页面或二级标签栏嵌入模式（[embed] = true）。
/// 包含 1~25 周横向滑动 PageView、安徽大学 13 节次作息时间轴、
/// 公历月日表头（当天高亮）、双向联动选择器以及 150ms 快速弹出的课程详情底栏。
class JwSchedulePage extends StatefulWidget {
  final bool embed;
  const JwSchedulePage({super.key, this.embed = false});

  @override
  State<JwSchedulePage> createState() => JwSchedulePageState();
}

class JwSchedulePageState extends State<JwSchedulePage>
    with AutomaticKeepAliveClientMixin {
  late final JwScheduleService _service;
  late final PageController _pageController;
  bool _isAnimating = false;
  static const _weekdays = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  static const _slotStartTimes = [
    '08:00',
    '08:50',
    '09:55',
    '10:45',
    '11:35',
    '14:00',
    '14:50',
    '15:55',
    '16:45',
    '17:35',
    '19:00',
    '19:50',
    '20:40',
  ];
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

  Future<void> refresh() => _service.activate();

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
          : AdaptiveTopAppBar(
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
          onRefresh: _service.refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildTopSelectors(theme, isDark),
                _buildWeekCapsules(theme),
                if (_service.isLoading) const LinearProgressIndicator(),
                if (_service.isOfflineCache)
                  _buildCacheBanner(
                    theme: theme,
                    icon: Icons.cloud_off_outlined,
                    text: '网络连接失败，当前展示本地缓存课表（下拉可重试）',
                    warn: true,
                  )
                else if (_service.isCached)
                  _buildCacheBanner(
                    theme: theme,
                    icon: Icons.info_outline,
                    text: '当前为本地缓存数据，正在加载最新数据...',
                    warn: false,
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

  /// 本地缓存状态横幅：加载中提示 vs 离线回退提示（与微教务课表保持完全一致的视觉与交互）
  Widget _buildCacheBanner({
    required ThemeData theme,
    required IconData icon,
    required String text,
    required bool warn,
  }) {
    final colorScheme = theme.colorScheme;
    final bgColor = warn
        ? colorScheme.errorContainer.withOpacity(0.55)
        : colorScheme.primaryContainer.withOpacity(0.7);
    final fgColor = warn
        ? colorScheme.onErrorContainer
        : colorScheme.onPrimaryContainer;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      color: bgColor,
      child: Row(
        children: [
          Icon(icon, size: 14, color: fgColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                color: fgColor,
                fontWeight: FontWeight.w500,
              ),
            ),
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
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.5,
                ),
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
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.5,
                ),
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
                  final isNow =
                      _service.isCurrentSemesterSelected &&
                      w == _service.currentWeek;
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
          final isCur =
              _service.isCurrentSemesterSelected && w == _service.currentWeek;

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

    return RepaintBoundary(
      child: LayoutBuilder(
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
      ),
    );
  }

  /// 顶部星期与公历日期表头
  Widget _buildHeader(ThemeData theme, double dayW, double timeColW, int week) {
    final sem = _service.selectedSemester;
    DateTime? monday;
    if (sem?.startDate != null) {
      try {
        final start = DateTime.parse(sem!.startDate!);
        final firstMonday = DateTime(
          start.year,
          start.month,
          start.day,
        ).subtract(Duration(days: start.weekday - DateTime.monday));
        monday = firstMonday.add(Duration(days: (week - 1) * 7));
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
            final isToday =
                DateTime.now().weekday == weekday &&
                _service.isCurrentSemesterSelected &&
                week == _service.currentWeek;

            return Container(
              width: dayW,
              height: 47,
              decoration: BoxDecoration(
                color: isToday
                    ? theme.colorScheme.primary.withOpacity(
                        isDark ? 0.22 : 0.16,
                      )
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
              color: theme.cardColor.withOpacity(0.7),
              border: Border(
                right: BorderSide(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.45),
                  width: 0.8,
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
                        color: slot == 5 || slot == 10
                            ? theme.colorScheme.primary.withOpacity(0.55)
                            : theme.colorScheme.outlineVariant.withOpacity(
                                0.45,
                              ),
                        width: slot == 5 || slot == 10 ? 1.2 : 0.6,
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
                        _slotStartTimes[slotIdx],
                        style: TextStyle(
                          fontSize: 8,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(
                            0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          // 7 列
          ...List.generate(7, (dIdx) {
            final weekday = dIdx + 1;
            final entries = weekData[weekday] ?? [];
            final isToday =
                DateTime.now().weekday == weekday &&
                week == _service.currentWeek;

            return Container(
              width: dayW,
              height: totalH,
              decoration: BoxDecoration(
                color: isToday
                    ? theme.colorScheme.primary.withOpacity(
                        isDark ? 0.14 : 0.10,
                      )
                    : null,
                border: Border(
                  right: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(
                      isToday ? 0.65 : 0.45,
                    ),
                    width: isToday ? 0.8 : 0.6,
                  ),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ...List.generate(totalSlots, (sIdx) {
                    final slot = sIdx + 1;
                    return Positioned(
                      top: sIdx * slotH,
                      left: 0,
                      right: 0,
                      height: slotH,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: slot == 5 || slot == 10
                                  ? theme.colorScheme.primary.withOpacity(
                                      isToday ? 0.7 : 0.5,
                                    )
                                  : theme.colorScheme.outlineVariant
                                        .withOpacity(isToday ? 0.5 : 0.4),
                              width: slot == 5 || slot == 10 ? 1.2 : 0.6,
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
                    final h = (span * slotH - 3.0).clamp(24.0, double.infinity);

                    return Positioned(
                      top: top,
                      left: 1.5,
                      right: 1.5,
                      height: h,
                      child: _buildCourseCard(entry, span, theme, isDark),
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
    int span,
    ThemeData theme,
    bool isDark,
  ) {
    final bg = _courseBackground(entry.courseName, isDark);
    final textColor = _courseForeground(entry.courseName, isDark);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDetailModal(entry),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 3.5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: textColor.withOpacity(isDark ? 0.35 : 0.22),
              width: 0.6,
            ),
            boxShadow: isMiuixUi()
                ? null
                : [
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
              Text(
                entry.courseName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  height: 1.12,
                ),
                maxLines: span >= 3 ? 5 : (span >= 2 ? 3 : 2),
                overflow: TextOverflow.ellipsis,
              ),
              if (entry.roomName.isNotEmpty) ...[
                const SizedBox(height: 1.5),
                Text(
                  '@ ${entry.roomName}',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w500,
                    color: textColor.withOpacity(0.85),
                    height: 1.08,
                  ),
                  maxLines: span >= 2 ? 2 : 1,
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
                    height: 1.08,
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

  Color _courseBackground(String name, bool isDark) {
    const lightColors = [
      Color(0xFFE8F0FE),
      Color(0xFFE6F4EA),
      Color(0xFFFEF7E0),
      Color(0xFFFCE8E6),
      Color(0xFFF3E8FD),
      Color(0xFFE0F2F1),
      Color(0xFFFFF0F5),
      Color(0xFFEFEBE9),
      Color(0xFFE1F5FE),
      Color(0xFFF9FBE7),
    ];
    const darkColors = [
      Color(0xFF1E3A5F),
      Color(0xFF1B4332),
      Color(0xFF4A3E1B),
      Color(0xFF4A2028),
      Color(0xFF38234D),
      Color(0xFF1B3D3B),
      Color(0xFF4A2A38),
      Color(0xFF36322F),
      Color(0xFF1E3747),
      Color(0xFF363D1F),
    ];
    final hash = name.hashCode.abs();
    return (isDark ? darkColors : lightColors)[hash % lightColors.length];
  }

  Color _courseForeground(String name, bool isDark) {
    const lightColors = [
      Color(0xFF1A56DB),
      Color(0xFF0D6832),
      Color(0xFF946200),
      Color(0xFFB42318),
      Color(0xFF6B21A8),
      Color(0xFF0E7090),
      Color(0xFF9D174D),
      Color(0xFF5D4037),
      Color(0xFF0284C7),
      Color(0xFF556B2F),
    ];
    const darkColors = [
      Color(0xFF93C5FD),
      Color(0xFF86EFAC),
      Color(0xFFFDE047),
      Color(0xFFFCA5A5),
      Color(0xFFD8B4FE),
      Color(0xFF67E8F9),
      Color(0xFFF472B6),
      Color(0xFFD7CCC8),
      Color(0xFF7DD3FC),
      Color(0xFFBEF264),
    ];
    final hash = name.hashCode.abs();
    return (isDark ? darkColors : lightColors)[hash % lightColors.length];
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

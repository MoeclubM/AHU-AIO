import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _isCached = false;
  int? _realCurrentWeek;

  List<dynamic> _semesters = [];
  int? _selectedSemesterId;
  String? _selectedSemesterName;

  static const _weekdays = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  static const _maxSlots = 11;
  double _slotHeight = 95.0;
  double _baseScaleSlotHeight = 95.0;
  static const _timeColumnWidth = 48.0;

  @override
  void initState() {
    super.initState();
    _loadSavedHeight();
    _loadData();
  }

  Future<void> _loadSavedHeight() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedHeight = prefs.getDouble('jw_schedule_slot_height');
      if (savedHeight != null) {
        setState(() {
          _slotHeight = savedHeight;
          _baseScaleSlotHeight = savedHeight;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final weekRaw = await _api.getCurrentTeachWeek();
      final weekInfo = TeachWeekInfo.fromJson(weekRaw);
      _realCurrentWeek = weekInfo.weekIndex;

      // 从成绩 API 获取学期列表
      final semList = await _api.getSemesters();
      _semesters = semList;

      final currentName = weekInfo.currentSemester ?? '';

      // 如果还没选择学期，自动检测
      if (_selectedSemesterId == null) {
        int? semId;
        for (final s in semList) {
          if (s['nameZh']?.toString() == currentName ||
              s['nameEn']?.toString() == currentName) {
            semId = toInt(s['id']);
            break;
          }
        }
        semId ??= semList.isNotEmpty ? toInt(semList.last['id']) : null;
        semId ??= 112;
        _selectedSemesterId = semId;
        _currentWeek = weekInfo.weekIndex ?? 1;
      }

      // 获取当前选中的学期名称
      if (_selectedSemesterId != null) {
        dynamic currentSem;
        for (final s in semList) {
          if (toInt(s['id']) == _selectedSemesterId) {
            currentSem = s;
            break;
          }
        }
        if (currentSem != null) {
          _selectedSemesterName =
              currentSem['nameZh']?.toString() ??
              currentSem['nameEn']?.toString() ??
              '未知学期';
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'jw_schedule_cache_$_selectedSemesterId';
      final cachedStr = prefs.getString(cacheKey);
      if (cachedStr != null) {
        try {
          final cachedData = CourseTableData.fromJson(jsonDecode(cachedStr));
          setState(() {
            _tableData = cachedData;
            _isCached = true;
            _isLoading = false;
          });
        } catch (_) {}
      }

      final raw = await _api.getCourseTablePrintData(_selectedSemesterId!);
      final freshData = CourseTableData.fromJson(raw);

      await prefs.setString(cacheKey, jsonEncode(raw));

      setState(() {
        _tableData = freshData;
        _isCached = false;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (_tableData != null) {
        setState(() {
          _isCached = true;
          _isLoading = false;
          _error = '更新课表失败，显示为本地缓存';
        });
      } else {
        setState(() {
          _error = '加载失败: $e';
          _isLoading = false;
        });
      }
    }
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
            .where((a) => a.courseName != null &&
                a.courseName!.trim().isNotEmpty &&
                a.courseName != '未知课程')
            .toList() ??
        [];

    return Column(
      children: [
        if (_isCached)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withOpacity(0.7),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error != null && _error!.contains('更新课表失败')
                        ? '更新最新课表失败，当前显示为本地缓存数据'
                        : '当前为本地缓存数据，正在加载最新数据...',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        _buildSemesterHeader(activities),
        Expanded(child: _buildGrid(activities)),
      ],
    );
  }

  Widget _buildSemesterHeader(List<CourseActivity> activities) {
    final colorScheme = Theme.of(context).colorScheme;
    final todayCount = activities
        .where((a) => a.weekday == DateTime.now().weekday)
        .length;
    final semName = _selectedSemesterName ?? '加载中...';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.4),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左侧：学期选择按钮
          InkWell(
            onTap: _showSemesterPicker,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    semName,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          // 右侧：课数统计
          Text(
            '本周 ${activities.length} 节 · 今日 $todayCount 节',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  void _switchSemester(int? semId) {
    if (semId == null || _selectedSemesterId == semId) return;
    setState(() {
      _selectedSemesterId = semId;
      _tableData = null; // 清空旧数据以展示加载中
      _currentWeek = 1; // 默认重置回第 1 周
    });
    _loadData();
  }

  void _showSemesterPicker() {
    if (_semesters.isEmpty) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface.withOpacity(0.72),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.3),
                  width: 0.8,
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4.5,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2.25),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        '选择学期',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _semesters.length,
                        itemBuilder: (context, index) {
                          final s = _semesters[index];
                          final semId = toInt(s['id']);
                          final semName =
                              s['nameZh']?.toString() ??
                              s['nameEn']?.toString() ??
                              '';
                          final isSelected = semId == _selectedSemesterId;
                          return ListTile(
                            title: Text(
                              semName,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  )
                                : null,
                            onTap: () {
                              Navigator.pop(context);
                              _switchSemester(semId);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingWeekSelector() {
    return SafeArea(
      top: false,
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 148),
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
              final isRealCurrent = week == _realCurrentWeek;
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
            final newHeight = (_baseScaleSlotHeight * details.verticalScale)
                .clamp(45.0, 240.0);
            setState(() {
              _slotHeight = newHeight;
            });
            SharedPreferences.getInstance().then((prefs) {
              prefs.setDouble('jw_schedule_slot_height', newHeight);
            });
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 148),
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

  String _formatCourseName(String name) {
    if (name.isEmpty) return name;
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < name.length; i++) {
      buffer.write(name[i]);
      if ((i + 1) % 3 == 0 && (i + 1) < name.length) {
        buffer.write('\n');
      }
    }
    return buffer.toString();
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
        borderRadius: BorderRadius.circular(6),
        onTap: () => _showCourseDetail(a),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatCourseName(a.courseName ?? ''),
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
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.72),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4.5,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.4,
                            ),
                            borderRadius: BorderRadius.circular(2.25),
                          ),
                        ),
                      ),
                      Text(
                        a.courseName ?? '课程详情',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _detailRow('课程代码', a.courseCode),
                      _detailRow(
                        '教师',
                        a.teacherStr.isNotEmpty ? a.teacherStr : null,
                      ),
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
            ),
          ),
        );
      },
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

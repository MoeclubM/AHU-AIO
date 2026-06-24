import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_service.dart';

class HomePage extends StatefulWidget {
  final bool isVisible;
  final bool embed;
  const HomePage({super.key, this.isVisible = true, this.embed = false});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  DateTime? _selectedDate;
  DateTime _lastRefreshDate = DateTime.now();
  bool _isUserSelectedDate = false; // 标记用户是否手动选择了日期

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastRefreshDate = DateTime.now();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当从其他页面切换回首页时，刷新即将开始课程的显示
    if (widget.isVisible && !oldWidget.isVisible) {
      _refreshUpcomingDisplay();
    }
  }

  /// 刷新即将开始课程的显示状态（不重新请求数据）
  void _refreshUpcomingDisplay() {
    if (!mounted) return;
    try {
      final logic = Provider.of<HomePageLogic>(context, listen: false);
      logic.refreshDisplay();
    } catch (e) {
      debugPrint('Refresh display skipped: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndRefreshIfNeeded();
    }
  }

  /// 检查是否需要刷新数据（跨天检测）
  void _checkAndRefreshIfNeeded() {
    if (!mounted) return;

    final now = DateTime.now();
    final lastDate = DateTime(
      _lastRefreshDate.year,
      _lastRefreshDate.month,
      _lastRefreshDate.day,
    );
    final today = DateTime(now.year, now.month, now.day);

    // 如果跨天了
    if (today.isAfter(lastDate)) {
      _lastRefreshDate = now;

      // 如果用户没有手动选择日期，或者选择的是旧的今天，则重置为新的今天
      if (!_isUserSelectedDate || _selectedDate?.day == lastDate.day) {
        setState(() {
          _selectedDate = null;
          _isUserSelectedDate = false;
        });
      }

      // 触发数据刷新
      try {
        final logic = Provider.of<HomePageLogic>(context, listen: false);
        logic.refreshData();
      } catch (e) {
        // Provider 可能在初始化阶段不可用，忽略错误
        debugPrint('Auto refresh skipped: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomePageLogic(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: widget.embed
              ? null
              : AppBar(
                  title: const Text('首页'),
                  bottom: const TabBar(
                    tabs: [
                      Tab(icon: Icon(Icons.schedule_outlined), text: '日程'),
                      Tab(icon: Icon(Icons.quiz_outlined), text: '考试'),
                    ],
                  ),
                ),
          body: Consumer<HomePageLogic>(
            builder: (context, logic, child) {
              if (logic.isLoading) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('正在加载数据...'),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  if (widget.embed)
                    Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: const TabBar(
                        tabs: [
                          Tab(icon: Icon(Icons.schedule_outlined), text: '日程'),
                          Tab(icon: Icon(Icons.quiz_outlined), text: '考试'),
                        ],
                      ),
                    ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        Column(
                          children: [
                            _buildDateSelector(logic),
                            Expanded(
                              child: _buildSchedules(
                                logic.schedules,
                                logic,
                                context,
                              ),
                            ),
                          ],
                        ),
                        // Exam tab without date selector
                        _buildExams(logic.tests, logic, context),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(HomePageLogic logic) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: InkWell(
        onTap: () => _selectDate(context, logic),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('选择日期', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 2),
                    Text(
                      _formatSelectedDate(),
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.date_range, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSelectedDate() {
    final date = _selectedDate ?? DateTime.now();
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.year}年${date.month}月${date.day}日 $weekday';
  }

  Future<void> _selectDate(BuildContext context, HomePageLogic logic) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('zh', 'CN'),
    );

    if (picked != null && picked != _selectedDate) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final pickedDate = DateTime(picked.year, picked.month, picked.day);

      setState(() {
        _selectedDate = picked;
        // 如果选择的是今天，重置标志；否则标记为用户手动选择
        _isUserSelectedDate = !pickedDate.isAtSameMomentAs(today);
        _lastRefreshDate = now;
      });
      // 格式化日期为API需要的格式
      final dateString =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      logic.refreshDataForDate(dateString);
    }
  }

  Widget _buildSchedules(
    dynamic schedules,
    HomePageLogic logic,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (logic.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? Colors.blue.shade300 : Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '正在加载课表数据...',
              style: TextStyle(
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (logic.currentError != null) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: isDark ? Colors.red.shade400 : Colors.red.shade600,
                ),
                const SizedBox(height: 16),
                Text(
                  '加载失败',
                  style: TextStyle(
                    fontSize: 18,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  logic.currentError!,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final remainingClassesCount = logic.getRemainingClassesCount();

    // 获取选定日期的课程，如果没有选择日期则显示今天的课程
    final selectedDateString = _selectedDate != null
        ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
        : DateTime.now().toString().substring(0, 10);
    final groupedSchedules = logic.getGroupedSchedulesForDate(
      selectedDateString,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 统计信息卡片
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
          child: Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Text(
                          groupedSchedules.values
                              .fold(0, (sum, courses) => sum + courses.length)
                              .toString(),
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedDate != null &&
                                  _selectedDate!.day != DateTime.now().day
                              ? '选定日期'
                              : '今日课程',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Text(
                          remainingClassesCount.toString(),
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text('本周剩余', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: groupedSchedules.isEmpty
              ? Center(
                  child: Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedDate != null ? '选定日期暂无课程' : '今日暂无课程',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text('请选择其他日期查看', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 148),
                  itemCount: groupedSchedules.keys.length,
                  itemBuilder: (context, index) {
                    final timeSlot = groupedSchedules.keys.elementAt(index);
                    final courses = groupedSchedules[timeSlot]!;

                    // 检查此时间段是否包含正在进行或即将进行的课程
                    final hasOngoingOrUpcoming = logic
                        .hasOngoingOrUpcomingCourse(
                          courses,
                          selectedDateString,
                        );

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      // 如果包含正在进行或即将进行的课程，添加边框高亮
                      // 浅色模式使用primaryContainer实现更柔和的背景色
                      color: hasOngoingOrUpcoming
                          ? (isDark
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.15,
                                  )
                                : theme.colorScheme.primaryContainer.withValues(
                                    alpha: 0.4,
                                  ))
                          : null,
                      shape: hasOngoingOrUpcoming
                          ? RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isDark
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.primary.withValues(
                                        alpha: 0.6,
                                      ),
                                width: isDark ? 2 : 1.5,
                              ),
                            )
                          : null,
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          // 只展开包含正在进行或即将进行课程的时间段
                          initiallyExpanded: hasOngoingOrUpcoming,
                          title: Row(
                            children: [
                              Text(timeSlot),
                              if (hasOngoingOrUpcoming) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.play_circle_outline,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text('${courses.length} 节课'),
                          children: courses.map((course) {
                            // 检查单个课程是否正在进行或即将进行
                            final isOngoingOrUpcoming = logic
                                .isCourseOngoingOrUpcoming(
                                  course,
                                  selectedDateString,
                                );

                            return Container(
                              decoration: isOngoingOrUpcoming
                                  ? BoxDecoration(
                                      // 浅色模式使用更柔和的背景
                                      color: isDark
                                          ? theme.colorScheme.primary
                                                .withValues(alpha: 0.12)
                                          : theme.colorScheme.primaryContainer
                                                .withValues(alpha: 0.5),
                                      border: Border(
                                        left: BorderSide(
                                          color: theme.colorScheme.primary,
                                          width: 4,
                                        ),
                                      ),
                                    )
                                  : null,
                              child: ListTile(
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        course['context'] ?? '未知课程',
                                        style: isOngoingOrUpcoming
                                            ? TextStyle(
                                                fontWeight: FontWeight.bold,
                                                // 浅色模式使用较深的primary色调
                                                color: isDark
                                                    ? theme.colorScheme.primary
                                                    : theme.colorScheme.primary,
                                              )
                                            : null,
                                      ),
                                    ),
                                    if (isOngoingOrUpcoming)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          // 浅色模式使用更柔和的标签背景
                                          color: isDark
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.primary
                                                    .withValues(alpha: 0.85),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '进行中',
                                          style: TextStyle(
                                            color: theme.colorScheme.onPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      '${course['startTime']} - ${course['endTime']}',
                                      style: isOngoingOrUpcoming
                                          ? TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? theme.colorScheme.primary
                                                  : theme.colorScheme.primary
                                                        .withValues(alpha: 0.8),
                                            )
                                          : null,
                                    ),
                                    if (course['place'] != null)
                                      Text(course['place']),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildExams(
    List<dynamic>? exams,
    HomePageLogic logic,
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    if (exams == null) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [Text('无法获取考试信息', style: theme.textTheme.titleMedium)],
            ),
          ),
        ),
      );
    }

    if (exams.isEmpty) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('暂无考试安排', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('请选择其他月份查看', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 148),
      itemCount: exams.length,
      itemBuilder: (context, index) {
        final exam = exams[index];
        final startTime = logic.formatExamTime(exam['startTime']);
        final endTime = logic.formatExamTime(exam['endTime']);
        final classroom = exam['classroom'] ?? exam['place'];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16.0),
            title: Text(exam['courseNameZh'] ?? '未知考试'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exam['examDate'] ?? '未知日期'),
                  const SizedBox(height: 4),
                  Text('$startTime - $endTime'),
                  if (classroom != null) ...[
                    const SizedBox(height: 4),
                    Text(classroom),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

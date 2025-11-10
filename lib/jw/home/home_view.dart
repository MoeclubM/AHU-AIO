import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChangeNotifierProvider(
      create: (_) => HomePageLogic(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
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

              return TabBarView(
                children: [
                  Column(
                    children: [
                      _buildDateSelector(logic),
                      Expanded(
                        child: _buildSchedules(logic.schedules, logic, context),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      _buildDateSelector(logic),
                      Expanded(
                        child: _buildExams(logic.tests, logic, context),
                      ),
                    ],
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
      margin: const EdgeInsets.all(16.0),
      child: InkWell(
        onTap: () => _selectDate(context, logic),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_outlined),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '选择日期',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatSelectedDate(),
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.date_range),
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
      setState(() {
        _selectedDate = picked;
      });
      // 格式化日期为API需要的格式
      final dateString = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      logic.refreshDataForDate(dateString);
    }
  }

  Widget _buildSchedules(dynamic schedules, HomePageLogic logic, BuildContext context) {
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
    final groupedSchedules = logic.getGroupedSchedulesForDate(selectedDateString);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 统计信息卡片
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
          child: Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(Icons.today_outlined, size: 24),
                        const SizedBox(height: 8),
                        Text(
                          groupedSchedules.values.fold(0, (sum, courses) => sum + courses.length).toString(),
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedDate != null && _selectedDate!.day != DateTime.now().day
                              ? '选定日期'
                              : '今日课程',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(Icons.schedule_outlined, size: 24),
                        const SizedBox(height: 8),
                        Text(
                          remainingClassesCount.toString(),
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '本周剩余',
                          style: theme.textTheme.bodySmall,
                        ),
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
                          const Icon(Icons.calendar_today_outlined, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            _selectedDate != null
                                ? '选定日期暂无课程'
                                : '今日暂无课程',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '请选择其他日期查看',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: groupedSchedules.keys.length,
                  itemBuilder: (context, index) {
                    final timeSlot = groupedSchedules.keys.elementAt(index);
                    final courses = groupedSchedules[timeSlot]!;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        leading: Icon(_getTimeSlotIcon(timeSlot)),
                        title: Text(timeSlot),
                        subtitle: Text('${courses.length} 节课'),
                        children: courses.map((course) {
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(_getWeekdayText(course['whatDay'])),
                            ),
                            title: Text(course['context'] ?? '未知课程'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('${course['startTime']} - ${course['endTime']}'),
                                if (course['place'] != null)
                                  Text(course['place']),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  
  IconData _getTimeSlotIcon(String timeSlot) {
    if (timeSlot.contains('早晨')) return Icons.wb_sunny_outlined;
    if (timeSlot.contains('上午')) return Icons.wb_sunny;
    if (timeSlot.contains('中午')) return Icons.lunch_dining;
    if (timeSlot.contains('下午')) return Icons.wb_cloudy;
    if (timeSlot.contains('晚上')) return Icons.nights_stay;
    return Icons.schedule;
  }

  /// 将各种格式的星期数据转换为单字符显示
  ///
  /// 支持多种输入格式：
  /// - 数字：1-7 → "一"到"日"
  /// - 字符串："周一"到"周日" → "一"到"日"
  /// - 字符串数字："1"到"7" → "一"到"日"
  /// - 其他格式：提取首字符或返回"?"
  ///
  /// 返回单字符星期标识，用于界面简洁显示
  String _getWeekdayText(dynamic whatDay) {
    String weekdayStr;

    if (whatDay is int) {
      // 处理数字格式（1-7对应周一到周日）
      final weekdays = ['', '一', '二', '三', '四', '五', '六', '日'];
      weekdayStr = whatDay > 0 && whatDay <= 7 ? weekdays[whatDay] : '?';
    } else if (whatDay is String) {
      if (whatDay.startsWith('周')) {
        // 处理"周X"格式，提取星期字符
        weekdayStr = whatDay.length > 1 ? whatDay.substring(1, 2) : '?';
      } else {
        // 尝试解析字符串中的数字
        final dayNum = int.tryParse(whatDay);
        if (dayNum != null) {
          final weekdays = ['', '一', '二', '三', '四', '五', '六', '日'];
          weekdayStr = dayNum > 0 && dayNum <= 7 ? weekdays[dayNum] : '?';
        } else {
          // 其他格式，提取首字符作为备选
          weekdayStr = whatDay.isNotEmpty ? whatDay.substring(0, 1) : '?';
        }
      }
    } else {
      weekdayStr = '?';
    }

    return weekdayStr;
  }

  Widget _buildExams(List<dynamic>? exams, HomePageLogic logic, BuildContext context) {
    final theme = Theme.of(context);

    if (exams == null) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64),
                const SizedBox(height: 16),
                Text(
                  '无法获取考试信息',
                  style: theme.textTheme.titleMedium,
                ),
              ],
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
                const Icon(Icons.quiz_outlined, size: 48),
                const SizedBox(height: 20),
                Text(
                  '暂无考试安排',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '请选择其他月份查看',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: exams.length,
      itemBuilder: (context, index) {
        final exam = exams[index];
        final startTime = logic.formatExamTime(exam['startTime']);
        final endTime = logic.formatExamTime(exam['endTime']);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16.0),
            leading: const Icon(Icons.quiz_outlined),
            title: Text(exam['courseNameZh'] ?? '未知考试'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exam['examDate'] ?? '未知日期'),
                  const SizedBox(height: 4),
                  Text('$startTime - $endTime'),
                  if (exam['place'] != null) ...[
                    const SizedBox(height: 4),
                    Text(exam['place'] ?? '未知地点'),
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
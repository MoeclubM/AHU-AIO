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
                  // Exam tab without date selector
                  _buildExams(logic.tests, logic, context),
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
                    Text(
                      '选择日期',
                      style: theme.textTheme.bodySmall,
                    ),
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
                          groupedSchedules.values.fold(0, (sum, courses) => sum + courses.length).toString(),
                          style: theme.textTheme.headlineMedium,
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
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          title: Text(timeSlot),
                          subtitle: Text('${courses.length} 节课'),
                          children: courses.map((course) {
                            return ListTile(
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
                      ),
                    );
                  },
                ),
        ),
      ],
    );
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
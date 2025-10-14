import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  DateTime? _selectedDate;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    // 启动动画
    _fadeController.forward();
    _slideController.forward();

    // 检查即将开始的课程将在Consumer内部调用
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ChangeNotifierProvider(
      create: (_) => HomePageLogic(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
          appBar: AppBar(
            title: const Text(
              '首页',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.blue.shade800,
                          Colors.blue.shade600,
                          Colors.indigo.shade700,
                        ]
                      : [
                          Colors.blue.shade600,
                          Colors.blue.shade700,
                          Colors.indigo.shade600,
                        ],
                ),
              ),
            ),
            bottom: TabBar(
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 15,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.schedule_outlined), text: '日程'),
                Tab(icon: Icon(Icons.quiz_outlined), text: '考试'),
              ],
            ),
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Consumer<HomePageLogic>(
                builder: (context, logic, child) {

                  if (logic.isLoading) {
                    return Center(
                      child: Card.filled(
                        color: isDark ? Colors.grey.shade800 : Colors.white,
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDark ? Colors.blue.shade400 : Colors.blue.shade600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '正在加载数据...',
                                style: TextStyle(
                                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
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
        ),
      ),
    );
  }

  Widget _buildDateSelector(HomePageLogic logic) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Card.filled(
        color: isDark ? Colors.grey.shade800 : Colors.blue.shade50,
        elevation: 0,
        child: InkWell(
          onTap: () => _selectDate(context, logic),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isDark ? Colors.blue.shade600 : Colors.blue.shade500,
                  radius: 20,
                  child: const Icon(
                    Icons.calendar_month_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '选择日期',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey.shade400 : Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formatSelectedDate(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.blue.shade900,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.date_range,
                            color: isDark ? Colors.blue.shade400 : Colors.blue.shade600,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('zh', 'CN'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: Colors.blue.shade300,
                    onPrimary: Colors.white,
                    surface: Colors.grey.shade800,
                    onSurface: Colors.white,
                  )
                : ColorScheme.light(
                    primary: Colors.blue,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black87,
                  ),
            dialogBackgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
          ),
          child: child!,
        );
      },
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
        Container(
          margin: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
          child: Row(
            children: [
              Expanded(
                child: Card(
                  elevation: 2,
                  shadowColor: Colors.blue.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Colors.blue.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.shade400,
                            Colors.blue.shade600,
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.today_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            groupedSchedules.values.fold(0, (sum, courses) => sum + courses.length).toString(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedDate != null && _selectedDate!.day != DateTime.now().day
                                ? '选定日期'
                                : '今日课程',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  elevation: 2,
                  shadowColor: Colors.indigo.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Colors.indigo.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.indigo.shade400,
                            Colors.indigo.shade600,
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            remainingClassesCount.toString(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '本周剩余',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
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
                  child: Card.filled(
                    color: isDark ? Colors.grey.shade800 : Colors.blue.shade50,
                    elevation: 0,
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.blue.shade900.withValues(alpha: 0.3)
                                  : Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.calendar_today_outlined,
                              size: 36,
                              color: isDark ? Colors.blue.shade300 : Colors.blue.shade600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedDate != null
                                ? '选定日期暂无课程'
                                : '今日暂无课程',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.grey.shade200 : Colors.blue.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '请选择其他日期查看',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade400 : Colors.blue.shade700,
                            ),
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

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: Card.filled(
                        color: isDark ? Colors.grey.shade800 : Colors.white,
                        elevation: 0,
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                            listTileTheme: ListTileThemeData(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              tileColor: Colors.transparent,
                            ),
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            initiallyExpanded: true,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getTimeSlotColor(timeSlot).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getTimeSlotIcon(timeSlot),
                                color: _getTimeSlotColor(timeSlot),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              timeSlot,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            subtitle: Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getTimeSlotColor(timeSlot).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${courses.length} 节课',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _getTimeSlotColor(timeSlot),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            children: courses.map((course) {
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: _getTimeSlotColor(timeSlot),
                                    child: Text(
                                      _getWeekdayText(course['whatDay']),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    course['context'] ?? '未知课程',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 14,
                                            color: _getTimeSlotColor(timeSlot),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${course['startTime']} - ${course['endTime']}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (course['place'] != null) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on_rounded,
                                              size: 14,
                                              color: _getTimeSlotColor(timeSlot),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                course['place'],
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
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

  Color _getTimeSlotColor(String timeSlot) {
    if (timeSlot.contains('早晨')) return Colors.orange;
    if (timeSlot.contains('上午')) return Colors.blue;
    if (timeSlot.contains('中午')) return Colors.green;
    if (timeSlot.contains('下午')) return Colors.purple;
    if (timeSlot.contains('晚上')) return Colors.indigo;
    return Colors.grey;
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

  Widget _buildExamDetailRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildExams(List<dynamic>? exams, HomePageLogic logic, BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (exams == null) {
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
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
                const SizedBox(height: 16),
                Text(
                  '无法获取考试信息',
                  style: TextStyle(
                    fontSize: 18,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (exams.isEmpty) {
      return Center(
        child: Card.filled(
          color: isDark ? Colors.grey.shade800 : Colors.red.shade50,
          elevation: 0,
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.red.shade900.withValues(alpha: 0.3)
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.quiz_outlined,
                    size: 48,
                    color: isDark ? Colors.red.shade300 : Colors.red.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '暂无考试安排',
                  style: TextStyle(
                    fontSize: 18,
                    color: isDark ? Colors.grey.shade200 : Colors.red.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '请选择其他月份查看',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade400 : Colors.red.shade700,
                  ),
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

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Card.filled(
            color: isDark ? Colors.grey.shade800 : Colors.white,
            elevation: 0,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16.0),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.quiz_outlined,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              title: Text(
                exam['courseNameZh'] ?? '未知考试',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildExamDetailRow(
                      Icons.event_rounded,
                      exam['examDate'] ?? '未知日期',
                      isDark,
                    ),
                    const SizedBox(height: 4),
                    _buildExamDetailRow(
                      Icons.access_time_rounded,
                      '$startTime - $endTime',
                      isDark,
                    ),
                    if (exam['place'] != null) ...[
                      const SizedBox(height: 4),
                      _buildExamDetailRow(
                        Icons.location_on_rounded,
                        exam['place'] ?? '未知地点',
                        isDark,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  }
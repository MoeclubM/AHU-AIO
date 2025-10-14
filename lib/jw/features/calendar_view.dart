import 'package:flutter/material.dart';
import '../api/getcalendar.dart';
import '../models/calendar_model.dart';
import '../../globals.dart' as globals;

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  List<SemesterModel> _semesters = [];
  SemesterModel? _selectedSemester;
  CalendarLayoutModel? _calendarLayout;
  List<CalendarEventModel> _events = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 获取学期列表
      final semestersData = await CalendarApi.getAllSemesters(globals.idToken!);
      final semesters = semestersData
          .map((data) => SemesterModel.fromJson(data))
          .toList();

      // 获取当前学期
      final currentSemesterData = await CalendarApi.getCurrentSemester(globals.idToken!);
      final currentSemesterId = currentSemesterData['id'] as int? ?? 0;

      // 找到当前学期并设为默认选中
      SemesterModel? currentSemester;
      for (final semester in semesters) {
        if (semester.id == currentSemesterId) {
          currentSemester = semester;
          break;
        }
      }

      if (currentSemester != null) {
        await _loadSemesterCalendar(currentSemester);
      }

      setState(() {
        _semesters = semesters;
        _selectedSemester = currentSemester ?? (semesters.isNotEmpty ? semesters.first : null);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSemesterCalendar(SemesterModel semester) async {
    try {
      // 获取校历布局表
      final layoutData = await CalendarApi.getCampusLayoutTable(globals.idToken!, semester.id);
      final layout = CalendarLayoutModel.fromJson(layoutData);

      // 获取校历事件
      final eventsData = await CalendarApi.getCalendarEvents(globals.idToken!, semester.id);
      final events = (eventsData['events'] as List? ?? [])
          .map((data) => CalendarEventModel.fromJson(data))
          .toList();

      setState(() {
        _calendarLayout = layout;
        _events = events;
      });
    } catch (e) {
      // 不设置错误状态，只打印日志
      debugPrint('加载学期校历失败: $e');
    }
  }

  void _onSemesterChanged(SemesterModel? semester) {
    if (semester != null && semester != _selectedSemester) {
      setState(() {
        _selectedSemester = semester;
        _calendarLayout = null;
        _events = [];
      });
      _loadSemesterCalendar(semester);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          '校历查询',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.teal.shade600,
                Colors.teal.shade700,
                Colors.cyan.shade600,
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : Column(
                  children: [
                    _buildSemesterSelector(),
                    Expanded(
                      child: _calendarLayout != null
                          ? _buildCalendarView()
                          : _buildEmptyWidget(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadCalendarData,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无校历数据',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_month,
            color: Colors.teal.shade600,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            '选择学期：',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<SemesterModel>(
              value: _selectedSemester,
              hint: const Text('请选择学期'),
              isExpanded: true,
              underline: const SizedBox(),
              items: _semesters.map((semester) {
                return DropdownMenuItem<SemesterModel>(
                  value: semester,
                  child: Text(semester.name),
                );
              }).toList(),
              onChanged: _onSemesterChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    if (_calendarLayout == null) return _buildEmptyWidget();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCalendarHeader(),
          const SizedBox(height: 16),
          _buildWeekCalendar(),
          if (_events.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildEventsSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    final semester = _selectedSemester!;

    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.school,
                  color: Colors.teal.shade600,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    semester.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildDateInfo('开始', semester.startDate),
                const SizedBox(width: 16),
                _buildDateInfo('结束', semester.endDate),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateInfo(String label, String date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.teal.shade700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            date,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekCalendar() {
    final layout = _calendarLayout!;

    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '教学周历',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildWeekGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekGrid() {
    final layout = _calendarLayout!;
    final weeks = layout.weeklyLayout.keys.toList()..sort();

    return Column(
      children: [
        // 星期标题
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const SizedBox(width: 40), // 周数列宽度
              ...layout.weekDays.map((day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              )),
            ],
          ),
        ),
        const Divider(height: 1),
        // 周数网格
        ...weeks.take(4).map((weekNum) => _buildWeekRow(weekNum, layout.weeklyLayout[weekNum]!)),
        if (weeks.length > 4)
          TextButton(
            onPressed: () {
              // 这里可以展开显示更多周
            },
            child: Text('显示更多周 (${weeks.length - 4}周)'),
          ),
      ],
    );
  }

  Widget _buildWeekRow(int weekNum, List<DayInfo> days) {
    return Container(
      height: 40,
      child: Row(
        children: [
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              '第$weekNum周',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...days.map((day) => Expanded(
            child: Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: day.isToday
                    ? Colors.teal.withOpacity(0.3)
                    : day.isHoliday
                        ? Colors.red.withOpacity(0.1)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: day.isToday
                    ? Border.all(color: Colors.teal, width: 1)
                    : null,
              ),
              child: Center(
                child: Text(
                  day.getDateString(),
                  style: TextStyle(
                    fontSize: 11,
                    color: day.isHoliday ? Colors.red.shade600 : null,
                    fontWeight: day.isToday ? FontWeight.bold : null,
                  ),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildEventsSection() {
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '重要事件',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._events.map((event) => _buildEventItem(event)),
          ],
        ),
      ),
    );
  }

  Widget _buildEventItem(CalendarEventModel event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: event.getEventTypeColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: event.getEventTypeColor().withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: event.getEventTypeColor(),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${event.date.year}-${event.date.month.toString().padLeft(2, '0')}-${event.date.day.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: event.getEventTypeColor(),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              event.eventType,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
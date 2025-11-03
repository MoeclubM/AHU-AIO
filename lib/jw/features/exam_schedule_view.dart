// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_manager.dart';
import '../api/api_models.dart';
import '../../globals.dart' as globals;

/// 考试安排页面
class ExamSchedulePage extends StatefulWidget {
  const ExamSchedulePage({super.key});

  @override
  State<ExamSchedulePage> createState() => _ExamSchedulePageState();
}

class _ExamSchedulePageState extends State<ExamSchedulePage>
    with TickerProviderStateMixin {
  List<ExamInfo> _exams = [];
  List<ExamInfo> _filteredExams = [];
  bool _isLoading = false;
  String? _error;
  late TabController _tabController;

  // 筛选参数
  String _selectedStatus = '全部';
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadExams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExams() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final examsData = await ApiManager.getExamSchedule(globals.idToken!);
      final exams = examsData.map((data) => ExamInfo.fromJson(data)).toList();

      setState(() {
        _exams = exams;
        _filteredExams = exams;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _error = '获取考试安排失败: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredExams = _exams.where((exam) {
        // 状态过滤
        final now = DateTime.now();
        final examDate = DateTime.tryParse(exam.examDate) ?? DateTime.now();
        bool matchesStatus = false;

        switch (_selectedStatus) {
          case '未开始':
            matchesStatus = examDate.isAfter(now);
            break;
          case '进行中':
            final startDateTime = DateTime.tryParse('${exam.examDate} ${exam.startTime}') ?? DateTime.now();
            final endDateTime = DateTime.tryParse('${exam.examDate} ${exam.endTime}') ?? DateTime.now();
            matchesStatus = now.isAfter(startDateTime) && now.isBefore(endDateTime);
            break;
          case '已结束':
            matchesStatus = examDate.isBefore(now);
            break;
          default:
            matchesStatus = true;
        }

        if (!matchesStatus) return false;

        // 搜索查询过滤
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!exam.courseName.toLowerCase().contains(query) &&
              !exam.examType.toLowerCase().contains(query) &&
              !exam.classroom.toLowerCase().contains(query)) {
            return false;
          }
        }

        // 日期范围过滤
        if (_startDate != null && examDate.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null && examDate.isAfter(_endDate!)) {
          return false;
        }

        return true;
      }).toList();

      // 按考试日期排序
      _filteredExams.sort((a, b) {
        final dateA = DateTime.tryParse(a.examDate) ?? DateTime.now();
        final dateB = DateTime.tryParse(b.examDate) ?? DateTime.now();
        return dateA.compareTo(dateB);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          '考试安排',
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
                Colors.red.shade600,
                Colors.red.shade700,
                Colors.pink.shade600,
              ],
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '全部考试', icon: Icon(Icons.list)),
            Tab(text: '即将考试', icon: Icon(Icons.upcoming)),
            Tab(text: '已结束', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorWidget()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildExamList(_filteredExams),
                          _buildExamList(_getUpcomingExams()),
                          _buildExamList(_getPastExams()),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadExams,
        backgroundColor: Colors.red.shade600,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 搜索框
          TextField(
            decoration: InputDecoration(
              hintText: '搜索课程名称、考试类型或教室...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _applyFilters();
            },
          ),

          const SizedBox(height: 12),

          // 状态筛选
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: '考试状态',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ['全部', '未开始', '进行中', '已结束'].map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _startDate == null ? '选择日期范围' :
                    '${DateFormat('MM/dd').format(_startDate!)} - ${DateFormat('MM/dd').format(_endDate ?? _startDate!)}',
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.red.shade600,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _applyFilters();
    }
  }

  List<ExamInfo> _getUpcomingExams() {
    final now = DateTime.now();
    return _filteredExams.where((exam) {
      final examDate = DateTime.tryParse(exam.examDate) ?? DateTime.now();
      return examDate.isAfter(now);
    }).toList();
  }

  List<ExamInfo> _getPastExams() {
    final now = DateTime.now();
    return _filteredExams.where((exam) {
      final examDate = DateTime.tryParse(exam.examDate) ?? DateTime.now();
      return examDate.isBefore(now);
    }).toList();
  }

  Widget _buildExamList(List<ExamInfo> exams) {
    if (exams.isEmpty) {
      return _buildEmptyWidget();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exams.length,
      itemBuilder: (context, index) {
        final exam = exams[index];
        return _buildExamCard(exam);
      },
    );
  }

  Widget _buildExamCard(ExamInfo exam) {
    final now = DateTime.now();
    final examDate = DateTime.tryParse(exam.examDate) ?? DateTime.now();
    final startDateTime = DateTime.tryParse('${exam.examDate} ${exam.startTime}') ?? DateTime.now();
    final endDateTime = DateTime.tryParse('${exam.examDate} ${exam.endTime}') ?? DateTime.now();

    ExamStatus status;
    Color statusColor;
    IconData statusIcon;

    if (examDate.isBefore(now)) {
      status = ExamStatus.ended;
      statusColor = Colors.grey;
      statusIcon = Icons.check_circle;
    } else if (now.isAfter(startDateTime) && now.isBefore(endDateTime)) {
      status = ExamStatus.inProgress;
      statusColor = Colors.orange;
      statusIcon = Icons.play_circle;
    } else {
      status = ExamStatus.upcoming;
      statusColor = Colors.red;
      statusIcon = Icons.schedule;
    }

    return Card.filled(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.courseName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        exam.examType,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      onPressed: () => _showExamDetails(exam),
                      icon: Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.calendar_today,
                    DateFormat('yyyy年MM月dd日').format(examDate),
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.access_time,
                    '${exam.startTime} - ${exam.endTime}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.location_on,
                    exam.classroom,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.event_seat,
                    exam.seatNumber.isNotEmpty ? '座位号: ${exam.seatNumber}' : '座位待分配',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getStatusText(ExamStatus status) {
    switch (status) {
      case ExamStatus.upcoming:
        return '即将考试';
      case ExamStatus.inProgress:
        return '考试中';
      case ExamStatus.ended:
        return '已结束';
    }
  }

  void _showExamDetails(ExamInfo exam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(exam.courseName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('考试类型: ${exam.examType}'),
              Text('考试日期: ${exam.examDate}'),
              Text('考试时间: ${exam.startTime} - ${exam.endTime}'),
              Text('考试地点: ${exam.classroom}'),
              Text('校区: ${exam.campus}'),
              Text('建筑: ${exam.building}'),
              if (exam.seatNumber.isNotEmpty) Text('座位号: ${exam.seatNumber}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
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
            Icons.event_busy_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无考试安排',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '当前没有考试安排信息',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadExams,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

enum ExamStatus { upcoming, inProgress, ended }

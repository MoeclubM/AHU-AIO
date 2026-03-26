// ignore_for_file: sort_child_properties_last, unused_field, use_build_context_synchronously
import 'package:flutter/material.dart';
import '../api/course_selection.dart';
import '../api/api_manager.dart';
import '../api/api_models.dart';
import '../utils/api_debug_helper.dart';
import '../../globals.dart' as globals;

/// 选课页面
class CourseSelectionPage extends StatefulWidget {
  const CourseSelectionPage({super.key});

  @override
  State<CourseSelectionPage> createState() => _CourseSelectionPageState();
}

class _CourseSelectionPageState extends State<CourseSelectionPage>
    with TickerProviderStateMixin {
  List<CourseItem> _availableCourses = [];
  List<CourseItem> _selectedCourses = [];
  SemesterInfo? _currentSemester;
  List<SemesterInfo> _semesters = [];
  List<CourseItem> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;
  late TabController _tabController;

  // 搜索参数
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _loadSemesters();
    await _loadCourses();
  }

  Future<void> _loadSemesters() async {
    final semestersData = await ApiManager.getStudentSemesters(
      globals.idToken!,
    );
    final semesters = semestersData
        .map((data) => SemesterInfo.fromJson(data))
        .toList();

    setState(() {
      _semesters = semesters;
      _currentSemester = semesters.firstWhere(
        (s) => s.isCurrent,
        orElse: () => semesters.first,
      );
    });
  }

  Future<void> _loadCourses() async {
    if (_currentSemester == null) return;

    setState(() {
      _isLoading = true;
    });

    final results = await Future.wait([
      CourseSelectionApi.getAvailableCourses(
        globals.idToken!,
        semesterId: _currentSemester!.semesterId.toString(),
      ),
      CourseSelectionApi.getSelectedCourses(
        globals.idToken!,
        semesterId: _currentSemester!.semesterId.toString(),
      ),
    ]);

    setState(() {
      _availableCourses = results[0]
          .map((data) => CourseItem.fromJson(data))
          .toList();
      _selectedCourses = results[1]
          .map((data) => CourseItem.fromJson(data))
          .toList();
      _searchResults = _availableCourses;
      _isLoading = false;
    });
  }

  Future<void> _searchCourses() async {
    if (_searchQuery.trim().isEmpty) {
      setState(() {
        _searchResults = _availableCourses;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final searchParams = {
      'query': _searchQuery,
      'semesterId': _currentSemester?.semesterId,
    };

    final results = await CourseSelectionApi.searchCourses(
      globals.idToken!,
      searchParams,
    );

    setState(() {
      _searchResults = results
          .map((data) => CourseItem.fromJson(data))
          .toList();
      _isSearching = false;
    });
  }

  Future<void> _selectCourse(CourseItem course, String classId) async {
    final selectionData = {
      'courseId': course.courseId,
      'classId': classId,
      'semesterId': _currentSemester!.semesterId,
    };

    final result = await CourseSelectionApi.selectCourse(
      globals.idToken!,
      selectionData,
    );

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('选课成功: ${course.courseName}'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadCourses(); // 重新加载课程数据
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('选课失败: ${result['message'] ?? '未知错误'}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _dropCourse(CourseItem course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退选'),
        content: Text('确定要退选课程"${course.courseName}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await CourseSelectionApi.dropCourse(
      globals.idToken!,
      course.selectionId!,
    );

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('退选成功: ${course.courseName}'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadCourses();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('退选失败: ${result['message'] ?? '未知错误'}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('选课系统'),
        actions: [
          ApiDebugButton(
            apiName: '选课系统',
            apiUrl:
                'https://jwapp.ahu.edu.cn/eams-course-selection-app/api/courses',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '可选课程', icon: Icon(Icons.search)),
            Tab(text: '已选课程', icon: Icon(Icons.check_circle)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorWidget()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAvailableCoursesTab(),
                _buildSelectedCoursesTab(),
              ],
            ),
    );
  }

  Widget _buildAvailableCoursesTab() {
    return Column(
      children: [
        _buildSearchSection(),
        Expanded(
          child: _isSearching
              ? const Center(child: CircularProgressIndicator())
              : _buildCourseList(_searchResults, true),
        ),
      ],
    );
  }

  Widget _buildSelectedCoursesTab() {
    return Column(
      children: [
        _buildSelectedCoursesHeader(),
        Expanded(
          child: _selectedCourses.isEmpty
              ? _buildEmptyWidget('暂无已选课程', '请前往"可选课程"进行选课')
              : _buildCourseList(_selectedCourses, false),
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
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
      child: TextField(
        decoration: InputDecoration(
          hintText: '搜索课程名称、课程代码或教师...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            onPressed: _searchCourses,
            icon: const Icon(Icons.search),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        onSubmitted: (_) => _searchCourses(),
      ),
    );
  }

  Widget _buildSelectedCoursesHeader() {
    final totalCredits = _selectedCourses.fold(
      0.0,
      (sum, course) => sum + course.credits,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '已选 ${_selectedCourses.length} 门课程',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '总计 $totalCredits 学分',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _loadCourses,
            icon: const Icon(Icons.refresh),
            label: const Text('刷新'),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseList(List<CourseItem> courses, bool isAvailableList) {
    if (courses.isEmpty) {
      return _buildEmptyWidget('未找到符合条件的课程', '请尝试调整搜索条件或筛选选项');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return _buildCourseCard(course, isAvailableList);
      },
    );
  }

  Widget _buildCourseCard(CourseItem course, bool isAvailableList) {
    return Card.filled(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.courseName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${course.courseCode} | ${course.credits}学分',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '教师: ${course.teacherName} | ${course.campus}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isAvailableList
                            ? (course.isAvailable ? Colors.green : Colors.red)
                            : Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isAvailableList
                            ? (course.isAvailable ? '可选' : '已满')
                            : '已选',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isAvailableList && course.isAvailable)
                      ElevatedButton(
                        onPressed: () => _showClassSelectionDialog(course),
                        child: const Text('选课'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    if (!isAvailableList)
                      OutlinedButton(
                        onPressed: () => _dropCourse(course),
                        child: const Text('退选'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    course.schedule,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
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
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadInitialData, child: const Text('重试')),
        ],
      ),
    );
  }

  void _showClassSelectionDialog(CourseItem course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('选择教学班'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('课程: ${course.courseName}'),
            const SizedBox(height: 16),
            // 这里应该显示可选的教学班列表
            // 简化实现，显示一个默认选项
            ListTile(
              title: Text('默认教学班'),
              subtitle: Text(course.schedule),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _selectCourse(course, 'default_class_id');
                },
                child: const Text('选择'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
}

// 课程项目数据模型
class CourseItem {
  final String courseId;
  final String courseName;
  final String courseCode;
  final double credits;
  final String teacherName;
  final String campus;
  final String category;
  final String schedule;
  final bool isAvailable;
  final bool hasConflict;
  final String? selectionId;

  CourseItem({
    required this.courseId,
    required this.courseName,
    required this.courseCode,
    required this.credits,
    required this.teacherName,
    required this.campus,
    required this.category,
    required this.schedule,
    required this.isAvailable,
    this.hasConflict = false,
    this.selectionId,
  });

  factory CourseItem.fromJson(Map<String, dynamic> json) {
    return CourseItem(
      courseId: (json['courseId'] ?? json['id']).toString(),
      courseName: (json['courseName'] ?? json['name']).toString(),
      courseCode: (json['courseCode'] ?? json['code']).toString(),
      credits: (json['credits'] ?? json['credit'] ?? 0.0).toDouble(),
      teacherName: (json['teacherName'] ?? json['teacher']).toString(),
      campus: (json['campus']).toString(),
      category: (json['category']).toString(),
      schedule: (json['schedule']).toString(),
      isAvailable: json['isAvailable'] ?? true,
      hasConflict: json['hasConflict'] ?? false,
      selectionId: (json['selectionId']).toString(),
    );
  }

  /// 创建一个副本并可选择性地更新某些字段
  CourseItem copyWith({
    String? courseId,
    String? courseName,
    String? courseCode,
    double? credits,
    String? teacherName,
    String? campus,
    String? category,
    String? schedule,
    bool? isAvailable,
    bool? hasConflict,
    String? selectionId,
  }) {
    return CourseItem(
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      courseCode: courseCode ?? this.courseCode,
      credits: credits ?? this.credits,
      teacherName: teacherName ?? this.teacherName,
      campus: campus ?? this.campus,
      category: category ?? this.category,
      schedule: schedule ?? this.schedule,
      isAvailable: isAvailable ?? this.isAvailable,
      hasConflict: hasConflict ?? this.hasConflict,
      selectionId: selectionId ?? this.selectionId,
    );
  }
}

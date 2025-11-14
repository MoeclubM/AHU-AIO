// ignore_for_file: unused_field, unused_local_variable
import 'package:flutter/material.dart';
import '../api/getgrades.dart';
import '../models/grade_model.dart';
import '../utils/api_debug_helper.dart';
import '../../globals.dart' as globals;

class GradesPage extends StatefulWidget {
  const GradesPage({super.key});

  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  List<GradeModel> _allGrades = [];
  List<GradeModel> _filteredGrades = [];
  Map<String, List<GradeModel>> _groupedGrades = {};
  List<String> _semesters = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedSemester;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final gradesData = await GradeApi.getStudentGrades(globals.idToken!);
      final grades = gradesData
          .map((data) => GradeModel.fromJson(data))
          .where((grade) => grade.courseName.isNotEmpty)
          .toList();

      // 按学期分组
      final Map<String, List<GradeModel>> grouped = {};
      final Set<String> semesterSet = {};

      for (final grade in grades) {
        if (!grouped.containsKey(grade.semester)) {
          grouped[grade.semester] = [];
        }
        grouped[grade.semester]!.add(grade);
        semesterSet.add(grade.semester);
      }

      
      setState(() {
        _allGrades = grades.isNotEmpty ? grades : grouped.values.expand((e) => e).toList();
        _groupedGrades = grouped;
        _semesters = semesterSet.toList()..sort((a, b) => b.compareTo(a));
        _filteredGrades = _allGrades;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterBySemester(String? semester) {
    setState(() {
      _selectedSemester = semester;
      if (semester == null) {
        _filteredGrades = _allGrades;
      } else {
        _filteredGrades = _allGrades
            .where((grade) => grade.semester == semester)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('成绩查询'),
        actions: [
          ApiDebugButton(
            apiName: '成绩查询',
            apiUrl: 'https://jwapp.ahu.edu.cn/eams-grade-app/api/student/grades',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : Column(
                  children: [
                    _buildSemesterFilter(),
                    Expanded(
                      child: _buildGradesList(),
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
            onPressed: _loadGrades,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterFilter() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 20),
          const SizedBox(width: 8),
          const Text(
            '学期筛选：',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedSemester,
              hint: const Text('全部学期'),
              isExpanded: true,
              underline: const SizedBox(),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('全部学期'),
                ),
                ..._semesters.map((semester) {
                  return DropdownMenuItem<String>(
                    value: semester,
                    child: Text(semester),
                  );
                }),
              ],
              onChanged: _filterBySemester,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradesList() {
    if (_filteredGrades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无成绩数据',
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

    // 按学期分组显示
    final grouped = <String, List<GradeModel>>{};
    for (final grade in _filteredGrades) {
      if (!grouped.containsKey(grade.semester)) {
        grouped[grade.semester] = [];
      }
      grouped[grade.semester]!.add(grade);
    }

    final sortedSemesters = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedSemesters.length,
      itemBuilder: (context, index) {
        final semester = sortedSemesters[index];
        final semesterGrades = grouped[semester]!;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  semester,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: semesterGrades.length,
                separatorBuilder: (context, index) => const Divider(height: 16),
                itemBuilder: (context, gradeIndex) {
                  final grade = semesterGrades[gradeIndex];
                  return _buildGradeItem(grade);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGradeItem(GradeModel grade) {
    final isPass = grade.isPass;
    final scoreColor = isPass ? Colors.green : Colors.red;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分数显示
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isPass ? Colors.green.shade100 : Colors.red.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              grade.gradeLevel,
              style: TextStyle(
                color: isPass ? Colors.green.shade700 : Colors.red.shade700,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 课程信息
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                grade.courseName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${grade.courseCode} | ${grade.courseType} | ${grade.requiredType}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildInfoChip('学分', '${grade.credit}'),
                  const SizedBox(width: 8),
                  _buildInfoChip('绩点', '${grade.gpa}'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../api/jw_api.dart';
import '../models/jw_models.dart';

class JwGradesPage extends StatefulWidget {
  const JwGradesPage({super.key});

  @override
  State<JwGradesPage> createState() => _JwGradesPageState();
}

class _JwGradesPageState extends State<JwGradesPage> {
  final _api = JwApi();
  List<JwSemester> _semesters = [];
  Map<int, List<GradeInfo>> _gradesMap = {};
  int? _selectedSemesterId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAllGrades();
  }

  Future<void> _loadAllGrades() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      if (_api.studentId == null) {
        await _api.fetchStudentIdDirect();
      }
      if (_api.studentId == null) {
        setState(() {
          _error = '无法获取学生信息，请重新登录';
          _isLoading = false;
        });
        return;
      }
      final raw = await _api.getGrades(0);
      final semesters = <JwSemester>[];
      final gradesMap = <int, List<GradeInfo>>{};

      // 解析学期列表
      final semList = raw['semesters'] as List?;
      if (semList != null) {
        for (final s in semList) {
          if (s is Map<String, dynamic>) {
            semesters.add(JwSemester.fromJson(s));
          }
        }
      }

      // 解析成绩
      final semGrades =
          raw['semesterId2studentGrades'] as Map<String, dynamic>?;
      if (semGrades != null) {
        for (final entry in semGrades.entries) {
          final semId = int.tryParse(entry.key);
          if (semId == null) continue;
          final gradeList = entry.value as List?;
          if (gradeList == null) continue;
          gradesMap[semId] = gradeList
              .map((g) => GradeInfo.fromJson(g as Map<String, dynamic>))
              .toList();
        }
      }

      // 如果首次请求没有学期列表，逐个学期请求
      if (semesters.isEmpty && gradesMap.isNotEmpty) {
        for (final id in gradesMap.keys) {
          semesters.add(JwSemester(id: id, nameZh: '学期 $id'));
        }
      }

      setState(() {
        _semesters = semesters;
        _gradesMap = gradesMap;
        _selectedSemesterId = semesters.isNotEmpty ? semesters.first.id : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSemesterGrades(int semesterId) async {
    if (_gradesMap.containsKey(semesterId)) {
      setState(() => _selectedSemesterId = semesterId);
      return;
    }
    try {
      final raw = await _api.getGrades(semesterId);
      final semGrades =
          raw['semesterId2studentGrades'] as Map<String, dynamic>?;
      if (semGrades != null && semGrades.containsKey(semesterId.toString())) {
        final gradeList = semGrades[semesterId.toString()] as List;
        _gradesMap[semesterId] = gradeList
            .map((g) => GradeInfo.fromJson(g as Map<String, dynamic>))
            .toList();
      }
      setState(() => _selectedSemesterId = semesterId);
    } catch (e) {
      setState(() => _selectedSemesterId = semesterId);
    }
  }

  List<GradeInfo> get _currentGrades => _gradesMap[_selectedSemesterId] ?? [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('成绩查询')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAllGrades,
                    child: const Text('重试'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                if (_semesters.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: DropdownButtonFormField<int>(
                      value: _selectedSemesterId,
                      decoration: const InputDecoration(
                        labelText: '选择学期',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: _semesters.map((s) {
                        return DropdownMenuItem(
                          value: s.id,
                          child: Text(s.displayName),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) _loadSemesterGrades(v);
                      },
                    ),
                  ),
                Expanded(
                  child: _currentGrades.isEmpty
                      ? const Center(child: Text('暂无成绩数据'))
                      : _buildGradeList(),
                ),
              ],
            ),
    );
  }

  Widget _buildGradeList() {
    final grades = _currentGrades;
    double totalGpTimesCredit = 0;
    double totalCredits = 0;

    for (final g in grades) {
      if (g.gp != null && g.credits != null) {
        totalGpTimesCredit += g.gp! * g.credits!;
        totalCredits += g.credits!;
      }
    }

    final gpa = totalCredits > 0
        ? (totalGpTimesCredit / totalCredits).toStringAsFixed(2)
        : null;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        if (gpa != null)
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem('课程数', '${grades.length}'),
                  _statItem('总学分', totalCredits.toStringAsFixed(1)),
                  _statItem('GPA', gpa),
                ],
              ),
            ),
          ),
        ...grades.map(_buildGradeCard),
      ],
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildGradeCard(GradeInfo g) {
    final score = g.numericGrade;
    final isLow = score != null && score < 60;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    g.courseName ?? '未知课程',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${g.courseCode ?? ''}  ${g.courseProperty ?? ''}  ${g.courseType ?? ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (g.credits != null)
                    Text(
                      '学分: ${g.credits}',
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  g.gaGrade ?? '-',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isLow
                        ? Colors.red
                        : (g.passed ? Colors.blue : Colors.orange),
                  ),
                ),
                if (g.gp != null)
                  Text(
                    '绩点 ${g.gp!.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

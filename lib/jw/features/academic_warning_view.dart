import 'package:flutter/material.dart';
import '../api/getplan.dart';
import '../utils/api_debug_helper.dart';
import '../../globals.dart' as globals;

/// 培养方案完成情况页面（原版教务系统风格）
class AcademicWarningPage extends StatefulWidget {
  const AcademicWarningPage({super.key});

  @override
  State<AcademicWarningPage> createState() => _AcademicWarningPageState();
}

class _AcademicWarningPageState extends State<AcademicWarningPage> with SingleTickerProviderStateMixin {
  Map<String, dynamic> _planData = {};
  bool _isLoading = false;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPlanData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPlanData() async {
    setState(() {
      _isLoading = true;
    });

    final data = await PlanApi.getPlanCompletion(globals.idToken!);

    setState(() {
      _planData = data;
      _isLoading = false;
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
          '培养方案完成情况',
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
                Colors.blue.shade600,
                Colors.blue.shade700,
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadPlanData,
            icon: const Icon(Icons.refresh),
          ),
          ApiDebugButton(
            apiName: '培养方案完成情况',
            apiUrl: 'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/plan/search/completion/info?code=01',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '计划完成情况'),
            Tab(text: '计划外完成情况'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPlanData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorWidget()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPlanCompletionTab(),
                      _buildOutOfPlanTab(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildPlanCompletionTab() {
    if (_planData.isEmpty) {
      return _buildEmptyWidget();
    }

    final modules = _planData['modules'] as List<dynamic>? ?? [];
    final totalPlanCredits = _planData['totalPlanCredits'] as int? ?? 0;
    final totalCompletedCredits = _calculateTotalCompletedCredits();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 总体完成情况
          _buildOverallProgress(totalCompletedCredits, totalPlanCredits),
          const SizedBox(height: 24),

          // 各模块完成情况
          const Text(
            '各类课程完成情况',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ...modules.map(_buildModuleCard),
        ],
      ),
    );
  }

  Widget _buildOverallProgress(int completed, int total) {
    final percentage = total > 0 ? (completed / total * 100) : 0.0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$completed',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(' / ', style: TextStyle(fontSize: 16)),
                Text(
                  '$total',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const Text(
              '计划学分完成情况',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage >= 80 ? Colors.green :
                percentage >= 60 ? Colors.orange : Colors.red,
              ),
              minHeight: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(module) {
    final name = module['name']?.toString() ?? '';
    final requiredCredits = (module['requiredCredits'] ?? 0).toInt();
    final actualCredits = (module['actualCredits'] ?? 0).toInt();
    final percentage = requiredCredits > 0 ? (actualCredits / requiredCredits * 100) : 0.0;
    final courses = module['courses'] as List<dynamic>? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage >= 100 ? Colors.green :
                percentage >= 50 ? Colors.orange : Colors.red,
              ),
              minHeight: 6,
            ),
            const SizedBox(height: 4),
          ],
        ),
        trailing: Text(
          '$actualCredits / $requiredCredits学分',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: percentage >= 100 ? Colors.green : Colors.black87,
          ),
        ),
        children: [
          if (courses.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '计划内课程',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...courses.map((course) => _buildCourseItem(course)),
                ],
              ),
            ),
          ] else ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '暂无计划内课程',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCourseItem(course) {
    final courseName = course['name']?.toString() ?? course['courseName']?.toString() ?? '未知课程';
    final courseCode = course['code']?.toString() ?? course['courseCode']?.toString() ?? '';
    final credits = (course['credits'] ?? 0).toDouble();
    final result = course['result']?.toString() ?? course['status']?.toString() ?? '未修读';
    final semester = course['semester']?.toString() ?? course['termName']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  courseName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (courseCode.isNotEmpty)
                  Text(
                    courseCode,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: 60,
            child: Text(
              '${credits}学分',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            width: 50,
            child: Text(
              result,
              style: TextStyle(
                fontSize: 11,
                color: _getResultColor(result),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (semester.isNotEmpty)
            Expanded(
              flex: 1,
              child: Text(
                semester,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.right,
              ),
            ),
        ],
      ),
    );
  }

  Color _getResultColor(String result) {
    if (result.contains('通过') || result.contains('及格') ||
        result.contains('优秀') || result.contains('良好') || result.contains('中等')) {
      return Colors.green;
    } else if (result.contains('不通过') || result.contains('不及格')) {
      return Colors.red;
    } else if (result.contains('在读') || result.contains('修读中')) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }

  Widget _buildOutOfPlanTab() {
    final outOfPlanCourses = _planData['outplanCourses'] as List<dynamic>? ?? [];
    final outOfPlanCredits = _planData['outOfPlanCredits'] as int? ?? 0;

    // 计算统计数据
    int passedCredits = 0;
    int failedCredits = 0;
    int studyingCredits = 0;
    int passedCourses = 0;
    int failedCourses = 0;
    int studyingCourses = 0;

    for (var course in outOfPlanCourses) {
      if (course is Map) {
        final credits = (course['course']?['credits'] ?? 0).toDouble();
        final result = course['result']?.toString() ?? '';

        if (_isPassed(result)) {
          passedCredits += (credits.toInt() as int);
          passedCourses++;
        } else if (_isFailed(result)) {
          failedCredits += (credits.toInt() as int);
          failedCourses++;
        } else {
          studyingCredits += (credits.toInt() as int);
          studyingCourses++;
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 计划外学分统计
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '$passedCourses门',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        '$passedCredits学分',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Text('通过'),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '$failedCourses门',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        '$failedCredits学分',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const Text('不通过'),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '$studyingCourses门',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        '$studyingCredits学分',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Text('在读'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            '计划外课程',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // 计划外课程列表
          if (outOfPlanCourses.isNotEmpty) ...[
            ...outOfPlanCourses.map((course) => _buildOutOfPlanCourseItem(course)),
          ] else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无计划外课程',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOutOfPlanCourseItem(course) {
    final courseName = course['course']?['name']?.toString() ?? course['courseName']?.toString() ?? '未知课程';
    final courseCode = course['course']?['code']?.toString() ?? course['courseCode']?.toString() ?? '';
    final credits = (course['course']?['credits'] ?? 0).toDouble();
    final result = course['result']?.toString() ?? course['status']?.toString() ?? '未修读';
    final semester = course['semester']?.toString() ?? course['termName']?.toString() ?? '';
    final gpa = (course['gpa'] ?? 0.0).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          courseName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (courseCode.isNotEmpty)
              Text(
                '课程代码：$courseCode',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            if (semester.isNotEmpty)
              Text(
                '开课学期：$semester',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '学分',
                  style: TextStyle(fontSize: 10),
                ),
                Text(
                  '${credits.toInt()}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '成绩',
                  style: TextStyle(fontSize: 10),
                ),
                Text(
                  result,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: _getResultColor(result),
                  ),
                ),
              ],
            ),
            if (gpa > 0) ...[
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '绩点',
                    style: TextStyle(fontSize: 10),
                  ),
                  Text(
                    gpa.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isPassed(String result) {
    return result.contains('通过') || result.contains('及格') ||
        result.contains('优秀') || result.contains('良好') || result.contains('中等');
  }

  bool _isFailed(String result) {
    return result.contains('不通过') || result.contains('不及格') || result.contains('缺考');
  }

  int _calculateTotalCompletedCredits() {
    final modules = _planData['modules'] as List<dynamic>? ?? [];
    return modules.fold(0, (sum, module) {
      return sum + ((module['actualCredits'] ?? 0) as num).toInt();
    });
  }

  Widget _buildEmptyWidget() {
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
            '暂无培养方案数据',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadPlanData,
            child: const Text('刷新'),
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
            onPressed: _loadPlanData,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}
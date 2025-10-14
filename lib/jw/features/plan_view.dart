import 'package:flutter/material.dart';
import '../api/getplan.dart';
import '../models/plan_model.dart';
import '../../globals.dart' as globals;

class PlanPage extends StatefulWidget {
  const PlanPage({super.key});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  PlanCompletionModel? _planData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlanData();
  }

  Future<void> _loadPlanData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await PlanApi.getPlanCompletion(globals.idToken!);
      final planData = PlanCompletionModel.fromJson(data);

      setState(() {
        _planData = planData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
                Colors.indigo.shade600,
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _planData != null
                  ? _buildPlanContent()
                  : const Center(child: Text('暂无数据')),
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
            onPressed: _loadPlanData,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanContent() {
    final planData = _planData!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCard(planData),
          const SizedBox(height: 20),
          _buildCategoriesSection(planData),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(PlanCompletionModel planData) {
    final overallCompletion = planData.totalCompletionRate;
    final planCompletion = planData.planCompletionRate;

    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.school_outlined,
                  color: Colors.blue.shade600,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  '完成情况概览',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildProgressItem(
              '总体完成率',
              overallCompletion,
              Colors.green,
            ),
            const SizedBox(height: 16),
            _buildProgressItem(
              '计划内完成率',
              planCompletion,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    '计划外学分',
                    '${planData.outOfPlanCredits}',
                    Icons.outlet_outlined,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    '总学分要求',
                    '${planData.totalCredits}',
                    Icons.scoreboard_outlined,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String label, double value, Color color) {
    final percentage = (value * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(PlanCompletionModel planData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '各类别完成情况',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // 优先使用详细的模块数据
        if (planData.modules.isNotEmpty) ...[
          ...planData.modules.map((module) => _buildModuleCard(module)),
        ] else ...[
          ...planData.categories.map((category) => _buildCategoryCard(category)),
        ],
      ],
    );
  }

  Widget _buildCategoryCard(CourseCategory category) {
    final isCompleted = category.isCompleted;
    final completionRate = category.completionRate;
    final percentage = (completionRate * 100).toStringAsFixed(1);

    return Card.filled(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: completionRate,
              backgroundColor: isCompleted ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? Colors.green : Colors.orange,
              ),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '已完成: ${category.actualCredits.toStringAsFixed(1)} 学分',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '要求: ${category.requiredCredits.toStringAsFixed(1)} 学分',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (!isCompleted)
                  Text(
                    '还需: ${category.remainingCredits.toStringAsFixed(1)} 学分',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(CourseModule module) {
    final isCompleted = module.isCompleted;
    final completionRate = module.completionRate;
    final percentage = (completionRate * 100).toStringAsFixed(1);

    return Card.filled(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 模块标题和进度
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (module.remark != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          module.remark!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: completionRate,
              backgroundColor: isCompleted ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? Colors.green : Colors.orange,
              ),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 12),
            // 学分统计
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '已完成: ${module.passedCredits.toStringAsFixed(1)} 学分',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '要求: ${module.requiredCredits.toStringAsFixed(1)} 学分',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (!isCompleted)
                  Text(
                    '还需: ${module.remainingCredits.toStringAsFixed(1)} 学分',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            // 课程统计
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '通过: ${module.passedCoursesCount} | 在读: ${module.takingCoursesCount} | 未修: ${module.unreplicatedCoursesCount}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            // 查看详情按钮
            if (module.planCourses.isNotEmpty) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => _showModuleDetails(module),
                icon: const Icon(Icons.list_alt, size: 16),
                label: const Text('查看课程详情'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
            // 子模块
            if (module.children.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...module.children.map((child) => _buildSubModule(child)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubModule(CourseModule subModule) {
    final isCompleted = subModule.isCompleted;
    final completionRate = subModule.completionRate;
    final percentage = (completionRate * 100).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(top: 8, left: 16),
      child: Card.filled(
        color: Colors.grey.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green : Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      subModule.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.green : Colors.blue,
                    ),
                  ),
                ],
              ),
              if (subModule.planCourses.isNotEmpty) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => _showModuleDetails(subModule),
                  icon: const Icon(Icons.list, size: 14),
                  label: const Text('查看课程'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showModuleDetails(CourseModule module) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏
              Row(
                children: [
                  Expanded(
                    child: Text(
                      module.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 统计信息
              Row(
                children: [
                  _buildStatCard('已完成', module.passedCoursesCount.toString(), Colors.green),
                  const SizedBox(width: 8),
                  _buildStatCard('在读中', module.takingCoursesCount.toString(), Colors.blue),
                  const SizedBox(width: 8),
                  _buildStatCard('未修', module.unreplicatedCoursesCount.toString(), Colors.orange),
                ],
              ),
              const SizedBox(height: 16),
              // 课程列表
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: module.planCourses.length,
                  itemBuilder: (context, index) {
                    final course = module.planCourses[index];
                    return _buildCourseTile(course);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseTile(CourseInfo course) {
    Color statusColor;
    IconData statusIcon;

    if (course.isPassed) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (course.isTaking) {
      statusColor = Colors.blue;
      statusIcon = Icons.schedule;
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.radio_button_unchecked;
    }

    return Card.filled(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(
            statusIcon,
            color: statusColor,
            size: 20,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (course.code.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                course.code,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${course.credits.toStringAsFixed(1)} 学分',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    course.courseType,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              if (course.getFormattedTerms().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  course.getFormattedTerms(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
              if (course.remark != null && course.remark!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  course.remark!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: course.getFormattedScore().isNotEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    course.getFormattedScore(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  if (course.gp != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '绩点: ${course.gp!.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              )
            : null,
      ),
    );
  }
}
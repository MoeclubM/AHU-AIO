import 'package:flutter/material.dart';
import '../api/jw_api.dart';
import '../models/jw_models.dart';

class JwProgramPage extends StatefulWidget {
  final bool embed;
  const JwProgramPage({super.key, this.embed = false});

  @override
  State<JwProgramPage> createState() => _JwProgramPageState();
}

class _JwProgramPageState extends State<JwProgramPage> {
  final _api = JwApi();
  ProgramModule? _root;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // 动态获取 programId，降级使用默认值
      final programId = await _api.fetchProgramId() ?? 3007;
      final raw = await _api.getProgramModules(programId);
      setState(() {
        _root = ProgramModule.fromJson(raw);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embed ? null : AppBar(title: const Text('培养方案')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadData, child: const Text('重试')),
                ],
              ),
            )
          : _root == null
          ? const Center(child: Text('暂无培养方案数据'))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final root = _root!;
    final totalRequired = root.requiredCredits?.toStringAsFixed(1) ?? '-';

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 92),
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  '培养方案完成情况',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '要求总学分: $totalRequired',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...root.children.map(_buildModuleCard),
      ],
    );
  }

  Widget _buildModuleCard(ProgramModule module) {
    final required = module.requiredCredits ?? 0;
    final courses = module.courses;
    final courseCount = courses.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: _moduleIcon(module),
        title: Text(
          module.name ?? '未命名模块',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '要求学分: ${required.toStringAsFixed(1)}  |  课程: $courseCount 门',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          if (courses.isNotEmpty) ...courses.map(_buildCourseTile),
          if (module.children.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: module.children.map(_buildModuleCard).toList(),
              ),
            ),
          if (courses.isEmpty && module.children.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('暂无课程详情', style: TextStyle(color: Colors.grey)),
            ),
        ],
      ),
    );
  }

  Widget _buildCourseTile(ProgramCourse course) {
    return ListTile(
      dense: true,
      leading: Icon(
        course.compulsory ? Icons.check_box : Icons.check_box_outline_blank,
        size: 18,
        color: course.compulsory ? Colors.blue : Colors.grey,
      ),
      title: Text(
        course.courseName ?? '未知课程',
        style: const TextStyle(fontSize: 13),
      ),
      subtitle: Text(
        '${course.courseCode ?? ''}  '
        '学分: ${course.credits ?? '-'}  '
        '学期: ${course.terms.join(", ")}',
        style: const TextStyle(fontSize: 11),
      ),
      trailing: course.compulsory
          ? const Text('必修', style: TextStyle(fontSize: 11, color: Colors.blue))
          : const Text(
              '选修',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
    );
  }

  Widget _moduleIcon(ProgramModule module) {
    final required = module.requiredCredits ?? 0;
    if (required <= 0) {
      return const Icon(Icons.info_outline, size: 20, color: Colors.grey);
    }
    // 简单判断：如果有课程数据就算有进度
    final hasCourses = module.courses.isNotEmpty;
    if (hasCourses) {
      return const Icon(Icons.check_circle, size: 20, color: Colors.green);
    }
    return const Icon(
      Icons.radio_button_unchecked,
      size: 20,
      color: Colors.grey,
    );
  }
}

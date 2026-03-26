// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import '../features/grades_view.dart';
import '../features/plan_view.dart';
import '../features/plan_query_view.dart';
import '../features/room_view.dart';
import '../features/classroom_schedule_view.dart';
import '../features/course_selection_view.dart';
import '../features/academic_warning_view.dart';
import '../features/notice_view.dart';

class FuncPage extends StatelessWidget {
  const FuncPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('更多功能')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: _features.length,
          itemBuilder: (context, index) {
            final feature = _features[index];
            return _buildFeatureCard(context, feature);
          },
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, Feature feature) {
    return Card(
      child: InkWell(
        onTap: () => _handleFeatureTap(context, feature),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                feature.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                feature.subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFeatureTap(BuildContext context, Feature feature) {
    if (feature.isComingSoon) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 8),
              Text('${feature.title}功能正在开发中...'),
            ],
          ),
          backgroundColor: Colors.blue.shade600,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      // 根据功能标题导航到对应页面
      switch (feature.title) {
        case '成绩查询':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GradesPage()),
          );
          break;
        case '空闲教室查询':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RoomPage()),
          );
          break;
        case '培养方案查询':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PlanQueryPage()),
          );
          break;
        case '教室课表查询':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ClassroomSchedulePage(),
            ),
          );
          break;
        case '通知公告':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NoticePage()),
          );
          break;
        case '选课系统':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CourseSelectionPage(),
            ),
          );
          break;
        case '培养方案完成情况':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AcademicWarningPage(),
            ),
          );
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('正在打开${feature.title}...'),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
      }
    }
  }
}

class Feature {
  final String title;
  final String subtitle;
  final bool isComingSoon;

  const Feature({
    required this.title,
    required this.subtitle,
    this.isComingSoon = true,
  });
}

final List<Feature> _features = [
  const Feature(title: '通知公告', subtitle: '查看学校通知公告', isComingSoon: false),
  const Feature(title: '培养方案完成情况', subtitle: '查看学分完成进度', isComingSoon: false),
  const Feature(title: '培养方案查询', subtitle: '查看专业培养计划', isComingSoon: false),
  const Feature(title: '成绩查询', subtitle: '查看考试成绩', isComingSoon: false),
  const Feature(title: '空闲教室查询', subtitle: '查找可用教室', isComingSoon: false),
  const Feature(title: '教室课表查询', subtitle: '查看教室使用情况', isComingSoon: false),
  const Feature(title: '选课系统', subtitle: '在线选课和退选', isComingSoon: false),
];

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          '更多功能',
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: _features.length,
          itemBuilder: (context, index) {
            final feature = _features[index];
            return _buildFeatureCard(context, feature, isDark);
          },
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, Feature feature, bool isDark) {
    return Card.filled(
      elevation: 4,
      color: isDark ? Colors.grey.shade800 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _handleFeatureTap(context, feature),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: feature.gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  feature.icon,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                feature.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                feature.subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
            MaterialPageRoute(builder: (context) => const ClassroomSchedulePage()),
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
            MaterialPageRoute(builder: (context) => const CourseSelectionPage()),
          );
          break;
        case '培养方案完成情况':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AcademicWarningPage()),
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
  final IconData icon;
  final List<Color> gradientColors;
  final bool isComingSoon;

  const Feature({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    this.isComingSoon = true,
  });
}

final List<Feature> _features = [
  Feature(
    title: '通知公告',
    subtitle: '查看学校通知公告',
    icon: Icons.notifications_outlined,
    gradientColors: [Colors.amber.shade400, Colors.amber.shade600],
    isComingSoon: false,
  ),
  Feature(
    title: '培养方案完成情况',
    subtitle: '查看学分完成进度',
    icon: Icons.school_outlined,
    gradientColors: [Colors.green.shade400, Colors.green.shade600],
    isComingSoon: false,
  ),
  Feature(
    title: '培养方案查询',
    subtitle: '查看专业培养计划',
    icon: Icons.menu_book_outlined,
    gradientColors: [Colors.purple.shade400, Colors.purple.shade600],
    isComingSoon: false,
  ),
  Feature(
    title: '成绩查询',
    subtitle: '查看考试成绩',
    icon: Icons.grade_outlined,
    gradientColors: [Colors.orange.shade400, Colors.orange.shade600],
    isComingSoon: false,
  ),
  Feature(
    title: '空闲教室查询',
    subtitle: '查找可用教室',
    icon: Icons.meeting_room_outlined,
    gradientColors: [Colors.teal.shade400, Colors.teal.shade600],
    isComingSoon: false,
  ),
  Feature(
    title: '教室课表查询',
    subtitle: '查看教室使用情况',
    icon: Icons.calendar_today_outlined,
    gradientColors: [Colors.cyan.shade400, Colors.cyan.shade600],
    isComingSoon: false,
  ),
  Feature(
    title: '选课系统',
    subtitle: '在线选课和退选',
    icon: Icons.add_task_outlined,
    gradientColors: [Colors.deepOrange.shade400, Colors.deepOrange.shade600],
    isComingSoon: false,
  ),
];

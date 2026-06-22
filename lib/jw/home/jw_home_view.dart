import 'package:flutter/material.dart';
import '../../globals.dart' as globals;
import '../api/jw_api.dart';
import '../login/jw_login_service.dart';
import '../login/jw_login_view.dart';
import '../pages/jw_grades_page.dart';
import '../pages/jw_schedule_page.dart';
import '../pages/jw_exam_page.dart';
import '../pages/jw_program_page.dart';
import '../pages/jw_student_info_page.dart';
import '../pages/jw_precaution_page.dart';
import '../pages/jw_course_select_page.dart';
import '../pages/jw_notice_page.dart';

/// 新教务系统首页
class JwHomePage extends StatefulWidget {
  final bool embed;
  const JwHomePage({super.key, this.embed = false});

  @override
  State<JwHomePage> createState() => _JwHomePageState();
}

class _JwHomePageState extends State<JwHomePage> {
  final _api = JwApi();
  Map<String, dynamic>? _teachWeek;
  Map<String, dynamic>? _notices;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    try {
      await _api.init();
    } catch (_) {}
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _api.getCurrentTeachWeek(),
        _api.getNoticeCounts(),
      ]);

      setState(() {
        _teachWeek = results[0];
        _notices = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  void _logout() async {
    await JwLoginService.logout();
    if (!mounted) return;
    if (globals.onLoginStateChanged == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const JwLoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embed
          ? null
          : AppBar(
              title: const Text('安大教务'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _logout,
                  tooltip: '退出登录',
                ),
              ],
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadData, child: const Text('重试')),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildTeachWeekCard(),
                  const SizedBox(height: 16),
                  _buildNoticeCard(),
                  const SizedBox(height: 16),
                  _buildFeatureGrid(),
                ],
              ),
            ),
    );
  }

  Widget _buildTeachWeekCard() {
    final week = _teachWeek;
    if (week == null) return const SizedBox();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              week['currentSemester'] ?? '',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '第 ${week['weekIndex'] ?? '?'} 周',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              week['isInSemester'] == true ? '教学进行中' : '非教学周',
              style: TextStyle(
                fontSize: 14,
                color: week['isInSemester'] == true
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeCard() {
    final notices = _notices;
    if (notices == null) return const SizedBox();

    final noticeCount = notices['noticeCount'] ?? {};
    final noReadCount = noticeCount['noReadCount'] ?? 0;

    return Card(
      child: ListTile(
        leading: Icon(
          noReadCount > 0
              ? Icons.notifications_active
              : Icons.notifications_none,
          color: noReadCount > 0 ? Colors.orange : Colors.grey,
        ),
        title: const Text('通知公告'),
        subtitle: Text('未读 $noReadCount 条'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const JwNoticePage()),
          );
        },
      ),
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      _Feature('成绩查询', Icons.grade, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const JwGradesPage()),
        );
      }),
      _Feature('我的课表', Icons.schedule, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const JwSchedulePage()),
        );
      }),
      _Feature('考试安排', Icons.quiz, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const JwExamPage()),
        );
      }),
      _Feature('培养方案', Icons.menu_book, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const JwProgramPage()),
        );
      }),
      _Feature('学籍信息', Icons.badge, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const JwStudentInfoPage()),
        );
      }),
      _Feature('学业预警', Icons.warning, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const JwPrecautionPage()),
        );
      }),
      _Feature('选课系统', Icons.app_registration, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const JwCourseSelectPage()),
        );
      }),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final f = features[index];
        return Card(
          child: InkWell(
            onTap: f.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(f.icon, size: 28, color: Colors.blue),
                const SizedBox(height: 8),
                Text(
                  f.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Feature {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  _Feature(this.title, this.icon, this.onTap);
}

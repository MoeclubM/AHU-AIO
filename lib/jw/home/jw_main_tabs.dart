import 'package:flutter/material.dart';
import '../../globals.dart' as globals;
import '../login/jw_login_service.dart';
import '../login/jw_login_view.dart';
import 'jw_home_view.dart';
import '../pages/jw_schedule_page.dart';
import '../pages/jw_grades_page.dart';
import '../pages/jw_notice_page.dart';
import '../pages/jw_program_page.dart';

class JwMainTabs extends StatefulWidget {
  const JwMainTabs({super.key});

  @override
  State<JwMainTabs> createState() => _JwMainTabsState();
}

class _JwMainTabsState extends State<JwMainTabs> {
  void _logout() async {
    await JwLoginService.logout();
    globals.onLoginStateChanged?.call();
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
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('安大教务'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: '退出登录',
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: '首页', icon: Icon(Icons.home)),
              Tab(text: '课表', icon: Icon(Icons.schedule)),
              Tab(text: '成绩', icon: Icon(Icons.grade)),
              Tab(text: '通知', icon: Icon(Icons.notifications)),
              Tab(text: '方案', icon: Icon(Icons.description)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            JwHomePage(embed: true),
            JwSchedulePage(embed: true),
            JwGradesPage(embed: true),
            JwNoticePage(embed: true),
            JwProgramPage(embed: true),
          ],
        ),
      ),
    );
  }
}

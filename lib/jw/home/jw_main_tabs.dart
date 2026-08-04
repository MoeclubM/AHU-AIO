import 'package:flutter/material.dart';
import '../../miuix/liquid_glass_app_bar.dart';
import 'jw_home_view.dart';
import '../pages/jw_schedule_page.dart';
import '../pages/jw_grades_page.dart';
import '../pages/jw_notice_page.dart';
import '../pages/jw_program_page.dart';

class JwMainTabs extends StatefulWidget {
  final bool isActive;
  final PageController pageController;
  const JwMainTabs({
    super.key,
    this.isActive = false,
    required this.pageController,
  });

  @override
  State<JwMainTabs> createState() => _JwMainTabsState();
}

class _JwMainTabsState extends State<JwMainTabs> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LiquidGlassAppBar(
        title: '安大教务',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: IconButton(
              icon: const Icon(Icons.notifications_none_outlined, size: 20),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const JwNoticePage()),
                );
              },
              tooltip: '通知公告',
            ),
          ),
        ],
      ),
      body: PageView(
        physics: const NeverScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        controller: widget.pageController,
        children: const [
          JwHomePage(embed: true),
          JwSchedulePage(embed: true),
          JwGradesPage(embed: true),
          JwProgramPage(embed: true),
        ],
      ),
    );
  }
}

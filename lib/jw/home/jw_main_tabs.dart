import 'dart:ui';
import 'package:flutter/material.dart';
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

class _JwMainTabsState extends State<JwMainTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        toolbarHeight: 52,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(0.68),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withOpacity(0.5),
                      width: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          '安大教务',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
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
      body: TabBarView(
        controller: _tabController,
        children: const [
          JwHomePage(embed: true),
          JwSchedulePage(embed: true),
          JwGradesPage(embed: true),
          JwProgramPage(embed: true),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withOpacity(0.35),
                      width: 0.8,
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    indicator: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    labelStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: const TextStyle(fontSize: 10),
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.home_outlined, size: 18),
                        text: '首页',
                      ),
                      Tab(
                        icon: Icon(Icons.schedule_outlined, size: 18),
                        text: '课表',
                      ),
                      Tab(
                        icon: Icon(Icons.grade_outlined, size: 18),
                        text: '成绩',
                      ),
                      Tab(
                        icon: Icon(Icons.description_outlined, size: 18),
                        text: '方案',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

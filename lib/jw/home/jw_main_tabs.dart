import 'dart:ui';
import 'package:flutter/material.dart';
import 'jw_home_view.dart';
import '../pages/jw_schedule_page.dart';
import '../pages/jw_grades_page.dart';
import '../pages/jw_notice_page.dart';
import '../pages/jw_program_page.dart';

class JwMainTabs extends StatefulWidget {
  final bool isActive;
  const JwMainTabs({super.key, this.isActive = false});

  @override
  State<JwMainTabs> createState() => _JwMainTabsState();
}

class _JwMainTabsState extends State<JwMainTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 1.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
        );
    if (widget.isActive) {
      _animController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant JwMainTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _animController.forward(from: 0.0);
    } else if (!widget.isActive && oldWidget.isActive) {
      _animController.reverse();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animController.dispose();
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
        centerTitle: true,
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
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: const [
              JwHomePage(embed: true),
              JwSchedulePage(embed: true),
              JwGradesPage(embed: true),
              JwProgramPage(embed: true),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: SafeArea(
                top: false,
                bottom: true,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: Container(
                    decoration: const BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.transparent,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withOpacity(0.08),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant.withOpacity(0.35),
                              width: 0.8,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 56,
                                child: TabBar(
                                  controller: _tabController,
                                  isScrollable: false,
                                  indicatorSize: TabBarIndicatorSize.tab,
                                  indicatorPadding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 8,
                                  ),
                                  indicator: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  labelStyle: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  unselectedLabelStyle: const TextStyle(
                                    fontSize: 10.5,
                                  ),
                                  labelColor: Theme.of(context).colorScheme.primary,
                                  unselectedLabelColor: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                                  tabs: const [
                                    Tab(
                                      icon: Icon(Icons.home_outlined, size: 20),
                                      text: '首页',
                                    ),
                                    Tab(
                                      icon: Icon(Icons.schedule_outlined, size: 20),
                                      text: '课表',
                                    ),
                                    Tab(
                                      icon: Icon(Icons.grade_outlined, size: 20),
                                      text: '成绩',
                                    ),
                                    Tab(
                                      icon: Icon(
                                        Icons.description_outlined,
                                        size: 20,
                                      ),
                                      text: '方案',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 64),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

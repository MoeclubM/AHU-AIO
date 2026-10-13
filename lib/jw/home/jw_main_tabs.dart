import 'package:flutter/material.dart';
import '../../adaptive_ui.dart';
import '../../miuix/adaptive_top_app_bar.dart';
import '../../theme_manager.dart';
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

class _JwMainTabsState extends State<JwMainTabs>
    with AutomaticKeepAliveClientMixin {
  final _themeManager = ThemeManager();
  final GlobalKey<JwSchedulePageState> _schedulePageKey =
      GlobalKey<JwSchedulePageState>();
  int _currentSubPage = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _themeManager.addListener(_onThemeChanged);
    _currentSubPage = widget.pageController.hasClients
        ? widget.pageController.page?.round() ?? 0
        : 0;
    widget.pageController.addListener(_onSubPageChanged);
  }

  @override
  void dispose() {
    _themeManager.removeListener(_onThemeChanged);
    widget.pageController.removeListener(_onSubPageChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant JwMainTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive && _currentSubPage == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _schedulePageKey.currentState?.refresh();
      });
    }
  }

  void _onSubPageChanged() {
    if (!widget.pageController.hasClients) return;
    final page = widget.pageController.page?.round() ?? _currentSubPage;
    if (page == _currentSubPage) return;
    _currentSubPage = page;
    if (page == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _schedulePageKey.currentState?.refresh();
      });
    }
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final showTitle = _themeManager.showAppBarTitle;
    return Scaffold(
      appBar: showTitle
          ? AdaptiveTopAppBar(
              title: const Text('安大教务'),
              actions: [
                AdaptiveIconButton(
                  icon: const Icon(Icons.notifications_none_outlined),
                  tooltip: '通知公告',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const JwNoticePage(),
                      ),
                    );
                  },
                ),
              ],
            )
          : null,
      body: SafeArea(
        top: !showTitle,
        bottom: false,
        child: PageView(
          physics: const NeverScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          controller: widget.pageController,
          children: [
            JwHomePage(embed: true),
            JwSchedulePage(key: _schedulePageKey, embed: true),
            JwGradesPage(embed: true),
            JwProgramPage(embed: true),
          ],
        ),
      ),
    );
  }
}

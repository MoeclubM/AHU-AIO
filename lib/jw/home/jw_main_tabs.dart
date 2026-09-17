import 'package:flutter/material.dart';
import '../../adaptive_ui.dart';
import '../../miuix/liquid_glass_app_bar.dart';
import '../../theme_manager.dart';
import 'jw_home_view.dart';
import '../../jwapp/schedule/schedule_view.dart';
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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _themeManager.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeManager.removeListener(_onThemeChanged);
    super.dispose();
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
          ? LiquidGlassAppBar(
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
          children: const [
            JwHomePage(embed: true),
            SchedulePage(embed: true),
            JwGradesPage(embed: true),
            JwProgramPage(embed: true),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../miuix/liquid_glass_app_bar.dart';
import '../../theme_manager.dart';
import '../home/home_view.dart';
import '../schedule/schedule_view.dart';
import '../features/grades_view.dart';
import '../features/room_view.dart';
import '../features/notice_view.dart';
import 'mainpage_service.dart';

class MainPage extends StatefulWidget {
  final bool isActive;
  final PageController pageController;
  const MainPage({
    super.key,
    this.isActive = false,
    required this.pageController,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentPage = 0;
  final _themeManager = ThemeManager();

  @override
  void initState() {
    super.initState();
    _themeManager.addListener(_onThemeChanged);
    MainPageService.checkTokenAndNavigate(context);
    _currentPage = widget.pageController.hasClients
        ? widget.pageController.page?.round() ?? 0
        : 0;
    widget.pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _themeManager.removeListener(_onThemeChanged);
    widget.pageController.removeListener(_onPageChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  void _onPageChanged() {
    if (widget.pageController.hasClients) {
      final newPage = widget.pageController.page?.round() ?? 0;
      if (newPage != _currentPage) {
        setState(() {
          _currentPage = newPage;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showTitle = _themeManager.showAppBarTitle;
    return Scaffold(
      appBar: showTitle
          ? LiquidGlassAppBar(
              title: '安大微教务',
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: IconButton(
                    icon: const Icon(
                      Icons.notifications_none_outlined,
                      size: 20,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NoticePage(),
                        ),
                      );
                    },
                    tooltip: '通知公告',
                  ),
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
            HomePage(isVisible: _currentPage == 0, embed: true),
            const SchedulePage(embed: true),
            const GradesPage(embed: true),
            const RoomPage(embed: true),
          ],
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    MainPageService.checkTokenAndNavigate(context);
    _currentPage = widget.pageController.hasClients
        ? widget.pageController.page?.round() ?? 0
        : 0;
    widget.pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_onPageChanged);
    super.dispose();
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
    return Scaffold(
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
                filter: ImageFilter.blur(
                  sigmaX: MediaQuery.highContrastOf(context) ? 0 : 12,
                  sigmaY: MediaQuery.highContrastOf(context) ? 0 : 12,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(
                      MediaQuery.highContrastOf(context) ? 0.96 : 0.68,
                    ),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant
                          .withOpacity(
                            MediaQuery.highContrastOf(context) ? 0.9 : 0.5,
                          ),
                      width: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          '安大微教务',
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
                  MaterialPageRoute(builder: (context) => const NoticePage()),
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
        children: [
          HomePage(isVisible: _currentPage == 0, embed: true),
          const SchedulePage(embed: true),
          const GradesPage(embed: true),
          const RoomPage(embed: true),
        ],
      ),
    );
  }
}

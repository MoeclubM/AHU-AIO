import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'globals.dart' as globals;
import 'jwapp/mainpage/mainpage_view.dart';
import 'jw/home/jw_main_tabs.dart';
import 'finance/api/synjones_client.dart';
import 'finance/home/finance_main_tabs.dart';
import 'app_settings_screen.dart';
import 'auth/unified_login_page.dart';
import 'auth/cas_auth_cache.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen>
    with TickerProviderStateMixin {
  bool _isInitializing = true;
  int _currentBottomIndex = 0;
  final SynjonesClient _synjonesClient = SynjonesClient();
  late PageController _pageController;
  final ValueNotifier<double> _pagePercentNotifier = ValueNotifier(0.0);
  bool _isDraggingBubble = false;
  late PageController _microPageController;
  late PageController _jwPageController;
  late PageController _financePageController;

  late AnimationController _subTabAnimController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      _pagePercentNotifier.value = _pageController.page ?? 0.0;
    });

    _microPageController = PageController();
    _jwPageController = PageController();
    _financePageController = PageController();

    _subTabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    if (_currentBottomIndex >= 0 && _currentBottomIndex <= 2) {
      _subTabAnimController.value = 1.0;
    } else {
      _subTabAnimController.value = 0.0;
    }

    // Register the global state change notifier
    globals.onLoginStateChanged = _onLoginStateChanged;
    _checkInit();
  }

  @override
  void dispose() {
    if (globals.onLoginStateChanged == _onLoginStateChanged) {
      globals.onLoginStateChanged = null;
    }
    _pageController.dispose();
    _pagePercentNotifier.dispose();
    _microPageController.dispose();
    _jwPageController.dispose();
    _financePageController.dispose();
    _subTabAnimController.dispose();
    super.dispose();
  }

  void _onLoginStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _checkInit() async {
    setState(() {
      _isInitializing = true;
    });
    await _synjonesClient.init();
    final prefs = await SharedPreferences.getInstance();
    final cachedIdToken = prefs.getString('idToken');
    if (cachedIdToken != null) {
      globals.idToken = cachedIdToken;
    }
    globals.jwLoggedIn = await CasAuthCache.isLoggedIn();
    globals.jwStudentNo = prefs.getString('jwStudentNo');
    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Widget _buildSubTabBarChild(double currentPage) {
    PageController? controller;
    List<Map<String, dynamic>> tabs = [];
    final activeIndex = currentPage.round();

    if (activeIndex == 0) {
      controller = _microPageController;
      tabs = const [
        {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'text': '首页'},
        {
          'icon': Icons.schedule_outlined,
          'activeIcon': Icons.schedule,
          'text': '课表',
        },
        {'icon': Icons.grade_outlined, 'activeIcon': Icons.grade, 'text': '成绩'},
        {
          'icon': Icons.meeting_room_outlined,
          'activeIcon': Icons.meeting_room,
          'text': '空闲教室',
        },
      ];
    } else if (activeIndex == 1) {
      controller = _jwPageController;
      tabs = const [
        {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'text': '首页'},
        {
          'icon': Icons.schedule_outlined,
          'activeIcon': Icons.schedule,
          'text': '课表',
        },
        {'icon': Icons.grade_outlined, 'activeIcon': Icons.grade, 'text': '成绩'},
        {
          'icon': Icons.description_outlined,
          'activeIcon': Icons.description,
          'text': '方案',
        },
      ];
    } else if (activeIndex == 2) {
      controller = _financePageController;
      tabs = const [
        {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'text': '主页'},
        {
          'icon': Icons.qr_code_outlined,
          'activeIcon': Icons.qr_code,
          'text': '一码通',
        },
        {
          'icon': Icons.payment_outlined,
          'activeIcon': Icons.payment,
          'text': '充值缴费',
        },
      ];
    }

    if (controller == null) return const SizedBox.shrink();

    return _buildCustomSubTabBar(controller, tabs, activeIndex);
  }

  Widget _buildCustomSubTabBar(
    PageController controller,
    List<Map<String, dynamic>> tabs,
    int activeIndex,
  ) {
    final int tabCount = tabs.length;
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      key: ValueKey(activeIndex),
      builder: (context, constraints) {
        final double totalWidth = constraints.maxWidth;
        final double tabWidth = totalWidth / tabCount;
        final double bubbleWidth = tabWidth - 12;
        final double bubbleHeight = 40;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: (details) {
            if (!controller.hasClients) return;
            final double pageViewWidth = MediaQuery.of(context).size.width;
            final double dragDelta = details.delta.dx;
            final double targetOffset =
                controller.offset + dragDelta * (pageViewWidth / tabWidth);
            final double maxOffset = pageViewWidth * (tabCount - 1);
            controller.jumpTo(targetOffset.clamp(0.0, maxOffset));
          },
          onHorizontalDragEnd: (details) {
            if (!controller.hasClients) return;
            final int targetIndex = (controller.page ?? 0.0).round().clamp(
              0,
              tabCount - 1,
            );
            controller.animateToPage(
              targetIndex,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          },
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final double displayPage = controller.hasClients
                  ? (controller.page ?? 0.0)
                  : 0.0;

              return Stack(
                children: [
                  Positioned(
                    left: displayPage * tabWidth + (tabWidth - bubbleWidth) / 2,
                    top: (56 - bubbleHeight) / 2,
                    width: bubbleWidth,
                    height: bubbleHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(tabCount, (index) {
                      final tab = tabs[index];
                      final bool isSelected = displayPage.round() == index;
                      return Expanded(
                        child: InkWell(
                          onTap: () {
                            controller.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          highlightColor: Colors.transparent,
                          splashColor: colorScheme.primary.withOpacity(0.1),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isSelected ? tab['activeIcon'] : tab['icon'],
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant.withOpacity(
                                        0.7,
                                      ),
                                size: 18,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tab['text'],
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant
                                            .withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  double _getSubTabVisibility(double page) {
    int left = page.floor();
    int right = page.ceil();
    double t = page - left;

    bool leftHasSub = left >= 0 && left <= 2;
    bool rightHasSub = right >= 0 && right <= 2;

    if (leftHasSub && rightHasSub) {
      return (1.0 - 2.0 * t).abs();
    } else if (leftHasSub && !rightHasSub) {
      if (t < 0.5) {
        return 1.0 - 2.0 * t;
      } else {
        return 0.0;
      }
    } else if (!leftHasSub && rightHasSub) {
      if (t > 0.5) {
        return 2.0 * (t - 0.5);
      } else {
        return 0.0;
      }
    } else {
      return 0.0;
    }
  }

  Future<void> _handleTabSwitch(int index) async {
    if (index == _currentBottomIndex) return;

    if (mounted) {
      await _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      setState(() {
        _currentBottomIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool isLoggedIn =
        globals.idToken != null ||
        globals.jwLoggedIn ||
        _synjonesClient.loggedIn;

    if (!isLoggedIn) {
      return UnifiedLoginPage(
        onLoginSuccess: () {
          setState(() {});
        },
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentBottomIndex = index;
              });
              if (index >= 0 && index <= 2) {
                _subTabAnimController.forward();
              } else {
                _subTabAnimController.reverse();
              }
            },
            children: [
              MainPage(
                isActive: _currentBottomIndex == 0,
                pageController: _microPageController,
              ),
              JwMainTabs(
                isActive: _currentBottomIndex == 1,
                pageController: _jwPageController,
              ),
              FinanceMainTabs(
                isActive: _currentBottomIndex == 2,
                pageController: _financePageController,
              ),
              AppSettingsScreen(onSwitchTab: _handleTabSwitch),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              bottom: true,
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _pagePercentNotifier,
                  _subTabAnimController,
                ]),
                builder: (context, child) {
                  final double currentPage = _pagePercentNotifier.value;
                  final gestureVisibility = _getSubTabVisibility(currentPage);
                  final finalVisibility =
                      _subTabAnimController.value * gestureVisibility;
                  final double yOffset = (1.0 - finalVisibility) * 44.0;

                  return Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Transform.translate(
                        offset: Offset(0, yOffset),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(64, 0, 64, 76),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surface.withOpacity(0.08),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                  border: Border(
                                    top: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant
                                          .withOpacity(0.35),
                                      width: 0.8,
                                    ),
                                    left: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant
                                          .withOpacity(0.35),
                                      width: 0.8,
                                    ),
                                    right: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant
                                          .withOpacity(0.35),
                                      width: 0.8,
                                    ),
                                    bottom: BorderSide.none,
                                  ),
                                ),
                                child: _buildSubTabBarChild(currentPage),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
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
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant
                                        .withOpacity(0.35),
                                    width: 0.8,
                                  ),
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final double totalWidth =
                                        constraints.maxWidth;
                                    final double tabWidth = totalWidth / 4;
                                    final double bubbleWidth = tabWidth - 8;
                                    final double bubbleHeight = 48;

                                    return GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onHorizontalDragStart: (details) {
                                        final double bubbleLeft =
                                            currentPage * tabWidth +
                                            (tabWidth - bubbleWidth) / 2;
                                        final double bubbleRight =
                                            bubbleLeft + bubbleWidth;
                                        final double touchX =
                                            details.localPosition.dx;
                                        _isDraggingBubble =
                                            touchX >= bubbleLeft &&
                                            touchX <= bubbleRight;
                                      },
                                      onHorizontalDragUpdate: (details) {
                                        if (!_isDraggingBubble) return;
                                        if (!_pageController.hasClients) return;
                                        final double pageViewWidth =
                                            MediaQuery.of(context).size.width;
                                        final double dragDelta =
                                            details.delta.dx;
                                        final double targetOffset =
                                            _pageController.offset +
                                            dragDelta *
                                                (pageViewWidth / tabWidth);
                                        final double maxOffset =
                                            pageViewWidth * 3;
                                        _pageController.jumpTo(
                                          targetOffset.clamp(0.0, maxOffset),
                                        );
                                      },
                                      onHorizontalDragEnd: (details) {
                                        if (!_isDraggingBubble) return;
                                        if (!_pageController.hasClients) return;
                                        final int targetPage = currentPage
                                            .round();
                                        _pageController.animateToPage(
                                          targetPage,
                                          duration: const Duration(
                                            milliseconds: 250,
                                          ),
                                          curve: Curves.easeOut,
                                        );
                                      },
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            left:
                                                currentPage * tabWidth +
                                                (tabWidth - bubbleWidth) / 2,
                                            top: (64 - bubbleHeight) / 2,
                                            width: bubbleWidth,
                                            height: bubbleHeight,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0.12),
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                              ),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              _buildTabItem(
                                                0,
                                                Icons.bolt_outlined,
                                                Icons.bolt,
                                                '微教务',
                                              ),
                                              _buildTabItem(
                                                1,
                                                Icons.school_outlined,
                                                Icons.school,
                                                '安大教务',
                                              ),
                                              _buildTabItem(
                                                2,
                                                Icons.credit_card_outlined,
                                                Icons.credit_card,
                                                '一卡通',
                                              ),
                                              _buildTabItem(
                                                3,
                                                Icons.settings_outlined,
                                                Icons.settings,
                                                '设置',
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final bool isSelected = _currentBottomIndex == index;
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: () => _handleTabSwitch(index),
        borderRadius: BorderRadius.circular(32),
        highlightColor: Colors.transparent,
        splashColor: colorScheme.primary.withOpacity(0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant.withOpacity(0.7),
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

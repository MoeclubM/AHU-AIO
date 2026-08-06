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
import 'miuix/miuix_theme.dart';
import 'miuix/bloom_stroke_painter.dart';
import 'miuix/liquid_glass_filter.dart';
import 'theme_manager.dart';

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
  // SukiSU-style bubble press spring: pressProgress spring(1, 1000).
  late AnimationController _bubblePressController;
  // InteractiveHighlight touch position relative to the bubble bar.
  final ValueNotifier<Offset> _highlightPosNotifier =
      ValueNotifier(Offset.zero);
  bool _showHighlight = false;
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

    _bubblePressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
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
    _bubblePressController.dispose();
    _highlightPosNotifier.dispose();
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
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        View.of(context).platformDispatcher.accessibilityFeatures.reduceMotion;

    return LayoutBuilder(
      key: ValueKey(activeIndex),
      builder: (context, constraints) {
        final double totalWidth = constraints.maxWidth;
        final double tabWidth = totalWidth / tabCount;
        final double bubbleWidth = tabWidth - 12;
        final double bubbleHeight = 40;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: (_) {
            if (controller.hasClients) {
              (controller.position as ScrollPositionWithSingleContext).goIdle();
            }
          },
          onHorizontalDragUpdate: (details) {
            if (!controller.hasClients) return;
            final position = controller.position;
            final double pageViewWidth = position.viewportDimension;
            final double dragDelta = details.delta.dx;
            double targetOffset =
                controller.offset + dragDelta * (pageViewWidth / tabWidth);
            if (targetOffset < position.minScrollExtent) {
              final overshoot = targetOffset - position.minScrollExtent;
              targetOffset =
                  position.minScrollExtent +
                  (overshoot * pageViewWidth * 0.55) /
                      (pageViewWidth + 0.55 * overshoot.abs());
            } else if (targetOffset > position.maxScrollExtent) {
              final overshoot = targetOffset - position.maxScrollExtent;
              targetOffset =
                  position.maxScrollExtent +
                  (overshoot * pageViewWidth * 0.55) /
                      (pageViewWidth + 0.55 * overshoot.abs());
            }
            controller.jumpTo(targetOffset);
          },
          onHorizontalDragEnd: (details) {
            if (!controller.hasClients) return;
            if (reduceMotion) {
              controller.jumpToPage(
                (controller.page ?? 0.0).round().clamp(0, tabCount - 1),
              );
              return;
            }
            final position =
                controller.position as ScrollPositionWithSingleContext;
            position.goBallistic(
              details.velocity.pixelsPerSecond.dx *
                  (position.viewportDimension / tabWidth),
            );
          },
          onHorizontalDragCancel: () {
            if (!controller.hasClients) return;
            if (reduceMotion) {
              controller.jumpToPage(
                (controller.page ?? 0.0).round().clamp(0, tabCount - 1),
              );
            } else {
              (controller.position as ScrollPositionWithSingleContext)
                  .goBallistic(0);
            }
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
                        color: MiuixColors.of(
                          context,
                        ).primary.withOpacity(0.12),
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
                            if (reduceMotion) {
                              controller.jumpToPage(index);
                            } else {
                              controller.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              );
                            }
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
      _bubblePressController.forward().orCancel.then((_) {
        if (mounted) _bubblePressController.reverse();
      });
    }

    if (mounted) {
      final reduceMotion =
          MediaQuery.disableAnimationsOf(context) ||
          View.of(
            context,
          ).platformDispatcher.accessibilityFeatures.reduceMotion;
      if (reduceMotion) {
        _pageController.jumpToPage(index);
      } else {
        await _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }

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
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        View.of(context).platformDispatcher.accessibilityFeatures.reduceMotion;
    final reduceTransparency = MediaQuery.highContrastOf(context);
    final tm = ThemeManager();
    final blurEnabled = tm.enableBlur && !reduceTransparency;
    final glassEnabled = tm.enableLiquidGlass && !reduceTransparency;

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
            physics: const NeverScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentBottomIndex = index;
              });
              if (index >= 0 && index <= 2) {
                if (reduceMotion) {
                  _subTabAnimController.value = 1;
                } else {
                  _subTabAnimController.forward();
                }
              } else {
                if (reduceMotion) {
                  _subTabAnimController.value = 0;
                } else {
                  _subTabAnimController.reverse();
                }
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
                  final gestureVisibility = reduceMotion
                      ? (currentPage.round() <= 2 ? 1.0 : 0.0)
                      : _getSubTabVisibility(currentPage);
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
                            borderRadius: BorderRadius.circular(28),
                            child: BackdropFilter(
                              filter: blurEnabled
                                  ? liquidGlassImageFilter(blurSigma: 4)
                                  : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  color: blurEnabled
                                      ? MiuixColors.of(
                                          context,
                                        ).surfaceContainer.withOpacity(0.40)
                                      : MiuixColors.of(
                                          context,
                                        ).surfaceContainer.withOpacity(0.92),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: MiuixColors.of(context).outline
                                        .withOpacity(
                                          reduceTransparency ? 0.9 : 0.5,
                                        ),
                                    width: 0.5,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: _buildSubTabBarChild(currentPage),
                                    ),
                                    if (glassEnabled)
                                      Positioned.fill(
                                        child: BloomStrokeLayer(
                                          radius: 28,
                                          isDark:
                                              Theme.of(context).brightness ==
                                              Brightness.dark,
                                          enabled: glassEnabled,
                                        ),
                                      ),
                                  ],
                                ),
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
                              filter: blurEnabled
                                  ? liquidGlassImageFilter(blurSigma: 4)
                                  : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                              child: Container(
                                height: 64,
                                decoration: BoxDecoration(
                                  color: blurEnabled
                                      ? MiuixColors.of(
                                          context,
                                        ).surfaceContainer.withOpacity(0.40)
                                      : MiuixColors.of(
                                          context,
                                        ).surfaceContainer.withOpacity(0.92),
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(
                                    color: MiuixColors.of(context).outline
                                        .withOpacity(
                                          reduceTransparency ? 0.9 : 0.5,
                                        ),
                                    width: 0.5,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final double totalWidth =
                                              constraints.maxWidth;
                                          final double tabWidth =
                                              totalWidth / 4;
                                          final double bubbleWidth =
                                              tabWidth - 8;
                                          final double bubbleHeight = 48;

                                          return GestureDetector(
                                            behavior:
                                                HitTestBehavior.translucent,
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
                                              if (_isDraggingBubble &&
                                                  _pageController.hasClients) {
                                                (_pageController.position
                                                        as ScrollPositionWithSingleContext)
                                                    .goIdle();
                                              }
                                                                                            _showHighlight = true;
                                                                                            _highlightPosNotifier.value = details.localPosition;
                                                                                            _bubblePressController.forward();
                                            },
                                            onHorizontalDragUpdate: (details) {
                                              if (!_isDraggingBubble) return;
                                              _highlightPosNotifier.value = details.localPosition;
                                              if (!_pageController.hasClients) {
                                                return;
                                              }
                                              final position =
                                                  _pageController.position;
                                              final double pageViewWidth =
                                                  position.viewportDimension;
                                              final double dragDelta =
                                                  details.delta.dx;
                                              double targetOffset =
                                                  _pageController.offset +
                                                  dragDelta *
                                                      (pageViewWidth /
                                                          tabWidth);
                                              if (targetOffset <
                                                  position.minScrollExtent) {
                                                final overshoot =
                                                    targetOffset -
                                                    position.minScrollExtent;
                                                targetOffset =
                                                    position.minScrollExtent +
                                                    (overshoot *
                                                            pageViewWidth *
                                                            0.55) /
                                                        (pageViewWidth +
                                                            0.55 *
                                                                overshoot
                                                                    .abs());
                                              } else if (targetOffset >
                                                  position.maxScrollExtent) {
                                                final overshoot =
                                                    targetOffset -
                                                    position.maxScrollExtent;
                                                targetOffset =
                                                    position.maxScrollExtent +
                                                    (overshoot *
                                                            pageViewWidth *
                                                            0.55) /
                                                        (pageViewWidth +
                                                            0.55 *
                                                                overshoot
                                                                    .abs());
                                              }
                                              _pageController.jumpTo(
                                                targetOffset,
                                              );
                                            },
                                            onHorizontalDragEnd: (details) {
                                              if (!_isDraggingBubble) return;
                                              if (!_pageController.hasClients) {
                                                return;
                                              }
                                              if (reduceMotion) {
                                                _pageController.jumpToPage(
                                                  (_pageController.page ?? 0.0)
                                                      .round()
                                                      .clamp(0, 3),
                                                );
                                              } else {
                                                final position =
                                                    _pageController.position
                                                        as ScrollPositionWithSingleContext;
                                                position.goBallistic(
                                                  details
                                                          .velocity
                                                          .pixelsPerSecond
                                                          .dx *
                                                      (position
                                                              .viewportDimension /
                                                          tabWidth),
                                                );
                                              }
                                              _isDraggingBubble = false;
                                              _showHighlight = false;
                                              _highlightPosNotifier.value = Offset.zero;
                                              if (mounted) _bubblePressController.reverse();
                                            },
                                            onHorizontalDragCancel: () {
                                              if (!_isDraggingBubble ||
                                                  !_pageController.hasClients) {
                                                return;
                                              }
                                              if (reduceMotion) {
                                                _pageController.jumpToPage(
                                                  (_pageController.page ?? 0.0)
                                                      .round()
                                                      .clamp(0, 3),
                                                );
                                              } else {
                                                (_pageController.position
                                                        as ScrollPositionWithSingleContext)
                                                    .goBallistic(0);
                                              }
                                              _isDraggingBubble = false;
                                              _showHighlight = false;
                                              _highlightPosNotifier.value = Offset.zero;
                                              if (mounted) _bubblePressController.reverse();
                                            },
                                            child: Stack(
                                              children: [
                                                Positioned(
                                                  left:
                                                      currentPage * tabWidth +
                                                      (tabWidth - bubbleWidth) /
                                                          2,
                                                  top: (64 - bubbleHeight) / 2,
                                                  width: bubbleWidth,
                                                  height: bubbleHeight,
                                                  child: AnimatedBuilder(
                                                    animation: Listenable.merge([
                                                      _bubblePressController,
                                                      _highlightPosNotifier,
                                                    ]),
                                                    builder: (context, _) {
                                                      final pressProgress = _bubblePressController.value;
                                                      final scale = 1.0 + 0.39 * pressProgress;
                                                      final darkBg = (1.0 - pressProgress) * 0.10 + pressProgress * 0.03;
                                                      return Transform.scale(
                                                        scale: scale,
                                                        child: ClipRRect(
                                                          borderRadius: BorderRadius.circular(24),
                                                          child: Stack(
                                                            children: [
                                                              Positioned.fill(
                                                                child: ColoredBox(
                                                                  color: Colors.black.withOpacity(darkBg),
                                                                ),
                                                              ),
                                                              Positioned.fill(
                                                                child: ColoredBox(
                                                                  color: MiuixColors.of(context).primary.withOpacity(0.12),
                                                                ),
                                                              ),
                                                              if (pressProgress > 0.01)
                                                                Positioned.fill(
                                                                  child: CustomPaint(
                                                                    painter: _BubbleInnerShadowPainter(
                                                                      radius: 8.0 * pressProgress,
                                                                      alpha: pressProgress * 0.15,
                                                                    ),
                                                                  ),
                                                                ),
                                                              if (_showHighlight && pressProgress > 0.01)
                                                                Positioned.fill(
                                                                  child: CustomPaint(
                                                                    painter: _InteractiveHighlightPainter(
                                                                      position: _highlightPosNotifier.value,
                                                                      progress: pressProgress,
                                                                    ),
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    },
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
                                                      Icons
                                                          .credit_card_outlined,
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
                                    if (glassEnabled)
                                      Positioned.fill(
                                        child: BloomStrokeLayer(
                                          radius: 32,
                                          isDark:
                                              Theme.of(context).brightness ==
                                              Brightness.dark,
                                          enabled: glassEnabled,
                                        ),
                                      ),
                                  ],
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
        child: AnimatedBuilder(
          animation: _bubblePressController,
          builder: (context, child) {
            final scale = 1.0 + 0.2 * _bubblePressController.value;
            return Transform.scale(scale: scale, child: child);
          },
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
      ),
    );
  }
}

/// SukiSU-style bubble inner shadow: radius scales with press progress,
/// color Black.copy(0.15 * alpha).
class _BubbleInnerShadowPainter extends CustomPainter {
  const _BubbleInnerShadowPainter({required this.radius, required this.alpha});

  final double radius;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0 || alpha <= 0) return;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(radius.clamp(0.0, w / 2)),
    );
    canvas.save();
    canvas.clipRRect(rrect);

    final shadowColor = Colors.black.withOpacity(alpha);
    final topPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment(0, 0.15),
        colors: [shadowColor, shadowColor.withOpacity(0)],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h * 0.12),
        Radius.circular(radius.clamp(0.0, w / 2)),
      ),
      topPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BubbleInnerShadowPainter oldDelegate) =>
      radius != oldDelegate.radius || alpha != oldDelegate.alpha;
}

/// SukiSU InteractiveHighlight: White(0.06*progress) rect (BlendMode.plus) +
/// radial White(0.12*progress) glow at touch position, radius = minDim*1.2.
class _InteractiveHighlightPainter extends CustomPainter {
  const _InteractiveHighlightPainter({
    required this.position,
    required this.progress,
  });

  final Offset position;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || progress <= 0) return;

    // Base white wash: White.copy(0.06 * progress)
    final baseWash = Paint()
      ..color = Colors.white.withOpacity(0.06 * progress)
      ..blendMode = BlendMode.plus;
    canvas.drawRect(Offset.zero & size, baseWash);

    // Radial glow: White.copy(0.12 * progress), radius = minDim * 1.2
    final clampedX = position.dx.clamp(0.0, size.width);
    final clampedY = position.dy.clamp(0.0, size.height);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: FractionalOffset.fromOffsetAndRect(
          Offset(clampedX, clampedY),
          Offset.zero & size,
        ),
        radius: 1.0,
        colors: [
          Colors.white.withOpacity(0.12 * progress),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Offset.zero & size)
      ..blendMode = BlendMode.plus;
    canvas.drawRect(Offset.zero & size, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _InteractiveHighlightPainter oldDelegate) =>
      position != oldDelegate.position || progress != oldDelegate.progress;
}

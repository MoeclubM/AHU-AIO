import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'globals.dart' as globals;
import 'jwapp/mainpage/mainpage_view.dart';
import 'jw/home/jw_main_tabs.dart';
import 'finance/api/synjones_client.dart';
import 'finance/home/finance_main_tabs.dart';
import 'app_settings_screen.dart';
import 'auth/unified_login_page.dart';
import 'auth/cas_auth_cache.dart';
import 'miuix/miuix_floating_bar.dart';
import 'miuix/miuix_theme.dart';
import 'theme_manager.dart';

/// 主底栏标签（Miuix 悬浮栏不显示文字，仅用于无障碍朗读）。
const List<MiuixFloatingBarItemData> _mainTabs = [
  MiuixFloatingBarItemData(
    icon: Icons.bolt_outlined,
    activeIcon: Icons.bolt,
    label: '微教务',
  ),
  MiuixFloatingBarItemData(
    icon: Icons.school_outlined,
    activeIcon: Icons.school,
    label: '安大教务',
  ),
  MiuixFloatingBarItemData(
    icon: Icons.credit_card_outlined,
    activeIcon: Icons.credit_card,
    label: '一卡通',
  ),
  MiuixFloatingBarItemData(
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings,
    label: '设置',
  ),
];

/// 微教务二级标签。
const List<MiuixFloatingBarItemData> _microSubTabs = [
  MiuixFloatingBarItemData(
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    label: '首页',
  ),
  MiuixFloatingBarItemData(
    icon: Icons.schedule_outlined,
    activeIcon: Icons.schedule,
    label: '课表',
  ),
  MiuixFloatingBarItemData(
    icon: Icons.grade_outlined,
    activeIcon: Icons.grade,
    label: '成绩',
  ),
  MiuixFloatingBarItemData(
    icon: Icons.meeting_room_outlined,
    activeIcon: Icons.meeting_room,
    label: '空闲教室',
  ),
];

/// 安大教务二级标签。
const List<MiuixFloatingBarItemData> _jwSubTabs = [
  MiuixFloatingBarItemData(
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    label: '首页',
  ),
  MiuixFloatingBarItemData(
    icon: Icons.schedule_outlined,
    activeIcon: Icons.schedule,
    label: '课表',
  ),
  MiuixFloatingBarItemData(
    icon: Icons.grade_outlined,
    activeIcon: Icons.grade,
    label: '成绩',
  ),
  MiuixFloatingBarItemData(
    icon: Icons.description_outlined,
    activeIcon: Icons.description,
    label: '方案',
  ),
];

/// 一卡通二级标签。
const List<MiuixFloatingBarItemData> _financeSubTabs = [
  MiuixFloatingBarItemData(
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    label: '主页',
  ),
  MiuixFloatingBarItemData(
    icon: Icons.qr_code_outlined,
    activeIcon: Icons.qr_code,
    label: '一码通',
  ),
  MiuixFloatingBarItemData(
    icon: Icons.payment_outlined,
    activeIcon: Icons.payment,
    label: '充值缴费',
  ),
];

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  /// 计算在给定全局 page 偏移下子标签栏的可见性 (0.0~1.0)
  /// 在前三个对象（微教务0、安大教务1、一卡通2）之间保持恒为 1.0 连续显示，绝不收起；
  /// 仅在滑向设置(3)时平滑收起隐藏到底栏后面。
  static double calculateSubTabVisibility(double page) {
    if (page <= 2.0) {
      return 1.0;
    } else if (page >= 3.0) {
      return 0.0;
    } else {
      final t = page - 2.0;
      if (t < 0.5) {
        return 1.0 - 2.0 * t;
      } else {
        return 0.0;
      }
    }
  }

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
  late PageController _microPageController;
  late PageController _jwPageController;
  late PageController _financePageController;

  /// 二级标签的 PageController 列表（索引即一级标签序号）。
  late final List<PageController> _subPageControllers;

  /// MD3 模式下贴底 TabBar 使用的控制器（与二级 PageController 双向同步）。
  late final List<TabController> _subTabControllers;

  late AnimationController _subTabAnimController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0, keepPage: false);
    _pageController.addListener(() {
      if (_pageController.hasClients) {
        _pagePercentNotifier.value = _pageController.page ?? 0.0;
      }
    });

    _microPageController = PageController(initialPage: 0, keepPage: false);
    _jwPageController = PageController(initialPage: 0, keepPage: false);
    _financePageController = PageController(initialPage: 0, keepPage: false);

    _subPageControllers = [
      _microPageController,
      _jwPageController,
      _financePageController,
    ];
    _subTabControllers = [
      TabController(length: _microSubTabs.length, vsync: this),
      TabController(length: _jwSubTabs.length, vsync: this),
      TabController(length: _financeSubTabs.length, vsync: this),
    ];
    for (int i = 0; i < _subPageControllers.length; i++) {
      final int section = i;
      _subPageControllers[i].addListener(() => _syncSubTabIndex(section));
    }

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

  ModalRoute<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<dynamic>? newRoute = ModalRoute.of(context);
    if (newRoute != _route) {
      _route?.secondaryAnimation?.removeListener(_onRouteAnimation);
      _route = newRoute;
      _route?.secondaryAnimation?.addListener(_onRouteAnimation);
    }
  }

  void _onRouteAnimation() {
    // 当上层子页面出栈就位时，刷新底栏与页面，确保毛玻璃与渲染层完全就绪。
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _route?.secondaryAnimation?.removeListener(_onRouteAnimation);
    if (globals.onLoginStateChanged == _onLoginStateChanged) {
      globals.onLoginStateChanged = null;
    }
    _pageController.dispose();
    _pagePercentNotifier.dispose();
    _microPageController.dispose();
    _jwPageController.dispose();
    _financePageController.dispose();
    _subTabAnimController.dispose();
    for (final controller in _subTabControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// 二级页面翻页后，同步二级标签的选中项。
  void _syncSubTabIndex(int section) {
    if (section < 0 || section >= _subTabControllers.length) return;
    final pageController = _subPageControllers[section];
    if (!pageController.hasClients) return;
    final tabController = _subTabControllers[section];
    final int index = (pageController.page ?? 0.0).round().clamp(
      0,
      tabController.length - 1,
    );
    if (tabController.index != index) {
      tabController.index = index;
      // 贴底模式下的 MiuixTabRow 由父级重建驱动选中态。
      if (mounted) setState(() {});
    }
  }

  /// 二级标签当前选中的下标。
  int _subIndex(int section) {
    final tabController = _subTabControllers[section];
    final pageController = _subPageControllers[section];
    if (!pageController.hasClients) return tabController.index;
    return (pageController.page ?? 0.0).round().clamp(
      0,
      tabController.length - 1,
    );
  }

  /// 点击二级标签：翻到对应子页面。
  void _selectSubTab(int section, int index) {
    final pageController = _subPageControllers[section];
    if (!pageController.hasClients) return;
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        View.of(context).platformDispatcher.accessibilityFeatures.reduceMotion;
    if (reduceMotion) {
      pageController.jumpToPage(index);
    } else {
      pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  List<MiuixFloatingBarItemData> _subTabsOf(int section) {
    switch (section) {
      case 0:
        return _microSubTabs;
      case 1:
        return _jwSubTabs;
      default:
        return _financeSubTabs;
    }
  }

  void _resetToHomeTab() {
    _currentBottomIndex = 0;
    _pagePercentNotifier.value = 0.0;
    _subTabAnimController.value = 1.0;
    for (final controller in _subTabControllers) {
      if (controller.index != 0) controller.index = 0;
    }

    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
    if (_microPageController.hasClients) {
      _microPageController.jumpToPage(0);
    }
    if (_jwPageController.hasClients) {
      _jwPageController.jumpToPage(0);
    }
    if (_financePageController.hasClients) {
      _financePageController.jumpToPage(0);
    }
  }

  void _onLoginStateChanged() {
    if (mounted) {
      _resetToHomeTab();
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
    globals.username = prefs.getString('username');
    globals.jwLoggedIn = await CasAuthCache.isLoggedIn();
    globals.jwStudentNo = prefs.getString('jwStudentNo');
    if (mounted) {
      _resetToHomeTab();
      setState(() {
        _isInitializing = false;
      });
    }
  }

  double _getSubTabVisibility(double page) =>
      MainLayoutScreen.calculateSubTabVisibility(page);

  Future<void> _handleTabSwitch(int index) async {
    if (index == _currentBottomIndex) return;

    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        View.of(context).platformDispatcher.accessibilityFeatures.reduceMotion;

    setState(() {
      _currentBottomIndex = index;
    });

    if (reduceMotion) {
      _subTabAnimController.value = (index >= 0 && index <= 2) ? 1.0 : 0.0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(index);
      }
    } else {
      if (index >= 0 && index <= 2) {
        _subTabAnimController.forward();
      } else {
        _subTabAnimController.reverse();
      }
      if (_pageController.hasClients) {
        await _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  Widget _buildPageView() {
    return PageView(
      physics: const NeverScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      controller: _pageController,
      onPageChanged: (index) {
        if (_currentBottomIndex != index) {
          setState(() {
            _currentBottomIndex = index;
          });
          if (index >= 0 && index <= 2) {
            _subTabAnimController.forward();
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
    );
  }

  /// Miuix 模式：悬浮液态玻璃胶囊底栏（主栏不显示文字，二级栏显示文字）。
  Widget _buildMiuix() {
    return Scaffold(
      body: Stack(
        children: [
          _buildPageView(),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _pagePercentNotifier,
                _subTabAnimController,
              ]),
              builder: (context, child) {
                final reduceMotion =
                    MediaQuery.disableAnimationsOf(context) ||
                    View.of(
                      context,
                    ).platformDispatcher.accessibilityFeatures.reduceMotion;
                final double currentPage = _pagePercentNotifier.value;
                final int section = currentPage.round().clamp(0, 3);
                final double gestureVisibility = reduceMotion
                    ? (section <= 2 ? 1.0 : 0.0)
                    : _getSubTabVisibility(currentPage);
                final double visibility =
                    _subTabAnimController.value * gestureVisibility;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 子栏槽位负责收起动画的裁剪与玻璃取样空间的留白
                    // （不留白的话，玻璃的上半边会被裁剪窗口切掉）。
                    MiuixFloatingSubBarSlot(
                      visibility: visibility,
                      child: section <= 2
                          ? MiuixFloatingTabBar(
                              key: ValueKey(section),
                              controller: _subPageControllers[section],
                              items: _subTabsOf(section),
                              height: MiuixFloatingBarDefaults.subBarHeight,
                              iconSize: MiuixFloatingBarDefaults.subIconSize,
                              fontSize:
                                  MiuixFloatingBarDefaults.subLabelFontSize,
                            )
                          : const SizedBox.shrink(),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: MiuixFloatingBarDefaults.bottomPadding(context),
                      ),
                      // 官方液态玻璃底栏常显图标 + 文字（图标 22dp、标签 11sp）。
                      child: MiuixFloatingTabBar(
                        controller: _pageController,
                        items: _mainTabs,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// MD3 模式：标准贴底 NavigationBar + 标准 TabBar，无悬浮、无模糊、无阴影自定义。
  Widget _buildMaterial3() {
    final int section = _currentBottomIndex.clamp(0, 3);
    final bool showSubTabs = section <= 2;
    final List<MiuixFloatingBarItemData> subTabs = _subTabsOf(section);

    return Scaffold(
      body: _buildPageView(),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 二级标签用 M3 的次级标签栏（`TabBar.secondary`）：颜色、指示器
          // 与高度全部取 TabBarTheme 默认值，不再手写 surface 容器。
          if (showSubTabs)
            TabBar.secondary(
              controller: _subTabControllers[section],
              tabs: [for (final tab in subTabs) Tab(text: tab.label)],
              onTap: (index) {
                final controller = _subPageControllers[section];
                if (!controller.hasClients) return;
                controller.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                );
              },
            ),
          NavigationBar(
            selectedIndex: section,
            onDestinationSelected: _handleTabSwitch,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.bolt_outlined),
                selectedIcon: Icon(Icons.bolt),
                label: '微教务',
              ),
              NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school),
                label: '安大教务',
              ),
              NavigationDestination(
                icon: Icon(Icons.credit_card_outlined),
                selectedIcon: Icon(Icons.credit_card),
                label: '一卡通',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: '设置',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Miuix 模式（关闭「悬浮底栏」）：官方贴底导航栏 + 官方 TabRow 二级标签。
  ///
  /// 贴底栏与悬浮栏是两个不同组件，规格也不同：贴底栏为实色 `surface` 背景、
  /// 顶部 0.5dp 分隔线、无外边距与胶囊；条目图标 26（悬浮栏 22）、标签 12sp
  /// （悬浮栏 11sp），未选中整体降到 40% 不透明度。这里直接用官方
  /// [MiuixNavigationBar] / [MiuixNavigationBarItem] / [MiuixTabRow] 实现，
  /// 保证与 Compose 版逐项一致。
  Widget _buildMiuixDocked() {
    final int section = _currentBottomIndex.clamp(0, 3);
    final bool showSubTabs = section <= 2;
    final List<MiuixFloatingBarItemData> subTabs = _subTabsOf(section);

    return Scaffold(
      body: _buildPageView(),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSubTabs)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: MiuixTabRow(
                tabs: [for (final tab in subTabs) tab.label],
                selectedTabIndex: _subIndex(section),
                onTabSelected: (index) => _selectSubTab(section, index),
              ),
            ),
          MiuixNavigationBar(
            children: [
              for (int i = 0; i < _mainTabs.length; i++)
                MiuixNavigationBarItem(
                  selected: section == i,
                  onPressed: () => _handleTabSwitch(i),
                  icon: Icon(
                    section == i ? _mainTabs[i].activeIcon : _mainTabs[i].icon,
                  ),
                  label: _mainTabs[i].label,
                ),
            ],
          ),
        ],
      ),
    );
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
          _resetToHomeTab();
          setState(() {});
        },
      );
    }

    final tm = ThemeManager();
    if (tm.isMaterial3) return _buildMaterial3();
    // 「悬浮底栏」开关决定用悬浮玻璃胶囊还是官方贴底栏。
    return tm.enableBottomBarTransparent ? _buildMiuix() : _buildMiuixDocked();
  }
}

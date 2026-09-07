import 'package:flutter/material.dart';
import '../../miuix/liquid_glass_app_bar.dart';
import '../../theme_manager.dart';
import 'finance_home_view.dart';
import '../pages/finance_pay_code_page.dart';
import '../pages/finance_recharge_page.dart';

class FinanceMainTabs extends StatefulWidget {
  final bool isActive;
  final PageController pageController;
  const FinanceMainTabs({
    super.key,
    this.isActive = false,
    required this.pageController,
  });

  @override
  State<FinanceMainTabs> createState() => _FinanceMainTabsState();
}

class _FinanceMainTabsState extends State<FinanceMainTabs> {
  int _currentPage = 0;
  final _themeManager = ThemeManager();

  @override
  void initState() {
    super.initState();
    _themeManager.addListener(_onThemeChanged);
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
              title: '一卡通系统',
              actions: [
                if (_currentPage == 2)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: financeRechargeIsListViewNotifier,
                      builder: (context, isListView, _) {
                        return IconButton(
                          icon: Icon(
                            isListView
                                ? Icons.grid_view_rounded
                                : Icons.view_list_rounded,
                            size: 20,
                          ),
                          onPressed: FinanceRechargePage.toggleViewMode,
                          tooltip: isListView ? '切换为网格视图' : '切换为列表视图',
                        );
                      },
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
            FinanceHomePage(embed: true),
            FinancePayCodePage(embed: true),
            FinanceRechargePage(embed: true),
          ],
        ),
      ),
    );
  }
}

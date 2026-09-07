import 'dart:ui';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
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
          '一卡通系统',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_currentPage == 2)
            Padding(
              padding: const EdgeInsets.only(right: 24),
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
      ),
      body: PageView(
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
    );
  }
}

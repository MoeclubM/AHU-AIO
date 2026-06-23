import 'dart:ui';
import 'package:flutter/material.dart';
import 'finance_home_view.dart';
import '../pages/finance_pay_code_page.dart';
import '../pages/finance_recharge_page.dart';

class FinanceMainTabs extends StatefulWidget {
  final bool isActive;
  const FinanceMainTabs({super.key, this.isActive = false});

  @override
  State<FinanceMainTabs> createState() => _FinanceMainTabsState();
}

class _FinanceMainTabsState extends State<FinanceMainTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 1.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
        );
    if (widget.isActive) {
      _animController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant FinanceMainTabs oldWidget) {
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
          '一卡通系统',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: const [],
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              FinanceHomePage(embed: true),
              FinancePayCodePage(embed: true),
              FinanceRechargePage(embed: true),
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
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 88),
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
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant.withOpacity(0.35),
                              width: 0.8,
                            ),
                          ),
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
                                text: '主页',
                              ),
                              Tab(
                                icon: Icon(Icons.qr_code_outlined, size: 20),
                                text: '一码通',
                              ),
                              Tab(
                                icon: Icon(Icons.payment_outlined, size: 20),
                                text: '充值缴费',
                              ),
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

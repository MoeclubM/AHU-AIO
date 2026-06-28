import 'dart:ui';
import 'package:flutter/material.dart';
import 'finance_home_view.dart';
import '../pages/finance_pay_code_page.dart';
import '../pages/finance_recharge_page.dart';

class FinanceMainTabs extends StatefulWidget {
  final bool isActive;
  final TabController tabController;
  const FinanceMainTabs({
    super.key,
    this.isActive = false,
    required this.tabController,
  });

  @override
  State<FinanceMainTabs> createState() => _FinanceMainTabsState();
}

class _FinanceMainTabsState extends State<FinanceMainTabs> {
  @override
  void initState() {
    super.initState();
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
      body: TabBarView(
        physics: const NeverScrollableScrollPhysics(),
        controller: widget.tabController,
        children: [
          FinanceHomePage(embed: true),
          FinancePayCodePage(embed: true),
          FinanceRechargePage(embed: true),
        ],
      ),
    );
  }
}

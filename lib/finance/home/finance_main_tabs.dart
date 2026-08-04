import 'package:flutter/material.dart';
import '../../miuix/liquid_glass_app_bar.dart';
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
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LiquidGlassAppBar(title: '一卡通系统'),
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
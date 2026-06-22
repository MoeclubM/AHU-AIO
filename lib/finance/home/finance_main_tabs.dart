import 'dart:ui';
import 'package:flutter/material.dart';
import '../../globals.dart' as globals;
import '../../auth/cas_auth_cache.dart';
import '../api/synjones_client.dart';
import '../../auth/unified_login_page.dart';
import 'finance_home_view.dart';
import '../pages/finance_pay_code_page.dart';
import '../pages/finance_recharge_page.dart';
import '../pages/finance_cards_page.dart';

class FinanceMainTabs extends StatefulWidget {
  const FinanceMainTabs({super.key});

  @override
  State<FinanceMainTabs> createState() => _FinanceMainTabsState();
}

class _FinanceMainTabsState extends State<FinanceMainTabs>
    with SingleTickerProviderStateMixin {
  final _client = SynjonesClient();
  late TabController _tabController;

  void _logout() async {
    await _client.logout();
    await CasAuthCache.clear();
    globals.onLoginStateChanged?.call();
    if (!mounted) return;
    if (globals.onLoginStateChanged == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UnifiedLoginPage()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.logout, size: 20),
              onPressed: _logout,
              tooltip: '退出登录',
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FinanceHomePage(embed: true),
          FinancePayCodePage(embed: true),
          FinanceRechargePage(embed: true),
          FinanceCardsPage(embed: true),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withOpacity(0.35),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
                  unselectedLabelStyle: const TextStyle(fontSize: 10.5),
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                  tabs: const [
                    Tab(icon: Icon(Icons.home_outlined, size: 19), text: '主页'),
                    Tab(
                      icon: Icon(Icons.qr_code_outlined, size: 19),
                      text: '一码通',
                    ),
                    Tab(
                      icon: Icon(Icons.payment_outlined, size: 19),
                      text: '充值缴费',
                    ),
                    Tab(
                      icon: Icon(Icons.credit_card_outlined, size: 19),
                      text: '电子卡',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

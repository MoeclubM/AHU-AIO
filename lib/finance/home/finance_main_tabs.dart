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

class _FinanceMainTabsState extends State<FinanceMainTabs> {
  final _client = SynjonesClient();

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
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('一卡通系统'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: '退出登录',
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: '主页', icon: Icon(Icons.home)),
              Tab(text: '一码通', icon: Icon(Icons.qr_code)),
              Tab(text: '充值缴费', icon: Icon(Icons.payment)),
              Tab(text: '电子卡', icon: Icon(Icons.credit_card)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            FinanceHomePage(embed: true),
            FinancePayCodePage(embed: true),
            FinanceRechargePage(embed: true),
            FinanceCardsPage(embed: true),
          ],
        ),
      ),
    );
  }
}

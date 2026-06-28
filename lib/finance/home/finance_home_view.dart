import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../globals.dart' as globals;

import '../../auth/cas_auth_cache.dart';
import '../api/synjones_client.dart';
import '../../auth/unified_login_page.dart';
import '../pages/finance_cards_page.dart';

/// 一卡通首页 — 原生展示余额、一码通入口、电子卡与更多功能。
class FinanceHomePage extends StatefulWidget {
  final bool embed;
  const FinanceHomePage({super.key, this.embed = false});

  @override
  State<FinanceHomePage> createState() => _FinanceHomePageState();
}

class _FinanceHomePageState extends State<FinanceHomePage> {
  final _client = SynjonesClient();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _userInfo;
  List<dynamic> _cards = [];
  List<dynamic> _payments = [];
  Map<String, dynamic>? _paymentInfo;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _client.init();
      final results = await Future.wait([
        _client.fetchUserInfo(),
        _client.getCampusCards(),
        _client.getPaymentInfo(),
      ]);

      _userInfo = results[0]['data'] as Map<String, dynamic>?;
      _cards = (results[1]['data']?['card'] as List?) ?? [];
      _payments = (results[2]['data'] as List?) ?? [];
      _paymentInfo = _payments.isNotEmpty
          ? Map<String, dynamic>.from(_payments.first as Map)
          : null;

      setState(() => _isLoading = false);
    } catch (e) {
      final msg = e.toString();
      final unauthorized =
          msg.contains('401') || msg.contains('鉴权') || !_client.loggedIn;
      if (unauthorized) {
        _client.accessToken = null;
      }
      setState(() {
        _error = unauthorized ? '登录已过期，请重新登录' : msg;
        _isLoading = false;
      });
    }
  }

  void _logout() async {
    await _client.logout();
    await CasAuthCache.clear();
    globals.jwLoggedIn = false;
    globals.idToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('idToken');
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
    return Scaffold(
      appBar: widget.embed
          ? null
          : AppBar(
              title: const Text('一卡通系统'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadData,
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _logout,
                  tooltip: '退出',
                ),
              ],
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 148),
                children: [
                  _buildUserCard(),
                  const SizedBox(height: 16),
                  _buildBalanceCard(),
                  const SizedBox(height: 16),
                  _buildCardsPreview(),
                ],
              ),
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _error == '登录已过期，请重新登录' ? _logout : _loadData,
            child: Text(_error == '登录已过期，请重新登录' ? '重新登录' : '重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard() {
    final name = _userInfo?['name']?.toString() ?? '-';
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.orange.shade100,
              backgroundImage: _userInfo?['avatar'] != null
                  ? NetworkImage(_userInfo!['avatar'])
                  : null,
              child: _userInfo?['avatar'] == null
                  ? Text(
                      name.isNotEmpty ? name[0] : '?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '学号: ${_userInfo?['account']?.toString() ?? '-'}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    var balanceFen = 0;
    var accountLabel = '';
    if (_paymentInfo != null) {
      balanceFen = (_paymentInfo!['elec_accamt'] as num?)?.toInt() ?? 0;
      accountLabel = _paymentInfo!['name']?.toString() ?? '电子账户';
    } else if (_cards.isNotEmpty) {
      balanceFen = (_cards[0]['elec_accamt'] as num?)?.toInt() ?? 0;
      accountLabel = _cards[0]['cardname']?.toString() ?? '校园卡';
    }
    final balanceYuan = (balanceFen / 100).toStringAsFixed(2);

    return Card(
      elevation: 3,
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              accountLabel,
              style: TextStyle(fontSize: 14, color: Colors.orange.shade800),
            ),
            const SizedBox(height: 8),
            Text(
              '¥$balanceYuan',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '当前余额',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsPreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '电子卡',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FinanceCardsPage(initialCards: _cards),
                      ),
                    );
                  },
                  child: const Text('全部'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_cards.isEmpty)
              Text('暂无校园卡', style: TextStyle(color: Colors.grey.shade600))
            else
              ..._cards.take(2).map((card) {
                final balance =
                    ((card['elec_accamt'] as num?)?.toInt() ?? 0) / 100;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.credit_card),
                  title: Text(
                    card['name']?.toString() ??
                        card['cardname']?.toString() ??
                        '校园卡',
                  ),
                  subtitle: Text(card['account']?.toString() ?? '-'),
                  trailing: Text('¥${balance.toStringAsFixed(2)}'),
                );
              }),
          ],
        ),
      ),
    );
  }
}

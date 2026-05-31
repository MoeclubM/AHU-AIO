import 'package:flutter/material.dart';

import '../../auth/cas_web_login_page.dart';
import '../api/synjones_client.dart';
import '../home/finance_home_view.dart';

/// 一卡通系统登录页：使用学校原版统一身份认证页面。
class FinanceLoginPage extends StatefulWidget {
  const FinanceLoginPage({super.key});

  @override
  State<FinanceLoginPage> createState() => _FinanceLoginPageState();
}

class _FinanceLoginPageState extends State<FinanceLoginPage> {
  bool _checkingSession = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initAndCheck();
  }

  Future<void> _initAndCheck() async {
    final client = SynjonesClient();
    await client.init();
    if (client.loggedIn) {
      try {
        await client.fetchUserInfo();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FinanceHomePage()),
        );
        return;
      } catch (e) {
        await client.logout();
        _error = '已有一卡通会话失效，请重新登录：$e';
      }
    }
    if (mounted) setState(() => _checkingSession = false);
  }

  Future<bool> _handleCasUrl(String url, _) async {
    final ticket = SynjonesClient.extractWebLoginTicket(url);
    if (ticket == null) return false;

    final client = SynjonesClient();
    final result = await client.casLoginDirect(ticket);
    if (!result.success) {
      throw result.message ?? '一卡通登录失败';
    }
    if (!mounted) return true;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const FinanceHomePage()),
      (_) => false,
    );
    return true;
  }

  void _openCasLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CasWebLoginPage(
          title: '统一身份认证',
          initialUrl: SynjonesClient.casWebLoginUrl,
          onUrlChanged: _handleCasUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('一卡通系统登录')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 72,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '安徽大学一卡通系统',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '使用学校原版统一身份认证页面登录',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 28),
                  if (_error != null) ...[
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _openCasLogin,
                      icon: const Icon(Icons.login),
                      label: const Text('打开统一身份认证'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

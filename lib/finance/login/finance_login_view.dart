import 'package:flutter/material.dart';

import '../../auth/cas_auth_cache.dart';
import '../api/synjones_client.dart';
import '../home/finance_home_view.dart';

/// 一卡通系统登录页：原生提交学校统一身份认证。
class FinanceLoginPage extends StatefulWidget {
  const FinanceLoginPage({super.key});

  @override
  State<FinanceLoginPage> createState() => _FinanceLoginPageState();
}

class _FinanceLoginPageState extends State<FinanceLoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _checkingSession = true;
  bool _loggingIn = false;
  bool _trustDevice = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initAndCheck();
  }

  Future<void> _initAndCheck() async {
    final client = SynjonesClient();
    await client.init();
    String? expiredSessionError;
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
        expiredSessionError = '已有一卡通会话失效，请重新登录：$e';
      }
    }
    LoginResult? cached;
    try {
      cached = await client.casLoginWithCachedSession();
    } catch (e) {
      _error = '一卡通 CAS 会话复用失败：$e';
    }
    if (cached != null) {
      if (cached.success) {
        await CasAuthCache.markLoggedIn('ycard');
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FinanceHomePage()),
        );
        return;
      }
      if (!mounted) return;
      _error = cached.message ?? '一卡通 CAS 会话复用失败';
    } else if (_error == null) {
      _error = expiredSessionError;
    }
    if (mounted) setState(() => _checkingSession = false);
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = '请输入统一身份认证账号和密码');
      return;
    }
    setState(() {
      _loggingIn = true;
      _error = null;
    });
    final client = SynjonesClient();
    try {
      final result = await client.casLoginNative(
        username: username,
        password: password,
        trustDevice: _trustDevice,
      );
      if (!mounted) return;
      if (!result.success) {
        setState(() {
          _loggingIn = false;
          _error = result.message ?? '一卡通登录失败';
        });
        return;
      }
      await CasAuthCache.markLoggedIn('ycard');
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const FinanceHomePage()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loggingIn = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '安徽大学一卡通系统',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '使用统一身份认证账号密码登录',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _usernameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: '学号 / 工号',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    onSubmitted: (_) {
                      if (!_loggingIn) _login();
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: '统一身份认证密码',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _trustDevice,
                    onChanged: _loggingIn
                        ? null
                        : (value) => setState(() {
                            _trustDevice = value!;
                          }),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('信任此设备'),
                  ),
                  if (_error != null) ...[
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.error),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _loggingIn ? null : _login,
                      icon: const Icon(Icons.login),
                      label: Text(_loggingIn ? '登录中...' : '登录'),
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

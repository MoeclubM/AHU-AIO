import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/synjones_client.dart';
import '../home/finance_home_view.dart';

/// 财务系统登录页 — CAS 统一身份认证 (原生协议，无 WebView)
class FinanceLoginPage extends StatefulWidget {
  const FinanceLoginPage({super.key});

  @override
  State<FinanceLoginPage> createState() => _FinanceLoginPageState();
}

class _FinanceLoginPageState extends State<FinanceLoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = true;
  bool _savePassword = true;
  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initAndCheck();
  }

  Future<void> _initAndCheck() async {
    final client = SynjonesClient();
    await client.init();

    // 已有有效 token，直接进入
    if (client.loggedIn) {
      try {
        await client.fetchUserInfo();
        if (mounted) _goHome();
        return;
      } catch (_) {
        // token 过期，继续登录流程
      }
    }

    // 加载已保存的凭据
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString('finance_username') ?? '';
    final savedPass = prefs.getString('finance_password') ?? '';
    if (savedUser.isNotEmpty) _usernameController.text = savedUser;
    if (savedPass.isNotEmpty) _passwordController.text = savedPass;
    setState(() => _isLoading = false);

    // 有已保存凭据则自动登录
    if (savedUser.isNotEmpty && savedPass.isNotEmpty) {
      _login();
    }
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = '请输入学号和密码');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = SynjonesClient();
      await client.init();
      final result = await client.casLogin(
        username: username,
        password: password,
      );

      if (!mounted) return;

      if (result.success) {
        // 保存凭据
        final prefs = await SharedPreferences.getInstance();
        if (_savePassword) {
          await prefs.setString('finance_username', username);
          await prefs.setString('finance_password', password);
        } else {
          await prefs.remove('finance_username');
          await prefs.remove('finance_password');
        }
        _goHome();
      } else {
        setState(() {
          _error = result.message ?? '登录失败';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '登录失败: $e';
        _isLoading = false;
      });
    }
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const FinanceHomePage()),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('缴费系统')),
      body: _isLoading && _usernameController.text.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          size: 64,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '安徽大学一卡通',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'CAS 统一身份认证',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: '学号',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.text,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: '密码',
                            prefixIcon: const Icon(Icons.lock),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                            ),
                          ),
                          onSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Checkbox(
                              value: _savePassword,
                              onChanged: (v) =>
                                  setState(() => _savePassword = v ?? true),
                            ),
                            const Text('记住密码'),
                          ],
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    '登录',
                                    style: TextStyle(fontSize: 16),
                                  ),
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

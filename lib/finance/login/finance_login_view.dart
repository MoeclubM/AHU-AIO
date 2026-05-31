import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/synjones_client.dart';
import '../home/finance_home_view.dart';

/// 缴费系统登录页 — 直接调用 CAS/一卡通接口。
class FinanceLoginPage extends StatefulWidget {
  const FinanceLoginPage({super.key});

  @override
  State<FinanceLoginPage> createState() => _FinanceLoginPageState();
}

const _keyUser = 'cas_username';
const _keyPass = 'cas_password';

class _FinanceLoginPageState extends State<FinanceLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _checkingSession = true;
  bool _isLoading = false;
  bool _savePassword = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _initAndCheck();
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _initAndCheck() async {
    final client = SynjonesClient();
    await client.init();

    if (client.loggedIn) {
      final valid = await _checkSessionValid(client);
      if (valid && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FinanceHomePage()),
        );
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    _userController.text = prefs.getString(_keyUser) ?? '';
    _passController.text = prefs.getString(_keyPass) ?? '';
    if (mounted) setState(() => _checkingSession = false);
  }

  Future<bool> _checkSessionValid(SynjonesClient client) async {
    try {
      await client.fetchUserInfo();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final client = SynjonesClient();
    await client.init();
    final result = await client.casLogin(
      username: _userController.text.trim(),
      password: _passController.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (!result.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message ?? '登录失败')));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, _userController.text.trim());
    if (_savePassword) {
      await prefs.setString(_keyPass, _passController.text);
    } else {
      await prefs.remove(_keyPass);
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const FinanceHomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('缴费系统登录')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            padding: const EdgeInsets.all(24),
            shrinkWrap: true,
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 72,
                color: Colors.orange.shade700,
              ),
              const SizedBox(height: 16),
              const Text(
                '安徽大学缴费系统',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '使用统一身份认证账号密码登录',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 28),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _userController,
                      decoration: const InputDecoration(
                        labelText: '学号/工号',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? '请输入学号/工号'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: '统一身份认证密码',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                      onFieldSubmitted: (_) {
                        if (!_isLoading) _login();
                      },
                      validator: (value) =>
                          value == null || value.isEmpty ? '请输入密码' : null,
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _savePassword,
                      onChanged: (value) {
                        setState(() => _savePassword = value ?? true);
                      },
                      title: const Text('保存密码供下次登录'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('登录'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

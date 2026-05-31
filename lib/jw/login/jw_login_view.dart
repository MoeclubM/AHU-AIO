import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'jw_login_service.dart';
import '../api/jw_api.dart';
import '../home/jw_home_view.dart';

class JwLoginPage extends StatefulWidget {
  const JwLoginPage({super.key});

  @override
  State<JwLoginPage> createState() => _JwLoginPageState();
}

class _JwLoginPageState extends State<JwLoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();
  bool _isLoading = false;
  bool _savePassword = true;
  String? _error;
  bool _obscurePassword = true;
  bool _needCaptcha = false;
  Uint8List? _captchaImage;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _tryAutoLogin();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('jw_username');
    final savedPassword = prefs.getString('jw_password');
    if (savedUsername != null) _usernameController.text = savedUsername;
    if (savedPassword != null) _passwordController.text = savedPassword;
  }

  Future<void> _tryAutoLogin() async {
    try {
      final api = JwApi();
      await api.init();

      final prefs = await SharedPreferences.getInstance();
      final savedUser = prefs.getString('jw_username');
      final savedPass = prefs.getString('jw_password');

      // 1) 已有有效会话，直接进入
      final hasSession = await api.hasValidSession();
      if (hasSession && savedUser != null && savedUser.isNotEmpty) {
        await api.fetchStudentIdDirect();
        _goHome();
        return;
      }

      // 2) 会话失效但已保存账号密码，使用密码自动登录
      if (savedUser != null &&
          savedUser.isNotEmpty &&
          savedPass != null &&
          savedPass.isNotEmpty) {
        if (mounted) setState(() => _isLoading = true);
        final result = await JwLoginService.login(
          username: savedUser,
          password: savedPass,
        );
        if (!mounted) return;
        if (result.success) {
          _goHome();
          return;
        }
        // 自动登录失败（如需要验证码），回退到手动登录
        setState(() {
          _isLoading = false;
          _needCaptcha = result.needCaptcha;
        });
        if (result.needCaptcha) _loadCaptcha();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const JwHomePage()),
    );
  }

  Future<void> _loadCaptcha() async {
    try {
      final api = JwApi();
      final data = await api.getLoginCaptcha();
      final base64Str = data['originalImageBase64']?.toString() ?? '';
      if (base64Str.isNotEmpty && mounted) {
        setState(() {
          _captchaImage = base64Decode(base64Str);
        });
      }
    } catch (_) {}
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
      final result = await JwLoginService.login(
        username: username,
        password: password,
        captchaToken: _captchaController.text.trim(),
      );

      if (!mounted) return;

      if (result.success) {
        final prefs = await SharedPreferences.getInstance();
        if (_savePassword) {
          await prefs.setString('jw_username', username);
          await prefs.setString('jw_password', password);
        } else {
          await prefs.remove('jw_username');
          await prefs.remove('jw_password');
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const JwHomePage()),
        );
      } else {
        final needCaptcha = result.needCaptcha;
        setState(() {
          _error = result.message ?? '登录失败';
          _isLoading = false;
          _needCaptcha = needCaptcha;
        });
        if (needCaptcha) {
          _loadCaptcha();
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '登录失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('教务系统')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.school, size: 64, color: Colors.blue),
                  const SizedBox(height: 16),
                  Text(
                    '安徽大学教务系统',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'jw.ahu.edu.cn',
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
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    onSubmitted: (_) => _login(),
                  ),
                  if (_needCaptcha) ...[
                    const SizedBox(height: 16),
                    if (_captchaImage != null)
                      GestureDetector(
                        onTap: _loadCaptcha,
                        child: Image.memory(
                          _captchaImage!,
                          height: 50,
                          fit: BoxFit.contain,
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _captchaController,
                      decoration: const InputDecoration(
                        labelText: '验证码（点击图片刷新）',
                        prefixIcon: Icon(Icons.verified),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _login(),
                    ),
                  ],
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('登录', style: TextStyle(fontSize: 16)),
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

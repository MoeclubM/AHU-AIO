// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_service.dart';
import '../mainpage/mainpage_view.dart';
import '../../globals.dart' as globals;

class JWLoginPage extends StatefulWidget {
  const JWLoginPage({super.key});

  @override
  State<JWLoginPage> createState() => _JWLoginPageState();
}

class _JWLoginPageState extends State<JWLoginPage> {
  // 定义控制器和状态变量
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _savePassword = false;

  @override
  void initState() {
    super.initState();
    _checkTokenAndNavigate();
    _loadSavedPassword();
  }

  // 检查是否存在 token 并跳转到主页面
  Future<void> _checkTokenAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    final String? idToken = prefs.getString('idToken');
    if (idToken != null) {
      globals.idToken = idToken;

      if (!context.mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
    }
  }

  // 加载保存的密码
  Future<void> _loadSavedPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('username') ?? '';
    final savedPassword = prefs.getString('password') ?? '';
    final savePassword = prefs.getBool('savePassword') ?? false;

    setState(() {
      _usernameController.text = savedUsername;
      _passwordController.text = savedPassword;
      _savePassword = savePassword;
    });
  }

  // 保存密码
  Future<void> _savePasswordToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_savePassword) {
      await prefs.setString('username', _usernameController.text.trim());
      await prefs.setString('password', _passwordController.text.trim());
    } else {
      await prefs.remove('username');
      await prefs.remove('password');
    }
    await prefs.setBool('savePassword', _savePassword);
    await prefs.setString('idToken', globals.idToken!);
  }

  // 显示提示信息
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // 处理登录事件
  Future<void> _handleLogin() async {
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showMessage('请输入学号和密码');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String? idToken = await LoginService.login(
        username: username,
        password: password,
      );
      if (idToken != null) {
        globals.idToken = idToken; // 将 idToken 存储为全局变量
        await _savePasswordToPrefs();

        if (!context.mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      }
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('安大微教务登录'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 4.0,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo and title
                      Column(
                        children: [
                          Icon(
                            Icons.school,
                            size: 80,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '欢迎登录',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '安大微教务',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Username field
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: '学号',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: '密码',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Remember password checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: _savePassword,
                            onChanged: (bool? value) {
                              setState(() {
                                _savePassword = value ?? false;
                              });
                            },
                          ),
                          const Text('保存密码'),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
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

                      const SizedBox(height: 16),

                      // Footer text
                      Text(
                        'AHU-AIO © 2024 MIT License',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

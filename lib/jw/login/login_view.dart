import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'login_service.dart';
import '../mainpage/mainpage_view.dart';
import '../../globals.dart' as globals;

class JWLoginPage extends StatefulWidget {
  const JWLoginPage({super.key});

  @override
  _JWLoginPageState createState() => _JWLoginPageState();
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '教务系统登录',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://wvpn.ahu.edu.cn/https/77726476706e69737468656265737421fff944d226387d1e7b0c9ce29b5b/cas/comm/ahu/image/kx.jpg?vpn-1&1732688305958',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [Colors.grey.shade900, Colors.grey.shade800]
                        : [Colors.blue.shade400, Colors.purple.shade400],
                  ),
                ),
              );
            },
          ),
          Container(
            color: (isDark ? Colors.black : Colors.grey.shade600).withValues(alpha: 0.4),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                    elevation: isDark ? 4.0 : 12.0,
                    color: isDark
                        ? Colors.grey.shade800.withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.95),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24.0),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: isDark ? 5.0 : 15.0, sigmaY: isDark ? 5.0 : 15.0),
                        child: Container(
                          padding: const EdgeInsets.all(32.0),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey.shade800.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(24.0),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.05),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Logo and title
                              Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.grey.shade700 : Colors.blue.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: SvgPicture.network(
                                      'https://jwapp.ahu.edu.cn/uniapp/static/h5/index/shuweilogo.svg',
                                      height: 80,
                                      colorFilter: ColorFilter.mode(
                                        isDark ? Colors.blue.shade300 : Colors.blue.shade600,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '欢迎登录',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.grey.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '安徽大学教务系统',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),

                              // Username field
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade50,
                                ),
                                child: TextField(
                                  controller: _usernameController,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: 16,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: '学号',
                                    labelStyle: TextStyle(
                                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                                    ),
                                    border: InputBorder.none,
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.person,
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Password field
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade50,
                                ),
                                child: TextField(
                                  controller: _passwordController,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: 16,
                                  ),
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: '密码',
                                    labelStyle: TextStyle(
                                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                                    ),
                                    border: InputBorder.none,
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock,
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Remember password checkbox
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: _savePassword,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          _savePassword = value ?? false;
                                        });
                                      },
                                      fillColor: WidgetStateProperty.resolveWith((states) {
                                        if (states.contains(WidgetState.selected)) {
                                          return isDark ? Colors.blue.shade400 : Colors.blue.shade600;
                                        }
                                        return isDark ? Colors.grey.shade600 : Colors.grey.shade400;
                                      }),
                                    ),
                                    Text(
                                      '保存密码',
                                      style: TextStyle(
                                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Login button
                              Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    colors: isDark
                                        ? [Colors.blue.shade400, Colors.blue.shade600]
                                        : [Colors.blue.shade500, Colors.blue.shade700],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isDark ? Colors.blue.shade400 : Colors.blue.shade600).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              isDark ? Colors.white : Colors.white,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          '登录',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Footer text
                              Text(
                                'AHU-AIO © 2024 MIT License',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
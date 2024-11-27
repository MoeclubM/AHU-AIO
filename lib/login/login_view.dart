import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'login_service.dart';
import '../mainpage/mainpage_view.dart';
import '../globals.dart' as globals;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
        appId: 'APP_ID',
        deviceId: 'DEVICE_ID',
        osType: 'OS_TYPE',
        geo: 'GEO',
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('教务系统登录'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://wvpn.ahu.edu.cn/https/77726476706e69737468656265737421fff944d226387d1e7b0c9ce29b5b/cas/comm/ahu/image/kx.jpg?vpn-1&1732688305958',
            fit: BoxFit.cover,
          ),
          Container(
            color: const Color.fromARGB(255, 199, 199, 199).withOpacity(0.5),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  elevation: 8.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.network(
                              'https://jwapp.ahu.edu.cn/uniapp/static/h5/index/shuweilogo.svg',
                              height: 150,
                            ),
                            const SizedBox(height: 32),
                            TextField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: '学号',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _passwordController,
                              decoration: const InputDecoration(
                                labelText: '密码',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              obscureText: true,
                            ),
                            const SizedBox(height: 16),
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
                            const SizedBox(height: 20),
                            _isLoading
                                ? const CircularProgressIndicator()
                                : ElevatedButton(
                                    onPressed: _handleLogin,
                                    child: const Text('登录'),
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
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../globals.dart' as globals;
import '../jwapp/login/login_service.dart';
import '../jw/api/jw_api.dart';
import '../finance/api/synjones_client.dart';
import 'cas_auth_cache.dart';

class UnifiedLoginPage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  const UnifiedLoginPage({super.key, this.onLoginSuccess});

  @override
  State<UnifiedLoginPage> createState() => _UnifiedLoginPageState();
}

class _UnifiedLoginPageState extends State<UnifiedLoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSilentLoading = true;
  bool _isLoading = false;
  bool _savePassword = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAndAutoLogin();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkAndAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('username') ?? '';
    final savedPassword = prefs.getString('password') ?? '';
    final savePassword = prefs.getBool('savePassword') ?? false;

    if (savePassword && savedUsername.isNotEmpty && savedPassword.isNotEmpty) {
      setState(() {
        _isSilentLoading = true;
        _usernameController.text = savedUsername;
        _passwordController.text = savedPassword;
        _savePassword = true;
      });
      try {
        await _performUnifiedLogin(savedUsername, savedPassword, true);
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSilentLoading = false;
            _error = '自动登录失败，请手动登录：\n${e.toString()}';
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isSilentLoading = false;
        });
      }
    }
  }

  Future<void> _performUnifiedLogin(
    String username,
    String password,
    bool savePassword,
  ) async {
    bool jwappOk = false;
    bool jwOk = false;
    bool financeOk = false;
    final List<String> errors = [];

    // 1. 微教务登录
    try {
      final token = await LoginService.login(
        username: username,
        password: password,
      );
      if (token != null) {
        globals.idToken = token;
        jwappOk = true;
      } else {
        errors.add('微教务：Token 返回为空');
      }
    } catch (e) {
      errors.add('微教务：${_cleanErrorMessage(e.toString())}');
    }

    // 2. 安大教务登录
    try {
      final jwApi = JwApi();
      await jwApi.loginWithCas(
        username: username,
        password: password,
        trustDevice: true,
      );
      await CasAuthCache.markLoggedIn('jw');
      globals.jwLoggedIn = true;
      globals.jwStudentNo = jwApi.studentId;
      jwOk = true;
    } catch (e) {
      errors.add('安大教务：${_cleanErrorMessage(e.toString())}');
    }

    // 3. 一卡通登录
    try {
      final client = SynjonesClient();
      final result = await client.casLoginNative(
        username: username,
        password: password,
        trustDevice: true,
      );
      if (result.success) {
        await CasAuthCache.markLoggedIn('ycard');
        financeOk = true;
      } else {
        errors.add('一卡通：${result.message ?? "登录失败"}');
      }
    } catch (e) {
      errors.add('一卡通：${_cleanErrorMessage(e.toString())}');
    }

    // 只要有任意一个登录成功，我们就视账号密码为正确，允许进入，后续如果失效可使用保存的密码静默自动登录
    if (jwappOk || jwOk || financeOk) {
      final prefs = await SharedPreferences.getInstance();
      if (savePassword) {
        await prefs.setString('username', username);
        await prefs.setString('password', password);
        await prefs.setBool('savePassword', true);
      } else {
        await prefs.remove('username');
        await prefs.remove('password');
        await prefs.setBool('savePassword', false);
      }

      if (globals.idToken != null) {
        await prefs.setString('idToken', globals.idToken!);
      }

      if (globals.jwStudentNo != null) {
        await prefs.setString('jwStudentNo', globals.jwStudentNo!);
      }

      globals.onLoginStateChanged?.call();

      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      }
    } else {
      throw StateError(errors.join('\n'));
    }
  }

  String _cleanErrorMessage(String message) {
    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }
    return message;
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = '请输入统一身份认证账号和密码');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _performUnifiedLogin(username, password, _savePassword);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('StateError: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isSilentLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                '正在自动登录中...',
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '一次登录，全线共享',
                style: TextStyle(fontSize: 12, color: colorScheme.outline),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('安徽大学统一身份认证')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                      child: Icon(
                        Icons.vpn_key_rounded,
                        size: 40,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '欢迎使用 AHU-AIO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '使用安徽大学统一身份认证登录',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        labelText: '学号 / 工号',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      onSubmitted: (_) {
                        if (!_isLoading) _handleLogin();
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        labelText: '统一认证密码',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: _savePassword,
                      onChanged: _isLoading
                          ? null
                          : (value) => setState(() {
                              _savePassword = value ?? false;
                            }),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      title: Text(
                        '保存密码（用于自动登录）',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: colorScheme.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.login_rounded),
                        label: Text(
                          _isLoading ? '正在建立连接...' : '一键登录所有系统',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

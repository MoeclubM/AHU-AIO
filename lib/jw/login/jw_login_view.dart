import 'package:flutter/material.dart';

import '../../auth/cas_auth_cache.dart';
import '../../globals.dart' as globals;
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
    _tryExistingSession();
  }

  Future<void> _tryExistingSession() async {
    final api = JwApi();
    await api.init();
    if (await api.hasValidSession()) {
      await api.fetchStudentIdDirect();
      globals.jwLoggedIn = true;
      globals.jwStudentNo = api.studentId;
      _goHome();
      return;
    }
    try {
      if (await api.loginWithCachedCas()) {
        await CasAuthCache.markLoggedIn('jw');
        globals.jwLoggedIn = true;
        globals.jwStudentNo = api.studentId;
        _goHome();
        return;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _checkingSession = false;
        _error = e.toString();
      });
      return;
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
    final api = JwApi();
    try {
      await api.loginWithCas(
        username: username,
        password: password,
        trustDevice: _trustDevice,
      );
      await CasAuthCache.markLoggedIn('jw');
      globals.jwLoggedIn = true;
      globals.jwStudentNo = api.studentId;
      if (!mounted) return;
      _goHome();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loggingIn = false;
          _error = e.toString();
        });
      }
    }
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const JwHomePage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('教务系统登录')),
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
                  Icon(Icons.school, size: 72, color: colorScheme.primary),
                  const SizedBox(height: 16),
                  const Text(
                    '安徽大学教务系统',
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

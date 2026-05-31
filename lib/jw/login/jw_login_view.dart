import 'package:flutter/material.dart';

import '../../auth/cas_web_login_page.dart';
import '../../globals.dart' as globals;
import '../api/jw_api.dart';
import '../home/jw_home_view.dart';
import '../utils/jw_webview_auth.dart';

class JwLoginPage extends StatefulWidget {
  const JwLoginPage({super.key});

  @override
  State<JwLoginPage> createState() => _JwLoginPageState();
}

class _JwLoginPageState extends State<JwLoginPage> {
  bool _checkingSession = true;

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
    if (mounted) setState(() => _checkingSession = false);
  }

  Future<bool> _handleCasUrl(String url, _) async {
    final uri = Uri.parse(url);
    if (uri.host != 'jw.ahu.edu.cn' || !uri.path.startsWith('/student')) {
      return false;
    }
    if (uri.path == '/student/sso/login') return false;
    await JwWebViewAuth.importCookiesFromWebView();
    final api = JwApi();
    if (!await api.hasValidSession()) return false;
    await api.fetchStudentIdDirect();
    globals.jwLoggedIn = true;
    globals.jwStudentNo = api.studentId;
    _goHome();
    return true;
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const JwHomePage()),
      (_) => false,
    );
  }

  void _openCasLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CasWebLoginPage(
          title: '统一身份认证',
          initialUrl: JwApi.ssoLoginUrl,
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
                  const Icon(Icons.school, size: 72, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text(
                    '安徽大学教务系统',
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

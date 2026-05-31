import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/synjones_client.dart';
import '../home/finance_home_view.dart';

/// 财务系统登录页 — CAS 统一身份认证 WebView
/// 教务(jw/jwapp)和缴费系统共用同一套 CAS 凭据。
class FinanceLoginPage extends StatefulWidget {
  const FinanceLoginPage({super.key});

  @override
  State<FinanceLoginPage> createState() => _FinanceLoginPageState();
}

/// 共享凭据存储键（教务/缴费通用）
const _keyUser = 'cas_username';
const _keyPass = 'cas_password';

class _FinanceLoginPageState extends State<FinanceLoginPage> {
  InAppWebViewController? _controller;
  bool _isLoading = true;
  double _progress = 0;
  bool _didNavigate = false;
  bool _checkingSession = true;
  String _savedUser = '';

  static const String _casUrl =
      'https://ycard.ahu.edu.cn/berserker-auth/cas/redirect/neusoftCas'
      '?targetUrl=https://ycard.ahu.edu.cn/plat/?name=loginTransit';

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
      final valid = await _checkSessionValid(client);
      if (valid && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FinanceHomePage()),
        );
        return;
      }
    }

    // 读取统一凭据
    final prefs = await SharedPreferences.getInstance();
    _savedUser = prefs.getString(_keyUser) ?? '';

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

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('缴费系统')),
      body: Column(
        children: [
          if (_isLoading)
            LinearProgressIndicator(value: _progress < 1 ? _progress : null),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(_casUrl)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                useWideViewPort: true,
                userAgent:
                    'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
                    '(KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36',
              ),
              onWebViewCreated: (c) => _controller = c,
              onLoadStart: (controller, url) {
                setState(() => _isLoading = true);
              },
              onLoadStop: (controller, url) async {
                setState(() {
                  _isLoading = false;
                  _progress = 1.0;
                });

                final urlStr = url?.toString() ?? '';

                // 在 CAS 登录页自动填入已保存凭据
                if (urlStr.contains('one.ahu.edu.cn/cas/login')) {
                  await _autoFillCredentials();
                }

                _checkSuccess(urlStr);
              },
              onProgressChanged: (_, progress) {
                setState(() => _progress = progress / 100.0);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 在 CAS 登录页自动填写学号和密码
  Future<void> _autoFillCredentials() async {
    if (_savedUser.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final savedPass = prefs.getString(_keyPass) ?? '';
    if (savedPass.isEmpty) return;

    try {
      final user = _savedUser;
      final js =
          'document.getElementById("un")?.value="$user";'
          'document.getElementById("pd")?.value="$savedPass";'
          'if(typeof initPassWordEvent==="function")initPassWordEvent();';
      await _controller?.evaluateJavascript(source: js);
      // 自动点击登录（CAS 的 login.js 需 device 预检通过）
      await _controller?.evaluateJavascript(
        source:
            'setTimeout(function(){'
            'var btn=document.getElementById("index_login_btn");'
            'if(btn)btn.click();'
            '},500);',
      );
    } catch (_) {}
  }

  void _checkSuccess(String url) {
    if (_didNavigate) return;
    if (url.contains('ycard.ahu.edu.cn/plat/') &&
        !url.contains('/plat/login')) {
      _didNavigate = true;
      _handleSuccess(url);
    }
  }

  Future<void> _handleSuccess(String latestUrl) async {
    // 1) Extract ticket from URL (synjones encrypted ticket)
    final ticketMatch = RegExp(
      r'[?&]ticket=(iFKYpYOO4[^&"\s]+)',
    ).firstMatch(latestUrl);
    String? ticket;
    if (ticketMatch != null) {
      var t = ticketMatch.group(1)!;
      try {
        t = Uri.decodeComponent(t);
      } catch (_) {}
      try {
        t = Uri.decodeComponent(t);
      } catch (_) {}
      ticket = t;
    }

    // 2) Also check sessionStorage for token
    if (ticket == null || ticket.isEmpty) {
      try {
        final ss = await _controller?.evaluateJavascript(
          source: 'sessionStorage.getItem("access_token")',
        );
        if (ss != null && ss is String && ss.isNotEmpty && ss != 'null') {
          final client = SynjonesClient();
          client.accessToken = ss.replaceAll('"', '');
          await _saveCredentialsOnSuccess();
          _goHome();
          return;
        }
      } catch (_) {}
    }

    // 3) Exchange ticket → JWT via SynjonesClient
    if (ticket != null && ticket.isNotEmpty) {
      try {
        final client = SynjonesClient();
        await client.init();
        final result = await client.casLoginDirect(ticket);
        if (result.success) {
          await _saveCredentialsOnSuccess();
          if (mounted) _goHome();
          return;
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Token 兑换失败: $e')));
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('登录态获取失败，请重试')));
      setState(() => _didNavigate = false);
    }
  }

  /// 登录成功后保存凭据
  Future<void> _saveCredentialsOnSuccess() async {
    try {
      // Extract login form values from WebView
      final userResult = await _controller?.evaluateJavascript(
        source: 'document.getElementById("un")?.value||""',
      );
      final passResult = await _controller?.evaluateJavascript(
        source: 'document.getElementById("pd")?.value||""',
      );
      final user = (userResult is String ? userResult : '').replaceAll('"', '');
      final pass = (passResult is String ? passResult : '').replaceAll('"', '');

      if (user.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUser, user);
        if (pass.isNotEmpty) await prefs.setString(_keyPass, pass);
      }
    } catch (_) {}
  }

  void _goHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const FinanceHomePage()),
    );
  }
}

import 'dart:io' show Cookie;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' hide Cookie;
import '../api/finance_api.dart';
import '../home/finance_home_view.dart';

/// 财务系统登录页 - CAS SSO WebView
class FinanceLoginPage extends StatefulWidget {
  const FinanceLoginPage({super.key});

  @override
  State<FinanceLoginPage> createState() => _FinanceLoginPageState();
}

class _FinanceLoginPageState extends State<FinanceLoginPage> {
  InAppWebViewController? _controller;
  bool _isLoading = true;
  double _progress = 0;
  bool _didNavigate = false;
  bool _checkingSession = true;

  static const String _casUrl =
      'https://ycard.ahu.edu.cn/berserker-auth/cas/redirect/neusoftCas'
      '?targetUrl=https://ycard.ahu.edu.cn/plat/?name=loginTransit';

  @override
  void initState() {
    super.initState();
    _initAndCheck();
  }

  Future<void> _initAndCheck() async {
    final api = FinanceApi();
    await api.init();

    // 尝试自动登录（已有持久化 token）
    if (api.accessToken != null) {
      final valid = await api.hasValidSession();
      if (valid && mounted) {
        api.loggedIn = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FinanceHomePage()),
        );
        return;
      }
    }

    // 清除旧 cookie，开始 CAS 登录
    await CookieManager.instance().deleteAllCookies();
    if (mounted) setState(() => _checkingSession = false);
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
                userAgent:
                    'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36',
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
                _checkSuccess(url?.toString() ?? '');
              },
              onProgressChanged: (controller, progress) {
                setState(() => _progress = progress / 100.0);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _checkSuccess(String url) {
    if (_didNavigate) return;
    if (url.contains('ycard.ahu.edu.cn/plat/') &&
        !url.contains('/login') &&
        !url.contains('/cas')) {
      _didNavigate = true;
      _waitForTokenAndNavigate();
    }
  }

  Future<void> _waitForTokenAndNavigate() async {
    String? token;

    // 轮询 sessionStorage 等待 OAuth token
    for (int i = 0; i < 20; i++) {
      try {
        final result = await _controller?.evaluateJavascript(
          source: 'sessionStorage.getItem("access_token")',
        );
        if (result != null &&
            result is String &&
            result.isNotEmpty &&
            result != 'null' &&
            result.length > 20) {
          token = result;
          break;
        }
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 500));
    }

    final api = FinanceApi();

    if (token != null) {
      api.setAccessToken(token);
    }

    // 提取 cookies
    try {
      final cookies = await CookieManager.instance().getCookies(
        url: WebUri('https://ycard.ahu.edu.cn'),
      );
      final cookieList = cookies
          .map(
            (c) => Cookie(c.name, c.value)
              ..domain = '.ycard.ahu.edu.cn'
              ..path = '/',
          )
          .toList();
      api.cookieJar.saveFromResponse(
        Uri.parse('https://ycard.ahu.edu.cn'),
        cookieList,
      );
    } catch (_) {}

    api.loggedIn = true;

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const FinanceHomePage()),
    );
  }
}

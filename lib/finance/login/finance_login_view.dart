import 'dart:io' show Cookie;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' hide Cookie;
import '../api/finance_api.dart';
import '../home/finance_home_view.dart';

/// 财务系统登录页 - CAS SSO WebView
/// 加载学校统一身份认证页面完成登录后提取 token
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

  static const String _casUrl =
      'https://ycard.ahu.edu.cn/berserker-auth/cas/redirect/neusoftCas'
      '?targetUrl=https://ycard.ahu.edu.cn/plat/?name=loginTransit';

  @override
  void initState() {
    super.initState();
    // 清除旧 cookie 确保干净会话
    CookieManager.instance().deleteAllCookies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('缴费系统登录')),
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
                _checkSuccess(url?.toString() ?? '');
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
    // CAS 登录成功后最终会重定向到 ycard 的 plat 页面
    if (url.contains('ycard.ahu.edu.cn/plat/') &&
        !url.contains('/login') &&
        !url.contains('/cas')) {
      _didNavigate = true;
      _extractTokenAndNavigate();
    }
  }

  Future<void> _extractTokenAndNavigate() async {
    try {
      final api = FinanceApi();

      // 从 WebView 的 sessionStorage 提取 access_token
      final token = await _controller?.evaluateJavascript(
        source: 'sessionStorage.getItem("access_token")',
      );
      if (token != null &&
          token is String &&
          token.isNotEmpty &&
          token != 'null') {
        api.setAccessToken(token);
      }

      // 同时提取 cookies 给 Dio
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

      api.loggedIn = true;
    } catch (_) {
      FinanceApi().loggedIn = true;
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const FinanceHomePage()),
    );
  }
}

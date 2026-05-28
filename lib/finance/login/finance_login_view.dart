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

    if (api.loggedIn || api.accessToken != null) {
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
              onProgressChanged: (_, progress) {
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
    if (url.contains('ycard.ahu.edu.cn/plat/')) {
      _didNavigate = true;
      _waitForTokenAndNavigate(url);
    }
  }

  Future<void> _waitForTokenAndNavigate(String latestUrl) async {
    String? token = _extractTokenFromUrl(latestUrl);

    for (int i = 0; i < 30 && token == null; i++) {
      try {
        final ssResult = await _controller?.evaluateJavascript(
          source: 'sessionStorage.getItem("access_token")',
        );
        if (_isValidToken(ssResult)) {
          token = ssResult.toString().replaceAll('"', '');
          break;
        }
        final lsResult = await _controller?.evaluateJavascript(
          source: 'localStorage.getItem("access_token")',
        );
        if (_isValidToken(lsResult)) {
          token = lsResult.toString().replaceAll('"', '');
          break;
        }
        final refreshObj = await _controller?.evaluateJavascript(
          source: 'sessionStorage.getItem("refreshObj")',
        );
        token = _extractTokenFromRefreshObj(refreshObj);
        if (token != null) break;
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 300));
    }

    final api = FinanceApi();
    if (token != null) {
      api.setAccessToken(token);
    }

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

    final valid = await api.hasValidSession();
    if (!valid) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('登录态校验失败，请重试')));
      setState(() => _didNavigate = false);
      return;
    }

    api.loggedIn = true;
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const FinanceHomePage()),
    );
  }

  String? _extractTokenFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final token =
          uri.queryParameters['synjones-auth'] ??
          uri.queryParameters['access_token'];
      if (token != null && token.isNotEmpty) {
        return token;
      }
    } catch (_) {}
    return null;
  }

  String? _extractTokenFromRefreshObj(dynamic value) {
    if (value == null || value is! String || value.isEmpty) return null;
    final match = RegExp(r'"access_token"\s*:\s*"([^"]+)"').firstMatch(value);
    return match?.group(1);
  }

  bool _isValidToken(dynamic value) {
    if (value == null || value is! String) return false;
    final normalized = value.replaceAll('"', '');
    return normalized.isNotEmpty &&
        normalized != 'null' &&
        normalized.length > 20;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../home/finance_home_view.dart';

/// 财务系统登录页面
/// 使用 InAppWebView 加载 ycard 登录页，处理安全键盘
/// 登录成功后自动跳转到财务首页
class FinanceLoginPage extends StatefulWidget {
  const FinanceLoginPage({super.key});

  @override
  State<FinanceLoginPage> createState() => _FinanceLoginPageState();
}

class _FinanceLoginPageState extends State<FinanceLoginPage> {
  InAppWebViewController? _controller;
  bool _isLoading = true;
  double _progress = 0;

  static const String _loginUrl =
      'https://ycard.ahu.edu.cn/plat/login?synAccessSource=h5&loginFrom=h5&type=logout';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('缴费系统登录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller?.reload(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading)
            LinearProgressIndicator(value: _progress < 1 ? _progress : null),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(_loginUrl)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                userAgent:
                    'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36',
              ),
              onWebViewCreated: (controller) {
                _controller = controller;
              },
              onLoadStart: (controller, url) {
                setState(() => _isLoading = true);
                _checkLoginSuccess(url?.toString() ?? '');
              },
              onLoadStop: (controller, url) async {
                setState(() {
                  _isLoading = false;
                  _progress = 1.0;
                });
                _checkLoginSuccess(url?.toString() ?? '');
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

  void _checkLoginSuccess(String url) {
    // 登录成功后 ycard 会跳转离开 /login 页面
    if (url.contains('ycard.ahu.edu.cn') &&
        !url.contains('/login') &&
        !url.contains('/signup') &&
        url != _loginUrl &&
        url != 'https://ycard.ahu.edu.cn/plat/login') {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    if (!mounted) return;
    // 清除导航栈，直接进入财务首页
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const FinanceHomePage()),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// 财务系统 - WebView 主页面
/// 登录后直接加载 ycard H5 首页，所有功能通过 WebView 内嵌实现
class FinanceHomePage extends StatefulWidget {
  const FinanceHomePage({super.key});

  @override
  State<FinanceHomePage> createState() => _FinanceHomePageState();
}

class _FinanceHomePageState extends State<FinanceHomePage> {
  InAppWebViewController? _controller;
  bool _isLoading = true;
  double _progress = 0;
  String _title = '缴费系统';

  static const String _homeUrl = 'https://ycard.ahu.edu.cn/plat/home';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            if (_controller != null && await _controller!.canGoBack()) {
              _controller!.goBack();
            } else if (mounted) {
              // ignore: use_build_context_synchronously
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => _controller?.loadUrl(
              urlRequest: URLRequest(url: WebUri(_homeUrl)),
            ),
            tooltip: '首页',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller?.reload(),
            tooltip: '刷新',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading)
            LinearProgressIndicator(value: _progress < 1 ? _progress : null),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(_homeUrl)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                useOnLoadResource: true,
                userAgent:
                    'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36',
                supportZoom: false,
                builtInZoomControls: false,
                transparentBackground: true,
              ),
              onWebViewCreated: (controller) {
                _controller = controller;
              },
              onLoadStart: (controller, url) {
                setState(() {
                  _isLoading = true;
                });
              },
              onLoadStop: (controller, url) async {
                setState(() {
                  _isLoading = false;
                  _progress = 1.0;
                });
                // 获取页面标题
                final title = await controller.getTitle();
                if (title != null && title.isNotEmpty && mounted) {
                  setState(() => _title = title);
                }
              },
              onProgressChanged: (controller, progress) {
                setState(() => _progress = progress / 100.0);
              },
              onTitleChanged: (controller, title) {
                if (title != null && title.isNotEmpty) {
                  setState(() => _title = title);
                }
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final url = navigationAction.request.url.toString();
                // 允许 ycard 域名的请求
                if (url.contains('ycard.ahu.edu.cn') ||
                    url.contains('xzxpay.com') ||
                    url.contains('supwisdom.com')) {
                  return NavigationActionPolicy.ALLOW;
                }
                // 阻止跳转到外部浏览器
                return NavigationActionPolicy.CANCEL;
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildQuickNav(),
    );
  }

  Widget _buildQuickNav() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home, '首页', () {
              _controller?.loadUrl(
                urlRequest: URLRequest(url: WebUri(_homeUrl)),
              );
            }),
            _navItem(Icons.credit_card, '校园卡', () {
              _controller?.loadUrl(
                urlRequest: URLRequest(
                  url: WebUri(
                    'https://ycard.ahu.edu.cn/campus-card/?name=campusCard',
                  ),
                ),
              );
            }),
            _navItem(Icons.account_balance_wallet, '充值', () {
              _controller?.loadUrl(
                urlRequest: URLRequest(
                  url: WebUri(
                    'https://ycard.ahu.edu.cn/campus-card/?name=cardRecharge',
                  ),
                ),
              );
            }),
            _navItem(Icons.qr_code, '一码通', () {
              _controller?.loadUrl(
                urlRequest: URLRequest(
                  url: WebUri('https://ycard.ahu.edu.cn/plat?name=cardcode'),
                ),
              );
            }),
            _navItem(Icons.receipt_long, '账单', () {
              _controller?.loadUrl(
                urlRequest: URLRequest(
                  url: WebUri(
                    'https://ycard.ahu.edu.cn/campus-card/?name=billList',
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: Colors.orange.shade700),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

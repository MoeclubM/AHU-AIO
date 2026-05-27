import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../api/jw_api.dart';

/// 通用 WebView 页面，共享 Dio 的认证 cookies
class JwWebViewPage extends StatefulWidget {
  final String title;
  final String url;

  const JwWebViewPage({super.key, required this.title, required this.url});

  @override
  State<JwWebViewPage> createState() => _JwWebViewPageState();
}

class _JwWebViewPageState extends State<JwWebViewPage> {
  bool _ready = false;
  bool _hasError = false;
  String? _errorMsg;
  InAppWebViewController? _controller;

  @override
  void initState() {
    super.initState();
    _syncCookies();
  }

  Future<void> _syncCookies() async {
    try {
      final api = JwApi();
      final cookies = await api.cookieJar.loadForRequest(
        Uri.parse(JwApi.baseUrl),
      );
      final cookieManager = CookieManager.instance();
      // 先清除旧 cookies
      await cookieManager.deleteAllCookies();
      for (final c in cookies) {
        await cookieManager.setCookie(
          url: WebUri(JwApi.baseUrl),
          name: c.name,
          value: c.value,
          domain: 'jw.ahu.edu.cn',
          path: c.path ?? '/',
          isSecure: true,
        );
      }
    } catch (_) {}
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller?.reload(),
            tooltip: '刷新',
          ),
        ],
      ),
      body: _ready
          ? Stack(
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    useWideViewPort: true,
                    supportZoom: true,
                    builtInZoomControls: true,
                    displayZoomControls: false,
                    // 允许跨域 cookie
                    thirdPartyCookiesEnabled: true,
                  ),
                  onWebViewCreated: (controller) {
                    _controller = controller;
                  },
                  onLoadStop: (controller, url) {
                    // 注入 viewport meta 让页面适配移动端
                    controller.evaluateJavascript(
                      source: """
                      (function() {
                        var meta = document.querySelector('meta[name="viewport"]');
                        if (!meta) {
                          meta = document.createElement('meta');
                          meta.name = 'viewport';
                          meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=3.0, user-scalable=yes';
                          document.head.appendChild(meta);
                        }
                        // 隐藏不需要的导航元素，优化移动端显示
                        var style = document.createElement('style');
                        style.textContent = 'body { font-size: 14px !important; } .page-header { display: none !important; }';
                        document.head.appendChild(style);
                      })();
                    """,
                    );
                    // 检查是否重定向到了登录页
                    final urlStr = url?.toString() ?? '';
                    if (urlStr.contains('/login') &&
                        !widget.url.contains('/login')) {
                      if (mounted) {
                        setState(() {
                          _hasError = true;
                          _errorMsg = '登录已过期，请重新登录';
                        });
                      }
                    }
                  },
                  onReceivedError: (controller, request, error) {
                    if (mounted) {
                      setState(() {
                        _hasError = true;
                        _errorMsg = '加载失败: ${error.description}';
                      });
                    }
                  },
                ),
                if (_hasError)
                  Center(
                    child: Card(
                      margin: const EdgeInsets.all(32),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMsg ?? '加载失败',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() => _hasError = false);
                                _controller?.loadUrl(
                                  urlRequest: URLRequest(
                                    url: WebUri(widget.url),
                                  ),
                                );
                              },
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

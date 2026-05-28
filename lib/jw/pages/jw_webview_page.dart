import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../utils/jw_webview_auth.dart';

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
  int _authRetryCount = 0;

  @override
  void initState() {
    super.initState();
    _prepareWebView();
  }

  Future<void> _prepareWebView() async {
    try {
      await JwWebViewAuth.syncCookies(widget.url);
    } catch (_) {}
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _handlePossibleAuthExpiry(String? currentUrl) async {
    if (!JwWebViewAuth.isLoginRedirect(currentUrl, widget.url)) return;
    if (_authRetryCount >= 1) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMsg = '登录已过期，请返回重新登录教务系统';
        });
      }
      return;
    }

    _authRetryCount++;
    await JwWebViewAuth.syncCookies(widget.url);
    await _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(widget.url)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              setState(() {
                _hasError = false;
                _authRetryCount = 0;
              });
              await JwWebViewAuth.syncCookies(widget.url);
              await _controller?.reload();
            },
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
                    thirdPartyCookiesEnabled: true,
                  ),
                  onWebViewCreated: (controller) {
                    _controller = controller;
                  },
                  onLoadStop: (controller, url) async {
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
                        var style = document.createElement('style');
                        style.textContent = 'body { font-size: 14px !important; } .page-header { display: none !important; }';
                        document.head.appendChild(style);
                      })();
                    """,
                    );

                    final urlStr = url?.toString() ?? '';
                    if (JwWebViewAuth.isLoginRedirect(urlStr, widget.url)) {
                      await _handlePossibleAuthExpiry(urlStr);
                    } else if (_hasError && mounted) {
                      setState(() => _hasError = false);
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
                              onPressed: () async {
                                setState(() {
                                  _hasError = false;
                                  _authRetryCount = 0;
                                });
                                await _prepareWebView();
                                await _controller?.loadUrl(
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

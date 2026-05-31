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
  int _blankRetryCount = 0;

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

  /// 检测页面是否白屏（SPA 渲染失败 / 空内容），并自动重试一次。
  Future<void> _scheduleBlankCheck(String loadedUrl) async {
    // 给 SPA 留出渲染时间
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted || _controller == null || _hasError) return;

    try {
      final result = await _controller!.evaluateJavascript(
        source: 'document.body ? document.body.innerText.trim().length : 0',
      );
      final len = result is num ? result.toInt() : int.tryParse('$result') ?? 0;
      if (len > 0) {
        _blankRetryCount = 0;
        return;
      }

      final current = (await _controller!.getUrl())?.toString() ?? loadedUrl;
      if (JwWebViewAuth.isLoginRedirect(current, widget.url)) return;

      if (_blankRetryCount < 1) {
        // 重新同步 Cookie 后再加载一次
        _blankRetryCount++;
        await JwWebViewAuth.syncCookies(widget.url);
        await _controller?.loadUrl(
          urlRequest: URLRequest(url: WebUri(widget.url)),
        );
      } else if (mounted) {
        setState(() {
          _hasError = true;
          _errorMsg = '页面加载为空白，请点击重试或稍后再试';
        });
      }
    } catch (_) {}
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
                _blankRetryCount = 0;
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
                    // 考试安排等页面为 SPA，依赖 DOM Storage，
                    // Android WebView 默认未开启会导致白屏。
                    domStorageEnabled: true,
                    databaseEnabled: true,
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
                    } else {
                      if (_hasError && mounted) {
                        setState(() => _hasError = false);
                      }
                      _scheduleBlankCheck(urlStr);
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
                                  _blankRetryCount = 0;
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

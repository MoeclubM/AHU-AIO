import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

typedef CasUrlHandler =
    Future<bool> Function(String url, InAppWebViewController controller);

class CasWebLoginPage extends StatefulWidget {
  final String title;
  final String initialUrl;
  final CasUrlHandler onUrlChanged;

  const CasWebLoginPage({
    super.key,
    required this.title,
    required this.initialUrl,
    required this.onUrlChanged,
  });

  @override
  State<CasWebLoginPage> createState() => _CasWebLoginPageState();
}

class _CasWebLoginPageState extends State<CasWebLoginPage> {
  InAppWebViewController? _controller;
  bool _loading = true;
  bool _handling = false;
  bool _completed = false;
  String? _pendingUrl;
  Object? _error;

  Future<void> _handleUrl(WebUri? url) async {
    final current = url?.toString();
    if (_completed || current == null) {
      return;
    }

    if (_handling) {
      _pendingUrl = current;
      return;
    }

    var nextUrl = current;
    while (!_completed && nextUrl != null) {
      final controller = _controller;
      if (controller == null) return;

      _handling = true;
      _pendingUrl = null;
      try {
        final done = await widget.onUrlChanged(nextUrl, controller);
        if (done && mounted) {
          setState(() => _completed = true);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _error = e);
        }
      } finally {
        _handling = false;
      }
      nextUrl = _pendingUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _error = null;
                _completed = false;
              });
              _handling = false;
              _pendingUrl = null;
              _controller?.loadUrl(
                urlRequest: URLRequest(url: WebUri(widget.initialUrl)),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              domStorageEnabled: true,
              databaseEnabled: true,
              thirdPartyCookiesEnabled: true,
              useWideViewPort: true,
              supportZoom: true,
            ),
            onWebViewCreated: (controller) {
              _controller = controller;
            },
            onLoadStart: (controller, url) {
              setState(() {
                _loading = true;
                _error = null;
              });
              _handleUrl(url);
            },
            onLoadStop: (controller, url) {
              if (mounted) setState(() => _loading = false);
              _handleUrl(url);
            },
            onReceivedError: (controller, request, error) {
              if (mounted) {
                setState(() {
                  _loading = false;
                  _error = error.description;
                });
              }
            },
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: Colors.red.shade700,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error.toString(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

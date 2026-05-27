import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../api/finance_api.dart';
import '../login/finance_login_view.dart';

/// 财务系统首页
class FinanceHomePage extends StatefulWidget {
  const FinanceHomePage({super.key});

  @override
  State<FinanceHomePage> createState() => _FinanceHomePageState();
}

class _FinanceHomePageState extends State<FinanceHomePage> {
  final _api = FinanceApi();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _userInfo;
  List<dynamic> _menuItems = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _api.init();
      final results = await Future.wait([
        _api.getUserInfo(),
        _api.getAppScheme(),
      ]);

      _userInfo = results[0];
      _menuItems = _extractMenu(results[1]);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<dynamic> _extractMenu(Map<String, dynamic> scheme) {
    try {
      final structure = scheme['data']?['schemeInfo']?['structureInfo'];
      if (structure == null) return [];
      final menus = <Map<String, dynamic>>[];
      void walk(dynamic node) {
        if (node is! Map) return;
        if (node['combinedMenuList'] is List) {
          for (final m in node['combinedMenuList']) {
            if (m is Map &&
                m['name'] != null &&
                m['name'].toString().isNotEmpty &&
                m['parentNodeId'] == 0) {
              menus.add(Map<String, dynamic>.from(m));
            }
            walk(m);
          }
        }
      }

      walk(structure);
      return menus;
    } catch (_) {
      return [];
    }
  }

  void _logout() async {
    await _api.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const FinanceLoginPage()),
    );
  }

  void _openWebView(String title, String path) {
    final fullUrl = path.startsWith('http')
        ? path
        : '${FinanceApi.baseUrl}$path';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FinanceInnerWebView(
          title: title,
          url: fullUrl,
          accessToken: _api.accessToken,
          cookies: _api.cookieJar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('缴费系统'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: '退出',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadData, child: const Text('重试')),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildUserCard(),
                  const SizedBox(height: 16),
                  _buildMenuGrid(),
                ],
              ),
            ),
    );
  }

  Widget _buildUserCard() {
    final data = _userInfo?['data'] ?? {};
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.orange.shade100,
              child: Text(
                (data['name']?.toString() ?? '?').isNotEmpty
                    ? data['name'].toString()[0]
                    : '?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name']?.toString() ?? '-',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '学号: ${data['sno']?.toString() ?? data['account']?.toString() ?? '-'}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGrid() {
    if (_menuItems.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('暂无可用功能')),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '功能菜单 (${_menuItems.length}项)',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: _menuItems.length,
          itemBuilder: (_, i) {
            final item = _menuItems[i];
            final name = item['name']?.toString() ?? '';
            final iconWhole = item['iconWhole']?.toString();
            final websize = item['websize']?.toString() ?? '';

            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: websize.isNotEmpty
                    ? () => _openWebView(name, websize)
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    iconWhole != null && iconWhole.startsWith('http')
                        ? Image.network(
                            iconWhole,
                            width: 32,
                            height: 32,
                            errorBuilder: (ctx, err, stack) => Icon(
                              Icons.apps,
                              size: 32,
                              color: Colors.orange.shade700,
                            ),
                          )
                        : Icon(
                            Icons.apps,
                            size: 32,
                            color: Colors.orange.shade700,
                          ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// 缴费系统内部 WebView（共享 token 和 cookies）
class FinanceInnerWebView extends StatefulWidget {
  final String title;
  final String url;
  final String? accessToken;
  final PersistCookieJar cookies;

  const FinanceInnerWebView({
    super.key,
    required this.title,
    required this.url,
    this.accessToken,
    required this.cookies,
  });

  @override
  State<FinanceInnerWebView> createState() => _FinanceInnerWebViewState();
}

class _FinanceInnerWebViewState extends State<FinanceInnerWebView> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _syncAuth();
  }

  Future<void> _syncAuth() async {
    final cookieManager = CookieManager.instance();
    await cookieManager.deleteAllCookies();

    // 同步 Dio cookies 到 WebView
    try {
      final cookies = await widget.cookies.loadForRequest(
        Uri.parse(FinanceApi.baseUrl),
      );
      for (final c in cookies) {
        await cookieManager.setCookie(
          url: WebUri(FinanceApi.baseUrl),
          name: c.name,
          value: c.value,
          domain: 'ycard.ahu.edu.cn',
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
      appBar: AppBar(title: Text(widget.title)),
      body: _ready
          ? InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                useWideViewPort: true,
                supportZoom: true,
                thirdPartyCookiesEnabled: true,
                userAgent:
                    'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36',
              ),
              onLoadStop: (controller, url) async {
                // 注入 viewport
                controller.evaluateJavascript(
                  source: """
                  var meta = document.querySelector('meta[name="viewport"]');
                  if (!meta) {
                    meta = document.createElement('meta');
                    meta.name = 'viewport';
                    meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=3.0';
                    document.head.appendChild(meta);
                  }
                """,
                );
                // 注入 access_token 到 sessionStorage
                if (widget.accessToken != null) {
                  controller.evaluateJavascript(
                    source:
                        'sessionStorage.setItem("access_token", "${widget.accessToken}");',
                  );
                }
              },
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

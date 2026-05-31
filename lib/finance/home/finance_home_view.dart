import 'dart:io' as io;

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
      _userInfo = await _api.getUserInfo();
      setState(() => _isLoading = false);
    } catch (e) {
      final message = e.toString();
      final unauthorized =
          message.contains('401') || message.contains('鉴权') || !_api.loggedIn;
      if (unauthorized) {
        _api.clearAuth();
      }
      setState(() {
        _error = unauthorized ? '登录已过期，请重新登录' : message;
        _isLoading = false;
      });
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
    var fullUrl = path.startsWith('http') ? path : '${FinanceApi.baseUrl}$path';
    // 将 token 直接拼到 URL，SPA 初始化时会从 synjones-auth 参数读取，
    // 避免仅靠 sessionStorage 注入产生的时序竞争（首屏跳登录）。
    final token = _api.accessToken;
    if (token != null &&
        token.isNotEmpty &&
        !fullUrl.contains('synjones-auth')) {
      final sep = fullUrl.contains('?') ? '&' : '?';
      fullUrl += '${sep}synjones-auth=${Uri.encodeComponent(token)}';
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FinanceInnerWebView(
          title: title,
          url: fullUrl,
          accessToken: token,
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
                  ElevatedButton(
                    onPressed: _error == '登录已过期，请重新登录' ? _logout : _loadData,
                    child: Text(_error == '登录已过期，请重新登录' ? '重新登录' : '重试'),
                  ),
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
                  _buildQuickServices(),
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

  /// 常用功能：直达一卡通平台的真实路由（一码通/充值/缴费等），
  /// 在共享登录态的 WebView 中打开。
  Widget _buildQuickServices() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '常用功能',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 12,
              childAspectRatio: 0.82,
              children: _financeServices.map((s) {
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openWebView(s.title, s.path),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: s.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(s.icon, color: s.color, size: 24),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.title,
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
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

    try {
      final requestUris = <Uri>{
        Uri.parse(FinanceApi.baseUrl),
        Uri.parse(widget.url),
      };
      final merged = <String, io.Cookie>{};
      for (final uri in requestUris) {
        final cookies = await widget.cookies.loadForRequest(uri);
        for (final c in cookies) {
          merged['${c.name}@${c.path ?? '/'}'] = c;
        }
      }
      for (final c in merged.values) {
        final path = c.path ?? '/';
        await cookieManager.setCookie(
          url: WebUri('${FinanceApi.baseUrl}$path'),
          name: c.name,
          value: c.value,
          domain: 'ycard.ahu.edu.cn',
          path: path,
          isSecure: true,
          isHttpOnly: c.httpOnly,
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
                domStorageEnabled: true,
                databaseEnabled: true,
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
                if (widget.accessToken != null) {
                  final token = widget.accessToken!.replaceAll('"', r'\"');
                  controller.evaluateJavascript(
                    source:
                        '''
                      sessionStorage.setItem("access_token", "$token");
                      localStorage.setItem("access_token", "$token");
                    ''',
                  );
                }
              },
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

/// 缴费系统常用功能项（直达一卡通平台真实路由）。
class _FinanceService {
  final String title;
  final IconData icon;
  final String path;
  final Color color;
  const _FinanceService(this.title, this.icon, this.path, this.color);
}

/// 路由取自一卡通 H5 平台（ycard.ahu.edu.cn/plat）的真实页面路由。
const List<_FinanceService> _financeServices = [
  _FinanceService('一码通', Icons.qr_code_2, '/plat/campusCode', Colors.orange),
  _FinanceService('电子卡', Icons.credit_card, '/plat/wecard', Colors.blue),
  _FinanceService(
    '充值大厅',
    Icons.account_balance_wallet,
    '/plat/dating',
    Colors.green,
  ),
  _FinanceService('在线缴费', Icons.payment, '/plat/pay', Colors.purple),
  _FinanceService('交易记录', Icons.receipt_long, '/plat/record', Colors.teal),
  _FinanceService('个人中心', Icons.person, '/plat/wode', Colors.indigo),
];

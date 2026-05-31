import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../api/synjones_client.dart';
import '../login/finance_login_view.dart';

/// 财务系统首页 — 一卡通余额/付款码/常用功能
class FinanceHomePage extends StatefulWidget {
  const FinanceHomePage({super.key});

  @override
  State<FinanceHomePage> createState() => _FinanceHomePageState();
}

class _FinanceHomePageState extends State<FinanceHomePage> {
  final _client = SynjonesClient();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _userInfo;
  List<dynamic> _cards = [];
  Map<String, dynamic>? _paymentInfo;

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
      await _client.init();

      // 并行获取用户信息、校园卡列表、支付信息
      final results = await Future.wait([
        _client.fetchUserInfo(),
        _client.getCampusCards(),
        _client.getPaymentInfo(),
      ]);

      _userInfo = results[0]['data'] as Map<String, dynamic>?;
      final cardsData = results[1];
      _cards = (cardsData['data']?['card'] as List?) ?? [];
      final payData = results[2];
      final payList = (payData['data'] as List?) ?? [];
      _paymentInfo = payList.isNotEmpty
          ? payList.first as Map<String, dynamic>
          : null;

      setState(() => _isLoading = false);
    } catch (e) {
      final msg = e.toString();
      final unauthorized =
          msg.contains('401') || msg.contains('鉴权') || !_client.loggedIn;
      if (unauthorized) {
        _client.accessToken = null;
      }
      setState(() {
        _error = unauthorized ? '登录已过期，请重新登录' : msg;
        _isLoading = false;
      });
    }
  }

  void _logout() async {
    await _client.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const FinanceLoginPage()),
    );
  }

  void _openWebView(String title, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FinanceWebView(title: title, url: url),
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
          ? _buildError()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildUserCard(),
                  const SizedBox(height: 16),
                  _buildBalanceCard(),
                  const SizedBox(height: 16),
                  _buildQuickServices(),
                ],
              ),
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
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
    );
  }

  Widget _buildUserCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.orange.shade100,
              backgroundImage: _userInfo?['avatar'] != null
                  ? NetworkImage(_userInfo!['avatar'])
                  : null,
              child: _userInfo?['avatar'] == null
                  ? Text(
                      (_userInfo?['name']?.toString() ?? '?').isNotEmpty
                          ? _userInfo!['name'].toString()[0]
                          : '?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userInfo?['name']?.toString() ?? '-',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '学号: ${_userInfo?['account']?.toString() ?? '-'}',
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

  /// 余额卡片：显示校园卡余额（单位：分 → 元）
  Widget _buildBalanceCard() {
    // 优先用 paymentInfo 的 elec_accamt，否则取第一张卡
    int balanceFen = 0;
    String accountLabel = '';
    if (_paymentInfo != null) {
      balanceFen = (_paymentInfo!['elec_accamt'] as num?)?.toInt() ?? 0;
      accountLabel = _paymentInfo!['name']?.toString() ?? '电子账户';
    } else if (_cards.isNotEmpty) {
      balanceFen = (_cards[0]['elec_accamt'] as num?)?.toInt() ?? 0;
      accountLabel = _cards[0]['cardname']?.toString() ?? '校园卡';
    }
    final balanceYuan = (balanceFen / 100).toStringAsFixed(2);

    return Card(
      elevation: 3,
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              accountLabel,
              style: TextStyle(fontSize: 14, color: Colors.orange.shade800),
            ),
            const SizedBox(height: 8),
            Text(
              '¥$balanceYuan',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '当前余额',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  /// 常用功能：直达一卡通平台的真实路由
  Widget _buildQuickServices() {
    final token = _client.accessToken;
    final tokenParam = token != null
        ? '&synjones-auth=${Uri.encodeComponent(token)}'
        : '';

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
                final fullUrl =
                    'https://ycard.ahu.edu.cn${s.path}'
                    '?synAccessSource=app$tokenParam';
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openWebView(s.title, fullUrl),
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

/// 缴费系统内部 WebView（token 通过 URL 参数注入）
class _FinanceWebView extends StatefulWidget {
  final String title;
  final String url;
  const _FinanceWebView({required this.title, required this.url});

  @override
  State<_FinanceWebView> createState() => _FinanceWebViewState();
}

class _FinanceWebViewState extends State<_FinanceWebView> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    // 小延时确保 WebView 初始化完成
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _ready = true);
    });
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
                    'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
                    '(KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36',
              ),
              onLoadStop: (controller, url) async {
                // 注入 viewport
                controller.evaluateJavascript(
                  source:
                      'var m=document.querySelector(\'meta[name="viewport"]\');'
                      'if(!m){m=document.createElement("meta");'
                      'm.name="viewport";'
                      'm.content="width=device-width,initial-scale=1.0,maximum-scale=3.0";'
                      'document.head.appendChild(m);}',
                );
              },
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class _FinanceService {
  final String title;
  final IconData icon;
  final String path;
  final Color color;
  const _FinanceService(this.title, this.icon, this.path, this.color);
}

/// 路由来自一卡通 H5 平台（ycard.ahu.edu.cn/plat）的真实页面
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

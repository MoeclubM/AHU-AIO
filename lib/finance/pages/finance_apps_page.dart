import 'package:flutter/material.dart';

import '../api/synjones_client.dart';
import 'finance_cards_page.dart';
import 'finance_pay_code_page.dart';
import 'finance_recharge_detail_page.dart';

class FinanceAppsPage extends StatefulWidget {
  final List<dynamic> initialCards;
  final List<dynamic> initialPayments;
  final Map<String, dynamic>? initialPayment;

  const FinanceAppsPage({
    super.key,
    this.initialCards = const [],
    this.initialPayments = const [],
    this.initialPayment,
  });

  @override
  State<FinanceAppsPage> createState() => _FinanceAppsPageState();
}

class _FinanceAppsPageState extends State<FinanceAppsPage> {
  final _client = SynjonesClient();
  List<Map<String, dynamic>> _apps = [];
  int? _cardRechargeFeeitemId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _client.init();
      final results = await Future.wait([
        _client.getAllApps(),
        _client.getFrontInfo(),
      ]);
      final resp = results[0];
      final frontInfo = results[1];
      _apps = ((resp['data'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final frontConfig = frontInfo['data']?['getFrontConfig'];
      if (frontConfig != null) {
        final recharge = RegExp(
          r'"recharge"\s*:\s*"?(\d+)"?',
        ).firstMatch(frontConfig.toString());
        if (recharge != null) {
          _cardRechargeFeeitemId = int.parse(recharge.group(1)!);
        }
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('一卡通功能')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : RefreshIndicator(
              onRefresh: _loadApps,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (_, index) => _buildApp(_apps[index]),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemCount: _apps.length,
              ),
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _loadApps, child: const Text('重试')),
          ],
        ),
      ),
    );
  }

  Widget _buildApp(Map<String, dynamic> app) {
    final action = _actionText(app);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade50,
          child: Icon(_icon(app), color: Colors.indigo.shade700),
        ),
        title: Text(_appTitle(app)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(action),
              Text(
                '编码：${app['appCode'] ?? app['code'] ?? app['indexCode'] ?? '-'}',
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openApp(app),
      ),
    );
  }

  void _openApp(Map<String, dynamic> app) {
    final code = _code(app);
    final title = _appTitle(app);
    final website = app['website']?.toString() ?? '';
    final lower = '$code $title $website'.toLowerCase();

    if (lower.contains('codebar') ||
        lower.contains('barcode') ||
        title.contains('付款码')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FinancePayCodePage(
            initialPayments: widget.initialPayments,
            initialPayment: widget.initialPayment,
          ),
        ),
      );
      return;
    }

    if (lower.contains('ecard') ||
        lower.contains('cardinfo') ||
        title.contains('电子卡')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FinanceCardsPage(initialCards: widget.initialCards),
        ),
      );
      return;
    }

    final isCardRecharge =
        code == 'card-recharge' ||
        website.contains('cardRecharge') ||
        title.contains('一卡通充值');
    final feeitemId = isCardRecharge
        ? _cardRechargeFeeitemId
        : _feeitemIdFromApp(app);
    if (feeitemId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FinanceRechargeDetailPage(
            entry: app,
            feeitemId: feeitemId,
            isCardRecharge: isCardRecharge,
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('该服务还没有原生接口映射：$title')));
  }

  String _actionText(Map<String, dynamic> app) {
    final code = _code(app);
    final title = _appTitle(app);
    final website = app['website']?.toString() ?? '';
    final lower = '$code $title $website'.toLowerCase();
    if (lower.contains('codebar') ||
        lower.contains('barcode') ||
        title.contains('付款码')) {
      return '原生打开付款二维码';
    }
    if (lower.contains('ecard') ||
        lower.contains('cardinfo') ||
        title.contains('电子卡')) {
      return '原生打开电子卡';
    }
    final isCardRecharge =
        code == 'card-recharge' ||
        website.contains('cardRecharge') ||
        title.contains('一卡通充值');
    final feeitemId = isCardRecharge
        ? _cardRechargeFeeitemId
        : _feeitemIdFromApp(app);
    if (feeitemId != null) {
      return isCardRecharge ? '原生打开一卡通充值' : '原生打开缴费项 $feeitemId';
    }
    return '暂未映射到原生接口';
  }

  IconData _icon(Map<String, dynamic> app) {
    final title = _appTitle(app);
    final lower = '${_code(app)} $title ${app['website'] ?? ''}'.toLowerCase();
    if (lower.contains('codebar') ||
        lower.contains('barcode') ||
        title.contains('付款码')) {
      return Icons.qr_code_2;
    }
    if (title.contains('充值')) return Icons.currency_yuan;
    if (title.contains('电')) return Icons.bolt;
    if (title.contains('网')) return Icons.wifi;
    if (title.contains('卡')) return Icons.credit_card;
    return Icons.apps;
  }

  int? _feeitemIdFromApp(Map<String, dynamic> app) {
    final raw = app['feeitemid'] ?? app['feeitemId'];
    if (raw != null) return int.parse(raw.toString());
    final website = app['website']?.toString() ?? '';
    final uri = Uri.tryParse(website);
    final value =
        uri?.queryParameters['feeitemid'] ?? uri?.queryParameters['feeitemId'];
    if (value != null) return int.parse(value);
    final fragment = uri?.fragment;
    if (fragment == null || !fragment.contains('?')) return null;
    final fragmentQuery = fragment.substring(fragment.indexOf('?') + 1);
    final fragmentParams = Uri.splitQueryString(fragmentQuery);
    final fragmentValue =
        fragmentParams['feeitemid'] ?? fragmentParams['feeitemId'];
    return fragmentValue == null ? null : int.parse(fragmentValue);
  }

  String _code(Map<String, dynamic> app) {
    return (app['appCode'] ?? app['code'] ?? app['indexCode'] ?? '').toString();
  }

  String _appTitle(Map<String, dynamic> app) {
    return app['name']?.toString() ??
        app['mc']?.toString() ??
        app['appName']?.toString() ??
        app['title']?.toString() ??
        '未命名服务';
  }
}

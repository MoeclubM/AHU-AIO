import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/synjones_client.dart';
import 'finance_recharge_detail_page.dart';

/// 充值缴费页面视图模式通知器（false: 网格大方块, true: 列表左图标右文字）
final ValueNotifier<bool> financeRechargeIsListViewNotifier =
    ValueNotifier<bool>(false);

class FinanceRechargePage extends StatefulWidget {
  final bool embed;
  const FinanceRechargePage({super.key, this.embed = false});

  /// 切换列表 / 网格视图模式并持久化存储
  static Future<void> toggleViewMode() async {
    await setViewMode(!financeRechargeIsListViewNotifier.value);
  }

  /// 设置指定的列表 / 网格视图模式并持久化存储
  static Future<void> setViewMode(bool isList) async {
    financeRechargeIsListViewNotifier.value = isList;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('finance_recharge_is_list', isList);
    } catch (_) {}
  }

  /// 读取已保存的视图模式配置
  static Future<void> loadSavedViewMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isList = prefs.getBool('finance_recharge_is_list') ?? false;
      financeRechargeIsListViewNotifier.value = isList;
    } catch (_) {}
  }

  @override
  State<FinanceRechargePage> createState() => _FinanceRechargePageState();
}

class _FinanceRechargePageState extends State<FinanceRechargePage> {
  final _client = SynjonesClient();
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadViewMode();
    _loadEntries();
  }

  Future<void> _loadViewMode() async {
    await FinanceRechargePage.loadSavedViewMode();
  }

  Future<void> _loadEntries() async {
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
      final apps = ((results[0]['data'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final frontConfig =
          jsonDecode(results[1]['data']['getFrontConfig'].toString())
              as Map<String, dynamic>;
      final cardRechargeFeeitemId = int.parse(
        frontConfig['recharge'].toString(),
      );

      final seen = <String>{};
      final entries = <Map<String, dynamic>>[];
      for (final app in apps) {
        final code = app['appCode']?.toString() ?? '';
        final website = app['website']?.toString() ?? '';
        final isCardRecharge =
            code == 'card-recharge' || website.contains('cardRecharge');
        final rawFeeitemId = app['feeitemid'] ?? app['feeitemId'];
        final feeitemId = isCardRecharge
            ? cardRechargeFeeitemId
            : rawFeeitemId == null
            ? _feeitemIdFromWebsite(website)
            : int.parse(rawFeeitemId.toString());
        if (!isCardRecharge && feeitemId == null) continue;

        final key = '$code-$feeitemId';
        if (seen.contains(key)) continue;
        seen.add(key);
        entries.add({
          ...app,
          'feeitemId': feeitemId,
          'isCardRecharge': isCardRecharge,
        });
      }

      entries.sort((a, b) {
        if (a['isCardRecharge'] == true) return -1;
        if (b['isCardRecharge'] == true) return 1;
        return _title(a).compareTo(_title(b));
      });
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int? _feeitemIdFromWebsite(String website) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embed
          ? null
          : AppBar(
              title: const Text('充值入口'),
              actions: [
                ValueListenableBuilder<bool>(
                  valueListenable: financeRechargeIsListViewNotifier,
                  builder: (context, isListView, _) {
                    return IconButton(
                      icon: Icon(
                        isListView
                            ? Icons.grid_view_rounded
                            : Icons.view_list_rounded,
                      ),
                      onPressed: FinanceRechargePage.toggleViewMode,
                      tooltip: isListView ? '切换为网格视图' : '切换为列表视图',
                    );
                  },
                ),
              ],
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : ValueListenableBuilder<bool>(
              valueListenable: financeRechargeIsListViewNotifier,
              builder: (context, isListView, _) {
                return RefreshIndicator(
                  onRefresh: _loadEntries,
                  child: isListView
                      ? ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 148),
                          itemCount: _entries.length,
                          itemBuilder: (_, index) =>
                              _buildListEntry(_entries[index]),
                        )
                      : GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 148),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.1,
                              ),
                          itemBuilder: (_, index) =>
                              _buildEntry(_entries[index]),
                          itemCount: _entries.length,
                        ),
                );
              },
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
            FilledButton(onPressed: _loadEntries, child: const Text('重试')),
          ],
        ),
      ),
    );
  }

  Widget _buildEntry(Map<String, dynamic> entry) {
    final isCardRecharge = entry['isCardRecharge'] == true;
    final title = _title(entry);

    IconData iconData = Icons.payment;
    if (isCardRecharge) {
      iconData = Icons.credit_card;
    } else if (title.contains('水')) {
      iconData = Icons.water_drop;
    } else if (title.contains('电')) {
      iconData = Icons.bolt;
    } else if (title.contains('网') ||
        title.contains('网络') ||
        title.contains('宽带')) {
      iconData = Icons.wifi;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FinanceRechargeDetailPage(
                entry: entry,
                feeitemId: entry['feeitemId'] as int,
                isCardRecharge: isCardRecharge,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                child: Icon(iconData, color: colorScheme.primary, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListEntry(Map<String, dynamic> entry) {
    final isCardRecharge = entry['isCardRecharge'] == true;
    final title = _title(entry);

    IconData iconData = Icons.payment;
    if (isCardRecharge) {
      iconData = Icons.credit_card;
    } else if (title.contains('水')) {
      iconData = Icons.water_drop;
    } else if (title.contains('电')) {
      iconData = Icons.bolt;
    } else if (title.contains('网') ||
        title.contains('网络') ||
        title.contains('宽带')) {
      iconData = Icons.wifi;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.35),
          width: 0.6,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FinanceRechargeDetailPage(
                entry: entry,
                feeitemId: entry['feeitemId'] as int,
                isCardRecharge: isCardRecharge,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                child: Icon(iconData, color: colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _title(Map<String, dynamic> entry) {
    return entry['appName']?.toString() ??
        entry['name']?.toString() ??
        entry['mc']?.toString() ??
        entry['appCode']?.toString() ??
        '充值入口';
  }
}

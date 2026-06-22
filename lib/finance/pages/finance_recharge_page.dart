import 'dart:convert';

import 'package:flutter/material.dart';

import '../api/synjones_client.dart';
import 'finance_recharge_detail_page.dart';

class FinanceRechargePage extends StatefulWidget {
  final bool embed;
  const FinanceRechargePage({super.key, this.embed = false});

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
    _loadEntries();
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
      appBar: widget.embed ? null : AppBar(title: const Text('充值入口')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : RefreshIndicator(
              onRefresh: _loadEntries,
              child: GridView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (_, index) => _buildEntry(_entries[index]),
                itemCount: _entries.length,
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
    } else if (title.contains('网') || title.contains('网络') || title.contains('宽带')) {
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
                child: Icon(
                  iconData,
                  color: colorScheme.primary,
                  size: 28,
                ),
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

  String _title(Map<String, dynamic> entry) {
    return entry['appName']?.toString() ??
        entry['name']?.toString() ??
        entry['mc']?.toString() ??
        entry['appCode']?.toString() ??
        '充值入口';
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';

import '../api/synjones_client.dart';
import 'finance_recharge_detail_page.dart';

class FinanceRechargePage extends StatefulWidget {
  const FinanceRechargePage({super.key});

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
      appBar: AppBar(title: const Text('充值入口')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : RefreshIndicator(
              onRefresh: _loadEntries,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (_, index) => _buildEntry(_entries[index]),
                separatorBuilder: (_, _) => const SizedBox(height: 12),
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
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCardRecharge
              ? Colors.orange.shade50
              : Colors.green.shade50,
          child: Icon(
            isCardRecharge ? Icons.credit_card : Icons.bolt,
            color: isCardRecharge ? Colors.orange.shade700 : Colors.green,
          ),
        ),
        title: Text(_title(entry)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('缴费项：${entry['feeitemId']}'),
              Text('入口：${entry['appCode'] ?? entry['bh'] ?? '-'}'),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
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

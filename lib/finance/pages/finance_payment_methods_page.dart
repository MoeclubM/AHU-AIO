import 'package:flutter/material.dart';

import '../api/synjones_client.dart';
import 'finance_pay_code_page.dart';

class FinancePaymentMethodsPage extends StatefulWidget {
  final List<dynamic> initialPayments;

  const FinancePaymentMethodsPage({super.key, this.initialPayments = const []});

  @override
  State<FinancePaymentMethodsPage> createState() =>
      _FinancePaymentMethodsPageState();
}

class _FinancePaymentMethodsPageState extends State<FinancePaymentMethodsPage> {
  final _client = SynjonesClient();
  List<Map<String, dynamic>> _payments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _payments = widget.initialPayments
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _client.init();
      if (_payments.isEmpty) {
        final resp = await _client.getPaymentInfo();
        _payments = ((resp['data'] as List?) ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
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
      appBar: AppBar(title: const Text('付款方式')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : RefreshIndicator(
              onRefresh: () async {
                _payments = [];
                await _loadPayments();
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (_, index) => _buildPayment(_payments[index]),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemCount: _payments.length,
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
            FilledButton(onPressed: _loadPayments, child: const Text('重试')),
          ],
        ),
      ),
    );
  }

  Widget _buildPayment(Map<String, dynamic> payment) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.shade50,
          child: Icon(
            Icons.account_balance_wallet,
            color: Colors.purple.shade700,
          ),
        ),
        title: Text(_title(payment)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('账户：${payment['account'] ?? '-'}'),
              Text(
                '支付账号：${payment['payacc'] ?? '-'} · 类型：${payment['paytype'] ?? '-'}',
              ),
              Text(
                '余额：¥${_money(payment['elec_accamt'] ?? payment['balance'])}',
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FinancePayCodePage(
                initialPayments: _payments,
                initialPayment: payment,
              ),
            ),
          );
        },
      ),
    );
  }

  String _title(Map<String, dynamic> payment) {
    final name = payment['name']?.toString();
    final payName = payment['payName']?.toString();
    final code = payment['code']?.toString();
    return [
      name,
      payName,
      code,
    ].where((e) => e != null && e.isNotEmpty).join(' · ');
  }

  String _money(dynamic value) {
    if (value is num) return (value / 100).toStringAsFixed(2);
    final parsed = num.tryParse(value?.toString() ?? '');
    return parsed == null ? '-' : (parsed / 100).toStringAsFixed(2);
  }
}

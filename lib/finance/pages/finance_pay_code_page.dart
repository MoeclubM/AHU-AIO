import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/synjones_client.dart';
import '../widgets/code128_barcode.dart';

class FinancePayCodePage extends StatefulWidget {
  final List<dynamic> initialPayments;
  final Map<String, dynamic>? initialPayment;

  const FinancePayCodePage({
    super.key,
    this.initialPayments = const [],
    this.initialPayment,
  });

  @override
  State<FinancePayCodePage> createState() => _FinancePayCodePageState();
}

class _FinancePayCodePageState extends State<FinancePayCodePage> {
  final _client = SynjonesClient();
  List<Map<String, dynamic>> _payments = [];
  Map<String, dynamic>? _payment;
  bool _loading = true;
  bool _generating = false;
  String? _error;
  String? _barcode;
  int? _expires;
  DateTime? _generatedAt;

  @override
  void initState() {
    super.initState();
    _payments = widget.initialPayments
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    _payment = widget.initialPayment;
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
      _payment ??= _payments.isNotEmpty ? _payments.first : null;
      setState(() => _loading = false);
      if (_payment != null) await _generateCode();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _generateCode() async {
    final payment = _payment;
    if (payment == null) return;
    setState(() {
      _generating = true;
      _error = null;
      _barcode = null;
    });
    try {
      final resp = await _client.generateBarcode(
        account: payment['account'].toString(),
        payacc: payment['payacc'].toString(),
        paytype: payment['paytype'].toString(),
      );
      final data = resp['data'] as Map?;
      final codes = (data?['barcode'] as List?) ?? [];
      if (codes.isEmpty) {
        setState(() {
          _error = resp['msg']?.toString() ?? '付款码接口未返回码值';
          _generating = false;
        });
        return;
      }
      setState(() {
        _barcode = codes.first.toString();
        _expires = (data?['expires'] as num?)?.toInt();
        _generatedAt = DateTime.now();
        _generating = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _generating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('付款码')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _generateCode,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_payments.isEmpty) _buildEmpty() else _buildPaymentCard(),
                  if (_payments.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildCodeCard(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildEmpty() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.payments_outlined,
              size: 56,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 12),
            const Text('当前账号没有可用付款方式'),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard() {
    final selectedIndex = _payments.indexWhere(
      (e) => e['id'] == _payment?['id'],
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '付款方式',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: selectedIndex < 0 ? 0 : selectedIndex,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '选择付款账户',
              ),
              items: [
                for (var i = 0; i < _payments.length; i++)
                  DropdownMenuItem(
                    value: i,
                    child: Text(_paymentTitle(_payments[i])),
                  ),
              ],
              onChanged: (value) async {
                _payment = _payments[value!];
                await _generateCode();
              },
            ),
            const SizedBox(height: 12),
            _infoRow('账户', _payment?['account']),
            _infoRow('支付账号', _payment?['payacc']),
            _infoRow('支付类型', _payment?['paytype']),
            _infoRow(
              '余额',
              '¥${_money(_payment?['elec_accamt'] ?? _payment?['balance'])}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '当前付款码',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: _generating ? null : _generateCode,
                  icon: const Icon(Icons.refresh),
                  tooltip: '刷新付款码',
                ),
              ],
            ),
            if (_generating)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              )
            else if (_barcode != null) ...[
              Code128Barcode(data: _barcode!),
              const SizedBox(height: 16),
              SelectableText(
                _groupCode(_barcode!),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _expires == null
                    ? '生成时间：${_timeText(_generatedAt)}'
                    : '有效期：${_expires}s · 生成时间：${_timeText(_generatedAt)}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: _barcode!));
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('码值已复制')));
                },
                icon: const Icon(Icons.copy),
                label: const Text('复制码值'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(child: Text(value?.toString() ?? '-')),
        ],
      ),
    );
  }

  String _paymentTitle(Map<String, dynamic> payment) {
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

  String _groupCode(String value) {
    return value
        .replaceAllMapped(RegExp(r'.{1,4}'), (m) => '${m.group(0)} ')
        .trim();
  }

  String _timeText(DateTime? value) {
    if (value == null) return '-';
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    final s = value.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

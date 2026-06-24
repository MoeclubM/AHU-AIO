import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/synjones_client.dart';
import '../widgets/code128_barcode.dart';

class FinanceCardsPage extends StatefulWidget {
  final List<dynamic> initialCards;
  final bool embed;

  const FinanceCardsPage({
    super.key,
    this.initialCards = const [],
    this.embed = false,
  });

  @override
  State<FinanceCardsPage> createState() => _FinanceCardsPageState();
}

class _FinanceCardsPageState extends State<FinanceCardsPage> {
  final _client = SynjonesClient();
  List<Map<String, dynamic>> _cards = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cards = widget.initialCards
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _client.init();
      if (_cards.isEmpty) {
        final resp = await _client.getCampusCards();
        _cards = ((resp['data']?['card'] as List?) ?? [])
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

  Future<void> _showAuthCode(Map<String, dynamic> card) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final resp = await _client.generateBarcode(
        account: card['account'].toString(),
        payacc: '###',
        paytype: '1',
        codeType: 'authCode',
      );
      final data = resp['data'] as Map?;
      final codes = (data?['barcode'] as List?) ?? [];
      if (!mounted) return;
      Navigator.pop(context);
      if (codes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp['msg']?.toString() ?? '身份码接口未返回码值')),
        );
        return;
      }
      final code = codes.first.toString();
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(card['name']?.toString() ?? '校园卡身份码'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Code128Barcode(data: code, height: 88),
              const SizedBox(height: 12),
              SelectableText(
                _groupCode(code),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, letterSpacing: 1),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text('复制'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('完成'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embed ? null : AppBar(title: const Text('电子卡')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : RefreshIndicator(
              onRefresh: () async {
                _cards = [];
                await _loadCards();
              },
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 148),
                itemBuilder: (_, index) => _buildCard(_cards[index]),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemCount: _cards.length,
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
            FilledButton(onPressed: _loadCards, child: const Text('重试')),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> card) {
    final balance = _money(
      card['elec_accamt'] ?? card['db_balance'] ?? card['balance'],
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: Icon(Icons.credit_card, color: Colors.blue.shade700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card['name']?.toString() ??
                            card['cardname']?.toString() ??
                            '校园卡',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        card['account']?.toString() ?? '-',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Text(
                  '¥$balance',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _infoRow('卡号', card['cardno'] ?? card['sno']),
            _infoRow('有效期', card['expdate']),
            _infoRow('状态', _cardStatus(card)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => _showAuthCode(card),
                icon: const Icon(Icons.qr_code_2),
                label: const Text('生成身份码'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(child: Text(value?.toString() ?? '-')),
        ],
      ),
    );
  }

  String _cardStatus(Map<String, dynamic> card) {
    if (card['lostflag'] == 1) return '已挂失';
    if (card['status'] == 0) return '不可用';
    return '正常';
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
}

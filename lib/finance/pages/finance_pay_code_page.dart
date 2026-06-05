import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../api/synjones_client.dart';
import '../api/synjones_offline_code.dart';

class FinancePayCodePage extends StatefulWidget {
  const FinancePayCodePage({super.key});

  @override
  State<FinancePayCodePage> createState() => _FinancePayCodePageState();
}

class _FinancePayCodePageState extends State<FinancePayCodePage> {
  final _client = SynjonesClient();

  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  String? _oneCode;
  String? _barcode;
  int? _expires;
  DateTime? _generatedAt;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _payment;
  List<Map<String, dynamic>> _payments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _client.init();
      if (!_client.loggedIn) {
        final result = await _client.casLoginWithCachedSession();
        if (result == null || !result.success) {
          throw StateError(result?.message ?? '请先登录一卡通系统');
        }
      }
      final userResp = await _client.fetchUserInfo();
      final paymentResp = await _client.getPaymentInfo();
      _user = userResp['data'] as Map<String, dynamic>?;
      _payments = ((paymentResp['data'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (_payments.isEmpty) {
        throw StateError('当前账号没有可用付款方式');
      }
      _payment = _payments.firstWhere(
        (payment) => payment['status'] == 1 || payment['status'] == '1',
        orElse: () => _payments.first,
      );
      final code = await _fetchOneCode(_payment!);
      setState(() {
        _oneCode = code.code;
        _barcode = code.barcode;
        _expires = code.expires;
        _generatedAt = DateTime.now();
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<_OneCodeData> _fetchOneCode(Map<String, dynamic> payment) async {
    if (payment['voucherStatus'] != 1 && payment['voucherStatus'] != '1') {
      throw StateError('当前付款方式未开通离线一码通参数，无法生成真实一码通二维码');
    }
    final barcodeResp = await _client.generateBarcode(
      account: payment['account'].toString(),
      payacc: payment['payacc'].toString(),
      paytype: payment['paytype'].toString(),
    );
    final barcodeData = barcodeResp['data'] as Map?;
    final barcodes = (barcodeData?['barcode'] as List?) ?? [];
    if (barcodes.isEmpty) {
      throw StateError(barcodeResp['msg']?.toString() ?? '一码通接口未返回码值');
    }
    final barcode = barcodes.first.toString();
    final frontInfo = await _client.getFrontInfo();
    final frontConfig = _frontConfig(frontInfo);
    final privateKey = frontConfig['privateKey']?.toString();
    if (privateKey == null || privateKey.isEmpty) {
      throw StateError('一卡通前端配置缺少离线码私钥');
    }
    final offlineParams = await _client.getOfflinePayParams(
      payacc: payment['payacc'].toString(),
      paytype: payment['paytype'].toString(),
      voucher: payment['voucher'].toString(),
    );
    final offlineData = offlineParams['data'] as Map?;
    if (offlineData == null) {
      throw StateError(offlineParams['msg']?.toString() ?? '离线一码通参数为空');
    }
    final code = SynjonesOfflineCode.build(
      barcode: barcode,
      payment: payment,
      offlineParams: Map<String, dynamic>.from(offlineData),
      privateKey: privateKey,
    );
    if (!RegExp(r'^\d{20}SP[A-Za-z0-9+/]+=*$').hasMatch(code)) {
      throw StateError('生成的一码通内容格式异常');
    }
    return _OneCodeData(
      code: code,
      barcode: barcode,
      expires: (barcodeData?['expires'] as num?)?.toInt(),
    );
  }

  Future<void> _refreshCode() async {
    final payment = _payment;
    if (payment == null) {
      await _load();
      return;
    }
    setState(() {
      _refreshing = true;
      _error = null;
    });
    try {
      final code = await _fetchOneCode(payment);
      setState(() {
        _oneCode = code.code;
        _barcode = code.barcode;
        _expires = code.expires;
        _generatedAt = DateTime.now();
        _refreshing = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _refreshing = false;
      });
    }
  }

  Map<String, dynamic> _frontConfig(Map<String, dynamic> resp) {
    final raw = resp['data']?['getFrontConfig'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.isNotEmpty) {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    }
    throw StateError('一卡通前端配置为空');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('一码通')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshCode,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildOneCodeCard(),
                  if (_payments.length > 1) ...[
                    const SizedBox(height: 16),
                    _buildPaymentCard(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentCard() {
    final selectedIndex = _payments.indexWhere(
      (payment) => payment['id'] == _payment?['id'],
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<int>(
          value: selectedIndex < 0 ? 0 : selectedIndex,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: '付款方式',
          ),
          items: [
            for (var i = 0; i < _payments.length; i++)
              DropdownMenuItem(
                value: i,
                child: Text(_paymentTitle(_payments[i])),
              ),
          ],
          onChanged: _refreshing
              ? null
              : (value) async {
                  _payment = _payments[value!];
                  await _refreshCode();
                },
        ),
      ),
    );
  }

  Widget _buildOneCodeCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final user = _user ?? {};
    final payment = _payment ?? {};
    final name = _maskedName(user['name']?.toString());
    final account =
        user['sno']?.toString() ?? user['account']?.toString() ?? '';
    final avatar = user['avatar']?.toString();
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      child: Column(
        children: [
          Text(
            '一码通',
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 54),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 70, 18, 20),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      account,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_refreshing)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 72),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 72),
                        child: Column(
                          children: [
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colorScheme.error),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _load,
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      )
                    else if (_oneCode != null)
                      Container(
                        width: 250,
                        height: 250,
                        padding: const EdgeInsets.all(8),
                        color: Colors.white,
                        child: QrImageView(
                          data: _oneCode!,
                          version: QrVersions.auto,
                          errorCorrectionLevel: QrErrorCorrectLevel.L,
                          backgroundColor: Colors.white,
                          errorStateBuilder: (_, error) =>
                              Center(child: Text('二维码生成失败：$error')),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      _timeText(),
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '余额',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            '￥${_money(payment['elec_accamt'] ?? payment['accinfo_balance'] ?? payment['balance'])}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_barcode != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '在线码：$_barcode',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _refreshing ? null : _refreshCode,
                      icon: const Icon(Icons.refresh),
                      label: const Text('点击刷新'),
                    ),
                    TextButton.icon(
                      onPressed: _oneCode == null
                          ? null
                          : () async {
                              await Clipboard.setData(
                                ClipboardData(text: _oneCode!),
                              );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('一码通内容已复制')),
                              );
                            },
                      icon: const Icon(Icons.copy),
                      label: const Text('复制二维码内容'),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -50,
                child: CircleAvatar(
                  radius: 54,
                  backgroundColor: colorScheme.surface,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage: _headImage(avatar),
                    child: _headImage(avatar) == null
                        ? Icon(
                            Icons.person,
                            size: 48,
                            color: colorScheme.onSurfaceVariant,
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ImageProvider? _headImage(String? value) {
    if (value == null || value.isEmpty) return null;
    return NetworkImage(value);
  }

  String _paymentTitle(Map<String, dynamic> payment) {
    final name = payment['name']?.toString();
    final code = payment['code']?.toString();
    return [name, code].where((e) => e != null && e.isNotEmpty).join(' · ');
  }

  String _money(dynamic value) {
    if (value is num) return (value / 100).toStringAsFixed(2);
    final parsed = num.tryParse(value?.toString() ?? '');
    return parsed == null ? '-' : (parsed / 100).toStringAsFixed(2);
  }

  String _timeText() {
    final time = _generatedAt;
    if (time == null) return '';
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    final expires = _expires == null ? '' : '有效期：${_expires}s · ';
    return '$expires生成时间：$h:$m:$s';
  }

  String _maskedName(String? value) {
    if (value == null || value.isEmpty) return '-';
    if (value.length == 2) return '${value.substring(0, 1)} *';
    if (value.length == 3) {
      return '${value.substring(0, 1)} * ${value.substring(2, 3)}';
    }
    return '${value.substring(0, 1)} * * ${value.substring(3)}';
  }
}

class _OneCodeData {
  final String code;
  final String barcode;
  final int? expires;

  const _OneCodeData({
    required this.code,
    required this.barcode,
    required this.expires,
  });
}

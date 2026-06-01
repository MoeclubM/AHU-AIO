import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/synjones_client.dart';

class FinanceRechargeDetailPage extends StatefulWidget {
  final Map<String, dynamic> entry;
  final int feeitemId;
  final bool isCardRecharge;

  const FinanceRechargeDetailPage({
    super.key,
    required this.entry,
    required this.feeitemId,
    required this.isCardRecharge,
  });

  @override
  State<FinanceRechargeDetailPage> createState() =>
      _FinanceRechargeDetailPageState();
}

class _FinanceRechargeDetailPageState extends State<FinanceRechargeDetailPage> {
  final _client = SynjonesClient();
  final _amountController = TextEditingController();
  final _thirdInputController = TextEditingController();

  Map<String, dynamic>? _feeitem;
  String _feeitemType = 'choose';
  List<Map<String, dynamic>> _accounts = [];
  String? _accountValue;
  List<String> _amountLayout = [];
  bool _thirdInputMode = false;

  List<Map<String, dynamic>> _thirdLevels = [];
  final Map<String, List<Map<String, dynamic>>> _thirdOptions = {};
  final Map<String, String> _thirdSelected = {};
  final Map<String, String> _thirdSelectedLabels = {};
  Map<String, dynamic>? _thirdPartyData;
  Map<String, dynamic> _thirdInfoRows = {};
  String? _thirdTip;
  String? _sceneText;
  bool _thirdLoading = false;

  Map<String, dynamic>? _orderResponse;
  Map<String, dynamic>? _payInfo;
  String? _selectedPayId;
  Map<String, dynamic>? _payStepResponse;
  bool _loading = true;
  bool _creating = false;
  bool _paying = false;
  String? _error;
  String? _thirdError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _thirdInputController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _thirdError = null;
      _orderResponse = null;
      _payInfo = null;
      _payStepResponse = null;
      _selectedPayId = null;
      _feeitemType = 'choose';
      _accounts = [];
      _accountValue = null;
      _amountLayout = [];
      _thirdInputMode = false;
      _thirdLevels = [];
      _thirdOptions.clear();
      _thirdSelected.clear();
      _thirdSelectedLabels.clear();
      _thirdPartyData = null;
      _thirdInfoRows = {};
      _thirdTip = null;
      _sceneText = null;
      _amountController.clear();
      _thirdInputController.clear();
    });
    try {
      await _client.init();
      final feeResp = await _client.getFeeItem(widget.feeitemId);
      _feeitem = Map<String, dynamic>.from(feeResp['feeitem'] as Map);
      _feeitemType = feeResp['view']?.toString() ?? 'choose';
      _amountLayout = _parseAmountLayout(_feeitem!['layout']);
      final flag = _feeitem!['flag'].toString();
      _thirdInputMode = flag.length > 4 && flag[4] == '1';
      if (_amountLayout.isNotEmpty) _amountController.text = _amountLayout[0];

      if (widget.isCardRecharge) {
        final results = await Future.wait([
          _client.getFrontInfo(),
          _client.queryRechargeCards(),
        ]);
        final ecardConfig =
            jsonDecode(results[0]['data']['getEcardConfig'].toString())
                as Map<String, dynamic>;
        _accounts = _buildRechargeAccounts(
          ((results[1]['data']?['card'] as List?) ?? []).whereType<Map>(),
          ecardConfig['type']?.toString() ?? '0',
        );
        if (_accounts.isNotEmpty) {
          _accountValue = _accounts.first['myID'].toString();
        }
      } else if (_feeitem!['impl_interface'] != null) {
        await _initThirdData(feeResp['sceneinfo']?.toString());
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<String> _parseAmountLayout(dynamic layout) {
    return layout
            ?.toString()
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];
  }

  List<Map<String, dynamic>> _buildRechargeAccounts(
    Iterable<Map> cards,
    String rechargeCardType,
  ) {
    final accounts = <Map<String, dynamic>>[];
    for (final rawCard in cards) {
      final card = Map<String, dynamic>.from(rawCard);
      final canRecharge = card['lostflag'] == 0 && card['freezeflag'] == 0;
      if (rechargeCardType != '1') {
        accounts.add({
          ...card,
          'myID': card['account'],
          'myTitle': card['cardname']?.toString().isNotEmpty == true
              ? card['cardname']
              : '校园卡',
          'myBalance':
              (((card['db_balance'] as num?) ?? 0) +
                  ((card['unsettle_amount'] as num?) ?? 0)) /
              100,
          'myIsRecharge': canRecharge,
        });
      }
      if (rechargeCardType != '2') {
        for (final rawAcc
            in ((card['accinfo'] as List?) ?? []).whereType<Map>()) {
          final acc = Map<String, dynamic>.from(rawAcc);
          accounts.add({
            ...acc,
            'account': card['account'],
            'sno': card['sno'],
            'lostflag': card['lostflag'],
            'freezeflag': card['freezeflag'],
            'myID': acc['type'],
            'myTitle': acc['name']?.toString().isNotEmpty == true
                ? acc['name']
                : '电子账户',
            'myBalance': (((acc['balance'] as num?) ?? 0) / 100),
            'myIsRecharge': canRecharge,
          });
        }
      }
    }
    return accounts;
  }

  Future<void> _initThirdData(String? sceneinfo) async {
    final parsed = _parseSceneInfo(sceneinfo);
    if (parsed.isNotEmpty) {
      for (final item in parsed) {
        _thirdSelected[item['key']!] = item['id']!;
        _thirdSelectedLabels[item['key']!] = item['name']!;
      }
      if (_thirdInputMode) {
        _thirdInputController.text = parsed.last['id']!;
      }
      _sceneText = parsed.map((e) => e['name']).join(' ');
      await _loadThirdData(type: 'IEC', level: parsed.length);
    } else {
      await _loadThirdData(type: 'select', level: 0);
    }
  }

  List<Map<String, String>> _parseSceneInfo(String? sceneinfo) {
    if (sceneinfo == null || sceneinfo.isEmpty) return [];
    return sceneinfo.split(';').where((e) => e.contains(':')).map((part) {
      final key = part.substring(0, part.indexOf(':'));
      final value = part.substring(part.indexOf(':') + 1);
      final pieces = value.split('#\$#');
      return {
        'key': key,
        'id': pieces[0],
        'name': pieces.length > 1 ? pieces[1] : pieces[0].split('&').last,
      };
    }).toList();
  }

  Future<void> _loadThirdData({
    required String type,
    required int level,
  }) async {
    setState(() {
      _thirdLoading = true;
      _thirdError = null;
      if (type == 'IEC') {
        _thirdPartyData = null;
        _thirdInfoRows = {};
        _thirdTip = null;
      }
    });
    try {
      final params = <String, dynamic>{
        'feeitemid': widget.feeitemId,
        'type': type,
        'level': level,
        ..._thirdSelected,
      };
      final resp = await _client.getFeeItemThirdData(params);
      final map = Map<String, dynamic>.from(resp['map'] as Map);
      final totals = ((map['total'] as List?) ?? []).whereType<Map>().toList();
      if (totals.isNotEmpty && _thirdLevels.isEmpty) {
        _thirdLevels = totals.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      if (type == 'select') {
        final dataList = ((map['data'] as List?) ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        final nextLevel = _thirdLevels
            .where((e) => (e['level'] as num?)?.toInt() == level + 1)
            .toList();
        if (nextLevel.isNotEmpty && nextLevel.first['code'] != null) {
          final code = nextLevel.first['code'].toString();
          _thirdOptions[code] = dataList;
        }
        _thirdTip = map['tipinfo']?.toString();
        final onlyDirectQuery =
            dataList.isEmpty &&
            _thirdTip == null &&
            _thirdLevels.length == 1 &&
            ((_thirdLevels.first['level'] as num?)?.toInt() ?? -1) == 0;
        if (onlyDirectQuery) {
          await _loadThirdData(type: 'IEC', level: 0);
          return;
        }
      } else {
        if (map['data'] is Map) {
          final data = Map<String, dynamic>.from(map['data'] as Map);
          if (_sceneText != null &&
              _sceneText!.isNotEmpty &&
              _thirdLevels.isNotEmpty) {
            final label = _thirdLevels.last['name']?.toString() ?? '';
            data['myCustomInfo'] = label.isEmpty
                ? _sceneText
                : '$label：$_sceneText';
          }
          _thirdPartyData = data;
        }
        _thirdInfoRows = _thirdInfoFromMap(map);
        _thirdTip = map['tipinfo']?.toString();
        if (map['money'] != null) {
          _amountController.text = map['money'].toString();
        }
      }
      setState(() => _thirdLoading = false);
    } catch (e) {
      setState(() {
        _thirdError = e.toString();
        _thirdLoading = false;
      });
    }
  }

  Future<void> _selectThirdValue(
    Map<String, dynamic> level,
    String value,
  ) async {
    final code = level['code'].toString();
    final levelNo = (level['level'] as num).toInt();
    final option = _thirdOptions[code]!.firstWhere(
      (e) => _thirdOptionValue(e) == value,
    );
    setState(() {
      _thirdSelected[code] = value;
      _thirdSelectedLabels[code] = _thirdOptionLabel(option);
      _sceneText = _thirdLevels
          .map((e) => e['code']?.toString())
          .where((e) => e != null && _thirdSelectedLabels.containsKey(e))
          .map((e) => _thirdSelectedLabels[e]!)
          .join(' ');
      for (final next in _thirdLevels.where(
        (e) => ((e['level'] as num?)?.toInt() ?? 0) > levelNo,
      )) {
        final nextCode = next['code']?.toString();
        if (nextCode != null) {
          _thirdSelected.remove(nextCode);
          _thirdSelectedLabels.remove(nextCode);
          _thirdOptions.remove(nextCode);
        }
      }
    });

    final maxLevel = _thirdLevels
        .map((e) => (e['level'] as num?)?.toInt() ?? 0)
        .fold<int>(0, (a, b) => a > b ? a : b);
    if (levelNo < maxLevel) {
      await _loadThirdData(type: 'select', level: levelNo);
    } else {
      await _loadThirdData(type: 'IEC', level: levelNo);
    }
  }

  Future<void> _queryThirdInput() async {
    final value = _thirdInputController.text.trim();
    if (value.isEmpty) {
      _showMessage('请输入查询信息');
      return;
    }
    if (_thirdLevels.isEmpty) {
      _showMessage('未获取到第三方查询字段');
      return;
    }
    final level = _thirdLevels.last;
    final code = level['code'].toString();
    final levelNo = (level['level'] as num?)?.toInt() ?? _thirdLevels.length;
    setState(() {
      _thirdSelected[code] = value;
      _thirdSelectedLabels[code] = value;
      _sceneText = value;
    });
    await _loadThirdData(type: 'IEC', level: levelNo);
  }

  Future<void> _createCardOrder() async {
    final amount = _amountController.text.trim();
    if (_accountValue == null) {
      _showMessage('请选择充值账户');
      return;
    }
    if (amount.isEmpty) {
      _showMessage('请输入充值金额');
      return;
    }
    setState(() {
      _creating = true;
      _orderResponse = null;
      _payInfo = null;
    });
    try {
      final resp = await _client.createCardRechargeOrder(
        feeitemId: widget.feeitemId,
        yktcard: _accountValue!,
        tranamt: amount,
      );
      await _setOrderResponse(resp);
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      setState(() => _creating = false);
    }
  }

  Future<void> _createChargeOrder() async {
    final amount = _amountController.text.trim();
    if (amount.isEmpty) {
      _showMessage('请输入缴费金额');
      return;
    }
    if (_feeitem?['impl_interface'] != null && _thirdPartyData == null) {
      _showMessage('请先完成缴费对象查询');
      return;
    }

    setState(() {
      _creating = true;
      _orderResponse = null;
      _payInfo = null;
    });
    try {
      final data = <String, dynamic>{
        'feeitemid': widget.feeitemId,
        'tranamt': amount,
        'flag': _feeitemType,
        'abstracts': _sceneText ?? '',
      };
      if (_thirdPartyData != null) {
        data['third_party'] = jsonEncode(_thirdPartyData);
      }
      final resp = await _client.createChargeOrder(data);
      await _setOrderResponse(resp);
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      setState(() => _creating = false);
    }
  }

  Future<void> _setOrderResponse(Map<String, dynamic> resp) async {
    _orderResponse = resp;
    final data = resp['data'];
    final orderId = data is Map
        ? data['orderid']?.toString()
        : resp['orderid']?.toString();
    if (orderId != null && orderId.isNotEmpty) {
      _payInfo = await _client.getChargePayInfo(orderId);
      final payList = ((_payInfo?['payList'] as List?) ?? []).whereType<Map>();
      if (payList.isNotEmpty) {
        final paytypeid = data is Map
            ? data['paytypeid']?.toString()
            : resp['paytypeid']?.toString();
        final matched = payList.any(
          (pay) => pay['payid'].toString() == paytypeid,
        );
        _selectedPayId = matched
            ? paytypeid
            : payList.first['payid'].toString();
      }
    }
    setState(() {});
  }

  Future<void> _requestPayStep() async {
    final orderData = _orderResponse?['data'];
    final orderId = orderData is Map
        ? orderData['orderid']?.toString()
        : _orderResponse?['orderid']?.toString();
    final pay = _selectedPay();
    if (orderId == null || orderId.isEmpty || pay == null) {
      _showMessage('缺少订单或支付方式');
      return;
    }
    final paytype = pay['code'] ?? pay['paytype'];
    final paytypeid = pay['payid'] ?? pay['paytypeid'];
    setState(() {
      _paying = true;
      _payStepResponse = null;
    });
    try {
      final data = <String, dynamic>{
        'orderid': orderId,
        'paystep': 2,
        if (paytype != null) 'paytype': paytype,
        if (paytypeid != null) 'paytypeid': paytypeid,
        if (pay['payment'] != null) 'payment': pay['payment'],
        if (pay['account'] != null) 'account': pay['account'],
        if (pay['payacc'] != null) 'payacc': pay['payacc'],
        if (pay['name'] != null) 'paytypename': pay['name'],
      };
      final resp = await _client.postChargePay(data);
      setState(() => _payStepResponse = resp);
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _title(widget.entry);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildFeeitemCard(),
                  const SizedBox(height: 12),
                  widget.isCardRecharge
                      ? _buildCardRechargeForm()
                      : _buildChargeForm(),
                  if (_orderResponse != null) ...[
                    const SizedBox(height: 12),
                    _buildOrderResult(),
                  ],
                ],
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
            FilledButton(onPressed: _load, child: const Text('重试')),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeitemCard() {
    final feeitem = _feeitem!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              feeitem['name']?.toString() ?? _title(widget.entry),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _infoRow('缴费项', widget.feeitemId),
            _infoRow('接口', feeitem['impl_interface'] ?? '标准充值'),
            _infoRow('限额', _limitText(feeitem)),
            if (feeitem['content'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _plainText(feeitem['content'].toString()),
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardRechargeForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '充值账户',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_accounts.isEmpty)
              const Text('当前账号没有可充值账户')
            else
              DropdownButtonFormField<String>(
                value: _accountValue,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '选择账户',
                ),
                items: _accounts
                    .map(
                      (e) => DropdownMenuItem<String>(
                        value: e['myID'].toString(),
                        child: Text(_accountTitle(e)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _accountValue = value),
              ),
            const SizedBox(height: 16),
            _buildAmountInput('充值金额'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _creating || _accounts.isEmpty
                  ? null
                  : _createCardOrder,
              icon: _creating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.payments),
              label: Text(_creating ? '正在下单' : '创建充值订单'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChargeForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '缴费信息',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (_feeitem?['impl_interface'] != null) ...[
              const SizedBox(height: 12),
              _buildThirdSelectors(),
            ],
            const SizedBox(height: 16),
            _buildAmountInput('缴费金额'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _creating ? null : _createChargeOrder,
              icon: _creating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.receipt_long),
              label: Text(_creating ? '正在下单' : '创建缴费订单'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThirdSelectors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_sceneText != null && _sceneText!.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('已解析缴费对象：$_sceneText'),
          ),
        if (_thirdInputMode) ...[
          const SizedBox(height: 12),
          _buildThirdInputQuery(),
        ] else
          for (final level in _thirdLevels)
            if (level['code'] != null) ...[
              const SizedBox(height: 12),
              _buildLevelSelector(level),
            ],
        if (_thirdLoading)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_thirdError != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _thirdError!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        if (_thirdTip != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _thirdTip!,
              style: TextStyle(color: Colors.orange.shade800),
            ),
          ),
        if (_thirdInfoRows.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(),
          ..._thirdInfoRows.entries.map((e) => _infoRow(e.key, e.value)),
        ],
      ],
    );
  }

  Widget _buildThirdInputQuery() {
    final level = _thirdLevels.isEmpty ? null : _thirdLevels.last;
    final label = level?['name']?.toString() ?? '查询信息';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: _thirdInputController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: label,
              hintText: '请输入$label',
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _thirdLoading ? null : _queryThirdInput,
          child: const Text('查询'),
        ),
      ],
    );
  }

  Widget _buildLevelSelector(Map<String, dynamic> level) {
    final code = level['code'].toString();
    final options = _thirdOptions[code] ?? [];
    final selected = _thirdSelected[code];
    if (options.isEmpty) {
      return _infoRow(
        level['name'] ?? code,
        selected == null ? '等待上一级查询' : _thirdSelectedLabels[code],
      );
    }
    return DropdownButtonFormField<String>(
      value: selected,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: level['name']?.toString() ?? code,
      ),
      items: options
          .map(
            (e) => DropdownMenuItem<String>(
              value: _thirdOptionValue(e),
              child: Text(_thirdOptionLabel(e)),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) _selectThirdValue(level, value);
      },
    );
  }

  Widget _buildAmountInput(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixText: '¥ ',
            hintText: '输入金额',
          ),
        ),
        if (_amountLayout.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _amountLayout
                .map(
                  (amount) => ActionChip(
                    label: Text('¥$amount'),
                    onPressed: () => setState(() {
                      _amountController.text = amount;
                    }),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildOrderResult() {
    final orderData = _orderResponse?['data'];
    final orderId = orderData is Map
        ? orderData['orderid']?.toString()
        : _orderResponse?['orderid']?.toString();
    final redirectUrl = orderData is Map
        ? orderData['redirectUrl']?.toString()
        : null;
    final payList = ((_payInfo?['payList'] as List?) ?? []).whereType<Map>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '下单结果',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _infoRow('接口返回', _orderResponse?['msg'] ?? _orderResponse?['code']),
            _infoRow(
              '支付状态',
              orderId == null
                  ? '未创建订单'
                  : _payStepResponse == null
                  ? '订单已创建，尚未支付'
                  : '支付接口已返回',
            ),
            _infoRow('订单号', orderId ?? '-'),
            if (redirectUrl != null) _infoRow('收银台', redirectUrl),
            if (payList.isNotEmpty) ...[
              const Divider(height: 24),
              const Text('可用支付方式'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPayId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '支付方式',
                ),
                items: payList
                    .map(
                      (pay) => DropdownMenuItem<String>(
                        value: pay['payid'].toString(),
                        child: Text(
                          pay['name']?.toString() ?? pay['code'].toString(),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _selectedPayId = value;
                  _payStepResponse = null;
                }),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _paying ? null : _requestPayStep,
                icon: _paying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.payment),
                label: Text(_paying ? '正在提交支付' : '提交支付'),
              ),
            ] else if (orderId != null) ...[
              const SizedBox(height: 8),
              Text(
                '订单已创建，但接口未返回可用支付方式。',
                style: TextStyle(color: Colors.orange.shade800),
              ),
            ],
            if (_payStepResponse != null) ...[
              const Divider(height: 24),
              const Text('支付接口响应'),
              const SizedBox(height: 8),
              SelectableText(jsonEncode(_payStepResponse)),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: jsonEncode(_payStepResponse)),
                  );
                  if (!mounted) return;
                  _showMessage('支付参数响应已复制');
                },
                icon: const Icon(Icons.copy),
                label: const Text('复制支付参数'),
              ),
            ],
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: jsonEncode(_orderResponse)),
                );
                if (!mounted) return;
                _showMessage('订单响应已复制');
              },
              icon: const Icon(Icons.copy),
              label: const Text('复制订单响应'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(child: Text(value?.toString() ?? '-')),
        ],
      ),
    );
  }

  String _accountTitle(Map<String, dynamic> account) {
    final balance = (account['myBalance'] as num?)?.toStringAsFixed(2) ?? '-';
    return '${account['myTitle']} · ${account['myID']} · ¥$balance';
  }

  Map<String, dynamic>? _selectedPay() {
    for (final pay
        in ((_payInfo?['payList'] as List?) ?? []).whereType<Map>()) {
      if (pay['payid'].toString() == _selectedPayId) {
        return Map<String, dynamic>.from(pay);
      }
    }
    return null;
  }

  String _thirdOptionValue(Map<String, dynamic> option) {
    return (option['value'] ??
            option['id'] ??
            option['code'] ??
            option['bh'] ??
            option['roomid'] ??
            option['roomId'] ??
            option['account'])
        .toString();
  }

  String _thirdOptionLabel(Map<String, dynamic> option) {
    return (option['name'] ??
            option['mc'] ??
            option['label'] ??
            option['text'] ??
            option['title'] ??
            _thirdOptionValue(option))
        .toString();
  }

  Map<String, dynamic> _thirdInfoFromMap(Map<String, dynamic> map) {
    final rows = <String, dynamic>{};
    if (map['data'] is Map) rows.addAll(Map<String, dynamic>.from(map['data']));
    if (map['showData'] is Map) {
      rows.addAll(Map<String, dynamic>.from(map['showData']));
    }
    for (final key in [
      'money',
      'balance',
      'leftmoney',
      'leftMoney',
      'surplus',
      'realMoney',
      'account',
      'username',
      'custname',
    ]) {
      if (map[key] != null) rows[key] = map[key];
    }
    return rows;
  }

  String _limitText(Map<String, dynamic> feeitem) {
    final min = feeitem['retain_money']?.toString();
    final max = feeitem['maxmoney']?.toString();
    return [
      if (min != null && min.isNotEmpty) '最低 ¥$min',
      if (max != null && max.isNotEmpty) '最高 ¥$max',
    ].join('，');
  }

  String _plainText(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _title(Map<String, dynamic> entry) {
    return entry['appName']?.toString() ??
        entry['name']?.toString() ??
        entry['appCode']?.toString() ??
        '充值入口';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

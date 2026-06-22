import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
  String? _boundSceneInfo;
  List<Map<String, String>> _boundSceneItems = [];
  bool _thirdSceneEditing = true;
  bool _thirdLoading = false;

  Map<String, dynamic>? _orderResponse;
  Map<String, dynamic>? _payInfo;
  String? _selectedPayId;
  List<String> _accountNoList = [];
  List<Map<String, dynamic>> _accountTypeList = [];
  String? _selectedAccountNo;
  String? _selectedCccType;
  Map<String, dynamic>? _payStepResponse;
  List<String> _secureKeyboardValues = [];
  List<String> _secureKeyboardImages = [];
  String? _secureKeyboardUuid;
  String _paymentPasswordValue = '';
  bool _loading = true;
  bool _creating = false;
  bool _preparingPay = false;
  bool _paying = false;
  bool _keyboardLoading = false;
  bool _sceneBinding = false;
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
      _accountNoList = [];
      _accountTypeList = [];
      _selectedAccountNo = null;
      _selectedCccType = null;
      _secureKeyboardValues = [];
      _secureKeyboardImages = [];
      _secureKeyboardUuid = null;
      _paymentPasswordValue = '';
      _keyboardLoading = false;
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
      _boundSceneInfo = null;
      _boundSceneItems = [];
      _thirdSceneEditing = true;
      _amountController.clear();
      _thirdInputController.clear();
      _sceneBinding = false;
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
      _boundSceneInfo = sceneinfo;
      _boundSceneItems = parsed;
      _thirdSceneEditing = false;
      _setThirdSelectionsFromScene(parsed);
      await _loadThirdData(type: 'select', level: 0);
      for (final level in _thirdLevels) {
        final levelNo = (level['level'] as num?)?.toInt();
        final code = level['code']?.toString();
        if (levelNo != null &&
            code != null &&
            _thirdSelected.containsKey(code) &&
            levelNo < _thirdLevels.length) {
          await _loadThirdData(type: 'select', level: levelNo);
        }
      }
      final lastLevel = (_thirdLevels.isEmpty
          ? parsed.length
          : (_thirdLevels.last['level'] as num?)?.toInt() ?? parsed.length);
      await _loadThirdData(type: 'IEC', level: lastLevel);
    } else {
      _thirdSceneEditing = true;
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

  void _setThirdSelectionsFromScene(List<Map<String, String>> items) {
    _thirdSelected.clear();
    _thirdSelectedLabels.clear();
    for (final item in items) {
      _thirdSelected[item['key']!] = item['id']!;
      _thirdSelectedLabels[item['key']!] = item['name']!;
    }
    if (_thirdInputMode) {
      _thirdInputController.text = items.last['id']!;
    }
    _sceneText = _sceneTextFromItems(items);
  }

  String _sceneTextFromItems(List<Map<String, String>> items) {
    return items.map((e) => e['name']).join(' ');
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
        _thirdLevels = totals.map((e) => Map<String, dynamic>.from(e)).toList()
          ..sort(
            (a, b) => ((a['level'] as num?)?.toInt() ?? 0).compareTo(
              (b['level'] as num?)?.toInt() ?? 0,
            ),
          );
      }

      if (type == 'select') {
        final dataList = ((map['data'] as List?) ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        if (dataList.isNotEmpty && _thirdLevels.isNotEmpty) {
          final nextLevel = _nextThirdLevel(level);
          if (nextLevel != null) {
            final levelNo = (nextLevel['level'] as num?)?.toInt();
            final code = nextLevel['code']?.toString();
            if (code != null) _thirdOptions[code] = dataList;
            if (levelNo != null) _thirdOptions['level:$levelNo'] = dataList;
          }
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
          if (_thirdInputMode &&
              (_sceneText == null || _sceneText!.isEmpty) &&
              _thirdLevels.isNotEmpty) {
            final code = _thirdLevels.last['code']?.toString();
            if (code != null && data[code] != null) {
              final val = data[code].toString();
              _thirdSelected[code] = val;
              _thirdSelectedLabels[code] = val;
              _thirdInputController.text = val;
              _sceneText = val;
              final label = _thirdLevels.last['name']?.toString() ?? '';
              data['myCustomInfo'] = label.isEmpty ? val : '$label：$val';
            }
          }
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
    final options = _thirdOptions[code] ?? _thirdOptions['level:$levelNo']!;
    final option = options.firstWhere((e) => _thirdOptionValue(e) == value);
    setState(() {
      _thirdSelected[code] = value;
      _thirdSelectedLabels[code] = _thirdOptionLabel(option);
      _thirdPartyData = null;
      _thirdInfoRows = {};
      _thirdTip = null;
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
        final nextLevelNo = (next['level'] as num?)?.toInt();
        if (nextLevelNo != null) _thirdOptions.remove('level:$nextLevelNo');
      }
    });

    final index = _thirdLevels.indexWhere(
      (e) => (e['level'] as num?)?.toInt() == levelNo,
    );
    if (index >= 0 && index < _thirdLevels.length - 1) {
      await _loadThirdData(type: 'select', level: levelNo);
    } else {
      await _loadThirdData(type: 'IEC', level: levelNo);
    }
  }

  Map<String, dynamic>? _nextThirdLevel(int currentLevel) {
    for (final level in _thirdLevels) {
      final levelNo = (level['level'] as num?)?.toInt();
      if (levelNo != null && levelNo > currentLevel) {
        return level;
      }
    }
    return null;
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

  Future<void> _editBoundScene() async {
    setState(() {
      _thirdSceneEditing = true;
      _thirdPartyData = null;
      _thirdInfoRows = {};
      _thirdTip = null;
    });
    if (_thirdOptions.isEmpty) await _loadThirdData(type: 'select', level: 0);
  }

  Future<void> _useBoundScene() async {
    setState(() {
      _setThirdSelectionsFromScene(_boundSceneItems);
      _thirdSceneEditing = false;
      _thirdPartyData = null;
      _thirdInfoRows = {};
      _thirdTip = null;
    });
    final lastLevel = (_thirdLevels.isEmpty
        ? _boundSceneItems.length
        : (_thirdLevels.last['level'] as num?)?.toInt() ??
              _boundSceneItems.length);
    await _loadThirdData(type: 'IEC', level: lastLevel);
  }

  Future<void> _confirmSceneBind(bool bind) async {
    final label = _sceneLabel();
    final sceneinfo = bind ? _currentSceneInfo() : null;
    final text = bind
        ? _sceneText ?? ''
        : _sceneTextFromItems(_boundSceneItems);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${bind ? '添加' : '解绑'}$label信息'),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _saveSceneBinding(sceneinfo);
  }

  Future<void> _saveSceneBinding(String? sceneinfo) async {
    setState(() => _sceneBinding = true);
    try {
      final resp = await _client.bindFeeItemScene(
        feeitemId: widget.feeitemId,
        sceneinfo: sceneinfo,
      );
      if (resp['code'] != 200) {
        throw StateError(resp['msg']?.toString() ?? '缴费对象绑定失败');
      }
      if (sceneinfo != null) {
        final parsed = _parseSceneInfo(sceneinfo);
        setState(() {
          _boundSceneInfo = sceneinfo;
          _boundSceneItems = parsed;
          _thirdSceneEditing = false;
          _setThirdSelectionsFromScene(parsed);
          _sceneBinding = false;
        });
        _showMessage('添加成功');
      } else {
        setState(() {
          _boundSceneInfo = null;
          _boundSceneItems = [];
          _thirdSceneEditing = true;
          _thirdSelected.clear();
          _thirdSelectedLabels.clear();
          _thirdOptions.clear();
          _thirdPartyData = null;
          _thirdInfoRows = {};
          _thirdTip = null;
          _sceneText = null;
          _thirdInputController.clear();
          _sceneBinding = false;
        });
        await _loadThirdData(type: 'select', level: 0);
        _showMessage('解绑成功');
      }
    } catch (e) {
      setState(() => _sceneBinding = false);
      _showMessage(e.toString());
    }
  }

  String _currentSceneInfo() {
    return _thirdLevels
        .map((level) {
          final code = level['code']?.toString();
          if (code == null || !_thirdSelected.containsKey(code)) return null;
          final value = _thirdSelected[code]!;
          final label = _thirdSelectedLabels[code] ?? value.split('&').last;
          return '$code:$value#\$#$label';
        })
        .whereType<String>()
        .join(';');
  }

  String _sceneLabel() {
    return _thirdLevels.isEmpty
        ? '信息'
        : (_thirdLevels.last['name']?.toString() ?? '信息');
  }

  Future<void> _createCardOrder() async {
    final amount = _amountController.text.trim();
    if (amount.isEmpty) {
      _showMessage('请输入充值金额');
      return;
    }
    if (_accountValue == null) {
      _showMessage('请选择充值账户');
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
        tranamt: amount,
        yktcard: _accountValue!,
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
    _payStepResponse = null;
    _accountNoList = [];
    _accountTypeList = [];
    _selectedAccountNo = null;
    _selectedCccType = null;
    _secureKeyboardValues = [];
    _secureKeyboardImages = [];
    _secureKeyboardUuid = null;
    _paymentPasswordValue = '';
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
    if (orderId != null && orderId.isNotEmpty && _selectedPayId != null) {
      await _prepareSelectedPay(orderId);
    }
  }

  Future<void> _prepareSelectedPay(String orderId) async {
    final pay = _selectedPay();
    if (pay == null) return;
    final code = _payCode(pay);
    setState(() {
      _preparingPay = true;
      _accountNoList = [];
      _accountTypeList = [];
      _selectedAccountNo = null;
      _selectedCccType = null;
      _payStepResponse = null;
      _secureKeyboardValues = [];
      _secureKeyboardImages = [];
      _secureKeyboardUuid = null;
      _paymentPasswordValue = '';
      _keyboardLoading = _requiresPaymentPassword(pay);
    });
    try {
      if (code == 'CARD' || code == 'CARDTSM') {
        final resp = await _client.postChargePay(
          _payBaseData(orderId, pay),
          includeRedirect: false,
        );
        final accounts = _accountNoFromPayStep(resp);
        setState(() {
          _accountNoList = accounts;
          _selectedAccountNo = accounts.isEmpty ? null : accounts.first;
        });
      } else if (code == 'ACCOUNT' || code == 'ACCOUNTTSM') {
        if (_truthy(pay['chooseAccount'])) {
          final resp = await _client.postChargePay(
            _payBaseData(orderId, pay),
            includeRedirect: false,
          );
          final accounts = _accountNoFromPayStep(resp);
          _accountNoList = accounts;
          _selectedAccountNo = accounts.isEmpty ? null : accounts.first;
        }
        await _loadAccountTypes(orderId, pay);
      }
      if (_requiresPaymentPassword(pay)) {
        await _loadSecureKeyboard();
      }
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) setState(() => _preparingPay = false);
    }
  }

  Future<void> _loadAccountTypes(
    String orderId,
    Map<String, dynamic> pay,
  ) async {
    final data = _payBaseData(orderId, pay);
    if (_selectedAccountNo != null) data['accountno'] = _selectedAccountNo;
    final resp = await _client.postChargePay(data, includeRedirect: false);
    if (resp['code'] != 200 && resp['code'] != '200') {
      throw StateError(
        (resp['msg'] ?? resp['message'] ?? '电子账户信息获取失败').toString(),
      );
    }
    final respData = resp['data'];
    final accountNo = respData is Map
        ? respData['accountno']?.toString()
        : null;
    final types = respData is Map
        ? ((respData['ccctype'] as List?) ?? [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : <Map<String, dynamic>>[];
    setState(() {
      if (accountNo != null && accountNo.isNotEmpty) {
        _selectedAccountNo = accountNo;
        if (!_accountNoList.contains(accountNo)) _accountNoList = [accountNo];
      }
      _accountTypeList = types;
      _selectedCccType = types.isEmpty
          ? null
          : types.first['ccctype']?.toString();
    });
  }

  Future<void> _loadSecureKeyboard() async {
    setState(() {
      _keyboardLoading = true;
      _paymentPasswordValue = '';
    });
    try {
      final keyboard = await _client.getSecureKeyboard(order: 0);
      final data = Map<String, dynamic>.from(keyboard['data'] as Map);
      final values = data['numberKeyboard'].toString().split('');
      final images = (data['numberKeyboardImage'] as List)
          .map((e) => e.toString())
          .toList();
      setState(() {
        _secureKeyboardValues = values;
        _secureKeyboardImages = images;
        _secureKeyboardUuid = data['uuid'].toString();
      });
    } finally {
      if (mounted) setState(() => _keyboardLoading = false);
    }
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
    final code = _payCode(pay);
    if ((code == 'CARD' || code == 'CARDTSM') &&
        _truthy(pay['chooseAccount']) &&
        _selectedAccountNo == null) {
      _showMessage('请选择支付账户');
      return;
    }
    if ((code == 'ACCOUNT' || code == 'ACCOUNTTSM') &&
        _truthy(pay['chooseAccount']) &&
        _selectedAccountNo == null) {
      _showMessage('请选择支付账户');
      return;
    }
    if ((code == 'ACCOUNT' || code == 'ACCOUNTTSM') &&
        _selectedCccType == null) {
      _showMessage('请选择电子账户');
      return;
    }
    final needsPassword = _requiresPaymentPassword(pay);
    if (needsPassword && _paymentPasswordValue.length < 6) {
      _showMessage('请输入支付密码');
      return;
    }
    setState(() {
      _paying = true;
      _payStepResponse = null;
    });
    try {
      final data = <String, dynamic>{..._payBaseData(orderId, pay)};
      if (_selectedAccountNo != null) data['accountno'] = _selectedAccountNo;
      if (_selectedCccType != null) data['ccctype'] = _selectedCccType;
      if (needsPassword) {
        data['password'] =
            '1\$1\$$_paymentPasswordValue\$1\$$_secureKeyboardUuid';
        data['pwdType'] = 1;
      }
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
    final colorScheme = Theme.of(context).colorScheme;
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
            _infoRow('限额', _limitText(feeitem)),
            if (feeitem['content'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _plainText(feeitem['content'].toString()),
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
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
            const Text('将为当前校园卡创建充值订单，支付完成后到账。'),
            if (_accounts.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _accountValue,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '当前卡片',
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
            ],
            const SizedBox(height: 16),
            _buildAmountInput('充值金额'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _creating ? null : _createCardOrder,
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
    final colorScheme = Theme.of(context).colorScheme;
    final canBind = _truthy(_feeitem?['bindStatus']);
    final hasBoundScene =
        _boundSceneInfo != null && _boundSceneInfo!.isNotEmpty;
    final sceneLabel = _sceneLabel();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasBoundScene && !_thirdSceneEditing)
          _buildBoundScenePanel(colorScheme)
        else if (_sceneText != null && _sceneText!.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '已解析缴费对象：$_sceneText',
              style: TextStyle(color: colorScheme.onPrimaryContainer),
            ),
          ),
        if (hasBoundScene && _thirdSceneEditing)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _sceneBinding ? null : _useBoundScene,
                icon: const Icon(Icons.bookmark),
                label: Text('我的$sceneLabel'),
              ),
            ),
          ),
        if (_thirdSceneEditing && _thirdInputMode) ...[
          const SizedBox(height: 12),
          _buildThirdInputQuery(),
        ] else if (_thirdSceneEditing)
          for (final level in _thirdLevels)
            if (level['code'] != null) ...[
              const SizedBox(height: 12),
              _buildLevelSelector(level),
            ],
        if (canBind &&
            _thirdPartyData != null &&
            (_thirdSceneEditing || !hasBoundScene))
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  FilledButton.icon(
                    onPressed: _sceneBinding
                        ? null
                        : () => _confirmSceneBind(true),
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(hasBoundScene ? '保存修改' : '添加为我的$sceneLabel'),
                  ),
                  if (hasBoundScene) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _sceneBinding
                          ? null
                          : () => _confirmSceneBind(false),
                      icon: const Icon(Icons.remove_circle_outline),
                      label: const Text('解绑'),
                    ),
                  ],
                ],
              ),
            ),
          ),
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
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        if (_thirdTip != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _thirdTip!,
              style: TextStyle(color: colorScheme.tertiary),
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

  Widget _buildBoundScenePanel(ColorScheme colorScheme) {
    final sceneLabel = _sceneLabel();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '我的$sceneLabel',
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _sceneTextFromItems(_boundSceneItems),
            style: TextStyle(color: colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton.icon(
                onPressed: _sceneBinding ? null : _editBoundScene,
                icon: const Icon(Icons.edit),
                label: const Text('编辑'),
              ),
              OutlinedButton.icon(
                onPressed: _sceneBinding
                    ? null
                    : () => _confirmSceneBind(false),
                icon: const Icon(Icons.remove_circle_outline),
                label: Text('解绑我的$sceneLabel'),
              ),
            ],
          ),
        ],
      ),
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
    final levelNo = (level['level'] as num?)?.toInt();
    final options =
        _thirdOptions[code] ?? _thirdOptions['level:$levelNo'] ?? [];
    final selected = _thirdSelected[code];
    if (options.isEmpty) {
      return _infoRow(
        level['name'] ?? code,
        selected == null ? '等待上一级查询' : _thirdSelectedLabels[code],
      );
    }
    final label = level['name']?.toString() ?? code;
    return InkWell(
      onTap: () => _showThirdOptionSheet(level, options),
      child: InputDecorator(
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: label,
          suffixIcon: const Icon(Icons.expand_more),
        ),
        child: Text(
          selected == null
              ? '请选择$label'
              : _thirdSelectedLabels[code] ?? selected,
        ),
      ),
    );
  }

  Future<void> _showThirdOptionSheet(
    Map<String, dynamic> level,
    List<Map<String, dynamic>> options,
  ) async {
    final keywordController = TextEditingController();
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        var filtered = options;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: FractionallySizedBox(
                heightFactor: 0.85,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    children: [
                      Text(
                        level['name']?.toString() ?? level['code'].toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: keywordController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                          hintText: '搜索',
                        ),
                        onChanged: (value) {
                          final keyword = value.trim();
                          setSheetState(() {
                            filtered = keyword.isEmpty
                                ? options
                                : options
                                      .where(
                                        (e) => _thirdOptionLabel(
                                          e,
                                        ).contains(keyword),
                                      )
                                      .toList();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final option = filtered[index];
                            return ListTile(
                              title: Text(_thirdOptionLabel(option)),
                              onTap: () => Navigator.pop(
                                context,
                                _thirdOptionValue(option),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    keywordController.dispose();
    if (picked != null) await _selectThirdValue(level, picked);
  }

  Widget _buildPayAccountSelectors(String orderId, Map<String, dynamic> pay) {
    final widgets = <Widget>[];
    final code = _payCode(pay);
    if (_preparingPay) {
      widgets.add(
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_accountNoList.isNotEmpty) {
      widgets.addAll([
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedAccountNo,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: '支付账户',
          ),
          items: _accountNoList
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (value) async {
            setState(() {
              _selectedAccountNo = value;
              _selectedCccType = null;
              _accountTypeList = [];
              _payStepResponse = null;
              _paymentPasswordValue = '';
            });
            if (value != null && (code == 'ACCOUNT' || code == 'ACCOUNTTSM')) {
              await _loadAccountTypes(orderId, pay);
            }
          },
        ),
      ]);
    }
    if (_accountTypeList.isNotEmpty) {
      widgets.addAll([
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedCccType,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: '电子账户',
          ),
          items: _accountTypeList
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e['ccctype']?.toString(),
                  child: Text(_accountTypeTitle(e)),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() {
            _selectedCccType = value;
            _payStepResponse = null;
            _paymentPasswordValue = '';
          }),
        ),
      ]);
    }
    if (_requiresPaymentPassword(pay)) {
      widgets.addAll([
        const SizedBox(height: 12),
        _buildSecurePasswordInput(),
        const SizedBox(height: 6),
        Text(
          '按一卡通安全键盘输入支付密码。',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }

  Widget _buildSecurePasswordInput() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InputDecorator(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: '支付密码',
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              6,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  index < _paymentPasswordValue.length
                      ? Icons.circle
                      : Icons.circle_outlined,
                  size: 14,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_keyboardLoading)
          const Center(child: CircularProgressIndicator())
        else ...[
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.2,
            children: [
              for (var digit = 1; digit <= 9; digit++) _secureKeyButton(digit),
              const SizedBox.shrink(),
              _secureKeyButton(0),
              OutlinedButton(
                onPressed: _paymentPasswordValue.isEmpty
                    ? null
                    : () => setState(() {
                        _paymentPasswordValue = _paymentPasswordValue.substring(
                          0,
                          _paymentPasswordValue.length - 1,
                        );
                      }),
                child: const Icon(Icons.backspace_outlined),
              ),
            ],
          ),
          TextButton(
            onPressed: _loadSecureKeyboard,
            child: const Text('刷新安全键盘'),
          ),
        ],
      ],
    );
  }

  Widget _secureKeyButton(int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasKey =
        index < _secureKeyboardValues.length &&
        index < _secureKeyboardImages.length;
    final enabled = hasKey && _paymentPasswordValue.length < 6;
    return OutlinedButton(
      onPressed: enabled
          ? () => setState(() {
              _paymentPasswordValue += _secureKeyboardValues[index];
            })
          : null,
      child: hasKey
          ? ColorFiltered(
              colorFilter: ColorFilter.mode(
                colorScheme.onSurface,
                BlendMode.srcIn,
              ),
              child: Image.memory(
                base64Decode(_secureKeyboardImages[index]),
                height: 30,
                fit: BoxFit.contain,
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildPayResponseSummary() {
    final resp = _payStepResponse!;
    final data = resp['data'];
    final rows = <Widget>[_infoRow('接口返回', resp['msg'] ?? resp['code'])];
    if (data is Map) {
      if (data['returnType'] != null) {
        rows.add(_infoRow('支付类型', data['returnType']));
      }
      if (data['webUrl'] != null) {
        rows.add(_infoRow('跳转支付', '支付页面已生成'));
      }
      if (data['qrCodeUrl'] != null) {
        rows.add(_infoRow('二维码', '请使用下方二维码完成支付'));
      }
    } else if (data != null) {
      rows.add(_infoRow('支付状态', '支付请求已完成'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('支付结果'),
        const SizedBox(height: 8),
        ...rows,
        if (data is Map && data['qrCodeUrl'] != null) ...[
          const SizedBox(height: 12),
          Center(
            child: QrImageView(
              data: data['qrCodeUrl'].toString(),
              version: QrVersions.auto,
              errorCorrectionLevel: QrErrorCorrectLevel.L,
              backgroundColor: Colors.white,
              size: 180,
              errorStateBuilder: (_, error) =>
                  Center(child: Text('二维码生成失败：$error')),
            ),
          ),
        ],
      ],
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
    final payList = ((_payInfo?['payList'] as List?) ?? []).whereType<Map>();
    final selectedPay = _selectedPay();
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
                onChanged: (value) async {
                  if (value == null || orderId == null) return;
                  setState(() => _selectedPayId = value);
                  await _prepareSelectedPay(orderId);
                },
              ),
              if (selectedPay != null && orderId != null)
                _buildPayAccountSelectors(orderId, selectedPay),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _paying || _preparingPay ? null : _requestPayStep,
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
                style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
              ),
            ],
            if (_payStepResponse != null) ...[
              const Divider(height: 24),
              _buildPayResponseSummary(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
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

  Map<String, dynamic> _payBaseData(String orderId, Map<String, dynamic> pay) {
    final data = <String, dynamic>{'orderid': orderId, 'paystep': 2};
    final paytype = pay['code'] ?? pay['paytype'];
    final paytypeid = pay['payid'] ?? pay['paytypeid'];
    if (paytype != null) data['paytype'] = paytype;
    if (paytypeid != null) data['paytypeid'] = paytypeid;
    return data;
  }

  List<String> _accountNoFromPayStep(Map<String, dynamic> resp) {
    final data = resp['data'];
    final raw = data is Map ? (data['accountData'] ?? data['data']) : data;
    return ((raw as List?) ?? []).map((e) => e.toString()).toList();
  }

  String _payCode(Map<String, dynamic> pay) {
    final code = (pay['myCode'] ?? pay['code'] ?? pay['paytype'] ?? '')
        .toString()
        .toUpperCase();
    return code.contains('-') ? code.split('-').first : code;
  }

  bool _requiresPaymentPassword(Map<String, dynamic> pay) {
    final code = _payCode(pay);
    final cardPay =
        code == 'CARD' ||
        code == 'CARDTSM' ||
        code == 'ACCOUNT' ||
        code == 'ACCOUNTTSM';
    return cardPay && pay['nopassword'] != 1 && pay['nopassword'] != '1';
  }

  bool _truthy(dynamic value) {
    return value == true || value == 1 || value == '1' || value == 'true';
  }

  String _accountTypeTitle(Map<String, dynamic> accountType) {
    final name = accountType['name']?.toString() ?? '电子账户';
    final type = accountType['ccctype']?.toString() ?? '';
    final balance = accountType['balance']?.toString();
    return balance == null || balance.isEmpty
        ? '$name$type'
        : '$name$type · ¥$balance';
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
    if (map['showData'] is Map) {
      rows.addAll(Map<String, dynamic>.from(map['showData']));
    }
    final labels = {
      'money': '应缴金额',
      'balance': '余额',
      'leftmoney': '剩余金额',
      'leftMoney': '剩余金额',
      'surplus': '剩余',
      'surplusCharge': '欠费',
      'realMoney': '实际金额',
      'account': '账号',
      'username': '姓名',
      'custname': '姓名',
      'iectranamt': '应缴金额',
    };
    for (final entry in labels.entries) {
      if (map[entry.key] != null) rows[entry.value] = map[entry.key];
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

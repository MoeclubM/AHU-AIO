library;

import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// Synjones (新中新 / 慧新E校) 一卡通协议客户端
// Protocol: CAS SSO → encrypted ticket → OAuth token (JWT)
// ============================================================

class SynjonesClient {
  static final SynjonesClient _instance = SynjonesClient._internal();
  factory SynjonesClient() => _instance;

  static const String _ycardBase = 'https://ycard.ahu.edu.cn';
  static const String _casBase = 'https://one.ahu.edu.cn';
  static const String _oauthBasic =
      'Basic bW9iaWxlX3NlcnZpY2VfcGxhdGZvcm06bW9iaWxlX3NlcnZpY2VfcGxhdGZvcm1fc2VjcmV0';
  static const String _chargeBasic = 'Basic Y2hhcmdlOmNoYXJnZV9zZWNyZXQ=';
  static const String _chargeAppId = '56321';
  static const String _chargeSecret = '0osTIhce7uPvDKHz6aa67bhCukaKoYl4';
  static const String _ua =
      'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36';

  late final Dio _ycardDio;
  String? accessToken;
  Map<String, dynamic>? userInfo;
  bool _initialized = false;
  bool get loggedIn => accessToken != null && accessToken!.isNotEmpty;

  SynjonesClient._internal() {
    _ycardDio = Dio(
      BaseOptions(
        baseUrl: _ycardBase,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json, text/plain, */*',
          'User-Agent': _ua,
        },
      ),
    );
  }

  // ============================================================
  // Initialization
  // ============================================================

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('synjones_access_token');
    if (saved != null && saved.isNotEmpty) {
      accessToken = saved;
      _setAuthHeader(saved);
    }
    _initialized = true;
  }

  // ============================================================
  // CAS SSO Login → Synjones OAuth Token
  // ============================================================

  static String get casWebLoginUrl {
    final serviceUrl =
        '$_ycardBase/berserker-auth/cas/login/neusoftCas'
        '?redirectUrl=${Uri.encodeComponent('$_ycardBase/plat/?name=loginTransit')}';
    return '$_casBase/cas/login?service=${Uri.encodeComponent(serviceUrl)}';
  }

  /// 已获得 CAS 跳转 ticket 时，直接兑换 JWT。
  Future<LoginResult> casLoginDirect(String ticket) async {
    await init();
    return await _exchangeToken(ticket);
  }

  Future<LoginResult> _exchangeToken(String ticket) async {
    try {
      final resp = await _ycardDio.post(
        '/berserker-auth/oauth/token?synAccessSource=h5',
        data:
            'username=${Uri.encodeComponent(ticket)}'
            '&password=${Uri.encodeComponent(ticket)}'
            '&grant_type=password&scope=all'
            '&loginFrom=app&logintype=sso&device_token=h5',
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          headers: {'Authorization': _oauthBasic},
        ),
      );
      if (resp.statusCode == 200 && resp.data is Map) {
        final data = resp.data as Map;
        final token = data['access_token']?.toString();
        if (token != null && token.isNotEmpty) {
          accessToken = token;
          _setAuthHeader(token);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('synjones_access_token', token);
          await fetchUserInfo();
          return LoginResult(success: true);
        }
      }
      return LoginResult(success: false, message: 'Token 兑换失败: ${resp.data}');
    } on DioException catch (e) {
      return LoginResult(
        success: false,
        message: 'Token 请求失败: ${e.response?.statusCode}',
      );
    }
  }

  void _setAuthHeader(String token) {
    _ycardDio.options.headers['synjones-auth'] = 'bearer $token';
  }

  // ============================================================
  // API Methods
  // ============================================================

  Future<Map<String, dynamic>> fetchUserInfo() async {
    final resp = await _ycardGet('/berserker-base/user');
    userInfo = resp['data'] as Map<String, dynamic>?;
    return resp;
  }

  /// 校园卡列表，含余额 (elec_accamt，单位：分)
  Future<Map<String, dynamic>> getCampusCards() async {
    return await _ycardGet('/berserker-app/ykt/tsm/getCampusCards');
  }

  /// 支付账户信息（account/payacc/paytype/balance）
  Future<Map<String, dynamic>> getPaymentInfo() async {
    return await _ycardGet('/berserker-app/ykt/tsm/codebarPayinfo');
  }

  /// 一卡通应用方案（原生首页按此识别可用模块）
  Future<Map<String, dynamic>> getAppScheme() async {
    return await _ycardGet(
      '/berserker-app/appScheme/info',
      params: {'type': 'user', 'serviceType': 'h5'},
    );
  }

  /// 卡片样式 HTML 模板
  Future<Map<String, dynamic>> getCardStyle() async {
    return await _ycardGet('/berserker-app/cardStyle');
  }

  /// 生成付款条形码（account/payacc/paytype 从 getPaymentInfo 获取）
  Future<Map<String, dynamic>> generateBarcode({
    required String account,
    required String payacc,
    required String paytype,
    String? codeType,
  }) async {
    final params = {'account': account, 'payacc': payacc, 'paytype': paytype};
    if (codeType != null) params['codeType'] = codeType;
    return await _ycardGet(
      '/berserker-app/ykt/tsm/batchGetBarCodeGet',
      params: params,
    );
  }

  /// 删除已下发的付款码/身份码
  Future<Map<String, dynamic>> deleteBarcode(String barcode) async {
    final resp = await _ycardDio.post(
      '/berserker-app/ykt/tsm/barcodeDel',
      queryParameters: {'synAccessSource': 'h5'},
      data: {'barcode': barcode},
    );
    return Map<String, dynamic>.from(resp.data);
  }

  /// 离线付款参数（部分付款方式启用离线码时使用）
  Future<Map<String, dynamic>> getOfflinePayParams({
    required String payacc,
    required String paytype,
    required String voucher,
  }) async {
    return await _ycardGet(
      '/berserker-app/ykt/tsm/offlienPar',
      params: {'payacc': payacc, 'paytype': paytype, 'voucher': voucher},
    );
  }

  /// 一码通扫码支付 URL
  String getQrCodeUrl(String qrCodeValue) {
    return '$_ycardBase/berserker-app/qrcode'
        '?qrCode=${Uri.encodeComponent(qrCodeValue)}'
        '&synjones-auth=bearer $accessToken'
        '&synAccessSource=app';
  }

  /// 查询指定账户的卡信息
  Future<Map<String, dynamic>> queryCard([String? account]) async {
    return await _ycardGet(
      '/berserker-app/ykt/tsm/queryCard',
      params: account == null ? null : {'account': account},
    );
  }

  /// 充值场景下的可充值卡/电子账户。
  Future<Map<String, dynamic>> queryRechargeCards() async {
    return await _ycardGet(
      '/berserker-app/ykt/tsm/queryCard',
      params: {'scene': 'recharge'},
    );
  }

  /// 获取所有可用应用（挂失/充值等）
  Future<Map<String, dynamic>> getAllApps() async {
    return await _ycardGet(
      '/berserker-app/app/getAllApps',
      params: {'platType': '1', 'userType': 'user'},
    );
  }

  /// 前端配置信息
  Future<Map<String, dynamic>> getFrontInfo() async {
    return await _ycardGet('/berserker-app/frontInfo');
  }

  /// 通知协议
  Future<Map<String, dynamic>> getNoticeProtocol() async {
    return await _ycardGet('/berserker-app/notice/protocol');
  }

  /// 缴费项目配置：一卡通充值、水电网费等均由该接口描述。
  Future<Map<String, dynamic>> getFeeItem(int feeitemId) async {
    return await _ycardGet(
      '/charge/feeitem/singleFeeitem',
      params: {'feeitemid': feeitemId},
      options: _chargeOptions(),
    );
  }

  /// 缴费项目第三方数据：楼栋/房间/网费账号等场景参数查询。
  Future<Map<String, dynamic>> getFeeItemThirdData(
    Map<String, dynamic> data,
  ) async {
    final resp = await _ycardDio.post(
      '/charge/feeitem/getThirdData',
      queryParameters: {'synAccessSource': 'h5'},
      data: data,
      options: _chargeFormOptions(),
    );
    return Map<String, dynamic>.from(resp.data);
  }

  /// 生活缴费下单。返回 orderid 后继续走 getChargePayInfo / blade-pay 支付确认。
  Future<Map<String, dynamic>> createChargeOrder(
    Map<String, dynamic> data,
  ) async {
    final signed = _signChargeData(data);
    final resp = await _ycardDio.post(
      '/blade-pay/pay',
      queryParameters: {'synAccessSource': 'h5'},
      data: signed,
      options: _chargeFormOptions(),
    );
    return Map<String, dynamic>.from(resp.data);
  }

  /// 一卡通卡片充值下单，H5 使用 /charge/order/thirdOrder。
  Future<Map<String, dynamic>> createCardRechargeOrder({
    required int feeitemId,
    required String yktcard,
    required String tranamt,
  }) async {
    final signed = _signChargeData({
      'feeitemid': feeitemId,
      'appid': _chargeAppId,
      'tranamt': tranamt,
      'source': 'app',
      'synjones-auth': 'bearer $accessToken',
      'yktcard': yktcard,
      'synAccessSource': 'h5',
      'abstracts': jsonEncode({'type': 'recharge'}),
    });
    final resp = await _ycardDio.post(
      '/charge/order/thirdOrder',
      data: signed,
      options: _chargeFormOptions(),
    );
    if (resp.data is Map) return Map<String, dynamic>.from(resp.data);
    return {
      'code': resp.statusCode,
      'contentType': resp.headers.value(Headers.contentTypeHeader),
      'data': resp.data?.toString() ?? '',
    };
  }

  /// 查询订单与可用支付方式。
  Future<Map<String, dynamic>> getChargePayInfo(String orderId) async {
    return await _ycardGet(
      '/charge/pay/getpayinfo',
      params: {'orderid': orderId},
      options: _chargeOptions(),
    );
  }

  /// 继续支付步骤。payment/paytype/account 字段按 getChargePayInfo 返回传入。
  Future<Map<String, dynamic>> postChargePay(Map<String, dynamic> data) async {
    final signed = _signChargeData(data);
    final resp = await _ycardDio.post(
      '/blade-pay/pay',
      queryParameters: {'synAccessSource': 'h5'},
      data: signed,
      options: _chargeFormOptions(),
    );
    return Map<String, dynamic>.from(resp.data);
  }

  Future<Map<String, dynamic>> _ycardGet(
    String path, {
    Map<String, dynamic>? params,
    Options? options,
  }) async {
    final qp = {'synAccessSource': 'h5', ...?params};
    try {
      final resp = await _ycardDio.get(
        path,
        queryParameters: qp,
        options: options,
      );
      return Map<String, dynamic>.from(resp.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        accessToken = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('synjones_access_token');
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _ycardDio.post(
        '/berserker-base/login/logout',
        queryParameters: {'synAccessSource': 'h5'},
      );
    } catch (_) {}
    accessToken = null;
    userInfo = null;
    _ycardDio.options.headers.remove('synjones-auth');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('synjones_access_token');
  }

  Options _chargeFormOptions() {
    return Options(
      contentType: Headers.formUrlEncodedContentType,
      headers: {'Authorization': _chargeBasic},
    );
  }

  Options _chargeOptions() {
    return Options(headers: {'Authorization': _chargeBasic});
  }

  Map<String, dynamic> _signChargeData(Map<String, dynamic> data) {
    final signed = Map<String, dynamic>.from(data);
    signed['APP_ID'] = _chargeAppId;
    signed['TIMESTAMP'] = _chargeTimestamp();
    signed['SIGN_TYPE'] = 'SHA256';
    signed['NONCE'] = Random().nextDouble().toString().substring(2);

    final keys =
        signed.keys
            .where(
              (key) =>
                  key != 'SIGN' &&
                  key != 'SECRET_KEY' &&
                  signed[key] != null &&
                  signed[key].toString().isNotEmpty,
            )
            .toList()
          ..sort();
    final payload = StringBuffer();
    for (final key in keys) {
      payload.write('$key=${signed[key]}&');
    }
    payload.write('SECRET_KEY=$_chargeSecret');
    signed['SIGN'] = sha256
        .convert(utf8.encode(payload.toString()))
        .toString()
        .toUpperCase();
    return signed;
  }

  String _chargeTimestamp() {
    final now = DateTime.now();
    return '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // CAS Ticket Extraction
  // ============================================================

  /// 从原版 CAS Web 登录跳转 URL 中提取一卡通加密 ticket。
  static String? extractWebLoginTicket(String url) {
    final m = RegExp(r'ticket=([^&"\s]+)').firstMatch(url);
    if (m == null) return null;
    var value = m.group(1)!;
    try {
      value = Uri.decodeComponent(value);
    } catch (_) {}
    try {
      value = Uri.decodeComponent(value);
    } catch (_) {}
    return value.startsWith('iFKYpYOO4') ? value : null;
  }
}

class LoginResult {
  final bool success;
  final String? message;
  const LoginResult({required this.success, this.message});
}

library;

import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/cas_auth_cache.dart';
import '../../auth/cas_native_client.dart';

// ============================================================
// Synjones (新中新 / 慧新E校) 一卡通协议客户端
// Protocol: CAS SSO → encrypted ticket → OAuth token (JWT)
// ============================================================

class SynjonesClient {
  static final SynjonesClient _instance = SynjonesClient._internal();
  factory SynjonesClient() => _instance;

  static const String _ycardBase = 'https://ycard.ahu.edu.cn';
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

  static String get casNativeLoginUrl {
    return Uri.parse('$_ycardBase/berserker-auth/cas/redirect/neusoftCas')
        .replace(
          queryParameters: {'targetUrl': '$_ycardBase/plat/?name=loginTransit'},
        )
        .toString();
  }

  Future<LoginResult> casLoginNative({
    required String username,
    required String password,
    required bool trustDevice,
  }) async {
    await init();
    final cas = CasNativeClient(cookieJar: await CasAuthCache.cookieJar());
    final result = await cas.login(
      loginUri: Uri.parse(casNativeLoginUrl),
      username: username,
      password: password,
      trustDevice: trustDevice,
    );
    return await _exchangeTokenFromCasResult(result);
  }

  Future<LoginResult?> casLoginWithCachedSession() async {
    await init();
    final cas = CasNativeClient(cookieJar: await CasAuthCache.cookieJar());
    final result = await cas.loginWithCachedSession(
      loginUri: Uri.parse(casNativeLoginUrl),
    );
    if (result == null) return null;
    return await _exchangeTokenFromCasResult(result);
  }

  Future<LoginResult> _exchangeTokenFromCasResult(
    CasNativeLoginResult result,
  ) async {
    String? ticket;
    for (final uri in result.observedUris) {
      ticket = extractWebLoginTicket(uri.toString());
      if (ticket != null) break;
    }
    if (ticket == null) {
      return LoginResult(
        success: false,
        message: 'CAS 登录完成但未获得一卡通票据：${result.finalUri}',
      );
    }
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

  /// 生成付款码（account/payacc/paytype 从 getPaymentInfo 获取）。
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
      params: {'feeitemid': feeitemId, 'synAccessSource': 'pc'},
      options: _chargeOptions('pc'),
    );
  }

  /// 缴费项目第三方数据：楼栋/房间/网费账号等场景参数查询。
  Future<Map<String, dynamic>> getFeeItemThirdData(
    Map<String, dynamic> data,
  ) async {
    final resp = await _ycardDio.post(
      '/charge/feeitem/getThirdData',
      queryParameters: {'synAccessSource': 'pc'},
      data: {'synAccessSource': 'pc', ...data},
      options: _chargeFormOptions('pc'),
    );
    if (resp.statusCode == 302) {
      throw StateError('一卡通缴费接口重定向到登录：${resp.headers.value('location')}');
    }
    return Map<String, dynamic>.from(resp.data);
  }

  Future<Map<String, dynamic>> bindFeeItemScene({
    required int feeitemId,
    String? sceneinfo,
  }) async {
    final data = <String, dynamic>{
      'synAccessSource': 'pc',
      'feeitemid': feeitemId,
    };
    if (sceneinfo != null && sceneinfo.isNotEmpty) {
      data['sceneinfo'] = sceneinfo;
    }
    final resp = await _ycardDio.post(
      '/charge/sceneBind/add',
      queryParameters: {'synAccessSource': 'pc'},
      data: data,
      options: _chargeOptions('pc'),
    );
    if (resp.statusCode == 302) {
      throw StateError('一卡通缴费绑定接口重定向到登录：${resp.headers.value('location')}');
    }
    return Map<String, dynamic>.from(resp.data);
  }

  /// 生活缴费下单。返回 orderid 后继续走 getChargePayInfo / blade-pay 支付确认。
  Future<Map<String, dynamic>> createChargeOrder(
    Map<String, dynamic> data,
  ) async {
    final signed = _signChargeData({
      'appid': _chargeAppId,
      'source': 'pc',
      'synAccessSource': 'pc',
      ...data,
    });
    final resp = await _ycardDio.post(
      '/charge/order/thirdOrder',
      data: signed,
      options: _chargeFormOptions('pc'),
    );
    return _chargeOrderResponse(resp, '一卡通缴费下单');
  }

  /// 一卡通卡片充值下单，参数保持与 campus-card 原始充值页面一致。
  Future<Map<String, dynamic>> createCardRechargeOrder({
    required int feeitemId,
    required String tranamt,
    required String yktcard,
  }) async {
    final signed = _signChargeData({
      'feeitemid': feeitemId,
      'appid': _chargeAppId,
      'tranamt': tranamt,
      'source': 'app',
      'synjones-auth': 'bearer $accessToken',
      'yktcard': yktcard,
      'synAccessSource': 'app',
      'abstracts': jsonEncode({'type': 'recharge'}),
    });
    final resp = await _ycardDio.post(
      '/charge/order/thirdOrder',
      data: signed,
      options: _chargeFormOptions('app'),
    );
    return _chargeOrderResponse(resp, '一卡通充值');
  }

  /// 查询订单与可用支付方式。
  Future<Map<String, dynamic>> getChargePayInfo(String orderId) async {
    return await _ycardGet(
      '/charge/pay/getpayinfo',
      params: {'orderid': orderId, 'userAgent': 'app'},
      options: _chargeOptions('h5'),
    );
  }

  /// 安全键盘。order=0 为 0-9 常用数字顺序，提交被点击按键对应的 numberKeyboard 字符。
  Future<Map<String, dynamic>> getSecureKeyboard({int order = 0}) async {
    return await _ycardGet(
      '/berserker-secure/keyboard',
      params: {'type': 'Number', 'order': order},
    );
  }

  /// 继续支付步骤。payment/paytype/account 字段按 getChargePayInfo 返回传入。
  Future<Map<String, dynamic>> postChargePay(
    Map<String, dynamic> data, {
    bool includeRedirect = true,
  }) async {
    final payData = Map<String, dynamic>.from(data);
    final orderId = payData['orderid']?.toString();
    final payId = payData['paytypeid']?.toString();
    if (includeRedirect && orderId != null && payId != null) {
      payData.putIfAbsent(
        'redirect_url',
        () => '$_ycardBase/payment/?name=result',
      );
    }
    if (includeRedirect) payData.putIfAbsent('userAgent', () => 'app');
    final signed = _signChargeData(payData);
    final resp = await _ycardDio.post(
      '/blade-pay/pay',
      data: signed,
      options: _chargeFormOptions('h5'),
    );
    if (resp.statusCode == 302) {
      throw StateError('一卡通支付接口重定向到登录：${resp.headers.value('location')}');
    }
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
      if (resp.statusCode == 302) {
        throw StateError('一卡通接口重定向到登录：${resp.headers.value('location')}');
      }
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

  Options _chargeFormOptions(String source) {
    return Options(
      contentType: Headers.formUrlEncodedContentType,
      followRedirects: false,
      validateStatus: (status) => status != null && status < 400,
      headers: {
        'Authorization': _chargeBasic,
        'synAccessSource': source,
        'Origin': _ycardBase,
        'Referer': '$_ycardBase/plat/',
        if (accessToken != null) 'synjones-auth': 'bearer $accessToken',
      },
    );
  }

  Options _chargeOptions(String source) {
    return Options(
      followRedirects: false,
      validateStatus: (status) => status != null && status < 400,
      headers: {
        'Authorization': _chargeBasic,
        'synAccessSource': source,
        'Referer': '$_ycardBase/plat/',
        if (accessToken != null) 'synjones-auth': 'bearer $accessToken',
      },
    );
  }

  Map<String, dynamic> _chargeOrderResponse(
    Response<dynamic> resp,
    String action,
  ) {
    if (resp.statusCode == 302) {
      final location = resp.headers.value('location') ?? '';
      if (location.contains('/login') || location.contains('/cas/')) {
        throw StateError('$action接口重定向到登录：$location');
      }
      final uri = Uri.tryParse(location);
      final params = uri?.queryParameters ?? {};
      final msg = params['msg'] == null
          ? '订单已创建，请继续提交支付'
          : Uri.decodeComponent(Uri.decodeComponent(params['msg']!));
      return {
        'code': resp.statusCode,
        'msg': msg,
        'data': {
          if (params['orderid'] != null) 'orderid': params['orderid'],
          if (params['paytypeid'] != null) 'paytypeid': params['paytypeid'],
          if (params['paytype'] != null) 'paytype': params['paytype'],
          if (params['chooseAccount'] != null)
            'chooseAccount': params['chooseAccount'],
          'redirectUrl': location.replaceAllMapped(
            RegExp(r'([?&]token=)[^&]+'),
            (match) => '${match.group(1)}<redacted>',
          ),
        },
      };
    }
    if (resp.data is Map) return Map<String, dynamic>.from(resp.data);
    return {
      'code': resp.statusCode,
      'contentType': resp.headers.value(Headers.contentTypeHeader),
      'data': resp.data?.toString() ?? '',
    };
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
    if (value.startsWith('ST-')) return null;
    return value;
  }
}

class LoginResult {
  final bool success;
  final String? message;
  const LoginResult({required this.success, this.message});
}

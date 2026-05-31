library;

import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// Synjones (新中新 / 慧新E校) 一卡通 H5 协议客户端
// Protocol: CAS SSO → encrypted ticket → OAuth token (JWT)
// ============================================================

class SynjonesClient {
  static final SynjonesClient _instance = SynjonesClient._internal();
  factory SynjonesClient() => _instance;

  static const String _ycardBase = 'https://ycard.ahu.edu.cn';
  static const String _casBase = 'https://one.ahu.edu.cn';
  static const String _oauthBasic =
      'Basic bW9iaWxlX3NlcnZpY2VfcGxhdGZvcm06bW9iaWxlX3NlcnZpY2VfcGxhdGZvcm1fc2VjcmV0';
  static const String _ua =
      'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36';

  late final Dio _casDio;
  late final Dio _ycardDio;
  late final PersistCookieJar _casCookieJar;
  String? accessToken;
  Map<String, dynamic>? userInfo;
  bool _initialized = false;
  bool get loggedIn => accessToken != null && accessToken!.isNotEmpty;

  SynjonesClient._internal() {
    _casDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'User-Agent': _ua},
      ),
    );
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
    final dir = await path_provider.getApplicationDocumentsDirectory();
    _casCookieJar = PersistCookieJar(
      storage: FileStorage('${dir.path}/synjones_cas_cookies'),
    );
    _casDio.interceptors.add(CookieManager(_casCookieJar));
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

  /// Full CAS login: username/password → encrypted ticket → JWT.
  Future<LoginResult> casLogin({
    required String username,
    required String password,
  }) async {
    try {
      final serviceUrl =
          '$_ycardBase/berserker-auth/cas/login/neusoftCas'
          '?redirectUrl=${Uri.encodeComponent('$_ycardBase/plat/?name=loginTransit')}';
      final loginPageUrl =
          '$_casBase/cas/login?service=${Uri.encodeComponent(serviceUrl)}';

      // 1) Get CAS login page for `lt` token
      final pageResp = await _casDio.get(loginPageUrl);
      final ltMatch = RegExp(
        r'name="lt"\s+value="([^"]+)"',
      ).firstMatch(pageResp.data.toString());
      if (ltMatch == null) {
        return LoginResult(success: false, message: 'CAS 页面异常');
      }
      final lt = ltMatch.group(1)!;

      // 2) Triple DES encrypt: strEnc(user+pass+lt, '1','2','3')
      final rsa = _strEnc(username + password + lt, '1', '2', '3');

      // 3) Device precheck
      final devResp = await _casDio.post(
        '$_casBase/cas/device',
        data:
            'ul=${username.length}&pl=${password.length}'
            '&rsa=${Uri.encodeComponent(rsa)}&method=login',
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          headers: {
            'X-Requested-With': 'XMLHttpRequest',
            'Referer': loginPageUrl,
          },
        ),
      );
      var devInfo = (devResp.data is Map ? devResp.data['info'] : null)
          ?.toString();
      if (devInfo == 'unbind') {
        await _casDio.post(
          '$_casBase/cas/device',
          data: 'saveDevice=1&method=bind2',
          options: Options(
            contentType: 'application/x-www-form-urlencoded',
            headers: {
              'X-Requested-With': 'XMLHttpRequest',
              'Referer': loginPageUrl,
            },
          ),
        );
        devInfo = 'ok';
      }
      if (devInfo != 'ok') {
        return LoginResult(success: false, message: '设备校验失败: $devInfo');
      }

      // 4) POST login form
      final formBody =
          'rsa=${Uri.encodeComponent(rsa)}'
          '&ul=${username.length}&pl=${password.length}'
          '&lt=${Uri.encodeComponent(lt)}'
          '&execution=e1s1&_eventId=submit';
      final loginResp = await _casDio.post(
        loginPageUrl,
        data: formBody,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          followRedirects: false,
          validateStatus: (s) => s != null && s < 500,
          headers: {'Referer': loginPageUrl, 'Origin': _casBase},
        ),
      );
      if (loginResp.statusCode != 302) {
        final body = loginResp.data?.toString() ?? '';
        if (body.contains('用户名') || body.contains('密码')) {
          return LoginResult(success: false, message: '用户名或密码错误');
        }
        return LoginResult(
          success: false,
          message: 'CAS 登录失败 (${loginResp.statusCode})',
        );
      }

      // 5) Follow redirects → extract synjones encrypted ticket
      String? synjonesTicket;
      var nextUrl = loginResp.headers.value('location');
      for (var i = 0; i < 6 && nextUrl != null; i++) {
        final t = _extractSynjonesTicket(nextUrl);
        if (t != null) {
          synjonesTicket = t;
          break;
        }
        final hop = await _casDio.get(
          nextUrl,
          options: Options(
            followRedirects: false,
            validateStatus: (s) => s != null && s < 500,
          ),
        );
        nextUrl = hop.headers.value('location');
      }
      if (synjonesTicket == null) {
        return LoginResult(success: false, message: '未获取到一卡通票据');
      }

      // 6) OAuth: ticket → JWT
      return await _exchangeToken(synjonesTicket);
    } on DioException catch (e) {
      return LoginResult(success: false, message: '网络错误: ${e.message}');
    } catch (e) {
      return LoginResult(success: false, message: '登录异常: $e');
    }
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

  /// 卡片样式 HTML 模板
  Future<Map<String, dynamic>> getCardStyle() async {
    return await _ycardGet('/berserker-app/cardStyle');
  }

  /// 生成付款条形码（account/payacc/paytype 从 getPaymentInfo 获取）
  Future<Map<String, dynamic>> generateBarcode({
    required String account,
    required String payacc,
    required String paytype,
  }) async {
    return await _ycardGet(
      '/berserker-app/ykt/tsm/batchGetBarCodeGet',
      params: {'account': account, 'payacc': payacc, 'paytype': paytype},
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
  Future<Map<String, dynamic>> queryCard(String account) async {
    return await _ycardGet(
      '/berserker-app/ykt/tsm/queryCard',
      params: {'account': account},
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

  Future<Map<String, dynamic>> _ycardGet(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    final qp = {'synAccessSource': 'h5', ...?params};
    try {
      final resp = await _ycardDio.get(path, queryParameters: qp);
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

  // ============================================================
  // CAS Ticket Extraction
  // ============================================================

  /// Extract synjones encrypted ticket from redirect URL.
  /// Starts with `iFKYpYOO4eQEKCTpPzHvR` (AES-ECB encrypted).
  /// CAS ST tickets (`ST-...`) are skipped.
  static String? _extractSynjonesTicket(String url) {
    final m = RegExp(r'ticket=(iFKYpYOO4[^&"\s]+)').firstMatch(url);
    if (m == null) return null;
    var value = m.group(1)!;
    try {
      value = Uri.decodeComponent(value);
    } catch (_) {}
    try {
      value = Uri.decodeComponent(value);
    } catch (_) {}
    return value;
  }

  // ============================================================
  // CAS strEnc: direct port of CAS des.js
  // Each char → 16-bit Unicode block, custom IP/FP/E permutations.
  // ============================================================

  /// Matches `strEnc(data, key1, key2, key3)` from CAS `des.js`.
  @visibleForTesting
  static String strEncForTest(
    String data,
    String firstKey,
    String secondKey,
    String thirdKey,
  ) => _strEnc(data, firstKey, secondKey, thirdKey);

  static String _strEnc(
    String data,
    String firstKey,
    String secondKey,
    String thirdKey,
  ) {
    final dataBts = _strToBt(data);
    final firstKeyBts = _getKeyBytes(firstKey);
    final secondKeyBts = _getKeyBytes(secondKey);
    final thirdKeyBts = _getKeyBytes(thirdKey);

    var encBt = dataBts;
    for (final kb in firstKeyBts) {
      encBt = _desEnc(encBt, kb);
    }
    for (final kb in secondKeyBts) {
      encBt = _desEnc(encBt, kb);
    }
    for (final kb in thirdKeyBts) {
      encBt = _desEnc(encBt, kb);
    }

    return _bt64ToHex(encBt);
  }

  /// String → 64-bit array (16 bits per char, ≤4 chars).
  static List<int> _strToBt(String str) {
    final bt = List<int>.filled(64, 0);
    final len = str.length;
    final limit = len < 4 ? len : 4;
    for (var i = 0; i < limit; i++) {
      var k = str.codeUnitAt(i);
      for (var j = 0; j < 16; j++) {
        var pow = 1;
        for (var m = 15; m > j; m--) {
          pow *= 2;
        }
        bt[16 * i + j] = (k ~/ pow) % 2;
      }
    }
    return bt;
  }

  /// Key string → list of 64-bit key arrays (split every 4 chars).
  static List<List<int>> _getKeyBytes(String key) {
    final keyBytes = <List<int>>[];
    final leng = key.length;
    final iterator = leng ~/ 4;
    final remainder = leng % 4;
    for (var i = 0; i < iterator; i++) {
      keyBytes.add(_strToBt(key.substring(i * 4, i * 4 + 4)));
    }
    if (remainder > 0) {
      keyBytes.add(_strToBt(key.substring(iterator * 4)));
    }
    return keyBytes;
  }

  /// 64-bit array → hex string.
  static String _bt64ToHex(List<int> byteData) {
    final hex = StringBuffer();
    for (var i = 0; i < 16; i++) {
      var binary = '';
      for (var j = 0; j < 4; j++) {
        binary += byteData[i * 4 + j].toString();
      }
      hex.write(_bt4ToHex(binary));
    }
    return hex.toString();
  }

  static String _bt4ToHex(String binary) {
    const map = {
      '0000': '0',
      '0001': '1',
      '0010': '2',
      '0011': '3',
      '0100': '4',
      '0101': '5',
      '0110': '6',
      '0111': '7',
      '1000': '8',
      '1001': '9',
      '1010': 'A',
      '1011': 'B',
      '1100': 'C',
      '1101': 'D',
      '1110': 'E',
      '1111': 'F',
    };
    return map[binary] ?? '0';
  }

  // ---- DES core (custom permutations from des.js) ----

  static List<int> _desEnc(List<int> dataByte, List<int> keyByte) {
    final keys = _generateKeys(keyByte);
    final ipByte = _initPermute(dataByte);
    final ipLeft = List<int>.filled(32, 0);
    final ipRight = List<int>.filled(32, 0);
    final tempLeft = List<int>.filled(32, 0);
    for (var k = 0; k < 32; k++) {
      ipLeft[k] = ipByte[k];
      ipRight[k] = ipByte[32 + k];
    }
    for (var i = 0; i < 16; i++) {
      for (var j = 0; j < 32; j++) {
        tempLeft[j] = ipLeft[j];
        ipLeft[j] = ipRight[j];
      }
      final key = List<int>.filled(48, 0);
      for (var m = 0; m < 48; m++) {
        key[m] = keys[i][m];
      }
      final tempRight = _xor(
        _pPermute(_sBoxPermute(_xor(_expandPermute(ipRight), key))),
        tempLeft,
      );
      for (var n = 0; n < 32; n++) {
        ipRight[n] = tempRight[n];
      }
    }
    final finalData = List<int>.filled(64, 0);
    for (var i = 0; i < 32; i++) {
      finalData[i] = ipRight[i];
      finalData[32 + i] = ipLeft[i];
    }
    return _finallyPermute(finalData);
  }

  static List<int> _xor(List<int> a, List<int> b) {
    final result = List<int>.filled(a.length, 0);
    for (var i = 0; i < a.length; i++) {
      result[i] = a[i] ^ b[i];
    }
    return result;
  }

  static List<int> _initPermute(List<int> originalData) {
    final ipByte = List<int>.filled(64, 0);
    var m = 1, n = 0;
    for (var i = 0; i < 4; i++, m += 2, n += 2) {
      var k = 0;
      for (var j = 7; j >= 0; j--, k++) {
        ipByte[i * 8 + k] = originalData[j * 8 + m];
        ipByte[i * 8 + k + 32] = originalData[j * 8 + n];
      }
    }
    return ipByte;
  }

  static List<int> _expandPermute(List<int> rightData) {
    final epByte = List<int>.filled(48, 0);
    for (var i = 0; i < 8; i++) {
      epByte[i * 6 + 0] = i == 0 ? rightData[31] : rightData[i * 4 - 1];
      epByte[i * 6 + 1] = rightData[i * 4 + 0];
      epByte[i * 6 + 2] = rightData[i * 4 + 1];
      epByte[i * 6 + 3] = rightData[i * 4 + 2];
      epByte[i * 6 + 4] = rightData[i * 4 + 3];
      epByte[i * 6 + 5] = i == 7 ? rightData[0] : rightData[i * 4 + 4];
    }
    return epByte;
  }

  static List<int> _sBoxPermute(List<int> expandByte) {
    final sBoxByte = List<int>.filled(32, 0);
    const s1 = [
      [14, 4, 13, 1, 2, 15, 11, 8, 3, 10, 6, 12, 5, 9, 0, 7],
      [0, 15, 7, 4, 14, 2, 13, 1, 10, 6, 12, 11, 9, 5, 3, 8],
      [4, 1, 14, 8, 13, 6, 2, 11, 15, 12, 9, 7, 3, 10, 5, 0],
      [15, 12, 8, 2, 4, 9, 1, 7, 5, 11, 3, 14, 10, 0, 6, 13],
    ];
    const s2 = [
      [15, 1, 8, 14, 6, 11, 3, 4, 9, 7, 2, 13, 12, 0, 5, 10],
      [3, 13, 4, 7, 15, 2, 8, 14, 12, 0, 1, 10, 6, 9, 11, 5],
      [0, 14, 7, 11, 10, 4, 13, 1, 5, 8, 12, 6, 9, 3, 2, 15],
      [13, 8, 10, 1, 3, 15, 4, 2, 11, 6, 7, 12, 0, 5, 14, 9],
    ];
    const s3 = [
      [10, 0, 9, 14, 6, 3, 15, 5, 1, 13, 12, 7, 11, 4, 2, 8],
      [13, 7, 0, 9, 3, 4, 6, 10, 2, 8, 5, 14, 12, 11, 15, 1],
      [13, 6, 4, 9, 8, 15, 3, 0, 11, 1, 2, 12, 5, 10, 14, 7],
      [1, 10, 13, 0, 6, 9, 8, 7, 4, 15, 14, 3, 11, 5, 2, 12],
    ];
    const s4 = [
      [7, 13, 14, 3, 0, 6, 9, 10, 1, 2, 8, 5, 11, 12, 4, 15],
      [13, 8, 11, 5, 6, 15, 0, 3, 4, 7, 2, 12, 1, 10, 14, 9],
      [10, 6, 9, 0, 12, 11, 7, 13, 15, 1, 3, 14, 5, 2, 8, 4],
      [3, 15, 0, 6, 10, 1, 13, 8, 9, 4, 5, 11, 12, 7, 2, 14],
    ];
    const s5 = [
      [2, 12, 4, 1, 7, 10, 11, 6, 8, 5, 3, 15, 13, 0, 14, 9],
      [14, 11, 2, 12, 4, 7, 13, 1, 5, 0, 15, 10, 3, 9, 8, 6],
      [4, 2, 1, 11, 10, 13, 7, 8, 15, 9, 12, 5, 6, 3, 0, 14],
      [9, 14, 15, 5, 2, 8, 12, 3, 7, 0, 4, 10, 1, 13, 11, 6],
    ];
    const s6 = [
      [4, 2, 1, 11, 10, 13, 7, 8, 15, 9, 12, 5, 6, 3, 0, 14],
      [0, 12, 7, 11, 10, 1, 13, 14, 5, 8, 15, 6, 2, 3, 9, 4],
      [1, 14, 4, 11, 8, 12, 6, 2, 15, 9, 7, 3, 10, 5, 0, 13],
      [6, 1, 13, 8, 11, 4, 2, 7, 15, 10, 9, 5, 3, 14, 12, 0],
    ];
    const s7 = [
      [13, 2, 8, 4, 6, 15, 11, 1, 10, 9, 3, 14, 5, 0, 12, 7],
      [1, 15, 13, 8, 10, 3, 7, 4, 12, 5, 6, 11, 0, 14, 9, 2],
      [7, 11, 4, 1, 9, 12, 14, 2, 0, 6, 10, 13, 15, 3, 5, 8],
      [2, 1, 14, 7, 4, 10, 8, 13, 15, 12, 9, 0, 3, 5, 6, 11],
    ];
    const s8 = [
      [1, 15, 13, 8, 10, 3, 7, 4, 12, 5, 6, 11, 0, 14, 9, 2],
      [7, 11, 4, 1, 9, 12, 14, 2, 0, 6, 10, 13, 15, 3, 5, 8],
      [4, 1, 14, 8, 13, 6, 2, 11, 15, 12, 9, 7, 3, 10, 5, 0],
      [15, 12, 8, 2, 4, 9, 1, 7, 5, 11, 3, 14, 10, 0, 6, 13],
    ];
    const sboxes = [s1, s2, s3, s4, s5, s6, s7, s8];

    for (var m = 0; m < 8; m++) {
      final i = expandByte[m * 6 + 0] * 2 + expandByte[m * 6 + 5];
      final j =
          expandByte[m * 6 + 1] * 8 +
          expandByte[m * 6 + 2] * 4 +
          expandByte[m * 6 + 3] * 2 +
          expandByte[m * 6 + 4];
      final val = sboxes[m][i][j];
      sBoxByte[m * 4 + 0] = (val ~/ 8) % 2;
      sBoxByte[m * 4 + 1] = (val ~/ 4) % 2;
      sBoxByte[m * 4 + 2] = (val ~/ 2) % 2;
      sBoxByte[m * 4 + 3] = val % 2;
    }
    return sBoxByte;
  }

  static List<int> _pPermute(List<int> sBoxByte) {
    return [
      sBoxByte[15],
      sBoxByte[6],
      sBoxByte[19],
      sBoxByte[20],
      sBoxByte[28],
      sBoxByte[11],
      sBoxByte[27],
      sBoxByte[16],
      sBoxByte[0],
      sBoxByte[14],
      sBoxByte[22],
      sBoxByte[25],
      sBoxByte[4],
      sBoxByte[17],
      sBoxByte[30],
      sBoxByte[9],
      sBoxByte[1],
      sBoxByte[7],
      sBoxByte[23],
      sBoxByte[13],
      sBoxByte[31],
      sBoxByte[26],
      sBoxByte[2],
      sBoxByte[8],
      sBoxByte[18],
      sBoxByte[12],
      sBoxByte[29],
      sBoxByte[5],
      sBoxByte[21],
      sBoxByte[10],
      sBoxByte[3],
      sBoxByte[24],
    ];
  }

  static List<int> _finallyPermute(List<int> endByte) {
    return [
      endByte[39],
      endByte[7],
      endByte[47],
      endByte[15],
      endByte[55],
      endByte[23],
      endByte[63],
      endByte[31],
      endByte[38],
      endByte[6],
      endByte[46],
      endByte[14],
      endByte[54],
      endByte[22],
      endByte[62],
      endByte[30],
      endByte[37],
      endByte[5],
      endByte[45],
      endByte[13],
      endByte[53],
      endByte[21],
      endByte[61],
      endByte[29],
      endByte[36],
      endByte[4],
      endByte[44],
      endByte[12],
      endByte[52],
      endByte[20],
      endByte[60],
      endByte[28],
      endByte[35],
      endByte[3],
      endByte[43],
      endByte[11],
      endByte[51],
      endByte[19],
      endByte[59],
      endByte[27],
      endByte[34],
      endByte[2],
      endByte[42],
      endByte[10],
      endByte[50],
      endByte[18],
      endByte[58],
      endByte[26],
      endByte[33],
      endByte[1],
      endByte[41],
      endByte[9],
      endByte[49],
      endByte[17],
      endByte[57],
      endByte[25],
      endByte[32],
      endByte[0],
      endByte[40],
      endByte[8],
      endByte[48],
      endByte[16],
      endByte[56],
      endByte[24],
    ];
  }

  static List<List<int>> _generateKeys(List<int> keyByte) {
    final key = List<int>.filled(56, 0);
    final keys = List.generate(16, (_) => List<int>.filled(48, 0));
    const loop = [1, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1];

    for (var i = 0; i < 7; i++) {
      var k = 7;
      for (var j = 0; j < 8; j++, k--) {
        key[i * 8 + j] = keyByte[8 * k + i];
      }
    }

    for (var i = 0; i < 16; i++) {
      for (var j = 0; j < loop[i]; j++) {
        final tempLeft = key[0];
        final tempRight = key[28];
        for (var k = 0; k < 27; k++) {
          key[k] = key[k + 1];
          key[28 + k] = key[29 + k];
        }
        key[27] = tempLeft;
        key[55] = tempRight;
      }
      keys[i] = [
        key[13],
        key[16],
        key[10],
        key[23],
        key[0],
        key[4],
        key[2],
        key[27],
        key[14],
        key[5],
        key[20],
        key[9],
        key[22],
        key[18],
        key[11],
        key[3],
        key[25],
        key[7],
        key[15],
        key[6],
        key[26],
        key[19],
        key[12],
        key[1],
        key[40],
        key[51],
        key[30],
        key[36],
        key[46],
        key[54],
        key[29],
        key[39],
        key[50],
        key[44],
        key[32],
        key[47],
        key[43],
        key[48],
        key[38],
        key[55],
        key[33],
        key[52],
        key[45],
        key[41],
        key[49],
        key[35],
        key[28],
        key[31],
      ];
    }
    return keys;
  }
}

class LoginResult {
  final bool success;
  final String? message;
  const LoginResult({required this.success, this.message});
}

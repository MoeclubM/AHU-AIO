library;

import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
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
  // CAS Triple-DES Encryption (strEnc)
  // ============================================================

  /// Matches `strEnc(data, key1, key2, key3)` from CAS `des.js`.
  /// Splits data into 8-byte chunks and encrypts each with rotating keys.
  static String _strEnc(String data, String k1, String k2, String k3) {
    final dataBytes = utf8.encode(data);
    final keys = [k1, k2, k3];
    final encrypted = <int>[];
    for (var i = 0; i < dataBytes.length; i += 8) {
      final chunk = dataBytes.sublist(i, (i + 8).clamp(0, dataBytes.length));
      final key = keys[(i ~/ 8) % 3];
      final keyBytes = Uint8List(8);
      for (var j = 0; j < 8; j++) {
        keyBytes[j] = j < key.length ? key.codeUnitAt(j) : 0;
      }
      encrypted.addAll(_desEncryptBlock(chunk, keyBytes));
    }
    return encrypted
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
  }

  // ============================================================
  // Pure Dart DES (ECB, no padding) — matches des.js `enc()`
  // ============================================================

  static List<int> _desEncryptBlock(List<int> data, Uint8List key) {
    final block = Uint8List(8);
    for (var i = 0; i < data.length && i < 8; i++) {
      block[i] = data[i];
    }
    final subKeys = _desGenerateSubkeys(key);
    return _desProcessBlock(block, subKeys);
  }

  static List<int> _desProcessBlock(Uint8List block, List<Uint8List> subKeys) {
    // Initial Permutation
    var bits = _bytesToBits(block);
    bits = _permute(bits, _ip);
    var l = bits.sublist(0, 32);
    var r = bits.sublist(32, 64);
    for (var round = 0; round < 16; round++) {
      final newR = _xor(l, _feistel(r, subKeys[round]));
      l = r;
      r = newR;
    }
    final combined = [...r, ...l]; // swap before final perm
    final output = _permute(combined, _fp);
    return _bitsToBytes(output);
  }

  static List<int> _feistel(List<int> r, Uint8List subKey) {
    final expanded = _permute(r, _e);
    final keyBits = _bytesToBits(subKey);
    final xored = _xor(expanded, keyBits);
    final substituted = <int>[];
    for (var i = 0; i < 8; i++) {
      final group = xored.sublist(i * 6, i * 6 + 6);
      final row = (group[0] << 1) | group[5];
      final col =
          (group[1] << 3) | (group[2] << 2) | (group[3] << 1) | group[4];
      var val = _sBoxes[i][row * 16 + col];
      substituted.addAll([
        (val >> 3) & 1,
        (val >> 2) & 1,
        (val >> 1) & 1,
        val & 1,
      ]);
    }
    return _permute(substituted, _p);
  }

  static List<Uint8List> _desGenerateSubkeys(Uint8List key) {
    final keyBits = _bytesToBits(key);
    final permuted = _permute(keyBits, _pc1);
    var c = permuted.sublist(0, 28);
    var d = permuted.sublist(28, 56);
    final subKeys = <Uint8List>[];
    for (var round = 0; round < 16; round++) {
      c = _rotateLeft(c, _shiftSchedule[round]);
      d = _rotateLeft(d, _shiftSchedule[round]);
      final cd = [...c, ...d];
      final subKeyBits = _permute(cd, _pc2);
      subKeys.add(_bitsToBytes(subKeyBits));
    }
    return subKeys;
  }

  // Bit helpers
  static List<int> _bytesToBits(List<int> bytes) {
    final bits = <int>[];
    for (final b in bytes) {
      for (var i = 7; i >= 0; i--) {
        bits.add((b >> i) & 1);
      }
    }
    return bits;
  }

  static Uint8List _bitsToBytes(List<int> bits) {
    final bytes = <int>[];
    for (var i = 0; i < bits.length; i += 8) {
      var b = 0;
      for (var j = 0; j < 8 && i + j < bits.length; j++) {
        b = (b << 1) | bits[i + j];
      }
      bytes.add(b);
    }
    return Uint8List.fromList(bytes);
  }

  static List<int> _permute(List<int> bits, List<int> table) {
    return table.map((i) => bits[i]).toList();
  }

  static List<int> _xor(List<int> a, List<int> b) {
    return List.generate(a.length, (i) => a[i] ^ b[i]);
  }

  static List<int> _rotateLeft(List<int> bits, int n) {
    return [...bits.sublist(n), ...bits.sublist(0, n)];
  }

  // DES Tables
  static const _ip = [
    57,
    49,
    41,
    33,
    25,
    17,
    9,
    1,
    59,
    51,
    43,
    35,
    27,
    19,
    11,
    3,
    61,
    53,
    45,
    37,
    29,
    21,
    13,
    5,
    63,
    55,
    47,
    39,
    31,
    23,
    15,
    7,
    56,
    48,
    40,
    32,
    24,
    16,
    8,
    0,
    58,
    50,
    42,
    34,
    26,
    18,
    10,
    2,
    60,
    52,
    44,
    36,
    28,
    20,
    12,
    4,
    62,
    54,
    46,
    38,
    30,
    22,
    14,
    6,
  ];
  static const _fp = [
    39,
    7,
    47,
    15,
    55,
    23,
    63,
    31,
    38,
    6,
    46,
    14,
    54,
    22,
    62,
    30,
    37,
    5,
    45,
    13,
    53,
    21,
    61,
    29,
    36,
    4,
    44,
    12,
    52,
    20,
    60,
    28,
    35,
    3,
    43,
    11,
    51,
    19,
    59,
    27,
    34,
    2,
    42,
    10,
    50,
    18,
    58,
    26,
    33,
    1,
    41,
    9,
    49,
    17,
    57,
    25,
    32,
    0,
    40,
    8,
    48,
    16,
    56,
    24,
  ];
  static const _e = [
    31,
    0,
    1,
    2,
    3,
    4,
    3,
    4,
    5,
    6,
    7,
    8,
    7,
    8,
    9,
    10,
    11,
    12,
    11,
    12,
    13,
    14,
    15,
    16,
    15,
    16,
    17,
    18,
    19,
    20,
    19,
    20,
    21,
    22,
    23,
    24,
    23,
    24,
    25,
    26,
    27,
    28,
    27,
    28,
    29,
    30,
    31,
    0,
  ];
  static const _p = [
    15,
    6,
    19,
    20,
    28,
    11,
    27,
    16,
    0,
    14,
    22,
    25,
    4,
    17,
    30,
    9,
    1,
    7,
    23,
    13,
    31,
    26,
    2,
    8,
    18,
    12,
    29,
    5,
    21,
    10,
    3,
    24,
  ];
  static const _pc1 = [
    56,
    48,
    40,
    32,
    24,
    16,
    8,
    0,
    57,
    49,
    41,
    33,
    25,
    17,
    9,
    1,
    58,
    50,
    42,
    34,
    26,
    18,
    10,
    2,
    59,
    51,
    43,
    35,
    62,
    54,
    46,
    38,
    30,
    22,
    14,
    6,
    61,
    53,
    45,
    37,
    29,
    21,
    13,
    5,
    60,
    52,
    44,
    36,
    28,
    20,
    12,
    4,
    27,
    19,
    11,
    3,
  ];
  static const _pc2 = [
    13,
    16,
    10,
    23,
    0,
    4,
    2,
    27,
    14,
    5,
    20,
    9,
    22,
    18,
    11,
    3,
    25,
    7,
    15,
    6,
    26,
    19,
    12,
    1,
    40,
    51,
    30,
    36,
    46,
    54,
    29,
    39,
    50,
    44,
    32,
    47,
    43,
    48,
    38,
    55,
    33,
    52,
    45,
    41,
    49,
    35,
    28,
    31,
  ];
  static const _shiftSchedule = [
    1,
    1,
    2,
    2,
    2,
    2,
    2,
    2,
    1,
    2,
    2,
    2,
    2,
    2,
    2,
    1,
  ];
  static const _sBoxes = [
    // S1
    [
      14,
      4,
      13,
      1,
      2,
      15,
      11,
      8,
      3,
      10,
      6,
      12,
      5,
      9,
      0,
      7,
      0,
      15,
      7,
      4,
      14,
      2,
      13,
      1,
      10,
      6,
      12,
      11,
      9,
      5,
      3,
      8,
      4,
      1,
      14,
      8,
      13,
      6,
      2,
      11,
      15,
      12,
      9,
      7,
      3,
      10,
      5,
      0,
      15,
      12,
      8,
      2,
      4,
      9,
      1,
      7,
      5,
      11,
      3,
      14,
      10,
      0,
      6,
      13,
    ],
    // S2
    [
      15,
      1,
      8,
      14,
      6,
      11,
      3,
      4,
      9,
      7,
      2,
      13,
      12,
      0,
      5,
      10,
      3,
      13,
      4,
      7,
      15,
      2,
      8,
      14,
      12,
      0,
      1,
      10,
      6,
      9,
      11,
      5,
      0,
      14,
      7,
      11,
      10,
      4,
      13,
      1,
      5,
      8,
      12,
      6,
      9,
      3,
      2,
      15,
      13,
      8,
      10,
      1,
      3,
      15,
      4,
      2,
      11,
      6,
      7,
      12,
      0,
      5,
      14,
      9,
    ],
    // S3
    [
      10,
      0,
      9,
      14,
      6,
      3,
      15,
      5,
      1,
      13,
      12,
      7,
      11,
      4,
      2,
      8,
      13,
      7,
      0,
      9,
      3,
      4,
      6,
      10,
      2,
      8,
      5,
      14,
      12,
      11,
      15,
      1,
      13,
      6,
      4,
      9,
      8,
      15,
      3,
      0,
      11,
      1,
      2,
      12,
      5,
      10,
      14,
      7,
      1,
      10,
      13,
      0,
      6,
      9,
      8,
      7,
      4,
      15,
      14,
      3,
      11,
      5,
      2,
      12,
    ],
    // S4
    [
      7,
      13,
      14,
      3,
      0,
      6,
      9,
      10,
      1,
      2,
      8,
      5,
      11,
      12,
      4,
      15,
      13,
      8,
      11,
      5,
      6,
      15,
      0,
      3,
      4,
      7,
      2,
      12,
      1,
      10,
      14,
      9,
      10,
      6,
      9,
      0,
      12,
      11,
      7,
      13,
      15,
      1,
      3,
      14,
      5,
      2,
      8,
      4,
      3,
      15,
      0,
      6,
      10,
      1,
      13,
      8,
      9,
      4,
      5,
      11,
      12,
      7,
      2,
      14,
    ],
    // S5
    [
      2,
      12,
      4,
      1,
      7,
      10,
      11,
      6,
      8,
      5,
      3,
      15,
      13,
      0,
      14,
      9,
      14,
      11,
      2,
      12,
      4,
      7,
      13,
      1,
      5,
      0,
      15,
      10,
      3,
      9,
      8,
      6,
      4,
      2,
      1,
      11,
      10,
      13,
      7,
      8,
      15,
      9,
      12,
      5,
      6,
      3,
      0,
      14,
      9,
      14,
      15,
      5,
      2,
      8,
      12,
      3,
      7,
      0,
      4,
      10,
      1,
      13,
      11,
      6,
    ],
    // S6
    [
      4,
      2,
      1,
      11,
      10,
      13,
      7,
      8,
      15,
      9,
      12,
      5,
      6,
      3,
      0,
      14,
      0,
      12,
      7,
      11,
      10,
      1,
      13,
      14,
      5,
      8,
      15,
      6,
      2,
      3,
      9,
      4,
      1,
      14,
      4,
      11,
      8,
      12,
      6,
      2,
      15,
      9,
      7,
      3,
      10,
      5,
      0,
      13,
      6,
      1,
      13,
      8,
      11,
      4,
      2,
      7,
      15,
      10,
      9,
      5,
      3,
      14,
      12,
      0,
    ],
    // S7
    [
      13,
      2,
      8,
      4,
      6,
      15,
      11,
      1,
      10,
      9,
      3,
      14,
      5,
      0,
      12,
      7,
      1,
      15,
      13,
      8,
      10,
      3,
      7,
      4,
      12,
      5,
      6,
      11,
      0,
      14,
      9,
      2,
      7,
      11,
      4,
      1,
      9,
      12,
      14,
      2,
      0,
      6,
      10,
      13,
      15,
      3,
      5,
      8,
      2,
      1,
      14,
      7,
      4,
      10,
      8,
      13,
      15,
      12,
      9,
      0,
      3,
      5,
      6,
      11,
    ],
    // S8
    [
      1,
      15,
      13,
      8,
      10,
      3,
      7,
      4,
      12,
      5,
      6,
      11,
      0,
      14,
      9,
      2,
      7,
      11,
      4,
      1,
      9,
      12,
      14,
      2,
      0,
      6,
      10,
      13,
      15,
      3,
      5,
      8,
      4,
      1,
      14,
      8,
      13,
      6,
      2,
      11,
      15,
      12,
      9,
      7,
      3,
      10,
      5,
      0,
      15,
      12,
      8,
      2,
      4,
      9,
      1,
      7,
      5,
      11,
      3,
      14,
      10,
      0,
      6,
      13,
    ],
  ];
}

class LoginResult {
  final bool success;
  final String? message;
  const LoginResult({required this.success, this.message});
}

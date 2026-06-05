import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

class AdwmhOneCode {
  final String code;
  final String time;

  const AdwmhOneCode({required this.code, required this.time});
}

class AdwmhClient {
  static final AdwmhClient _instance = AdwmhClient._internal();
  factory AdwmhClient() => _instance;

  static const String baseUrl = 'https://adwmh.ahu.edu.cn';
  static const String _ua =
      'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36';

  late final Dio _dio;
  late final PersistCookieJar _cookieJar;
  bool _initialized = false;

  AdwmhClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json, text/plain, */*',
          'User-Agent': _ua,
          'x-requested-with': 'XMLHttpRequest',
        },
      ),
    );
  }

  Future<void> init() async {
    if (_initialized) return;
    final dir = await path_provider.getApplicationDocumentsDirectory();
    _cookieJar = PersistCookieJar(
      storage: FileStorage('${dir.path}/adwmh_cookies'),
    );
    _dio.interceptors.add(CookieManager(_cookieJar));
    _initialized = true;
  }

  Future<Uint8List> fetchCaptcha() async {
    await init();
    final resp = await _dio.get<List<int>>(
      '/remind/authcode',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(resp.data!);
  }

  Future<void> login({
    required String username,
    required String password,
    required String captcha,
  }) async {
    await init();
    final resp = await _dio.post<dynamic>(
      '/user/login',
      data: {
        'username': username,
        'pwd': password,
        'flag': 0,
        'imgcode': captcha,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    final data = _json(resp);
    if (data['code'].toString() != '10000') {
      throw StateError(data['msg']?.toString() ?? '智慧安大登录失败');
    }
  }

  Future<Map<String, dynamic>?> fetchSessionUser() async {
    await init();
    final resp = await _dio.post<dynamic>(
      '/user/session',
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    final data = _json(resp);
    if (data['code'].toString() != '10000') return null;
    final object = data['object'];
    if (object is! Map) return null;
    final user = object['user'];
    return user is Map ? Map<String, dynamic>.from(user) : null;
  }

  Future<bool> hasSession() async {
    return await fetchSessionUser() != null;
  }

  Future<AdwmhOneCode> fetchOneCode() async {
    await init();
    final resp = await _dio.get<dynamic>('/xzxcard/qrcode');
    final data = _json(resp);
    if (data['code'].toString() != '10000') {
      throw StateError(data['msg']?.toString() ?? '一码通二维码获取失败');
    }
    final code = data['object']?.toString() ?? '';
    if (!RegExp(r'^\d{20}.+').hasMatch(code)) {
      throw StateError('一码通接口返回的不是完整二维码内容');
    }
    return AdwmhOneCode(code: code, time: data['msg']?.toString() ?? '');
  }

  Future<String> fetchBalance() async {
    await init();
    final resp = await _dio.get<dynamic>('/xzxcard/yue');
    final data = _json(resp);
    if (data['code'].toString() != '10000') {
      throw StateError(data['msg']?.toString() ?? '一码通余额获取失败');
    }
    return data['object']?.toString() ?? '-';
  }

  Map<String, dynamic> _json(Response<dynamic> resp) {
    final body = resp.data;
    if (body is Map) return Map<String, dynamic>.from(body);
    throw StateError('智慧安大接口返回非 JSON：${resp.realUri}');
  }
}

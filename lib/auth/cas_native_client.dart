import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import 'cas_des.dart';

class CasNativeLoginResult {
  final Uri finalUri;
  final List<Uri> redirectUris;

  const CasNativeLoginResult({
    required this.finalUri,
    required this.redirectUris,
  });

  Iterable<Uri> get observedUris => [...redirectUris, finalUri];
}

class CasNativeClient {
  static const _casBase = 'https://one.ahu.edu.cn';

  final CookieJar cookieJar;
  late final Dio _dio;

  CasNativeClient({CookieJar? cookieJar})
    : cookieJar = cookieJar ?? CookieJar() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _casBase,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36',
        },
      ),
    );
    _dio.interceptors.add(CookieManager(this.cookieJar));
  }

  static Uri loginUriForService(String serviceUrl) {
    return Uri.parse(
      '$_casBase/cas/login',
    ).replace(queryParameters: {'service': serviceUrl});
  }

  Future<CasNativeLoginResult> login({
    required Uri loginUri,
    required String username,
    required String password,
    required bool trustDevice,
  }) async {
    final initialRedirects = <Uri>[];
    var currentLoginUri = loginUri;
    late Response<String> loginPage;
    while (true) {
      loginPage = await _dio.getUri<String>(
        currentLoginUri,
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (!_isRedirect(loginPage.statusCode)) break;
      currentLoginUri = loginPage.realUri.resolve(
        loginPage.headers.value('location')!,
      );
      initialRedirects.add(currentLoginUri);
    }
    if (loginPage.statusCode != 200 || loginPage.data == null) {
      throw StateError('CAS 登录页加载失败：${loginPage.statusCode}');
    }

    final html = loginPage.data!;
    final lt = _hiddenValue(html, 'lt');
    final execution = _hiddenValue(html, 'execution');
    final rsa = CasDes.encrypt('$username$password$lt');
    final device = await _postDevice({
      'ul': username.length,
      'pl': password.length,
      'rsa': rsa,
      'method': 'login',
    });
    final info = device['info']?.toString();
    if (info == 'unbind') {
      final bind = await _postDevice({
        'saveDevice': trustDevice ? 1 : 0,
        'method': 'bind2',
      });
      if (bind['info'] != 'ok') {
        throw StateError('CAS 设备确认失败：${bind['info']}');
      }
    } else if (info != 'ok') {
      throw StateError(_deviceErrorMessage(info));
    }

    final loginResp = await _dio.postUri<String>(
      loginPage.realUri,
      data: {
        'rsa': rsa,
        'ul': username.length,
        'pl': password.length,
        'lt': lt,
        'execution': execution,
        '_eventId': 'submit',
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.plain,
        followRedirects: false,
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    if (_isRedirect(loginResp.statusCode)) {
      final firstRedirect = loginResp.realUri.resolve(
        loginResp.headers.value('location')!,
      );
      final result = await _followGetRedirects(firstRedirect);
      return CasNativeLoginResult(
        finalUri: result.finalUri,
        redirectUris: [...initialRedirects, ...result.redirectUris],
      );
    }
    throw StateError(_loginPageError(loginResp.data) ?? 'CAS 登录未产生服务跳转');
  }

  Future<CasNativeLoginResult> _followGetRedirects(Uri firstUri) async {
    final redirects = <Uri>[];
    var current = firstUri;
    while (true) {
      redirects.add(current);
      final resp = await _dio.getUri<String>(
        current,
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (!_isRedirect(resp.statusCode)) {
        return CasNativeLoginResult(
          finalUri: resp.realUri,
          redirectUris: redirects,
        );
      }
      current = resp.realUri.resolve(resp.headers.value('location')!);
    }
  }

  Future<Map<String, dynamic>> _postDevice(Map<String, dynamic> data) async {
    final resp = await _dio.post<dynamic>(
      '/cas/device',
      data: data,
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    final body = resp.data;
    if (body is Map) return Map<String, dynamic>.from(body);
    if (body is String) return Map<String, dynamic>.from(jsonDecode(body));
    throw StateError('CAS 设备接口返回异常：$body');
  }

  static bool _isRedirect(int? statusCode) {
    return statusCode != null && statusCode >= 300 && statusCode < 400;
  }

  static String _hiddenValue(String html, String name) {
    final pattern = RegExp(
      '<input[^>]*(?:name|id)="$name"[^>]*value="([^"]*)"',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(html);
    if (match == null) {
      throw StateError('CAS 登录页缺少 $name');
    }
    return match.group(1)!;
  }

  static String _deviceErrorMessage(String? info) {
    return switch (info) {
      'nf' || 'err' => 'CAS 用户名或密码错误',
      null || '' => 'CAS 设备接口未返回状态',
      _ => 'CAS 设备接口异常：$info',
    };
  }

  static String? _loginPageError(String? html) {
    if (html == null) return null;
    final hidden = RegExp(
      r'id="errormsghide"[^>]*>([^<]+)',
      caseSensitive: false,
    ).firstMatch(html);
    if (hidden != null && hidden.group(1)!.trim().isNotEmpty) {
      return hidden.group(1)!.trim();
    }
    final notice = RegExp(
      r'id="errormsg"[^>]*>([^<]+)',
      caseSensitive: false,
    ).firstMatch(html);
    if (notice != null && notice.group(1)!.trim().isNotEmpty) {
      return notice.group(1)!.trim();
    }
    return null;
  }
}

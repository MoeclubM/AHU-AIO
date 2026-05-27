import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';

/// 财务系统 API 客户端 (ycard.ahu.edu.cn)
class FinanceApi {
  static final FinanceApi _instance = FinanceApi._internal();
  factory FinanceApi() => _instance;

  static const String baseUrl = 'https://ycard.ahu.edu.cn';
  late final Dio _dio;
  final CookieJar _cookieJar = CookieJar();
  bool _loggedIn = false;
  String? _accessToken;

  FinanceApi._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36',
      },
    ));
  }

  bool get loggedIn => _loggedIn;
  CookieJar get cookieJar => _cookieJar;
  String? get accessToken => _accessToken;

  /// 从 WebView 提取 access_token 后设置
  void setAccessToken(String token) {
    _accessToken = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// 从 WebView 提取所有 cookies 后设置
  void setCookies(List<Cookie> cookies) {
    _cookieJar.saveFromResponse(
      Uri.parse(baseUrl),
      cookies,
    );
    // 也从 cookies 中提取 access_token
    for (final cookie in cookies) {
      if (cookie.name == 'access_token' && cookie.value.isNotEmpty) {
        setAccessToken(cookie.value);
      }
    }
  }

  /// 获取用户信息
  Future<Map<String, dynamic>> getUserInfo() async {
    try {
      final resp = await _dio.get('/berserker-base/user');
      return Map<String, dynamic>.from(resp.data);
    } catch (e) {
      return {'code': 401, 'message': '获取用户信息失败: $e'};
    }
  }

  /// 获取一卡通应用信息（含菜单、余额等入口）
  Future<Map<String, dynamic>> getEcardInfo() async {
    final resp = await _dio.get(
      '/berserker-app/appScheme/info',
      queryParameters: {
        'type': 'user',
        'serviceType': 'h5',
        'synAccessSource': 'h5',
      },
    );
    return Map<String, dynamic>.from(resp.data);
  }

  /// 获取前端配置信息
  Future<Map<String, dynamic>> getFrontInfo() async {
    final resp = await _dio.get(
      '/berserker-app/frontInfo',
      queryParameters: {'synAccessSource': 'h5'},
    );
    return Map<String, dynamic>.from(resp.data);
  }

  /// 通用 GET 请求
  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? params}) async {
    final resp = await _dio.get(path, queryParameters: params);
    return Map<String, dynamic>.from(resp.data);
  }

  /// 通用 POST 请求
  Future<Map<String, dynamic>> post(String path,
      {dynamic data}) async {
    final resp = await _dio.post(path, data: data);
    return Map<String, dynamic>.from(resp.data);
  }

  /// 登出
  Future<void> logout() async {
    try {
      await _dio.post('/berserker-base/login/logout');
    } catch (_) {}
    _loggedIn = false;
    _accessToken = null;
    _dio.options.headers.remove('Authorization');
  }
}

import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:shared_preferences/shared_preferences.dart';

/// 财务系统 API 客户端 (ycard.ahu.edu.cn)
class FinanceApi {
  static final FinanceApi _instance = FinanceApi._internal();
  factory FinanceApi() => _instance;

  static const String baseUrl = 'https://ycard.ahu.edu.cn';
  late final Dio _dio;
  late PersistCookieJar _cookieJar;
  bool loggedIn = false;
  String? accessToken;
  bool _initialized = false;

  FinanceApi._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json, text/plain, */*',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36',
        },
      ),
    );
  }

  Future<void> init() async {
    if (_initialized) return;
    final dir = await path_provider.getApplicationDocumentsDirectory();
    _cookieJar = PersistCookieJar(
      storage: FileStorage('${dir.path}/finance_cookies'),
    );
    _dio.interceptors.add(CookieManager(_cookieJar));
    // 添加拦截器：确保所有请求带 synAccessSource
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.queryParameters.putIfAbsent('synAccessSource', () => 'h5');
          handler.next(options);
        },
        onError: (error, handler) {
          final status = error.response?.statusCode;
          final code = error.response?.data is Map
              ? error.response?.data['code']
              : null;
          if (status == 401 || code == 401) {
            loggedIn = false;
          }
          handler.next(error);
        },
      ),
    );
    _initialized = true;

    // 恢复 token
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('finance_access_token');
    if (savedToken != null && savedToken.isNotEmpty) {
      setAccessToken(savedToken);
      loggedIn = true;
    }
  }

  PersistCookieJar get cookieJar => _cookieJar;

  void setAccessToken(String token) {
    final normalized = _normalizeToken(token);
    accessToken = normalized;
    _dio.options.headers['synjones-auth'] = 'bearer $normalized';
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('finance_access_token', normalized);
    });
  }

  static String _normalizeToken(String token) {
    var value = token.trim();
    if (value.startsWith('"') && value.endsWith('"')) {
      value = value.substring(1, value.length - 1);
    }
    final lower = value.toLowerCase();
    if (lower.startsWith('bearer ')) {
      value = value.substring(7).trim();
    }
    return value;
  }

  void clearAuth() {
    loggedIn = false;
    accessToken = null;
    _dio.options.headers.remove('synjones-auth');
    _cookieJar.deleteAll();
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('finance_access_token');
    });
  }

  /// 验证当前 session 是否有效
  Future<bool> hasValidSession() async {
    if (!loggedIn) return false;
    try {
      final resp = await getUserInfo();
      return resp['code'] == 200 && resp['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// 获取用户信息
  Future<Map<String, dynamic>> getUserInfo() async {
    final resp = await _dio.get(
      '/berserker-base/user',
      queryParameters: {'synAccessSource': 'h5'},
    );
    return Map<String, dynamic>.from(resp.data);
  }

  /// 获取一卡通应用方案（含菜单结构）
  Future<Map<String, dynamic>> getAppScheme() async {
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

  /// 获取通知
  Future<Map<String, dynamic>> getNotices() async {
    final resp = await _dio.get(
      '/berserker-app/notice/page',
      queryParameters: {
        'isPublish': '1',
        'sendType': '2',
        'current': '1',
        'size': '10',
        'synAccessSource': 'h5',
      },
    );
    return Map<String, dynamic>.from(resp.data);
  }

  /// 获取日程/待办数量
  Future<Map<String, dynamic>> getScheduleCount() async {
    final resp = await _dio.get(
      '/berserker-schedule/schedule/info/count',
      queryParameters: {
        'dateCondition': '1',
        'overdue': '2',
        'synAccessSource': 'h5',
      },
    );
    return Map<String, dynamic>.from(resp.data);
  }

  /// 通用 GET
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    params ??= {};
    params.putIfAbsent('synAccessSource', () => 'h5');
    final resp = await _dio.get(path, queryParameters: params);
    return Map<String, dynamic>.from(resp.data);
  }

  /// 通用 POST
  Future<Map<String, dynamic>> post(String path, {dynamic data}) async {
    final resp = await _dio.post(
      path,
      data: data,
      queryParameters: {'synAccessSource': 'h5'},
    );
    return Map<String, dynamic>.from(resp.data);
  }

  /// 登出
  Future<void> logout() async {
    try {
      await _dio.post(
        '/berserker-base/login/logout',
        queryParameters: {'synAccessSource': 'h5'},
      );
    } catch (_) {}
    clearAuth();
  }
}

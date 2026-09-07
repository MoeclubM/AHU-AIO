import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../globals.dart' as globals;
import '../jwapp/login/login_service.dart';
import '../jw/api/jw_api.dart';
import '../finance/api/synjones_client.dart';
import 'cas_auth_cache.dart';

/// 密码认证行为模式。
enum AuthBehavior {
  /// 统一密码认证：一套账号密码同时登录微教务、安大教务与一卡通（默认）。
  unified,

  /// 独立密码认证：各业务平台使用各自独立的账号密码分别认证与维护。
  independent;

  String get displayName =>
      this == AuthBehavior.unified ? '统一密码认证' : '独立密码认证';

  String get description => this == AuthBehavior.unified
      ? '使用一套账号密码同时登录微教务、安大教务与一卡通'
      : '各业务平台使用各自独立的账号密码分别认证';
}

/// 认证配置与偏好管理器。
class AuthManager extends ChangeNotifier {
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  AuthManager._internal();

  AuthBehavior _behavior = AuthBehavior.unified;

  AuthBehavior get behavior => _behavior;
  bool get isUnified => _behavior == AuthBehavior.unified;
  bool get isIndependent => _behavior == AuthBehavior.independent;

  /// 设置认证行为模式并持久化存储。
  Future<void> setBehavior(AuthBehavior value) async {
    if (_behavior == value) return;
    _behavior = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_behavior', value.name);
  }

  /// 读取本地保存的认证配置。
  Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString('auth_behavior');
    if (val != null) {
      _behavior = AuthBehavior.values.firstWhere(
        (e) => e.name == val,
        orElse: () => AuthBehavior.unified,
      );
      notifyListeners();
    }
  }

  /// 获取微教务密码（独立认证时优先使用独立密码，否则回退到统一密码）
  Future<String?> getJwappPassword() async {
    final prefs = await SharedPreferences.getInstance();
    if (isIndependent) {
      final p = prefs.getString('jwapp_password');
      if (p != null && p.isNotEmpty) return p;
    }
    return prefs.getString('password');
  }

  /// 获取安大教务密码（独立认证时优先使用独立密码，否则回退到统一密码）
  Future<String?> getJwPassword() async {
    final prefs = await SharedPreferences.getInstance();
    if (isIndependent) {
      final p = prefs.getString('jw_password');
      if (p != null && p.isNotEmpty) return p;
    }
    return prefs.getString('password');
  }

  /// 获取一卡通密码（独立认证时优先使用独立密码，否则回退到统一密码）
  Future<String?> getFinancePassword() async {
    final prefs = await SharedPreferences.getInstance();
    if (isIndependent) {
      final p = prefs.getString('finance_password');
      if (p != null && p.isNotEmpty) return p;
    }
    return prefs.getString('password');
  }

  /// 保存单个平台的独立密码
  Future<void> savePlatformPassword(String platform, String password) async {
    final prefs = await SharedPreferences.getInstance();
    switch (platform) {
      case 'jwapp':
        await prefs.setString('jwapp_password', password);
        break;
      case 'jw':
        await prefs.setString('jw_password', password);
        break;
      case 'finance':
        await prefs.setString('finance_password', password);
        break;
    }
    notifyListeners();
  }

  /// 单独验证微教务密码并保存生效
  /// 返回 null 表示验证成功，返回字符串表示失败原因
  Future<String?> verifyJwapp({
    required String username,
    required String password,
  }) async {
    try {
      final token = await LoginService.login(
        username: username,
        password: password,
      );
      if (token != null && token.isNotEmpty) {
        globals.idToken = token;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('idToken', token);
        await prefs.setString('username', username);
        await prefs.setString('jwapp_password', password);
        globals.onLoginStateChanged?.call();
        notifyListeners();
        return null;
      } else {
        return '登录返回的令牌为空';
      }
    } catch (e) {
      return _cleanErrorMessage(e.toString());
    }
  }

  /// 单独验证安大教务 (CAS) 密码并保存生效
  Future<String?> verifyJw({
    required String username,
    required String password,
  }) async {
    try {
      final jwApi = JwApi();
      await jwApi.loginWithCas(
        username: username,
        password: password,
        trustDevice: true,
      );
      await CasAuthCache.markLoggedIn('jw');
      globals.jwLoggedIn = true;
      globals.jwStudentNo = jwApi.studentId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      if (jwApi.studentId != null) {
        await prefs.setString('jwStudentNo', jwApi.studentId!);
      }
      await prefs.setString('jw_password', password);
      globals.onLoginStateChanged?.call();
      notifyListeners();
      return null;
    } catch (e) {
      return _cleanErrorMessage(e.toString());
    }
  }

  /// 单独验证一卡通 (CAS / 新中新) 密码并保存生效
  Future<String?> verifyFinance({
    required String username,
    required String password,
  }) async {
    try {
      final client = SynjonesClient();
      final result = await client.casLoginNative(
        username: username,
        password: password,
        trustDevice: true,
      );
      if (result.success) {
        await CasAuthCache.markLoggedIn('ycard');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', username);
        await prefs.setString('finance_password', password);
        globals.onLoginStateChanged?.call();
        notifyListeners();
        return null;
      } else {
        return result.message ?? '一卡通登录失败';
      }
    } catch (e) {
      return _cleanErrorMessage(e.toString());
    }
  }

  String _cleanErrorMessage(String message) {
    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }
    if (message.startsWith('StateError: ')) {
      return message.substring(12);
    }
    return message;
  }
}

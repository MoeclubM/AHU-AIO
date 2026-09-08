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

  String get displayName => this == AuthBehavior.unified ? '统一密码认证' : '独立密码认证';

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

  /// 清除保存的所有密码（包括统一密码与各平台独立密码）。
  Future<void> clearAllPasswords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('password');
    await prefs.remove('jwapp_password');
    await prefs.remove('jw_password');
    await prefs.remove('finance_password');
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
        globals.username = username;
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
      globals.username = username;
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
        globals.username = username;
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

  /// 执行全平台登录（微教务、安大教务、一卡通）。
  /// 自动从本地读取当前学号与当前认证模式下各平台对应的密码进行登录。
  /// [usernameOverride] 可选，若传入则优先使用该账号。
  Future<AllPlatformsLoginResult> loginAllPlatforms({
    String? usernameOverride,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final username = usernameOverride ??
        prefs.getString('username') ??
        globals.username ??
        '';

    if (username.isEmpty) {
      const emptyUserRes = PlatformLoginResult(
        success: false,
        message: '未配置认证学号/账号',
      );
      return const AllPlatformsLoginResult(
        jwapp: emptyUserRes,
        jw: emptyUserRes,
        finance: emptyUserRes,
      );
    }

    final jwappPass = await getJwappPassword();
    final jwPass = await getJwPassword();
    final financePass = await getFinancePassword();

    PlatformLoginResult jwappResult;
    PlatformLoginResult jwResult;
    PlatformLoginResult financeResult;

    // 1. 微教务
    if (jwappPass == null || jwappPass.isEmpty) {
      jwappResult = const PlatformLoginResult(
        success: false,
        message: '未配置密码',
      );
    } else {
      try {
        final token = await LoginService.login(
          username: username,
          password: jwappPass,
        );
        if (token != null && token.isNotEmpty) {
          globals.idToken = token;
          globals.username = username;
          await prefs.setString('idToken', token);
          await prefs.setString('username', username);
          jwappResult = const PlatformLoginResult(success: true);
        } else {
          jwappResult = const PlatformLoginResult(
            success: false,
            message: '微教务 Token 返回为空',
          );
        }
      } catch (e) {
        jwappResult = PlatformLoginResult(
          success: false,
          message: _cleanErrorMessage(e.toString()),
        );
      }
    }

    // 2. 安大教务 (CAS)
    if (jwPass == null || jwPass.isEmpty) {
      jwResult = const PlatformLoginResult(
        success: false,
        message: '未配置密码',
      );
    } else {
      try {
        final jwApi = JwApi();
        await jwApi.loginWithCas(
          username: username,
          password: jwPass,
          trustDevice: true,
        );
        await CasAuthCache.markLoggedIn('jw');
        globals.jwLoggedIn = true;
        globals.username = username;
        globals.jwStudentNo = jwApi.studentId;
        await prefs.setString('username', username);
        if (jwApi.studentId != null) {
          await prefs.setString('jwStudentNo', jwApi.studentId!);
        }
        jwResult = const PlatformLoginResult(success: true);
      } catch (e) {
        jwResult = PlatformLoginResult(
          success: false,
          message: _cleanErrorMessage(e.toString()),
        );
      }
    }

    // 3. 一卡通 (CAS / 新中新)
    if (financePass == null || financePass.isEmpty) {
      financeResult = const PlatformLoginResult(
        success: false,
        message: '未配置密码',
      );
    } else {
      try {
        final client = SynjonesClient();
        final result = await client.casLoginNative(
          username: username,
          password: financePass,
          trustDevice: true,
        );
        if (result.success) {
          await CasAuthCache.markLoggedIn('ycard');
          globals.username = username;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('username', username);
          financeResult = const PlatformLoginResult(success: true);
        } else {
          financeResult = PlatformLoginResult(
            success: false,
            message: result.message ?? '一卡通登录失败',
          );
        }
      } catch (e) {
        financeResult = PlatformLoginResult(
          success: false,
          message: _cleanErrorMessage(e.toString()),
        );
      }
    }

    globals.onLoginStateChanged?.call();
    notifyListeners();

    return AllPlatformsLoginResult(
      jwapp: jwappResult,
      jw: jwResult,
      finance: financeResult,
    );
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

/// 单个平台的登录验证结果。
class PlatformLoginResult {
  final bool success;
  final String? message;

  const PlatformLoginResult({required this.success, this.message});
}

/// 全平台登录结果汇总。
class AllPlatformsLoginResult {
  final PlatformLoginResult jwapp;
  final PlatformLoginResult jw;
  final PlatformLoginResult finance;

  const AllPlatformsLoginResult({
    required this.jwapp,
    required this.jw,
    required this.finance,
  });

  bool get anySuccess => jwapp.success || jw.success || finance.success;
  bool get allSuccess => jwapp.success && jw.success && finance.success;

  String toSummaryString() {
    final jwappText = jwapp.success ? '成功' : '失败(${jwapp.message ?? "未知错误"})';
    final jwText = jw.success ? '成功' : '失败(${jw.message ?? "未知错误"})';
    final financeText = finance.success ? '成功' : '失败(${finance.message ?? "未知错误"})';
    return '微教务: $jwappText | 教务: $jwText | 一卡通: $financeText';
  }
}

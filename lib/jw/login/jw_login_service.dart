import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../api/jw_api.dart';
import '../../globals.dart' as globals;

/// 新教务系统登录服务
class JwLoginService {
  /// 登录新教务系统
  static Future<LoginResult> login({
    required String username,
    required String password,
    String captchaToken = '',
  }) async {
    final api = JwApi();
    await api.init();

    // 1. 先访问登录页建立 session（服务器要求同一 session）
    await api.prepareLogin();

    // 2. 获取盐值
    final salt = await api.getLoginSalt();

    // 3. SHA1(salt + "-" + password) 加密
    final bytes = utf8.encode('$salt-$password');
    final hash = sha1.convert(bytes).toString();

    // 4. 提交登录
    final result = await api.login(
      username: username,
      passwordHash: hash,
      captchaToken: captchaToken,
    );

    if (result.success) {
      globals.jwLoggedIn = true;
      globals.jwStudentNo = username;
    }

    return result;
  }

  /// 登出
  static Future<void> logout() async {
    final api = JwApi();
    await api.deleteAllCookies();
    api.studentId = null;
    globals.jwLoggedIn = false;
    globals.jwStudentNo = null;
  }
}

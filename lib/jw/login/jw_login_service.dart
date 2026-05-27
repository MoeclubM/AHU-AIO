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
  }) async {
    final api = JwApi();

    // 1. 获取盐值
    final salt = await api.getLoginSalt();

    // 2. SHA1(salt + "-" + password) 加密
    final bytes = utf8.encode('$salt-$password');
    final hash = sha1.convert(bytes).toString();

    // 3. 提交登录
    final result = await api.login(
      username: username,
      passwordHash: hash,
    );

    if (result.success) {
      globals.jwLoggedIn = true;
      globals.jwStudentNo = username;
    }

    return result;
  }

  /// 登出
  static void logout() {
    final api = JwApi();
    api.cookieJar.deleteAll();
    api.studentId = null;
    globals.jwLoggedIn = false;
    globals.jwStudentNo = null;
  }
}

import '../api/jw_api.dart';
import '../../auth/cas_auth_cache.dart';
import '../../globals.dart' as globals;

/// 新教务系统登录服务
class JwLoginService {
  /// 登出
  static Future<void> logout() async {
    final api = JwApi();
    await api.deleteAllCookies();
    await CasAuthCache.clear();
    api.studentId = null;
    globals.jwLoggedIn = false;
    globals.jwStudentNo = null;
    globals.onLoginStateChanged?.call();
  }
}

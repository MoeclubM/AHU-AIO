import '../api/jw_api.dart';
import '../../globals.dart' as globals;

/// 新教务系统登录服务
class JwLoginService {
  /// 登出
  static Future<void> logout() async {
    final api = JwApi();
    await api.deleteAllCookies();
    api.studentId = null;
    globals.jwLoggedIn = false;
    globals.jwStudentNo = null;
  }
}

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 统一身份认证缓存状态。
class CasAuthCache {
  static const _loggedInAtKey = 'cas_logged_in_at';
  static const _lastServiceKey = 'cas_last_service';

  CasAuthCache._();

  static Future<void> markLoggedIn(String service) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_loggedInAtKey, DateTime.now().millisecondsSinceEpoch);
    await prefs.setString(_lastServiceKey, service);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInAtKey);
    await prefs.remove(_lastServiceKey);
    await prefs.remove('synjones_access_token');
    await CookieManager.instance().deleteAllCookies();
  }
}

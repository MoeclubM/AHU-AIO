import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:shared_preferences/shared_preferences.dart';

/// 统一身份认证缓存状态。
class CasAuthCache {
  static const _loggedInAtKey = 'cas_logged_in_at';
  static const _lastServiceKey = 'cas_last_service';
  static PersistCookieJar? _cookieJar;

  CasAuthCache._();

  static Future<PersistCookieJar> cookieJar() async {
    final cached = _cookieJar;
    if (cached != null) return cached;
    final dir = await path_provider.getApplicationDocumentsDirectory();
    return _cookieJar = PersistCookieJar(
      storage: FileStorage('${dir.path}/cas_cookies'),
    );
  }

  static Future<void> markLoggedIn(String service) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_loggedInAtKey, DateTime.now().millisecondsSinceEpoch);
    await prefs.setString(_lastServiceKey, service);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final jar = await cookieJar();
    await jar.deleteAll();
    await prefs.remove(_loggedInAtKey);
    await prefs.remove(_lastServiceKey);
    await prefs.remove('synjones_access_token');
    await CookieManager.instance().deleteAllCookies();
  }
}

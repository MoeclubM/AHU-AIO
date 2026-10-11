import 'package:shared_preferences/shared_preferences.dart';

/// 近邻宝本地数据持久化管理
class JlbStorage {
  static const String _keySessionId = 'jlb_session_id';
  static const String _keyUserPhone = 'jlb_user_phone';
  static const String _keyUserName = 'jlb_user_name';
  static const String _keyLastExpCode = 'jlb_last_exp_code';
  static const String _keyHistoryExpCodes = 'jlb_history_exp_codes';

  static Future<String> getSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySessionId) ?? '';
  }

  static Future<void> saveSessionId(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySessionId, sessionId.trim());
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySessionId);
    await prefs.remove(_keyUserPhone);
    await prefs.remove(_keyUserName);
  }

  static Future<void> saveUserInfo({
    required String phone,
    required String userName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserPhone, phone);
    await prefs.setString(_keyUserName, userName);
  }

  static Future<Map<String, String>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'phone': prefs.getString(_keyUserPhone) ?? '',
      'userName': prefs.getString(_keyUserName) ?? '',
    };
  }

  static Future<String> getLastExpCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastExpCode) ?? '';
  }

  static Future<void> saveLastExpCode(String code) async {
    final clean = code.trim();
    if (clean.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastExpCode, clean);

    // 更新历史查询记录 (最多保留 15 条)
    final history = prefs.getStringList(_keyHistoryExpCodes) ?? [];
    history.remove(clean);
    history.insert(0, clean);
    if (history.length > 15) {
      history.removeRange(15, history.length);
    }
    await prefs.setStringList(_keyHistoryExpCodes, history);
  }

  static Future<List<String>> getHistoryExpCodes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyHistoryExpCodes) ?? [];
  }
}

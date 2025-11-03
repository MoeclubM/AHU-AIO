// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login/login_view.dart';
import '../../globals.dart' as globals;
import '../api/getuserinfo.dart';

class MainPageService {
  static Future<void> checkTokenAndNavigate(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final String? idToken = prefs.getString('idToken');
    if (idToken != null) {
      globals.idToken = idToken;
      try {
        final userInfo = await getUserInfo(idToken);
        if (userInfo != null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('登录成功')),
            );
          }
        } else {
          await _logout(context);
        }
      } catch (e) {
        if (e.toString() == 'Exception: 网络请求超时') {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('网络请求超时')),
            );
          }
        } else if (e.toString() == 'Exception: Unauthorized') {
          await _logout(context);
        }
      }
    } else {
      await _logout(context);
    }
  }

  static Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('idToken');

    if (!context.mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const JWLoginPage()),
    );
  }
}

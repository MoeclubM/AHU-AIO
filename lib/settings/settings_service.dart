import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/getuserinfo.dart';
import '../globals.dart' as globals;

class SettingsService extends ChangeNotifier {
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;

  Map<String, dynamic>? get userInfo => _userInfo;
  bool get isLoading => _isLoading;

  SettingsService() {
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final userInfo = await getUserInfo(globals.idToken!);
      _userInfo = userInfo;
      await prefs.setString('cachedUserInfo', jsonEncode(userInfo));
    } catch (e) {
      final cachedUserInfo = prefs.getString('cachedUserInfo');
      if (cachedUserInfo != null) {
        _userInfo = jsonDecode(cachedUserInfo);
      }
    }
    _isLoading = false;
    notifyListeners();
  }
}
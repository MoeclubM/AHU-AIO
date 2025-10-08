import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/getuserinfo.dart';
import '../../globals.dart' as globals;

class SettingsService extends ChangeNotifier {
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;
  ThemeMode _themeMode = ThemeMode.system;

  Map<String, dynamic>? get userInfo => _userInfo;
  bool get isLoading => _isLoading;
  ThemeMode get themeMode => _themeMode;

  SettingsService() {
    _fetchUserInfo();
    _loadThemeMode();
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
    if (hasListeners) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString('themeMode') ?? 'system';
    _themeMode = _themeModeFromString(themeModeString);
    notifyListeners();
  }

  Future<void> _saveThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', _themeModeToString(themeMode));
  }

  void setThemeMode(ThemeMode themeMode) {
    _themeMode = themeMode;
    _saveThemeMode(themeMode);
    notifyListeners();
  }

  ThemeMode _themeModeFromString(String themeModeString) {
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DarkModeProvider with ChangeNotifier {
  /// 深色模式 0: 关闭 1: 开启 2: 随系统
  int _darkMode = 2;

  int get darkMode => _darkMode;

  DarkModeProvider() {
    _loadDarkMode();
  }

  void changeMode(int darkMode) async {
    _darkMode = darkMode;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('darkMode', darkMode);
  }

  Future<void> _loadDarkMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getInt('darkMode') ?? 2;
    notifyListeners();
  }
}
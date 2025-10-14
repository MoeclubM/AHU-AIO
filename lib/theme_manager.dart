import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager extends ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  String _themeMode = 'system'; // 'system', 'light', 'dark'

  String get themeMode => _themeMode;

  bool isDarkMode(BuildContext context) {
    if (_themeMode == 'dark') return true;
    if (_themeMode == 'light') return false;
    // system mode
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  ThemeMode get themeModeEnum {
    switch (_themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(String mode) async {
    _themeMode = mode;
    notifyListeners();

    // 保存到本地存储
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode);
  }

  Future<void> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('themeMode') ?? 'system';
    if (_themeMode != savedTheme) {
      _themeMode = savedTheme;
      notifyListeners();
    }
  }

  // 获取当前主题模式的中文名称
  String get currentThemeName {
    switch (_themeMode) {
      case 'light':
        return '浅色模式';
      case 'dark':
        return '深色模式';
      default:
        return '跟随系统';
    }
  }
}
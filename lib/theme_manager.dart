import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题颜色模式。
enum ColorMode {
  system, // 跟随系统
  light, // 浅色
  dark, // 深色
  amoled; // AMOLED 纯黑

  static ColorMode fromValue(int v) => ColorMode.values.firstWhere(
    (e) => e.index == v,
    orElse: () => ColorMode.system,
  );

  int get value => index;

  bool get isDark => this == ColorMode.dark || this == ColorMode.amoled;
  bool get isAmoled => this == ColorMode.amoled;
}

/// 预设主色列表，参考 SukiSU Ultra 的 keyColor 选择。
class PresetColors {
  static const List<Color> presets = [
    Color(0xFF3482FF), // miuix 蓝（默认）
    Color(0xFF277AF7), // 深色蓝
    Color(0xFF00BFA5), // 青绿
    Color(0xFFE91E63), // 粉红
    Color(0xFF7B68EE), // 紫罗兰
    Color(0xFFFF6D00), // 橙
    Color(0xFF2E7D32), // 森林绿
    Color(0xFFD32F2F), // 红
    Color(0xFF455A64), // 蓝灰
    Color(0xFF8D6E63), // 棕
  ];

  static const List<String> names = [
    '极客蓝',
    '海洋蓝',
    '青碧',
    '樱花粉',
    '紫罗兰',
    '夕阳橙',
    '森林绿',
    '中国红',
    '岩石灰',
    '大地棕',
  ];
}

class ThemeManager extends ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  ColorMode _colorMode = ColorMode.system;
  Color _keyColor = const Color(0xFF3482FF);

  ColorMode get colorMode => _colorMode;
  Color get keyColor => _keyColor;

  /// 是否为 AMOLED 纯黑模式。
  bool get isAmoled => _colorMode == ColorMode.amoled;

  // --- 向后兼容的 themeMode 字符串接口 ---
  String get themeMode {
    switch (_colorMode) {
      case ColorMode.light:
        return 'light';
      case ColorMode.dark:
        return 'dark';
      case ColorMode.amoled:
        return 'dark'; // AMOLED 归入 dark 的 ThemeMode
      case ColorMode.system:
        return 'system';
    }
  }

  ThemeMode get themeModeEnum {
    switch (_colorMode) {
      case ColorMode.light:
        return ThemeMode.light;
      case ColorMode.dark:
      case ColorMode.amoled:
        return ThemeMode.dark;
      case ColorMode.system:
        return ThemeMode.system;
    }
  }

  String get currentColorModeName {
    switch (_colorMode) {
      case ColorMode.light:
        return '浅色模式';
      case ColorMode.dark:
        return '深色模式';
      case ColorMode.amoled:
        return 'AMOLED 纯黑';
      case ColorMode.system:
        return '跟随系统';
    }
  }

  // 兼容旧接口
  String get currentThemeName => currentColorModeName;

  bool isDarkMode(BuildContext context) {
    if (_colorMode == ColorMode.dark || _colorMode == ColorMode.amoled) {
      return true;
    }
    if (_colorMode == ColorMode.light) return false;
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  Future<void> setColorMode(ColorMode mode) async {
    _colorMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('colorMode', mode.value);
  }

  Future<void> setKeyColor(Color color) async {
    _keyColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('keyColor', color.toARGB32());
  }

  // 兼容旧的 setThemeMode 字符串接口
  Future<void> setThemeMode(String mode) async {
    final cm = switch (mode) {
      'light' => ColorMode.light,
      'dark' => ColorMode.dark,
      _ => ColorMode.system,
    };
    await setColorMode(cm);
  }

  Future<void> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeVal = prefs.getInt('colorMode');
    if (modeVal != null) {
      _colorMode = ColorMode.fromValue(modeVal);
    } else {
      // 兼容旧版字符串存储
      final old = prefs.getString('themeMode') ?? 'system';
      _colorMode = switch (old) {
        'light' => ColorMode.light,
        'dark' => ColorMode.dark,
        _ => ColorMode.system,
      };
    }
    final keyVal = prefs.getInt('keyColor');
    if (keyVal != null) {
      _keyColor = Color(keyVal);
    }
    notifyListeners();
  }
}

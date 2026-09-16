import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题颜色模式。
enum ColorMode {
  system, // 跟随系统
  light, // 浅色
  dark, // 深色
  amoled, // AMOLED 纯黑
  monet; // Monet 动态取色

  static ColorMode fromValue(int v) => ColorMode.values.firstWhere(
    (e) => e.index == v,
    orElse: () => ColorMode.system,
  );

  int get value => index;

  bool get isDark => this == ColorMode.dark || this == ColorMode.amoled;
  bool get isAmoled => this == ColorMode.amoled;
  bool get isMonet => this == ColorMode.monet;
}

/// 界面风格模式，参考 SukiSU Ultra 的 UiMode。
enum UiMode {
  miuix, // Miuix 风格（默认）
  material3; // Material 3 风格

  static UiMode fromValue(String v) =>
      v == 'material3' ? UiMode.material3 : UiMode.miuix;

  String get value => this == UiMode.material3 ? 'material3' : 'miuix';

  String get displayName => this == UiMode.material3 ? 'Material 3' : 'Miuix';
}

/// Material 3 调色板风格（对应 Flutter 的 [DynamicSchemeVariant]）。
///
/// 决定「由种子色推导整套配色」的算法，是 MD3 下最主要的一类样式调整。
/// Miuix 模式不使用该设置。
enum PaletteStyle {
  tonalSpot('色调点', '默认，色彩平衡、低饱和'),
  vibrant('鲜明', '更高饱和度，色彩更抢眼'),
  expressive('表现力', '色彩分布更有个性'),
  fidelity('忠实', '最大程度贴近种子色本身'),
  content('内容', '从种子色提取更多色彩层次'),
  neutral('中性', '近乎灰阶，极低饱和'),
  monochrome('单色', '完全灰阶'),
  rainbow('彩虹', '跨色相的丰富配色'),
  fruitSalad('果缤纷', '相邻色相，活泼明快');

  const PaletteStyle(this.displayName, this.summary);

  final String displayName;
  final String summary;

  DynamicSchemeVariant get variant => switch (this) {
    PaletteStyle.tonalSpot => DynamicSchemeVariant.tonalSpot,
    PaletteStyle.vibrant => DynamicSchemeVariant.vibrant,
    PaletteStyle.expressive => DynamicSchemeVariant.expressive,
    PaletteStyle.fidelity => DynamicSchemeVariant.fidelity,
    PaletteStyle.content => DynamicSchemeVariant.content,
    PaletteStyle.neutral => DynamicSchemeVariant.neutral,
    PaletteStyle.monochrome => DynamicSchemeVariant.monochrome,
    PaletteStyle.rainbow => DynamicSchemeVariant.rainbow,
    PaletteStyle.fruitSalad => DynamicSchemeVariant.fruitSalad,
  };

  static PaletteStyle fromValue(int v) => PaletteStyle.values.firstWhere(
    (e) => e.index == v,
    orElse: () => PaletteStyle.tonalSpot,
  );

  int get value => index;
}

/// 预设主色列表，参考 MIUI / HyperOS 官方经典配色与 SukiSU 的 keyColor。
class PresetColors {
  static const List<Color> presets = [
    Color(0xFF3482FF), // 极客蓝（MIUI / HyperOS 经典蓝）
    Color(0xFF1E88E5), // 海洋蓝
    Color(0xFF00BFA5), // 青碧绿
    Color(0xFF2E7D32), // 翡翠绿
    Color(0xFF00ACC1), // 极光青
    Color(0xFFFF6D00), // 活力橙
    Color(0xFFFFA000), // 琥珀金
    Color(0xFFE91E63), // 樱花粉
    Color(0xFF7B68EE), // 鸢尾紫
    Color(0xFFD32F2F), // 烈焰红
    Color(0xFF455A64), // 玄武灰
    Color(0xFF8D6E63), // 摩卡棕
  ];

  static const List<String> names = [
    '极客蓝',
    '海洋蓝',
    '青碧绿',
    '翡翠绿',
    '极光青',
    '活力橙',
    '琥珀金',
    '樱花粉',
    '鸢尾紫',
    '烈焰红',
    '玄武灰',
    '摩卡棕',
  ];
}

class ThemeManager extends ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  ColorMode _colorMode = ColorMode.system;
  Color _keyColor = const Color(0xFF3482FF);
  UiMode _uiMode = UiMode.miuix;
  PaletteStyle _paletteStyle = PaletteStyle.tonalSpot;
  double _uiScale = 1.0;
  bool _predictiveBack = false;
  bool _enableBlur = true;
  bool _enableLiquidGlass = true;
  bool _enableBottomBarTransparent = true;
  bool _showAppBarTitle = true; // 默认开启

  ColorMode get colorMode => _colorMode;
  Color get keyColor => _keyColor;
  UiMode get uiMode => _uiMode;
  PaletteStyle get paletteStyle => _paletteStyle;

  /// 全局界面缩放（仅作用于文字），范围 0.85–1.30。
  double get uiScale => _uiScale;

  /// 是否启用 Android 预测性返回手势（仅 Android 生效）。
  bool get predictiveBack => _predictiveBack;
  bool get enableBlur => _enableBlur;
  bool get enableLiquidGlass => _enableLiquidGlass;
  bool get enableBottomBarTransparent => _enableBottomBarTransparent;
  bool get showAppBarTitle => _showAppBarTitle;

  bool get isMiuix => _uiMode == UiMode.miuix;
  bool get isMaterial3 => _uiMode == UiMode.material3;

  /// 是否为 AMOLED 纯黑模式。
  bool get isAmoled => _colorMode == ColorMode.amoled;

  // --- 向后兼容的 themeMode 字符串接口 ---
  String get themeMode {
    switch (_colorMode) {
      case ColorMode.light:
        return 'light';
      case ColorMode.dark:
      case ColorMode.amoled:
        return 'dark';
      case ColorMode.system:
      case ColorMode.monet:
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
      case ColorMode.monet:
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
      case ColorMode.monet:
        return '动态壁纸取色';
      case ColorMode.system:
        return '跟随系统';
    }
  }

  String get currentUiModeName => _uiMode.displayName;

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

  Future<void> setUiMode(UiMode mode) async {
    _uiMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uiMode', mode.value);
  }

  Future<void> setPaletteStyle(PaletteStyle style) async {
    _paletteStyle = style;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('paletteStyle', style.value);
  }

  Future<void> setUiScale(double scale) async {
    _uiScale = scale.clamp(0.85, 1.30);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('uiScale', _uiScale);
  }

  Future<void> setPredictiveBack(bool value) async {
    _predictiveBack = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('predictiveBack', value);
  }

  Future<void> setEnableBlur(bool value) async {
    _enableBlur = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableBlur', value);
  }

  Future<void> setEnableLiquidGlass(bool value) async {
    _enableLiquidGlass = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableLiquidGlass', value);
  }

  Future<void> setEnableBottomBarTransparent(bool value) async {
    _enableBottomBarTransparent = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableBottomBarTransparent', value);
  }

  /// 设置主界面是否显示顶部标题栏与通知图标（默认关闭）
  Future<void> setShowAppBarTitle(bool value) async {
    _showAppBarTitle = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showAppBarTitle', value);
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
    final uiModeVal = prefs.getString('uiMode');
    if (uiModeVal != null) {
      _uiMode = UiMode.fromValue(uiModeVal);
    }
    final paletteVal = prefs.getInt('paletteStyle');
    if (paletteVal != null) {
      _paletteStyle = PaletteStyle.fromValue(paletteVal);
    }
    _uiScale = (prefs.getDouble('uiScale') ?? 1.0).clamp(0.85, 1.30);
    _predictiveBack = prefs.getBool('predictiveBack') ?? false;
    _enableBlur = prefs.getBool('enableBlur') ?? true;
    _enableLiquidGlass = prefs.getBool('enableLiquidGlass') ?? true;
    _enableBottomBarTransparent =
        prefs.getBool('enableBottomBarTransparent') ?? true;
    _showAppBarTitle = prefs.getBool('showAppBarTitle') ?? true;
    notifyListeners();
  }
}

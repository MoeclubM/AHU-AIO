import 'package:flutter/material.dart';

/// Miuix 风格配色体系。
///
/// 色值参考 compose-miuix-ui/miuix 的 lightColorScheme() / darkColorScheme()，
/// 在 Flutter 中以 [ColorScheme] 与扩展色 [MiuixColors] 表达。
class MiuixColors extends ThemeExtension<MiuixColors> {
  const MiuixColors({
    required this.primary,
    required this.onPrimary,
    required this.primaryVariant,
    required this.onPrimaryVariant,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryVariant,
    required this.onSecondaryVariant,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.background,
    required this.onBackground,
    required this.onBackgroundVariant,
    required this.surface,
    required this.onSurface,
    required this.surfaceVariant,
    required this.onSurfaceVariant,
    required this.onSurfaceVariantSummary,
    required this.onSurfaceVariantActions,
    required this.surfaceContainer,
    required this.onSurfaceContainer,
    required this.onSurfaceContainerVariant,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.outline,
    required this.dividerLine,
    required this.windowDimming,
  });

  final Color primary;
  final Color onPrimary;
  final Color primaryVariant;
  final Color onPrimaryVariant;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryVariant;
  final Color onSecondaryVariant;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color background;
  final Color onBackground;
  final Color onBackgroundVariant;
  final Color surface;
  final Color onSurface;
  final Color surfaceVariant;
  final Color onSurfaceVariant;
  final Color onSurfaceVariantSummary;
  final Color onSurfaceVariantActions;
  final Color surfaceContainer;
  final Color onSurfaceContainer;
  final Color onSurfaceContainerVariant;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color outline;
  final Color dividerLine;
  final Color windowDimming;

  static const light = MiuixColors(
    primary: Color(0xFF3482FF),
    onPrimary: Color(0xFFFFFFFF),
    primaryVariant: Color(0xFF3482FF),
    onPrimaryVariant: Color(0xFFAECDFF),
    primaryContainer: Color(0xFF5D9BFF),
    onPrimaryContainer: Color(0xFFFFFFFF),
    secondary: Color(0xFFE6E6E6),
    onSecondary: Color(0xFFFFFFFF),
    secondaryVariant: Color(0xFFF0F0F0),
    onSecondaryVariant: Color(0xFF303030),
    secondaryContainer: Color(0xFFF0F0F0),
    onSecondaryContainer: Color(0xFFA9A9A9),
    tertiaryContainer: Color(0xFFEAF2FF),
    onTertiaryContainer: Color(0xFF3482FF),
    background: Color(0xFFFFFFFF),
    onBackground: Color(0xFF000000),
    onBackgroundVariant: Color(0xFF8C93B0),
    surface: Color(0xFFF7F7F7),
    onSurface: Color(0xFF000000),
    surfaceVariant: Color(0xFFFFFFFF),
    onSurfaceVariant: Color(0xCC000000),
    onSurfaceVariantSummary: Color(0x99000000),
    onSurfaceVariantActions: Color(0x66000000),
    surfaceContainer: Color(0xFFFFFFFF),
    onSurfaceContainer: Color(0xFF000000),
    onSurfaceContainerVariant: Color(0xFF959595),
    surfaceContainerHigh: Color(0xFFE8E8E8),
    surfaceContainerHighest: Color(0xFFE8E8E8),
    outline: Color(0xFFD9D9D9),
    dividerLine: Color(0xFFE0E0E0),
    windowDimming: Color(0x4D000000),
  );

  static const dark = MiuixColors(
    primary: Color(0xFF277AF7),
    onPrimary: Color(0xFFFFFFFF),
    primaryVariant: Color(0xFF0073DD),
    onPrimaryVariant: Color(0xFF99C7F1),
    primaryContainer: Color(0xFF0E3A66),
    onPrimaryContainer: Color(0xFFAECDFF),
    secondary: Color(0xFF242424),
    onSecondary: Color(0xFFE6E6E6),
    secondaryVariant: Color(0xFF2D2D2D),
    onSecondaryVariant: Color(0xFFCCCCCC),
    secondaryContainer: Color(0xFF2D2D2D),
    onSecondaryContainer: Color(0xFF737373),
    tertiaryContainer: Color(0xFF0E3A66),
    onTertiaryContainer: Color(0xFFAECDFF),
    background: Color(0xFF000000),
    onBackground: Color(0xE6FFFFFF),
    onBackgroundVariant: Color(0xFF787E96),
    surface: Color(0xFF000000),
    onSurface: Color(0xFFF2F2F2),
    surfaceVariant: Color(0xFF242424),
    onSurfaceVariant: Color(0xCCFFFFFF),
    onSurfaceVariantSummary: Color(0x80FFFFFF),
    onSurfaceVariantActions: Color(0x66FFFFFF),
    surfaceContainer: Color(0xFF242424),
    onSurfaceContainer: Color(0xE6FFFFFF),
    onSurfaceContainerVariant: Color(0xFF737373),
    surfaceContainerHigh: Color(0xFF242424),
    surfaceContainerHighest: Color(0xFF2D2D2D),
    outline: Color(0xFF404040),
    dividerLine: Color(0xFF393939),
    windowDimming: Color(0x99000000),
  );

  static MiuixColors of(BuildContext context) {
    return Theme.of(context).extension<MiuixColors>() ?? _fromColorScheme(Theme.of(context).colorScheme);
  }

  /// 从 [ColorScheme] 派生 [MiuixColors]，用于 Material3 模式下的安全回退。
  static MiuixColors _fromColorScheme(ColorScheme s) {
    final isDark = s.brightness == Brightness.dark;
    return MiuixColors(
      primary: s.primary,
      onPrimary: s.onPrimary,
      primaryVariant: s.primary,
      onPrimaryVariant: s.onPrimaryContainer,
      primaryContainer: s.primaryContainer,
      onPrimaryContainer: s.onPrimaryContainer,
      secondary: s.secondary,
      onSecondary: s.onSecondary,
      secondaryVariant: s.secondaryContainer,
      onSecondaryVariant: s.onSecondaryContainer,
      secondaryContainer: s.secondaryContainer,
      onSecondaryContainer: s.onSecondaryContainer,
      tertiaryContainer: s.tertiaryContainer,
      onTertiaryContainer: s.onTertiaryContainer,
      background: s.surface,
      onBackground: s.onSurface,
      onBackgroundVariant: s.onSurfaceVariant,
      surface: s.surface,
      onSurface: s.onSurface,
      surfaceVariant: s.surfaceContainerHighest,
      onSurfaceVariant: s.onSurfaceVariant,
      onSurfaceVariantSummary: s.onSurfaceVariant.withOpacity(0.7),
      onSurfaceVariantActions: s.onSurfaceVariant.withOpacity(0.5),
      surfaceContainer: s.surfaceContainer,
      onSurfaceContainer: s.onSurface,
      onSurfaceContainerVariant: s.onSurfaceVariant,
      surfaceContainerHigh: s.surfaceContainerHigh,
      surfaceContainerHighest: s.surfaceContainerHighest,
      outline: s.outline,
      dividerLine: s.outlineVariant,
      windowDimming: isDark ? const Color(0x99000000) : const Color(0x4D000000),
    );
  }

  @override
  MiuixColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? primaryVariant,
    Color? onPrimaryVariant,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? secondary,
    Color? onSecondary,
    Color? secondaryVariant,
    Color? onSecondaryVariant,
    Color? secondaryContainer,
    Color? onSecondaryContainer,
    Color? tertiaryContainer,
    Color? onTertiaryContainer,
    Color? background,
    Color? onBackground,
    Color? onBackgroundVariant,
    Color? surface,
    Color? onSurface,
    Color? surfaceVariant,
    Color? onSurfaceVariant,
    Color? onSurfaceVariantSummary,
    Color? onSurfaceVariantActions,
    Color? surfaceContainer,
    Color? onSurfaceContainer,
    Color? onSurfaceContainerVariant,
    Color? surfaceContainerHigh,
    Color? surfaceContainerHighest,
    Color? outline,
    Color? dividerLine,
    Color? windowDimming,
  }) {
    return MiuixColors(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryVariant: primaryVariant ?? this.primaryVariant,
      onPrimaryVariant: onPrimaryVariant ?? this.onPrimaryVariant,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      secondaryVariant: secondaryVariant ?? this.secondaryVariant,
      onSecondaryVariant: onSecondaryVariant ?? this.onSecondaryVariant,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      onSecondaryContainer: onSecondaryContainer ?? this.onSecondaryContainer,
      tertiaryContainer: tertiaryContainer ?? this.tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer ?? this.onTertiaryContainer,
      background: background ?? this.background,
      onBackground: onBackground ?? this.onBackground,
      onBackgroundVariant: onBackgroundVariant ?? this.onBackgroundVariant,
      surface: surface ?? this.surface,
      onSurface: onSurface ?? this.onSurface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      onSurfaceVariantSummary:
          onSurfaceVariantSummary ?? this.onSurfaceVariantSummary,
      onSurfaceVariantActions:
          onSurfaceVariantActions ?? this.onSurfaceVariantActions,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      onSurfaceContainer: onSurfaceContainer ?? this.onSurfaceContainer,
      onSurfaceContainerVariant:
          onSurfaceContainerVariant ?? this.onSurfaceContainerVariant,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      surfaceContainerHighest:
          surfaceContainerHighest ?? this.surfaceContainerHighest,
      outline: outline ?? this.outline,
      dividerLine: dividerLine ?? this.dividerLine,
      windowDimming: windowDimming ?? this.windowDimming,
    );
  }

  @override
  MiuixColors lerp(MiuixColors? other, double t) {
    if (other == null) return this;
    return MiuixColors(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primaryVariant: Color.lerp(primaryVariant, other.primaryVariant, t)!,
      onPrimaryVariant: Color.lerp(
        onPrimaryVariant,
        other.onPrimaryVariant,
        t,
      )!,
      primaryContainer: Color.lerp(
        primaryContainer,
        other.primaryContainer,
        t,
      )!,
      onPrimaryContainer: Color.lerp(
        onPrimaryContainer,
        other.onPrimaryContainer,
        t,
      )!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      secondaryVariant: Color.lerp(
        secondaryVariant,
        other.secondaryVariant,
        t,
      )!,
      onSecondaryVariant: Color.lerp(
        onSecondaryVariant,
        other.onSecondaryVariant,
        t,
      )!,
      secondaryContainer: Color.lerp(
        secondaryContainer,
        other.secondaryContainer,
        t,
      )!,
      onSecondaryContainer: Color.lerp(
        onSecondaryContainer,
        other.onSecondaryContainer,
        t,
      )!,
      tertiaryContainer: Color.lerp(
        tertiaryContainer,
        other.tertiaryContainer,
        t,
      )!,
      onTertiaryContainer: Color.lerp(
        onTertiaryContainer,
        other.onTertiaryContainer,
        t,
      )!,
      background: Color.lerp(background, other.background, t)!,
      onBackground: Color.lerp(onBackground, other.onBackground, t)!,
      onBackgroundVariant: Color.lerp(
        onBackgroundVariant,
        other.onBackgroundVariant,
        t,
      )!,
      surface: Color.lerp(surface, other.surface, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      onSurfaceVariant: Color.lerp(
        onSurfaceVariant,
        other.onSurfaceVariant,
        t,
      )!,
      onSurfaceVariantSummary: Color.lerp(
        onSurfaceVariantSummary,
        other.onSurfaceVariantSummary,
        t,
      )!,
      onSurfaceVariantActions: Color.lerp(
        onSurfaceVariantActions,
        other.onSurfaceVariantActions,
        t,
      )!,
      surfaceContainer: Color.lerp(
        surfaceContainer,
        other.surfaceContainer,
        t,
      )!,
      onSurfaceContainer: Color.lerp(
        onSurfaceContainer,
        other.onSurfaceContainer,
        t,
      )!,
      onSurfaceContainerVariant: Color.lerp(
        onSurfaceContainerVariant,
        other.onSurfaceContainerVariant,
        t,
      )!,
      surfaceContainerHigh: Color.lerp(
        surfaceContainerHigh,
        other.surfaceContainerHigh,
        t,
      )!,
      surfaceContainerHighest: Color.lerp(
        surfaceContainerHighest,
        other.surfaceContainerHighest,
        t,
      )!,
      outline: Color.lerp(outline, other.outline, t)!,
      dividerLine: Color.lerp(dividerLine, other.dividerLine, t)!,
      windowDimming: Color.lerp(windowDimming, other.windowDimming, t)!,
    );
  }
}

/// 计算颜色的相对亮度。
double _luminance(Color c) {
  final r = c.red / 255, g = c.green / 255, b = c.blue / 255;
  return 0.299 * r + 0.587 * g + 0.114 * b;
}

/// 根据 keyColor 派生浅色模式的 primary 系列配色。
MiuixColors _lightFromKeyColor(Color key) {
  final isLightKey = _luminance(key) > 0.7;
  final primary = key;
  final onPrimary = isLightKey
      ? const Color(0xFF000000)
      : const Color(0xFFFFFFFF);
  // tertiaryContainer: 极浅的 key 色背景
  final tertiaryContainer = Color.alphaBlend(
    key.withOpacity(0.12),
    const Color(0xFFFFFFFF),
  );
  return MiuixColors.light.copyWith(
    primary: primary,
    onPrimary: onPrimary,
    primaryVariant: primary,
    onPrimaryVariant: Color.alphaBlend(
      key.withOpacity(0.7),
      const Color(0xFFFFFFFF),
    ),
    primaryContainer: Color.alphaBlend(
      key.withOpacity(0.8),
      const Color(0xFFFFFFFF),
    ),
    tertiaryContainer: tertiaryContainer,
    onTertiaryContainer: primary,
  );
}

/// 根据 keyColor 派生深色模式的 primary 系列配色。
MiuixColors _darkFromKeyColor(Color key) {
  return MiuixColors.dark.copyWith(
    primary: key,
    primaryVariant: key,
    onPrimaryVariant: Color.alphaBlend(
      key.withOpacity(0.5),
      const Color(0xFFFFFFFF),
    ),
    primaryContainer: Color.alphaBlend(
      key.withOpacity(0.25),
      const Color(0xFF000000),
    ),
    onPrimaryContainer: Color.alphaBlend(
      key.withOpacity(0.8),
      const Color(0xFFFFFFFF),
    ),
    tertiaryContainer: Color.alphaBlend(
      key.withOpacity(0.25),
      const Color(0xFF000000),
    ),
    onTertiaryContainer: Color.alphaBlend(
      key.withOpacity(0.8),
      const Color(0xFFFFFFFF),
    ),
  );
}

/// AMOLED 纯黑配色：在深色基础上把 surface 系列推向纯黑。
MiuixColors _amoledFromKeyColor(Color key) {
  return _darkFromKeyColor(key).copyWith(
    background: const Color(0xFF000000),
    surface: const Color(0xFF000000),
    surfaceVariant: const Color(0xFF0A0A0A),
    surfaceContainer: const Color(0xFF0A0A0A),
    surfaceContainerHigh: const Color(0xFF111111),
    surfaceContainerHighest: const Color(0xFF181818),
    secondary: const Color(0xFF0A0A0A),
    secondaryVariant: const Color(0xFF121212),
    secondaryContainer: const Color(0xFF121212),
  );
}

/// 构建 miuix 浅色 [ThemeData]，可传入 [keyColor] 自定义主色。
ThemeData miuixLightTheme({Color? keyColor}) {
  final c = keyColor != null ? _lightFromKeyColor(keyColor) : MiuixColors.light;
  return _buildTheme(c, Brightness.light);
}

/// 构建 miuix 深色 [ThemeData]，可传入 [keyColor] 自定义主色。
ThemeData miuixDarkTheme({Color? keyColor}) {
  final c = keyColor != null ? _darkFromKeyColor(keyColor) : MiuixColors.dark;
  return _buildTheme(c, Brightness.dark);
}

/// 构建 AMOLED 纯黑 [ThemeData]。
ThemeData miuixAmoledTheme({Color? keyColor}) {
  final c = keyColor != null
      ? _amoledFromKeyColor(keyColor)
      : _amoledFromKeyColor(const Color(0xFF277AF7));
  return _buildTheme(c, Brightness.dark);
}

ThemeData _buildTheme(MiuixColors c, Brightness brightness) {
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: c.background,
    canvasColor: c.background,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.tertiaryContainer,
      onPrimaryContainer: c.onTertiaryContainer,
      secondary: c.secondaryVariant,
      onSecondary: c.onSecondaryVariant,
      secondaryContainer: c.secondaryContainer,
      onSecondaryContainer: c.onSecondaryContainer,
      tertiary: c.primary,
      onTertiary: c.onPrimary,
      tertiaryContainer: c.tertiaryContainer,
      onTertiaryContainer: c.onTertiaryContainer,
      error: const Color(0xFFE94634),
      onError: const Color(0xFFFFFFFF),
      errorContainer: const Color(0xFFFDF6F4),
      onErrorContainer: const Color(0xFF410002),
      surface: c.surface,
      onSurface: c.onSurface,
      surfaceContainerHighest: c.surfaceContainerHighest,
      outline: c.outline,
      outlineVariant: c.dividerLine,
      shadow: const Color(0xFF000000),
    ),
    extensions: [c],
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: c.background,
      foregroundColor: c.onBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: c.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: c.outline, width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: DividerThemeData(
      color: c.dividerLine,
      thickness: 0.5,
      space: 0.5,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      height: 64,
      indicatorColor: c.primary.withOpacity(0.12),
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11)),
    ),
  );
}

/// Material 3 浅色主题，基于 keyColor 生成 seed 配色。
ThemeData material3LightTheme({Color? keyColor}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: keyColor ?? const Color(0xFF3482FF),
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 3,
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      elevation: 3,
      height: 64,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11)),
    ),
  );
}

/// Material 3 深色主题。
ThemeData material3DarkTheme({Color? keyColor}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: keyColor ?? const Color(0xFF277AF7),
    brightness: Brightness.dark,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 3,
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      elevation: 3,
      height: 64,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11)),
    ),
  );
}

/// Material 3 AMOLED 纯黑主题。
ThemeData material3AmoledTheme({Color? keyColor}) {
  final base = material3DarkTheme(keyColor: keyColor);
  return base.copyWith(
    scaffoldBackgroundColor: Colors.black,
    colorScheme: base.colorScheme.copyWith(
      surface: Colors.black,
      surfaceContainer: const Color(0xFF0A0A0A),
      surfaceContainerHigh: const Color(0xFF111111),
      surfaceContainerHighest: const Color(0xFF181818),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.black,
      foregroundColor: Color(0xE6FFFFFF),
      elevation: 0,
      scrolledUnderElevation: 3,
    ),
  );
}
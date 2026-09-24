import 'package:flutter/material.dart';

import 'miuix_kit.dart';

// 统一出口：令牌、主题与自研组件一起暴露，使用方只需 import 本文件。
export 'miuix_kit.dart';
export 'miuix_tokens.dart';

/// AMOLED 纯黑配色方案：基于 Miuix 深色体系将 surface/background 等推向纯黑。
MiuixColors amoledColorScheme({Color? keyColor}) {
  final base = keyColor != null
      ? miuixColorsFromSeed(seed: keyColor, dark: true)
      : darkColorScheme();
  return base.copy(
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

/// 构建 Miuix 浅色 ThemeData。
ThemeData miuixLightTheme({Color? keyColor}) {
  final c = keyColor != null
      ? miuixColorsFromSeed(seed: keyColor, dark: false)
      : lightColorScheme();
  return _buildMiuixTheme(c, Brightness.light, isDynamic: keyColor != null);
}

/// 构建 Miuix 深色 ThemeData。
ThemeData miuixDarkTheme({Color? keyColor}) {
  final c = keyColor != null
      ? miuixColorsFromSeed(seed: keyColor, dark: true)
      : darkColorScheme();
  return _buildMiuixTheme(c, Brightness.dark, isDynamic: keyColor != null);
}

/// 构建 Miuix AMOLED 纯黑 ThemeData。
ThemeData miuixAmoledTheme({Color? keyColor}) {
  final c = amoledColorScheme(keyColor: keyColor);
  return _buildMiuixTheme(c, Brightness.dark, isDynamic: keyColor != null);
}

ThemeData _buildMiuixTheme(
  MiuixColors c,
  Brightness brightness, {
  bool isDynamic = false,
}) {
  final MiuixTextStyles ts = defaultTextStyles();
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: c.background,
    canvasColor: c.background,
    // 文本体系整体换成 Miuix 规格：未显式指定样式的 Text 与
    // `Theme.of(context).textTheme.*` 都拿到 HyperOS 的字号与前景色。
    textTheme: TextTheme(
      displayLarge: ts.title1.copyWith(color: c.onBackground),
      displayMedium: ts.title2.copyWith(color: c.onBackground),
      displaySmall: ts.title3.copyWith(color: c.onBackground),
      headlineLarge: ts.title3.copyWith(color: c.onBackground),
      headlineMedium: ts.title4.copyWith(color: c.onBackground),
      headlineSmall: ts.headline2.copyWith(color: c.onBackground),
      titleLarge: ts.headline1.copyWith(color: c.onBackground),
      titleMedium: ts.headline2.copyWith(color: c.onBackground),
      titleSmall: ts.subtitle.copyWith(color: c.onBackgroundVariant),
      bodyLarge: ts.main.copyWith(color: c.onBackground),
      bodyMedium: ts.body1.copyWith(color: c.onBackground),
      bodySmall: ts.body2.copyWith(color: c.onSurfaceVariantSummary),
      labelLarge: ts.button.copyWith(color: c.onBackground),
      labelMedium: ts.footnote1.copyWith(color: c.onSurfaceVariantSummary),
      labelSmall: ts.footnote2.copyWith(color: c.onSurfaceVariantSummary),
    ),
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.primaryContainer,
      onPrimaryContainer: c.onPrimaryContainer,
      secondary: c.secondary,
      onSecondary: c.onSecondary,
      secondaryContainer: c.secondaryContainer,
      onSecondaryContainer: c.onSecondaryContainer,
      tertiary: c.primary,
      onTertiary: c.onPrimary,
      tertiaryContainer: c.tertiaryContainer,
      onTertiaryContainer: c.onTertiaryContainer,
      error: c.error,
      onError: c.onError,
      errorContainer: c.errorContainer,
      onErrorContainer: c.onErrorContainer,
      surface: c.surface,
      onSurface: c.onSurface,
      onSurfaceVariant: c.onSurfaceVariantActions,
      surfaceContainer: c.surfaceContainer,
      surfaceContainerHigh: c.surfaceContainerHigh,
      surfaceContainerHighest: c.surfaceContainerHighest,
      outline: c.outline,
      outlineVariant: c.dividerLine,
      shadow: const Color(0xFF000000),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: c.background,
      foregroundColor: c.onBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontSize: ts.title3.fontSize,
        fontWeight: FontWeight.w500,
        color: c.onBackground,
      ),
    ),
    cardTheme: CardThemeData(
      color: c.surfaceContainer,
      elevation: 0,
      shape: MiuixSquircleBorder(
        cornerRadius: 16,
        side: BorderSide(color: c.outline, width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: DividerThemeData(
      color: c.dividerLine,
      thickness: 0.5,
      space: 0.5,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: c.primary,
      unselectedLabelColor: c.onSurfaceVariantActions,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      overlayColor: WidgetStateProperty.all(c.primary.withOpacity(0.08)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surfaceContainer,
      elevation: 0,
      shape: const MiuixSquircleBorder(cornerRadius: 24),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: c.onSurface,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      height: 64,
      indicatorColor: c.primary.withOpacity(0.12),
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surfaceContainerHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.outline, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.outline, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.primary, width: 1.5),
      ),
      hintStyle: TextStyle(color: c.onSurfaceVariantSummary, fontSize: 14),
      labelStyle: TextStyle(color: c.onSurfaceVariantActions, fontSize: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return c.disabledPrimaryButton;
          }
          return c.primary;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return c.disabledOnPrimaryButton;
          }
          return c.onPrimary;
        }),
        shape: const WidgetStatePropertyAll(
          MiuixSquircleBorder(cornerRadius: 16),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return c.disabledSecondaryVariant;
          }
          return c.secondaryVariant;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return c.disabledOnSecondaryVariant;
          }
          return c.onSecondaryVariant;
        }),
        shape: const WidgetStatePropertyAll(
          MiuixSquircleBorder(cornerRadius: 16),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        elevation: const WidgetStatePropertyAll(0),
        side: WidgetStatePropertyAll(BorderSide(color: c.outline, width: 0.5)),
        shape: const WidgetStatePropertyAll(
          MiuixSquircleBorder(cornerRadius: 16),
        ),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return c.disabledPrimary;
          }
          return c.primary;
        }),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        elevation: const WidgetStatePropertyAll(0),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return c.disabledPrimary;
          }
          return c.primary;
        }),
        shape: const WidgetStatePropertyAll(
          MiuixSquircleBorder(cornerRadius: 12),
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      disabledElevation: 0,
      highlightElevation: 0,
      shape: const MiuixSquircleBorder(cornerRadius: 18),
      backgroundColor: c.primary,
      foregroundColor: c.onPrimary,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return c.primary;
        return Colors.transparent;
      }),
      checkColor: WidgetStatePropertyAll(c.onPrimary),
      side: BorderSide(color: c.outline, width: 1.5),
      shape: const MiuixSquircleBorder(cornerRadius: 6),
    ),
  );
}

/// Material 3 形状刻度（官方 corner radius tokens，单位 dp）。
abstract final class M3ShapeScale {
  static const double extraSmall = 4;
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double extraLarge = 28;

  /// 按钮族胶囊圆角（完整半圆）。
  static const double full = 100;
}

/// Material 3 字阶（Type Scale，官方 text appearance tokens）。
///
/// Flutter 的 [TextTheme] 字段与 M3 角色一一对应；这里固定字号/字重/行高，
/// 避免各版本 ThemeData 默认值漂移。
TextTheme m3TextTheme(Brightness brightness, ColorScheme scheme) {
  // brightness 保留签名一致性；颜色一律从 scheme 取，避免暗色下写死。
  Color ink() => scheme.onSurface;
  Color muted() => scheme.onSurfaceVariant;

  return TextTheme(
    displayLarge: TextStyle(
      fontSize: 57,
      height: 64 / 57,
      fontWeight: FontWeight.w400,
      color: ink(),
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      height: 52 / 45,
      fontWeight: FontWeight.w400,
      color: ink(),
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      height: 44 / 36,
      fontWeight: FontWeight.w400,
      color: ink(),
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      height: 40 / 32,
      fontWeight: FontWeight.w400,
      color: ink(),
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      height: 36 / 28,
      fontWeight: FontWeight.w400,
      color: ink(),
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      height: 32 / 24,
      fontWeight: FontWeight.w400,
      color: ink(),
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      height: 28 / 22,
      fontWeight: FontWeight.w400,
      color: ink(),
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      color: ink(),
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: ink(),
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      color: ink(),
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: ink(),
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      color: muted(),
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: ink(),
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: muted(),
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      height: 16 / 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: muted(),
    ),
  );
}

/// Material 3 主题基座：种子取色 + 显式字阶/形状刻度。
ThemeData _material3Base({
  required Color seed,
  required Brightness brightness,
  DynamicSchemeVariant variant = DynamicSchemeVariant.tonalSpot,
}) {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
    dynamicSchemeVariant: variant,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    textTheme: m3TextTheme(brightness, scheme),
    // 形状刻度对齐 M3：卡片 large(16)、按钮 medium(12)/large(16)、
    // 对话框 extraLarge(28)、输入框 extraSmall(4) 由组件默认承担。
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(M3ShapeScale.large),
      ),
      elevation: 1,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(M3ShapeScale.extraLarge),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(M3ShapeScale.full),
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(M3ShapeScale.full),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(M3ShapeScale.full),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(M3ShapeScale.full),
        ),
      ),
    ),
    // M3 状态层：按压/悬停用 primary 的 8%/10%（框架 overlay 默认已接近）。
    splashFactory: InkSparkle.splashFactory,
  );
}

/// Material 3 浅色主题：种子取色 + 显式 M3 字阶/形状刻度。
ThemeData material3LightTheme({
  Color? keyColor,
  DynamicSchemeVariant variant = DynamicSchemeVariant.tonalSpot,
}) {
  return _material3Base(
    seed: keyColor ?? const Color(0xFF3482FF),
    brightness: Brightness.light,
    variant: variant,
  );
}

/// Material 3 深色主题：同浅色。
ThemeData material3DarkTheme({
  Color? keyColor,
  DynamicSchemeVariant variant = DynamicSchemeVariant.tonalSpot,
}) {
  return _material3Base(
    seed: keyColor ?? const Color(0xFF277AF7),
    brightness: Brightness.dark,
    variant: variant,
  );
}

/// Material 3 AMOLED 纯黑主题：把 surface 族压到纯黑，其余令牌从原方案派生。
///
/// 只动「容器有多黑」，不动前景色与语义色——`onSurface` 等仍取原 scheme，
/// 保证对比度语义不被绕过。
ThemeData material3AmoledTheme({
  Color? keyColor,
  DynamicSchemeVariant variant = DynamicSchemeVariant.tonalSpot,
}) {
  final base = material3DarkTheme(keyColor: keyColor, variant: variant);
  return base.copyWith(
    scaffoldBackgroundColor: base.colorScheme.surfaceContainerLowest,
    colorScheme: base.colorScheme.copyWith(
      surface: const Color(0xFF000000),
      surfaceContainerLowest: const Color(0xFF000000),
      surfaceContainerLow: const Color(0xFF0A0A0A),
      surfaceContainer: const Color(0xFF0F0F0F),
      surfaceContainerHigh: const Color(0xFF161616),
      surfaceContainerHighest: const Color(0xFF1D1D1D),
    ),
  );
}

/// 控制 Android 的页面转场风格。
///
/// 开启预测性返回时用框架默认（Flutter 3.44 的 Android 默认即
/// `FadeForwardsPageTransitionsBuilder` + 返回手势联动，需配合 manifest 的
/// `enableOnBackInvokedCallback`）；关闭时也保持 M3 的淡入前进转场，
/// **不再退回 Material 2 时代的 Zoom**。其余平台不设置，保持各自原生转场。
ThemeData withPredictiveBack(ThemeData base, bool enabled) {
  if (enabled) return base;
  return base.copyWith(
    pageTransitionsTheme: PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: const FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}

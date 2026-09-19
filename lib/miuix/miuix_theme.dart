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
  return _buildMiuixTheme(c, Brightness.light);
}

/// 构建 Miuix 深色 ThemeData。
ThemeData miuixDarkTheme({Color? keyColor}) {
  final c = keyColor != null
      ? miuixColorsFromSeed(seed: keyColor, dark: true)
      : darkColorScheme();
  return _buildMiuixTheme(c, Brightness.dark);
}

/// 构建 Miuix AMOLED 纯黑 ThemeData。
ThemeData miuixAmoledTheme({Color? keyColor}) {
  final c = amoledColorScheme(keyColor: keyColor);
  return _buildMiuixTheme(c, Brightness.dark);
}

ThemeData _buildMiuixTheme(MiuixColors c, Brightness brightness) {
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
  );
}

/// Material 3 浅色主题：完全使用框架默认值，仅固定种子色、调色板风格与居中标题。
/// Material 3 浅色主题：**完全交给框架默认值**。
///
/// 只固定种子色与调色板推导算法；顶栏标题对齐、高度、转场等一律不覆盖，
/// 由 Flutter 按平台与 M3 规范决定（Android 上标题左对齐、工具栏高 64）。
ThemeData material3LightTheme({
  Color? keyColor,
  DynamicSchemeVariant variant = DynamicSchemeVariant.tonalSpot,
}) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: keyColor ?? const Color(0xFF3482FF),
      brightness: Brightness.light,
      dynamicSchemeVariant: variant,
    ),
  );
}

/// Material 3 深色主题：同浅色，只用框架默认值。
ThemeData material3DarkTheme({
  Color? keyColor,
  DynamicSchemeVariant variant = DynamicSchemeVariant.tonalSpot,
}) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: keyColor ?? const Color(0xFF277AF7),
      brightness: Brightness.dark,
      dynamicSchemeVariant: variant,
    ),
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

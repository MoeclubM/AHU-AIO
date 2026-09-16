import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter_miuix/miuix.dart';

export 'package:flutter_miuix/miuix.dart';

/// 上下文扩展，方便快速获取 Miuix 主题与配色。
extension MiuixContextExt on BuildContext {
  MiuixThemeData get miuixTheme => MiuixTheme.of(this);
  MiuixColors get miuixColors => MiuixTheme.of(this).colors;
}

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
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: c.background,
    canvasColor: c.background,
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
        fontSize: 17,
        fontWeight: FontWeight.w600,
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
  );
}

/// Material 3 浅色主题：完全使用框架默认值，仅固定种子色、调色板风格与居中标题。
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
    appBarTheme: const AppBarTheme(centerTitle: true),
  );
}

/// Material 3 深色主题。
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
    appBarTheme: const AppBarTheme(centerTitle: true),
  );
}

/// Material 3 AMOLED 纯黑主题：仅把 surface 系列压到纯黑，其余保持默认。
ThemeData material3AmoledTheme({
  Color? keyColor,
  DynamicSchemeVariant variant = DynamicSchemeVariant.tonalSpot,
}) {
  final base = material3DarkTheme(keyColor: keyColor, variant: variant);
  return base.copyWith(
    scaffoldBackgroundColor: Colors.black,
    colorScheme: base.colorScheme.copyWith(
      surface: Colors.black,
      surfaceContainerLowest: Colors.black,
      surfaceContainer: const Color(0xFF0A0A0A),
      surfaceContainerHigh: const Color(0xFF111111),
      surfaceContainerHighest: const Color(0xFF181818),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.black,
      foregroundColor: Color(0xE6FFFFFF),
    ),
  );
}

/// 按设置选择 Android 的页面转场。
///
/// 开启时使用预测性返回转场（需配合 manifest 的 `enableOnBackInvokedCallback`，
/// 这也是 Flutter 3.44 的 Android 默认值）；关闭时退回传统缩放转场。
/// 其余平台显式保持框架默认，避免 iOS / 桌面端转场退化。
ThemeData withPredictiveBack(ThemeData base, bool enabled) {
  if (!enabled) {
    return base.copyWith(
      pageTransitionsTheme: PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: const ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: const CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: const ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: const ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
  // 开启时即框架默认，无需改动。
  return base;
}

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
      error: c.error,
      onError: c.onError,
      errorContainer: c.errorContainer,
      onErrorContainer: c.onErrorContainer,
      surface: c.surface,
      onSurface: c.onSurface,
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

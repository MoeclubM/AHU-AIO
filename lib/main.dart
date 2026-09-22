import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'dart:io';
import 'theme_manager.dart';
import 'auth/auth_manager.dart';
import 'miuix/liquid_glass_layer.dart';
import 'miuix/miuix_theme.dart';
import 'main_layout_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    WebViewPlatform.instance = AndroidWebViewPlatform();
  }

  final themeManager = ThemeManager();
  await themeManager.loadThemeMode();
  await AuthManager().loadConfig();
  // 预加载液态玻璃着色器，避免底栏首帧缺少边缘高光。
  await preloadLiquidGlassShaders();

  runApp(MyApp(themeManager: themeManager));
}

class MyApp extends StatelessWidget {
  final ThemeManager themeManager;

  const MyApp({super.key, required this.themeManager});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return AnimatedBuilder(
          animation: themeManager,
          builder: (context, child) {
            final Color effectiveKeyColor =
                (themeManager.colorMode == ColorMode.monet &&
                    lightDynamic != null)
                ? lightDynamic.primary
                : themeManager.keyColor;

            final ThemeData light;
            final ThemeData dark;
            final MiuixColors miuixLightColors;
            final MiuixColors miuixDarkColors;

            if (themeManager.isMiuix) {
              miuixLightColors = miuixColorsFromSeed(
                seed: effectiveKeyColor,
                dark: false,
              );
              miuixDarkColors = themeManager.isAmoled
                  ? amoledColorScheme(keyColor: effectiveKeyColor)
                  : miuixColorsFromSeed(seed: effectiveKeyColor, dark: true);
              light = miuixLightTheme(keyColor: effectiveKeyColor);
              dark = themeManager.isAmoled
                  ? miuixAmoledTheme(keyColor: effectiveKeyColor)
                  : miuixDarkTheme(keyColor: effectiveKeyColor);
            } else {
              miuixLightColors = lightColorScheme();
              miuixDarkColors = darkColorScheme();
              if (themeManager.colorMode == ColorMode.monet &&
                  lightDynamic != null &&
                  darkDynamic != null) {
                // 动态取色：只换 ColorScheme，其余全部走框架默认。
                light = ThemeData(colorScheme: lightDynamic);
                dark = themeManager.isAmoled
                    ? material3AmoledTheme(keyColor: effectiveKeyColor)
                    : ThemeData(colorScheme: darkDynamic);
              } else {
                light = material3LightTheme(
                  keyColor: effectiveKeyColor,
                  variant: themeManager.paletteStyle.variant,
                );
                dark = themeManager.isAmoled
                    ? material3AmoledTheme(
                        keyColor: effectiveKeyColor,
                        variant: themeManager.paletteStyle.variant,
                      )
                    : material3DarkTheme(
                        keyColor: effectiveKeyColor,
                        variant: themeManager.paletteStyle.variant,
                      );
              }
            }

            // 预测性返回手势（仅 Android 生效），与全局界面缩放一起在根部应用。
            final ThemeData effectiveLight = withPredictiveBack(
              light,
              themeManager.predictiveBack,
            );
            final ThemeData effectiveDark = withPredictiveBack(
              dark,
              themeManager.predictiveBack,
            );

            final systemBrightness =
                MediaQuery.maybePlatformBrightnessOf(context) ??
                WidgetsBinding.instance.platformDispatcher.platformBrightness;
            final currentBrightness = themeManager.colorMode == ColorMode.light
                ? Brightness.light
                : (themeManager.colorMode.isDark
                      ? Brightness.dark
                      : systemBrightness);

            return MiuixTheme(
              data: MiuixThemeData.of(
                currentBrightness,
                lightColors: miuixLightColors,
                darkColors: miuixDarkColors,
              ),
              child: GetMaterialApp(
                title: 'AHU AIO',
                debugShowCheckedModeBanner: false,
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('zh', 'CN'),
                  Locale('en', 'US'),
                ],
                theme: effectiveLight,
                darkTheme: effectiveDark,
                themeMode: themeManager.themeModeEnum,
                builder: (context, child) {
                  final mediaQuery = MediaQuery.of(context);
                  // 界面缩放：在系统文字缩放之上叠加用户设置的比例。
                  final double scale =
                      mediaQuery.textScaler.scale(1) * themeManager.uiScale;
                  return MediaQuery(
                    data: mediaQuery.copyWith(
                      textScaler: TextScaler.linear(scale),
                    ),
                    child: child ?? const SizedBox.shrink(),
                  );
                },
                home: const MainLayoutScreen(),
              ),
            );
          },
        );
      },
    );
  }
}

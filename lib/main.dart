import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'dart:io';
import 'theme_manager.dart';
import 'miuix/miuix_theme.dart';
import 'main_layout_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    WebViewPlatform.instance = AndroidWebViewPlatform();
  } else if (Platform.isIOS) {
    WebViewPlatform.instance = WebKitWebViewPlatform();
  }

  final themeManager = ThemeManager();
  await themeManager.loadThemeMode();

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
                  : miuixColorsFromSeed(
                      seed: effectiveKeyColor,
                      dark: true,
                    );
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
                light = ThemeData(
                  useMaterial3: true,
                  colorScheme: lightDynamic,
                  appBarTheme: AppBarTheme(
                    centerTitle: true,
                    backgroundColor: lightDynamic.surface,
                    foregroundColor: lightDynamic.onSurface,
                    elevation: 0,
                  ),
                );
                dark = themeManager.isAmoled
                    ? material3AmoledTheme(keyColor: effectiveKeyColor)
                    : ThemeData(
                        useMaterial3: true,
                        colorScheme: darkDynamic,
                        appBarTheme: AppBarTheme(
                          centerTitle: true,
                          backgroundColor: darkDynamic.surface,
                          foregroundColor: darkDynamic.onSurface,
                          elevation: 0,
                        ),
                      );
              } else {
                light = material3LightTheme(keyColor: effectiveKeyColor);
                dark = themeManager.isAmoled
                    ? material3AmoledTheme(keyColor: effectiveKeyColor)
                    : material3DarkTheme(keyColor: effectiveKeyColor);
              }
            }

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
                theme: light,
                darkTheme: dark,
                themeMode: themeManager.themeModeEnum,
                home: const MainLayoutScreen(),
              ),
            );
          },
        );
      },
    );
  }
}

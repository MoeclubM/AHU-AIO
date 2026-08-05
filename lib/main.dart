import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
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
    return AnimatedBuilder(
      animation: themeManager,
      builder: (context, child) {
        final light = miuixLightTheme(keyColor: themeManager.keyColor);
        final dark = themeManager.isAmoled
            ? miuixAmoledTheme(keyColor: themeManager.keyColor)
            : miuixDarkTheme(keyColor: themeManager.keyColor);
        return GetMaterialApp(
          title: 'AHU AIO',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
          theme: light,
          darkTheme: dark,
          themeMode: themeManager.themeModeEnum,
          home: const MainLayoutScreen(),
        );
      },
    );
  }
}
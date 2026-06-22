import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'dart:io';
import 'theme_manager.dart';
import 'main_layout_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化WebView平台实现
  if (Platform.isAndroid) {
    WebViewPlatform.instance = AndroidWebViewPlatform();
  } else if (Platform.isIOS) {
    WebViewPlatform.instance = WebKitWebViewPlatform();
  }

  // 初始化主题管理器
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
        return GetMaterialApp(
          title: 'AHU AIO',
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
          theme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.light,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.dark,
            useMaterial3: true,
          ),
          themeMode: themeManager.themeModeEnum,
          home: const MainLayoutScreen(),
        );
      },
    );
  }
}

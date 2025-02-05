import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dark_mode_provider.dart';
import 'jw/login/login_view.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DarkModeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DarkModeProvider>(
      builder: (context, darkModeProvider, child) {
        return MaterialApp(
          title: 'AHU 教务系统',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.dark,
          ),
          themeMode: darkModeProvider.darkMode == 2
              ? ThemeMode.system
              : darkModeProvider.darkMode == 1
                  ? ThemeMode.dark
                  : ThemeMode.light,
          home: const LoginPage(),
        );
      },
    );
  }
}
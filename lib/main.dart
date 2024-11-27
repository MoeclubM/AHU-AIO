import 'package:flutter/material.dart';
import 'login/login_page.dart'; // 引入登录页面

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      themeMode: ThemeMode.system, // 根据系统设置切换主题
      home: const LoginPage(), // 设置登录页面为启动页
    );
  }
}
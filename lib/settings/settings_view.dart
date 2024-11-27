import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login/login_page.dart';
import 'settings_service.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('idToken');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsService(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('设置'),
        ),
        body: Consumer<SettingsService>(
          builder: (context, logic, child) {
            if (logic.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (logic.userInfo == null) {
              return const Center(child: Text('无法获取用户信息'));
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserInfo(logic.userInfo!),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _logout(context),
                    child: const Text('登出'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserInfo(Map<String, dynamic> userInfo) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('姓名: ${userInfo['user']['nameZh']}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('学号: ${userInfo['account']}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('性别: ${userInfo['gender']['nameZh']}', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
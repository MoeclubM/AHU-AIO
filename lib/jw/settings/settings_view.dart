import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login/login_view.dart';
import '../api/getuserinfo.dart';
import '../../theme_manager.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ThemeManager _themeManager = ThemeManager();

  @override
  void initState() {
    super.initState();
    // 监听主题管理器的变化
    _themeManager.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    // 移除监听器
    _themeManager.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleThemeMode(String mode) async {
    await _themeManager.setThemeMode(mode);
  }

  bool get _isDarkMode {
    return _themeManager.isDarkMode(context);
  }

  String get _currentThemeMode {
    return _themeManager.themeMode;
  }

  Future<Map<String, dynamic>?> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final String? idToken = prefs.getString('idToken');

    if (idToken != null) {
      try {
        return await getUserInfo(idToken);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('idToken');

    if (!context.mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const JWLoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: FutureBuilder(
        future: _loadUserInfo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('加载用户信息中...'),
                ],
              ),
            );
          }

          if (snapshot.hasError || snapshot.data == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48),
                  SizedBox(height: 16),
                  Text('无法获取用户信息'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserInfo(snapshot.data!),
                const SizedBox(height: 16),
                _buildThemeModeSelector(context),
                const SizedBox(height: 16),
                _buildLogoutButton(context),
                const SizedBox(height: 16),
                _buildAppInfo(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildThemeModeSelector(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '主题模式',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            RadioListTile<String>(
              title: const Text('跟随系统'),
              value: 'system',
              groupValue: _currentThemeMode,
              onChanged: (value) => _toggleThemeMode(value!),
            ),
            RadioListTile<String>(
              title: const Text('浅色模式'),
              value: 'light',
              groupValue: _currentThemeMode,
              onChanged: (value) => _toggleThemeMode(value!),
            ),
            RadioListTile<String>(
              title: const Text('深色模式'),
              value: 'dark',
              groupValue: _currentThemeMode,
              onChanged: (value) => _toggleThemeMode(value!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(Map<String, dynamic> userInfo) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '个人信息',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('姓名'),
              subtitle: Text(userInfo['user']['nameZh'] ?? '未知'),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              title: const Text('学号'),
              subtitle: Text(userInfo['account'] ?? '未知'),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              title: const Text('性别'),
              subtitle: Text(userInfo['gender']['nameZh'] ?? '未知'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(context),
        icon: const Icon(Icons.logout),
        label: const Text('退出登录'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认退出'),
          content: const Text('您确定要退出登录吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('确认退出'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppInfo() {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '关于应用',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildInfoItem('应用名称', 'AHU-AIO'),
            const SizedBox(height: 8),
            _buildInfoItem('版本', '1.0.0'),
            const SizedBox(height: 8),
            _buildInfoItem('开发者', 'MoeCaa'),
            const SizedBox(height: 8),
            _buildInfoItem('许可证', 'MIT License'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
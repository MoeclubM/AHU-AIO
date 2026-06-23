import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'globals.dart' as globals;
import 'theme_manager.dart';
import 'jw/login/jw_login_service.dart';
import 'finance/api/synjones_client.dart';
import 'auth/cas_auth_cache.dart';

class AppSettingsScreen extends StatefulWidget {
  final ValueChanged<int> onSwitchTab;
  const AppSettingsScreen({super.key, required this.onSwitchTab});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  final _themeManager = ThemeManager();
  final _synjonesClient = SynjonesClient();

  @override
  void initState() {
    super.initState();
  }

  void _globalLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('password');
    await prefs.setBool('savePassword', false);
    await prefs.remove('idToken');
    await prefs.remove('jwStudentNo');

    globals.idToken = null;
    globals.jwLoggedIn = false;
    globals.jwStudentNo = null;

    await JwLoginService.logout();
    await _synjonesClient.logout();
    await CasAuthCache.clear();

    globals.onLoginStateChanged?.call();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('系统设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Section
          _buildSectionHeader('外观设置'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('主题模式'),
                  subtitle: Text(_themeManager.currentThemeName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showThemeDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Accounts Section
          _buildSectionHeader('账号与登录状态'),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilledButton.icon(
              onPressed: _globalLogout,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text(
                '退出登录 (清除所有账号与缓存)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择主题模式'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('跟随系统'),
                value: 'system',
                groupValue: _themeManager.themeMode,
                onChanged: (value) async {
                  if (value != null) {
                    await _themeManager.setThemeMode(value);
                    if (context.mounted) Navigator.pop(context);
                    setState(() {});
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('浅色模式'),
                value: 'light',
                groupValue: _themeManager.themeMode,
                onChanged: (value) async {
                  if (value != null) {
                    await _themeManager.setThemeMode(value);
                    if (context.mounted) Navigator.pop(context);
                    setState(() {});
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('深色模式'),
                value: 'dark',
                groupValue: _themeManager.themeMode,
                onChanged: (value) async {
                  if (value != null) {
                    await _themeManager.setThemeMode(value);
                    if (context.mounted) Navigator.pop(context);
                    setState(() {});
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

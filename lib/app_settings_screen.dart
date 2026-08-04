import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'globals.dart' as globals;
import 'miuix/miuix_theme.dart';
import 'miuix/miuix_components.dart';
import 'miuix/liquid_glass_card.dart';
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 148),
        children: [
          const MiuixSmallTitle('外观设置'),
          LiquidGlassCard(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              children: [
                MiuixComponent(
                  title: '主题模式',
                  summary: _themeManager.currentThemeName,
                  leading: Icon(
                    Icons.palette_outlined,
                    color: MiuixColors.of(context).primary,
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: MiuixColors.of(context).onSurfaceVariantActions,
                  ),
                  onTap: () => _showThemeDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const MiuixSmallTitle('账号与登录状态'),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: MiuixDangerButton(
              onPressed: _globalLogout,
              icon: const Icon(Icons.logout_rounded),
              minimumSize: const Size.fromHeight(52),
              child: const Text(
                '退出登录 (清除所有账号与缓存)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
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

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'globals.dart' as globals;
import 'miuix/miuix_components.dart';
import 'miuix/liquid_glass_card.dart';
import 'theme_manager.dart';
import 'theme_settings_screen.dart';
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
    _themeManager.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeManager.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
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
    final mc = MiuixTheme.of(context).colors;
    return Scaffold(
      appBar: AppBar(title: const Text('系统设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 148),
        children: [
          const MiuixSmallTitle('个性化与显示'),
          LiquidGlassCard(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              children: [
                MiuixComponent(
                  title: '个性化与主题',
                  summary:
                      '${_themeManager.currentUiModeName} · ${_themeManager.currentColorModeName}',
                  leading: Icon(Icons.palette_outlined, color: mc.primary),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildKeyColorDot(),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.chevron_right,
                        color: mc.onSurfaceVariantActions,
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ThemeSettingsScreen(),
                      ),
                    );
                  },
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

  Widget _buildKeyColorDot() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: _themeManager.colorMode == ColorMode.monet
            ? MiuixTheme.of(context).colors.primary
            : _themeManager.keyColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: MiuixTheme.of(context).colors.outline,
          width: 1.5,
        ),
      ),
    );
  }
}

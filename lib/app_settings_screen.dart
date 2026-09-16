import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'globals.dart' as globals;
import 'adaptive_ui.dart';
import 'theme_manager.dart';
import 'theme_settings_screen.dart';
import 'widget_settings_screen.dart';
import 'advanced_settings_screen.dart';
import 'auth/auth_manager.dart';
import 'jw/login/jw_login_service.dart';
import 'finance/api/synjones_client.dart';
import 'auth/cas_auth_cache.dart';
import 'miuix/liquid_glass_app_bar.dart';

class AppSettingsScreen extends StatefulWidget {
  final ValueChanged<int> onSwitchTab;
  const AppSettingsScreen({super.key, required this.onSwitchTab});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  final _themeManager = ThemeManager();
  final _authManager = AuthManager();
  final _synjonesClient = SynjonesClient();

  @override
  void initState() {
    super.initState();
    _themeManager.addListener(_onThemeChanged);
    _authManager.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeManager.removeListener(_onThemeChanged);
    _authManager.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  void _globalLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('password');
    await prefs.remove('jwapp_password');
    await prefs.remove('jw_password');
    await prefs.remove('finance_password');
    await prefs.setBool('savePassword', false);
    await prefs.remove('idToken');
    await prefs.remove('jwStudentNo');

    await _authManager.clearAllPasswords();
    await _authManager.setBehavior(AuthBehavior.unified);

    globals.username = null;
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

  void _open(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chevron = Icon(Icons.chevron_right, color: scheme.onSurfaceVariant);

    return Scaffold(
      appBar: const LiquidGlassAppBar(title: '系统设置'),
      body: ListView(
        padding: adaptivePagePadding(
          context,
          top: 8,
          bottom: adaptiveBottomPadding(context, withSubBar: false),
        ),
        children: [
          const AdaptiveSectionTitle('个性化与显示'),
          AdaptiveCard(
            child: AdaptiveSettingsTile(
              title: '个性化与主题',
              summary:
                  '${_themeManager.currentUiModeName} · ${_themeManager.currentColorModeName}',
              leading: Icon(Icons.palette_outlined, color: scheme.primary),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _themeManager.colorMode == ColorMode.monet
                          ? scheme.primary
                          : _themeManager.keyColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.outline, width: 1),
                    ),
                  ),
                  const SizedBox(width: 6),
                  chevron,
                ],
              ),
              onTap: () => _open(const ThemeSettingsScreen()),
            ),
          ),
          const SizedBox(height: 20),

          const AdaptiveSectionTitle('控件'),
          AdaptiveCard(
            child: AdaptiveSettingsTile(
              title: '控件',
              summary: _themeManager.showAppBarTitle
                  ? '显示Title · 已开启'
                  : '显示Title · 已关闭',
              leading: Icon(Icons.widgets_outlined, color: scheme.primary),
              trailing: chevron,
              onTap: () => _open(const WidgetSettingsScreen()),
            ),
          ),
          const SizedBox(height: 20),

          const AdaptiveSectionTitle('高级'),
          AdaptiveCard(
            child: AdaptiveSettingsTile(
              title: '高级',
              summary: '密码认证行为 · ${_authManager.behavior.displayName}',
              leading: Icon(Icons.tune_outlined, color: scheme.primary),
              trailing: chevron,
              onTap: () => _open(const AdvancedSettingsScreen()),
            ),
          ),
          const SizedBox(height: 20),

          const AdaptiveSectionTitle('账号与登录状态'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AdaptiveDangerButton(
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
}

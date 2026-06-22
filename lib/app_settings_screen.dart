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
  String? _jwappUsername;
  bool _loadingFinanceInfo = false;

  @override
  void initState() {
    super.initState();
    _loadJwappUsername();
    _loadFinanceInfoIfNeeded();
  }

  Future<void> _loadJwappUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _jwappUsername = prefs.getString('username');
    });
  }

  Future<void> _loadFinanceInfoIfNeeded() async {
    if (_synjonesClient.loggedIn && _synjonesClient.userInfo == null) {
      setState(() => _loadingFinanceInfo = true);
      try {
        await _synjonesClient.fetchUserInfo();
      } catch (_) {}
      if (mounted) {
        setState(() => _loadingFinanceInfo = false);
      }
    }
  }

  void _logoutJwapp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('idToken');
    globals.idToken = null;
    globals.onLoginStateChanged?.call();
    setState(() {});
  }

  void _logoutJw() async {
    await JwLoginService.logout();
    globals.onLoginStateChanged?.call();
    setState(() {});
  }

  void _logoutFinance() async {
    await _synjonesClient.logout();
    await CasAuthCache.clear();
    globals.onLoginStateChanged?.call();
    setState(() {});
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

          // Jwapp (微教务)
          _buildAccountCard(
            title: '微教务',
            icon: Icons.bolt,
            iconColor: Colors.amber,
            isLoggedIn: globals.idToken != null,
            subtitle: globals.idToken != null
                ? '学号: ${_jwappUsername ?? '已登录'}'
                : '未登录',
            onLoginTap: () => widget.onSwitchTab(0),
            onLogoutTap: _logoutJwapp,
          ),
          const SizedBox(height: 12),

          // Jw (安大教务)
          _buildAccountCard(
            title: '安大教务',
            icon: Icons.school,
            iconColor: Colors.blue,
            isLoggedIn: globals.jwLoggedIn,
            subtitle: globals.jwLoggedIn
                ? '学号: ${globals.jwStudentNo ?? '已登录'}'
                : '未登录',
            onLoginTap: () => widget.onSwitchTab(1),
            onLogoutTap: _logoutJw,
          ),
          const SizedBox(height: 12),

          // Finance (一卡通)
          _buildAccountCard(
            title: '一卡通系统',
            icon: Icons.credit_card,
            iconColor: Colors.green,
            isLoggedIn: _synjonesClient.loggedIn,
            subtitle: _synjonesClient.loggedIn
                ? _loadingFinanceInfo
                    ? '正在加载...'
                    : '姓名: ${_synjonesClient.userInfo?['name'] ?? '已登录'}'
                : '未登录',
            onLoginTap: () => widget.onSwitchTab(2),
            onLogoutTap: _logoutFinance,
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

  Widget _buildAccountCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isLoggedIn,
    required String subtitle,
    required VoidCallback onLoginTap,
    required VoidCallback onLogoutTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: iconColor.withValues(alpha: 0.12),
            child: Icon(icon, color: iconColor),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle),
          trailing: isLoggedIn
              ? OutlinedButton(
                  onPressed: onLogoutTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(color: colorScheme.error.withValues(alpha: 0.4)),
                  ),
                  child: const Text('登出'),
                )
              : FilledButton(
                  onPressed: onLoginTap,
                  child: const Text('去登录'),
                ),
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

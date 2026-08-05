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
    final mc = MiuixColors.of(context);
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
                  title: '界面风格',
                  summary: _themeManager.currentUiModeName,
                  leading: Icon(Icons.dashboard_outlined, color: mc.primary),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: mc.onSurfaceVariantActions,
                  ),
                  onTap: () => _showUiModeSheet(context),
                ),
                const Divider(height: 0.5, indent: 20),
                MiuixComponent(
                  title: '颜色模式',
                  summary: _themeManager.currentColorModeName,
                  leading: Icon(Icons.brightness_6_outlined, color: mc.primary),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: mc.onSurfaceVariantActions,
                  ),
                  onTap: () => _showColorModeSheet(context),
                ),
                const Divider(height: 0.5, indent: 20),
                MiuixComponent(
                  title: '主题色',
                  summary: _currentKeyColorName(),
                  leading: Icon(Icons.color_lens_outlined, color: mc.primary),
                  trailing: _buildKeyColorDot(),
                  onTap: () => _showKeyColorSheet(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const MiuixSmallTitle('效果'),
          LiquidGlassCard(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              children: [
                MiuixComponent(
                  title: '模糊效果',
                  summary: '为顶栏和底栏启用背景模糊',
                  leading: Icon(Icons.blur_on_outlined, color: mc.primary),
                  trailing: Switch(
                    value: _themeManager.enableBlur,
                    onChanged: (v) => _themeManager.setEnableBlur(v),
                    activeColor: mc.primary,
                  ),
                ),
                const Divider(height: 0.5, indent: 20),
                MiuixComponent(
                  title: '液态玻璃',
                  summary: '为悬浮元素启用液态玻璃高光与润色',
                  leading: Icon(Icons.water_drop_outlined, color: mc.primary),
                  trailing: Switch(
                    value: _themeManager.enableLiquidGlass,
                    onChanged: _themeManager.enableBlur
                        ? (v) => _themeManager.setEnableLiquidGlass(v)
                        : null,
                    activeColor: mc.primary,
                  ),
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

  String _currentKeyColorName() {
    final idx = PresetColors.presets.indexOf(_themeManager.keyColor);
    return idx >= 0 ? PresetColors.names[idx] : '自定义';
  }

  Widget _buildKeyColorDot() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: _themeManager.keyColor,
        shape: BoxShape.circle,
        border: Border.all(color: MiuixColors.of(context).outline, width: 1.5),
      ),
    );
  }

  void _showUiModeSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '界面风格',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _uiModeOption(UiMode.miuix, 'Miuix', 'HyperOS 风格圆角与配色'),
              _uiModeOption(
                UiMode.material3,
                'Material 3',
                'Google Material You 风格',
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _uiModeOption(UiMode mode, String label, String summary) {
    final selected = _themeManager.uiMode == mode;
    final mc = MiuixColors.of(context);
    return ListTile(
      leading: Icon(
        mode == UiMode.miuix ? Icons.phone_iphone : Icons.widgets_outlined,
        color: selected ? mc.primary : mc.onSurfaceVariantActions,
      ),
      title: Text(label),
      subtitle: Text(summary, style: const TextStyle(fontSize: 12)),
      trailing: selected
          ? Icon(Icons.check_circle, color: mc.primary, size: 22)
          : Icon(Icons.radio_button_unchecked, color: mc.outline, size: 22),
      onTap: () async {
        await _themeManager.setUiMode(mode);
        if (mounted) Navigator.pop(context);
      },
    );
  }

  void _showColorModeSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '颜色模式',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _colorModeOption(
                ColorMode.system,
                '跟随系统',
                Icons.brightness_auto_outlined,
              ),
              _colorModeOption(
                ColorMode.light,
                '浅色模式',
                Icons.light_mode_outlined,
              ),
              _colorModeOption(
                ColorMode.dark,
                '深色模式',
                Icons.dark_mode_outlined,
              ),
              _colorModeOption(
                ColorMode.amoled,
                'AMOLED 纯黑',
                Icons.contrast,
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _colorModeOption(
    ColorMode mode,
    String label,
    IconData icon,
  ) {
    final selected = _themeManager.colorMode == mode;
    final mc = MiuixColors.of(context);
    return ListTile(
      leading: Icon(icon, color: selected ? mc.primary : mc.onSurfaceVariantActions),
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check_circle, color: mc.primary, size: 22)
          : Icon(Icons.radio_button_unchecked, color: mc.outline, size: 22),
      onTap: () async {
        await _themeManager.setColorMode(mode);
        if (mounted) Navigator.pop(context);
      },
    );
  }

  void _showKeyColorSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    '主题色',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: PresetColors.presets.length,
                  itemBuilder: (context, index) {
                    final color = PresetColors.presets[index];
                    final selected =
                        _themeManager.keyColor.toARGB32() == color.toARGB32();
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _themeManager.setKeyColor(color);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? MiuixColors.of(context).onSurface
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: selected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      final color = await _pickCustomColor(context);
                      if (color != null) {
                        _themeManager.setKeyColor(color);
                      }
                    },
                    icon: const Icon(Icons.palette),
                    label: const Text('自定义颜色'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Color?> _pickCustomColor(BuildContext context) async {
    Color picked = _themeManager.keyColor;
    final result = await showDialog<Color>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('自定义颜色'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: picked,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                          Colors.red,
                          Colors.pink,
                          Colors.purple,
                          Colors.deepPurple,
                          Colors.indigo,
                          Colors.blue,
                          Colors.lightBlue,
                          Colors.cyan,
                          Colors.teal,
                          Colors.green,
                          Colors.lightGreen,
                          Colors.lime,
                          Colors.amber,
                          Colors.orange,
                          Colors.deepOrange,
                          Colors.brown,
                          Colors.grey,
                        ].map((c) {
                          return GestureDetector(
                            onTap: () => setState(() => picked = c),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: picked.toARGB32() == c.toARGB32()
                                      ? Colors.black
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, picked),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
    return result;
  }
}
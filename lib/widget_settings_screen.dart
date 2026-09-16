import 'package:flutter/material.dart';
import 'theme_manager.dart';
import 'adaptive_ui.dart';

import 'finance/pages/finance_recharge_page.dart';

class WidgetSettingsScreen extends StatefulWidget {
  const WidgetSettingsScreen({super.key});

  @override
  State<WidgetSettingsScreen> createState() => _WidgetSettingsScreenState();
}

class _WidgetSettingsScreenState extends State<WidgetSettingsScreen> {
  final ThemeManager _themeManager = ThemeManager();

  @override
  void initState() {
    super.initState();
    _themeManager.addListener(_onThemeChanged);
    FinanceRechargePage.loadSavedViewMode();
  }

  @override
  void dispose() {
    _themeManager.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('控件')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
        children: [
          const AdaptiveSectionTitle('顶栏设置'),
          AdaptiveCard(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              children: [
                AdaptiveSwitchTile(
                  title: '显示Title',
                  summary: _themeManager.showAppBarTitle
                      ? '在微教务、安大教务、一卡通最上方显示标题与通知图标'
                      : '已移除顶部标题与通知图标，内容整体上移',
                  value: _themeManager.showAppBarTitle,
                  onChanged: (val) => _themeManager.setShowAppBarTitle(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const AdaptiveSectionTitle('一卡通'),
          AdaptiveCard(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: ValueListenableBuilder<bool>(
              valueListenable: financeRechargeIsListViewNotifier,
              builder: (context, isList, _) {
                return Column(
                  children: [
                    AdaptiveSettingsTile(
                      title: '充值缴费显示样式',
                      summary: isList ? '列表 (左图标右文字)' : '网格大方块',
                      leading: Icon(
                        isList
                            ? Icons.view_list_rounded
                            : Icons.grid_view_rounded,
                        color: scheme.primary,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isList ? '列表' : '网格',
                            style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            color: scheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      onTap: () => _showRechargeStyleSheet(context, isList),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showRechargeStyleSheet(BuildContext context, bool currentIsList) {
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).viewPadding.bottom;

        return Material(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.outline.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '充值缴费显示样式',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStyleOption(
                    ctx: ctx,
                    title: '网格大方块',
                    subtitle: '双列大卡片，大图标大色块',
                    icon: Icons.grid_view_rounded,
                    isSelected: !currentIsList,
                    onTap: () {
                      FinanceRechargePage.setViewMode(false);
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildStyleOption(
                    ctx: ctx,
                    title: '列表 (左图标右文字)',
                    subtitle: '单列水平排列，左侧图标右侧名称',
                    icon: Icons.view_list_rounded,
                    isSelected: currentIsList,
                    onTap: () {
                      FinanceRechargePage.setViewMode(true);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStyleOption({
    required BuildContext ctx,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(ctx).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? scheme.primary.withOpacity(0.08)
              : scheme.surfaceContainer.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? scheme.primary
                : scheme.outline.withOpacity(0.3),
            width: isSelected ? 1.5 : 0.6,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isSelected
                  ? scheme.primary.withOpacity(0.18)
                  : scheme.surfaceContainerHighest,
              child: Icon(
                icon,
                color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isSelected ? scheme.primary : scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: scheme.primary, size: 22),
          ],
        ),
      ),
    );
  }
}

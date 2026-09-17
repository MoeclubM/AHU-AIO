import 'package:flutter/material.dart';

import 'adaptive_ui.dart';
import 'miuix/miuix_components.dart';
import 'theme_manager.dart';

/// 主题设置。
///
/// 形态参考 LSPosed 管理器：页面使用大标题 + 圆形返回按钮，每个选项一张
/// 独立卡片（图标在左、标题与副标题在中间、当前取值在右），开关直接内嵌在行内。
class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  final ThemeManager _themeManager = ThemeManager();

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

  @override
  Widget build(BuildContext context) {
    final tm = _themeManager;
    final scheme = Theme.of(context).colorScheme;
    final Color leadingColor = scheme.onSurface;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(
          top: MediaQuery.viewPaddingOf(context).top,
          bottom: adaptiveBottomPadding(context, withSubBar: false),
        ),
        children: [
          const AdaptivePageHeader(title: '主题设置'),

          // 主题模式
          _OptionCard(
            icon: Icons.dark_mode_outlined,
            iconColor: leadingColor,
            title: '主题',
            subtitle: '选择应用的主题模式',
            trailing: _ValueTrailing(text: tm.currentColorModeName),
            onTap: _pickColorMode,
          ),
          // 强调色
          _OptionCard(
            icon: Icons.palette_outlined,
            iconColor: leadingColor,
            title: '强调色',
            subtitle: '自定义主题的强调色与色板',
            trailing: _ValueTrailing(
              text: tm.colorMode == ColorMode.monet ? '动态取色' : '默认',
              leading: _ColorDot(
                color: tm.keyColor,
                monet: tm.colorMode == ColorMode.monet,
              ),
            ),
            onTap: _pickKeyColor,
          ),
          // 界面风格
          _OptionCard(
            icon: Icons.auto_awesome_outlined,
            iconColor: leadingColor,
            title: '界面风格',
            subtitle: '在 Miuix 与 Material 3 之间切换',
            trailing: _ValueTrailing(text: tm.currentUiModeName),
            onTap: _pickUiMode,
          ),
          // 调色板风格：Material 3 专属的配色推导算法
          if (tm.isMaterial3)
            _OptionCard(
              icon: Icons.color_lens_outlined,
              iconColor: leadingColor,
              title: '调色板风格',
              subtitle: '用于推导 Material 3 配色的算法',
              trailing: _ValueTrailing(text: tm.paletteStyle.displayName),
              onTap: _pickPaletteStyle,
            ),

          if (tm.isMiuix) ...[
            _SwitchCard(
              icon: Icons.blur_on_outlined,
              iconColor: leadingColor,
              title: '模糊',
              subtitle: '启用顶栏和底栏的模糊效果',
              value: tm.enableBlur,
              onChanged: tm.setEnableBlur,
            ),
            _SwitchCard(
              icon: Icons.view_agenda_outlined,
              iconColor: leadingColor,
              title: '悬浮底栏',
              subtitle: '使用类 Apple 风格的悬浮底栏',
              value: tm.enableBottomBarTransparent,
              onChanged: tm.setEnableBottomBarTransparent,
            ),
            _SwitchCard(
              icon: Icons.water_drop_outlined,
              iconColor: leadingColor,
              title: '液态玻璃',
              subtitle: '启用悬浮底栏的液态玻璃效果',
              value: tm.enableLiquidGlass,
              enabled: tm.enableBlur,
              onChanged: tm.setEnableLiquidGlass,
            ),
          ],

          // 通用：与界面风格无关的系统级样式调整
          _SwitchCard(
            icon: Icons.swipe_outlined,
            iconColor: leadingColor,
            title: '预测性返回手势',
            subtitle: '启用对预测性返回手势的支持（仅 Android）',
            value: tm.predictiveBack,
            onChanged: tm.setPredictiveBack,
          ),
          _OptionCard(
            icon: Icons.format_size_outlined,
            iconColor: leadingColor,
            title: '界面缩放',
            subtitle: '调整全局显示比例',
            trailing: _ValueTrailing(text: '${(tm.uiScale * 100).round()}%'),
            onTap: _pickUiScale,
          ),
        ],
      ),
    );
  }

  Future<void> _pickPaletteStyle() async {
    final style = await showAdaptiveChoiceDialog<PaletteStyle>(
      context: context,
      title: '调色板风格',
      current: _themeManager.paletteStyle,
      options: [
        for (final item in PaletteStyle.values)
          AdaptiveChoice(
            value: item,
            label: item.displayName,
            summary: item.summary,
          ),
      ],
    );
    if (style != null) {
      await _themeManager.setPaletteStyle(style);
    }
  }

  Future<void> _pickUiScale() async {
    final scale = await showDialog<double>(
      context: context,
      builder: (ctx) {
        double current = _themeManager.uiScale;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final scheme = Theme.of(ctx).colorScheme;
            return AlertDialog(
              title: const Text('界面缩放'),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(current * 100).round()}%',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                    ),
                    Slider(
                      value: current,
                      min: 0.85,
                      max: 1.30,
                      divisions: 9,
                      label: '${(current * 100).round()}%',
                      onChanged: (v) => setDialogState(() => current = v),
                    ),
                  ],
                ),
              ),
              actions: [
                AdaptiveTextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                AdaptiveTextButton(
                  onPressed: () => Navigator.pop(ctx, current),
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
    if (scale != null) {
      await _themeManager.setUiScale(scale);
    }
  }

  Future<void> _pickUiMode() async {
    final mode = await showAdaptiveChoiceDialog<UiMode>(
      context: context,
      title: '界面风格',
      current: _themeManager.uiMode,
      options: const [
        AdaptiveChoice(
          value: UiMode.miuix,
          label: 'Miuix',
          summary: 'HyperOS 风格：悬浮玻璃胶囊底栏与弹簧动效',
        ),
        AdaptiveChoice(
          value: UiMode.material3,
          label: 'Material 3',
          summary: 'Google 原生规范：贴底导航栏与标准控件',
        ),
      ],
    );
    if (mode != null) {
      await _themeManager.setUiMode(mode);
    }
  }

  Future<void> _pickColorMode() async {
    final mode = await showAdaptiveChoiceDialog<ColorMode>(
      context: context,
      title: '主题',
      current: _themeManager.colorMode,
      options: const [
        AdaptiveChoice(value: ColorMode.system, label: '跟随系统'),
        AdaptiveChoice(value: ColorMode.light, label: '浅色模式'),
        AdaptiveChoice(value: ColorMode.dark, label: '深色模式'),
        AdaptiveChoice(
          value: ColorMode.amoled,
          label: 'AMOLED 纯黑',
          summary: '纯黑背景，适合 OLED 屏幕',
        ),
        AdaptiveChoice(
          value: ColorMode.monet,
          label: '动态壁纸取色',
          summary: '从系统壁纸提取主色（Monet）',
        ),
      ],
    );
    if (mode != null) {
      await _themeManager.setColorMode(mode);
    }
  }

  Future<void> _pickKeyColor() async {
    final color = await showThemeColorDialog(
      context: context,
      current: _themeManager.keyColor,
    );
    if (color != null) {
      await _themeManager.setKeyColor(color);
    }
  }
}

/// 单行选项卡片：图标 + 标题/副标题 + 右侧当前取值。
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: AdaptiveCard(
        padding: EdgeInsets.zero,
        child: AdaptiveSettingsTile(
          title: title,
          summary: subtitle,
          leading: Icon(icon, size: 24, color: iconColor),
          trailing: trailing,
          onTap: onTap,
        ),
      ),
    );
  }
}

/// 开关行卡片：图标 + 标题/副标题 + 内嵌开关。
class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: AdaptiveCard(
        padding: EdgeInsets.zero,
        child: AdaptiveSwitchTile(
          title: title,
          summary: subtitle,
          leading: Icon(icon, size: 24, color: iconColor),
          value: value,
          enabled: enabled,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// 右侧当前取值：可选色点 + 文本 + 右箭头。
class _ValueTrailing extends StatelessWidget {
  const _ValueTrailing({required this.text, this.leading});

  final String text;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 8)],
        Text(text, style: _valueStyle(context, scheme)),
        const SizedBox(width: 2),
        Icon(Icons.chevron_right, size: 22, color: scheme.onSurfaceVariant),
      ],
    );
  }
}

/// 当前主色小圆点。
class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, required this.monet});

  final Color color;
  final bool monet;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: monet ? scheme.primary : color,
        shape: BoxShape.circle,
        border: Border.all(color: scheme.outlineVariant, width: 1),
      ),
    );
  }
}

/// 主色选择弹窗：预设色板 + 自定义取色。
Future<Color?> showThemeColorDialog({
  required BuildContext context,
  required Color current,
}) {
  return showDialog<Color>(
    context: context,
    builder: (ctx) {
      Color picked = current;
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          final scheme = Theme.of(ctx).colorScheme;
          return AlertDialog(
            title: const Text('强调色'),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                    itemCount: PresetColors.presets.length,
                    itemBuilder: (context, index) {
                      final color = PresetColors.presets[index];
                      final bool selected =
                          color.toARGB32() == picked.toARGB32();
                      return GestureDetector(
                        onTap: () => setDialogState(() => picked = color),
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? scheme.onSurface
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: selected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  AdaptiveTextButton(
                    icon: const Icon(Icons.colorize_rounded, size: 18),
                    onPressed: () async {
                      final custom = await _showCustomColorPicker(ctx, picked);
                      if (custom != null) {
                        setDialogState(() => picked = custom);
                      }
                    },
                    child: const Text('自定义取色'),
                  ),
                ],
              ),
            ),
            actions: [
              AdaptiveTextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              AdaptiveTextButton(
                onPressed: () => Navigator.pop(ctx, picked),
                child: const Text('确定'),
              ),
            ],
          );
        },
      );
    },
  );
}

/// 自定义取色：Miuix 使用 OkHSV 取色器，MD3 使用标准 HSV 滑块。
Future<Color?> _showCustomColorPicker(BuildContext context, Color initial) {
  if (isMiuixUi()) {
    return showDialog<Color>(
      context: context,
      builder: (ctx) {
        Color picked = initial;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('自定义取色'),
              content: SizedBox(
                width: 300,
                child: MiuixColorPicker(
                  color: picked,
                  colorSpace: MiuixColorSpace.oklch,
                  showPreview: true,
                  onColorChanged: (c) => setDialogState(() => picked = c),
                ),
              ),
              actions: [
                AdaptiveTextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                AdaptiveTextButton(
                  onPressed: () => Navigator.pop(ctx, picked),
                  child: const Text('应用'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  return showDialog<Color>(
    context: context,
    builder: (ctx) => _HsvColorDialog(initial: initial),
  );
}

/// Material 3 下的标准 HSV 取色弹窗。
class _HsvColorDialog extends StatefulWidget {
  const _HsvColorDialog({required this.initial});

  final Color initial;

  @override
  State<_HsvColorDialog> createState() => _HsvColorDialogState();
}

class _HsvColorDialogState extends State<_HsvColorDialog> {
  late HSVColor _hsv = HSVColor.fromColor(widget.initial);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final preview = _hsv.toColor();
    return AlertDialog(
      title: const Text('自定义取色'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: preview,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
              ),
            ),
            const SizedBox(height: 12),
            const Text('色相'),
            Slider(
              value: _hsv.hue,
              max: 360,
              onChanged: (v) => setState(() => _hsv = _hsv.withHue(v)),
            ),
            const Text('饱和度'),
            Slider(
              value: _hsv.saturation,
              onChanged: (v) => setState(() => _hsv = _hsv.withSaturation(v)),
            ),
            const Text('明度'),
            Slider(
              value: _hsv.value,
              onChanged: (v) => setState(() => _hsv = _hsv.withValue(v)),
            ),
          ],
        ),
      ),
      actions: [
        AdaptiveTextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        AdaptiveTextButton(
          onPressed: () => Navigator.pop(context, preview),
          child: const Text('应用'),
        ),
      ],
    );
  }
}

/// 当前取值文本样式：Miuix 用官方 body1(16sp) + 弱化前景色，MD3 用 bodyMedium。
TextStyle _valueStyle(BuildContext context, ColorScheme scheme) {
  if (!isMiuixUi()) {
    return TextStyle(fontSize: 15, color: scheme.onSurfaceVariant);
  }
  final theme = MiuixTheme.of(context);
  return theme.textStyles.body1
      .copyWith(color: theme.colors.onSurfaceVariantSummary)
      .withMiuixWeight(theme.fontWeightAdjustment);
}

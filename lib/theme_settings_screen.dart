import 'package:flutter/material.dart';

import 'adaptive_ui.dart';
import 'miuix/miuix_components.dart';
import 'theme_manager.dart';

/// 主题设置。
///
/// 两种风格的布局按设计稿区分：
/// - **Miuix**：大标题 + 普通返回箭头；所有选项装在**同一张卡片**里，
///   行内不显示图标，取值行尾随箭头（选择器用上下双箭头）；
/// - **Material 3**：大标题 + 圆形返回按钮；**每个选项一张独立卡片**，
///   行内有前置图标，取值行只显示文本。
///
/// 两种风格的「界面缩放」都是**卡内内联滑块**，不再弹窗。
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
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool miuix = tm.isMiuix;
    final Color iconColor = miuix ? scheme.onSurface : scheme.onSurfaceVariant;

    // 行内容两种风格共用；差别只在是否显示前置图标与卡片如何分组：
    // - Miuix：一整张卡片装下所有行，行内不显示图标（与设计稿一致）；
    // - MD3：每行一张独立卡片，行内带前置图标。
    final List<Widget> rows = <Widget>[
      _ThemeRow(
        icon: Icons.dark_mode_outlined,
        iconColor: iconColor,
        title: '主题',
        subtitle: '选择应用的主题模式',
        trailing: _ValueTrailing(
          text: tm.currentColorModeName,
          chevron: miuix ? Icons.unfold_more : null,
        ),
        onTap: _pickColorMode,
      ),
      _ThemeRow(
        icon: Icons.auto_awesome_outlined,
        iconColor: iconColor,
        title: '界面风格',
        subtitle: '在 Miuix 与 Material 3 之间切换',
        trailing: _ValueTrailing(
          text: tm.currentUiModeName,
          chevron: miuix ? Icons.unfold_more : null,
        ),
        onTap: _pickUiMode,
      ),
      if (miuix) ...[
        _ThemeSwitchRow(
          icon: Icons.blur_on_outlined,
          iconColor: iconColor,
          title: '模糊',
          subtitle: '启用顶栏和底栏的模糊效果',
          value: tm.enableBlur,
          onChanged: tm.setEnableBlur,
        ),
        _ThemeSwitchRow(
          icon: Icons.view_agenda_outlined,
          iconColor: iconColor,
          title: '悬浮底栏',
          subtitle: '使用类 Apple 风格的悬浮底栏',
          value: tm.enableBottomBarTransparent,
          onChanged: tm.setEnableBottomBarTransparent,
        ),
        _ThemeSwitchRow(
          icon: Icons.water_drop_outlined,
          iconColor: iconColor,
          title: '液态玻璃',
          subtitle: '启用悬浮底栏的液态玻璃效果',
          value: tm.enableLiquidGlass,
          enabled: tm.enableBlur,
          onChanged: tm.setEnableLiquidGlass,
        ),
      ] else ...[
        _ThemeRow(
          icon: Icons.palette_outlined,
          iconColor: iconColor,
          title: '强调色',
          subtitle: '在使用 Monet 时自定义种子色',
          trailing: _ValueTrailing(
            text: tm.colorMode == ColorMode.monet ? '动态取色' : '默认',
            leading: _ColorDot(
              color: tm.keyColor,
              monet: tm.colorMode == ColorMode.monet,
            ),
          ),
          onTap: _pickKeyColor,
        ),
        _ThemeRow(
          icon: Icons.color_lens_outlined,
          iconColor: iconColor,
          title: '调色板风格',
          subtitle: '用于推导 Material 3 调色板的色调算法',
          trailing: _ValueTrailing(text: tm.paletteStyle.displayName),
          onTap: _pickPaletteStyle,
        ),
      ],
      _ThemeSwitchRow(
        icon: Icons.swipe_outlined,
        iconColor: iconColor,
        title: '预测性返回手势',
        subtitle: '启用对预测性返回手势的支持',
        value: tm.predictiveBack,
        onChanged: tm.setPredictiveBack,
      ),
      _ThemeScaleRow(
        icon: Icons.format_size_outlined,
        iconColor: iconColor,
        value: tm.uiScale,
        onChanged: tm.setUiScale,
      ),
    ];

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(
          top: MediaQuery.viewPaddingOf(context).top,
          bottom: adaptiveBottomPadding(context, withSubBar: false),
        ),
        children: <Widget>[
          const AdaptivePageHeader(title: '主题设置'),
          if (miuix)
            // Miuix：一整张卡片包住所有行，行间不加分隔线。
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: MiuixCard(
                cornerRadius: 20,
                insideMargin: EdgeInsets.zero,
                child: Column(mainAxisSize: MainAxisSize.min, children: rows),
              ),
            )
          else
            // MD3：每行一张独立卡片。
            for (final Widget row in rows)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: row,
                ),
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

/// 主题设置行。
///
/// 两种风格共用同一套行内容，差别在是否显示前置图标：Miuix 的设计稿里行内
/// 没有图标，MD3 每行都有。
class _ThemeRow extends StatelessWidget {
  const _ThemeRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AdaptiveSettingsTile(
      title: title,
      summary: subtitle,
      leading: isMiuixUi() ? null : Icon(icon, size: 24, color: iconColor),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// 开关行。
///
/// Miuix 用原生偏好开关；MD3 用标准 [SwitchListTile]，开关滑块内带勾选图标
/// （设计稿里 MD3 的开关是带勾的）。
class _ThemeSwitchRow extends StatelessWidget {
  const _ThemeSwitchRow({
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
    if (isMiuixUi()) {
      return AdaptiveSwitchTile(
        title: title,
        summary: subtitle,
        value: value,
        enabled: enabled,
        onChanged: onChanged,
      );
    }
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      secondary: Icon(icon, size: 24, color: iconColor),
      value: value,
      onChanged: enabled ? onChanged : null,
      thumbIcon: WidgetStateProperty.resolveWith<Icon?>(
        (Set<WidgetState> states) => states.contains(WidgetState.selected)
            ? const Icon(Icons.check, size: 16)
            : null,
      ),
    );
  }
}

/// 界面缩放行：滑块直接放在卡片内，不再弹窗。
///
/// Miuix 用官方滑块并在轨道上叠常用档位的关键点；MD3 用新版 Material 3 滑块
/// （`year2023: false`，竖条形滑块 + 轨道档位点）。
class _ThemeScaleRow extends StatelessWidget {
  const _ThemeScaleRow({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.onChanged,
  });

  static const double min = 0.85;
  static const double max = 1.30;

  /// 轨道上的关键点（Miuix 滑块的档位标记），放在常用比例处。
  static const List<double> keyPoints = <double>[0.90, 1.00, 1.25];

  final IconData icon;
  final Color iconColor;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool miuix = isMiuixUi();
    final double clamped = value.clamp(min, max);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _ThemeRow(
          icon: icon,
          iconColor: iconColor,
          title: '界面缩放',
          subtitle: '调整全局显示比例',
          trailing: _ValueTrailing(
            text: '${(clamped * 100).round()}%',
            chevron: miuix ? Icons.chevron_right : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Slider(
                value: clamped,
                min: min,
                max: max,
                year2023: !miuix,
                label: '${(clamped * 100).round()}%',
                onChanged: onChanged,
              ),
              if (miuix)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _MiuixSliderKeyPointsPainter(
                        value: clamped,
                        primary: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Miuix 滑块的关键点：按比例在轨道上画小圆点，落在已填充段的用亮色。
class _MiuixSliderKeyPointsPainter extends CustomPainter {
  const _MiuixSliderKeyPointsPainter({
    required this.value,
    required this.primary,
  });

  final double value;
  final Color primary;

  @override
  void paint(Canvas canvas, Size size) {
    // 与 Slider 的默认内边距对齐：两侧各留出半个滑块宽度。
    const double horizontalInset = 12;
    final double usable = size.width - horizontalInset * 2;
    if (usable <= 0) return;
    final double centerY = size.height / 2;

    for (final double point in _ThemeScaleRow.keyPoints) {
      final double t =
          ((point - _ThemeScaleRow.min) /
                  (_ThemeScaleRow.max - _ThemeScaleRow.min))
              .clamp(0.0, 1.0);
      final double x = horizontalInset + usable * t;
      canvas.drawCircle(
        Offset(x, centerY),
        3,
        Paint()
          ..color = point <= value
              ? Colors.white.withValues(alpha: 0.55)
              : primary.withValues(alpha: 0.18),
      );
    }
  }

  @override
  bool shouldRepaint(_MiuixSliderKeyPointsPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.primary != primary;
}

/// 右侧当前取值：可选色点 + 文本 + 可选箭头。
///
/// Miuix 会显示箭头（取值选择器用上下双箭头、可展开项用右箭头）；
/// MD3 只显示文本。
class _ValueTrailing extends StatelessWidget {
  const _ValueTrailing({required this.text, this.leading, this.chevron});

  final String text;
  final Widget? leading;
  final IconData? chevron;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (leading != null) ...<Widget>[leading!, const SizedBox(width: 8)],
        Text(text, style: _valueStyle(context, scheme)),
        if (chevron != null) ...<Widget>[
          const SizedBox(width: 4),
          Icon(chevron, size: 20, color: scheme.onSurfaceVariant),
        ],
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
  return showAdaptiveAppDialog<Color>(
    context: context,
    builder: (ctx) {
      Color picked = current;
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          final scheme = Theme.of(ctx).colorScheme;
          return AdaptiveAlertDialog(
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
    return showAdaptiveAppDialog<Color>(
      context: context,
      builder: (ctx) {
        Color picked = initial;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AdaptiveAlertDialog(
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
  return showAdaptiveAppDialog<Color>(
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
    return AdaptiveAlertDialog(
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
    // M3：取值文本用 bodyMedium（14sp），不再写死 15。
    final theme = Theme.of(context);
    return theme.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ) ??
        TextStyle(color: scheme.onSurfaceVariant);
  }
  final theme = MiuixTheme.of(context);
  return theme.textStyles.body1
      .copyWith(color: theme.colors.onSurfaceVariantSummary)
      .withMiuixWeight(theme.fontWeightAdjustment);
}

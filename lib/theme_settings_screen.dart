import 'package:flutter/material.dart';

import 'adaptive_ui.dart';
import 'miuix/miuix_components.dart';
import 'theme_manager.dart';

/// 个性化与主题设置。
///
/// 布局参考 LSPosed 管理器：列表只保留「当前取值」的精简行，
/// 具体选项放进弹窗完成选择，避免大块预览卡片与冗余说明。
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
    final chevron = Icon(Icons.chevron_right, color: scheme.onSurfaceVariant);

    return Scaffold(
      appBar: AppBar(title: const Text('个性化与主题')),
      body: ListView(
        padding: adaptivePagePadding(context, top: 8, bottom: 40),
        children: [
          const AdaptiveSectionTitle('外观'),
          AdaptiveCard(
            child: Column(
              children: [
                AdaptiveSettingsTile(
                  title: '界面风格',
                  summary: tm.currentUiModeName,
                  leading: Icon(
                    tm.isMiuix
                        ? Icons.phone_iphone_rounded
                        : Icons.widgets_outlined,
                    color: scheme.primary,
                  ),
                  trailing: chevron,
                  onTap: _pickUiMode,
                ),
                const AdaptiveDivider(),
                AdaptiveSettingsTile(
                  title: '色彩模式',
                  summary: tm.currentColorModeName,
                  leading: Icon(
                    Icons.brightness_6_outlined,
                    color: scheme.primary,
                  ),
                  trailing: chevron,
                  onTap: _pickColorMode,
                ),
                const AdaptiveDivider(),
                AdaptiveSettingsTile(
                  title: '主题主色',
                  summary: tm.colorMode == ColorMode.monet
                      ? '跟随动态壁纸取色'
                      : '预设色板或自定义取色',
                  leading: Icon(Icons.palette_outlined, color: scheme.primary),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ColorDot(
                        color: tm.keyColor,
                        monet: tm.colorMode == ColorMode.monet,
                      ),
                      const SizedBox(width: 6),
                      chevron,
                    ],
                  ),
                  onTap: _pickKeyColor,
                ),
              ],
            ),
          ),
          if (tm.isMiuix) ...[
            const SizedBox(height: 20),
            const AdaptiveSectionTitle('视觉效果'),
            AdaptiveCard(
              child: Column(
                children: [
                  AdaptiveSwitchTile(
                    title: '底栏毛玻璃透视',
                    summary: tm.enableBottomBarTransparent ? '开启' : '关闭',
                    value: tm.enableBottomBarTransparent,
                    onChanged: tm.setEnableBottomBarTransparent,
                  ),
                  const AdaptiveDivider(),
                  AdaptiveSwitchTile(
                    title: '背景高斯模糊',
                    summary: tm.enableBlur ? '开启' : '关闭',
                    value: tm.enableBlur,
                    onChanged: tm.setEnableBlur,
                  ),
                  const AdaptiveDivider(),
                  AdaptiveSwitchTile(
                    title: '液态玻璃边缘高光',
                    summary: tm.enableLiquidGlass ? '开启' : '关闭',
                    value: tm.enableLiquidGlass,
                    enabled: tm.enableBlur,
                    onChanged: tm.setEnableLiquidGlass,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
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
      title: '色彩模式',
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

/// 当前主色小圆点。
class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, required this.monet});

  final Color color;
  final bool monet;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: monet ? scheme.primary : color,
        shape: BoxShape.circle,
        border: Border.all(color: scheme.outline, width: 1),
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
            title: const Text('主题主色'),
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
                  colorSpace: MiuixColorSpace.okhsv,
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

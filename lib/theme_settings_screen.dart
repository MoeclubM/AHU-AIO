import 'package:flutter/material.dart';
import 'theme_manager.dart';
import 'miuix/miuix_components.dart';

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
    final mc = MiuixTheme.of(context).colors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('个性化与主题'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
        children: [
          // 1. 实时预览卡片
          _buildLivePreviewCard(context, mc),
          const SizedBox(height: 12),

          // 2. 界面风格
          const MiuixSmallTitle('界面风格'),
          const SizedBox(height: 6),
          _buildUiModeCards(context, mc),
          const SizedBox(height: 16),

          // 3. 颜色模式
          const MiuixSmallTitle('色彩模式'),
          const SizedBox(height: 6),
          MiuixCard(
            cornerRadius: 18,
            child: Column(
              children: [
                MiuixRadioButtonPreference(
                  title: '跟随系统',
                  summary: '自动匹配系统深浅色与夜间模式设置',
                  selected: _themeManager.colorMode == ColorMode.system,
                  radioButtonLocation: MiuixRadioButtonLocation.end,
                  onClick: () => _themeManager.setColorMode(ColorMode.system),
                ),
                const Divider(height: 0.5, indent: 20, endIndent: 20),
                MiuixRadioButtonPreference(
                  title: '浅色模式',
                  summary: '明亮通透的高对比度视觉质感',
                  selected: _themeManager.colorMode == ColorMode.light,
                  radioButtonLocation: MiuixRadioButtonLocation.end,
                  onClick: () => _themeManager.setColorMode(ColorMode.light),
                ),
                const Divider(height: 0.5, indent: 20, endIndent: 20),
                MiuixRadioButtonPreference(
                  title: '深色模式',
                  summary: '弱光环境下舒适的深色调',
                  selected: _themeManager.colorMode == ColorMode.dark,
                  radioButtonLocation: MiuixRadioButtonLocation.end,
                  onClick: () => _themeManager.setColorMode(ColorMode.dark),
                ),
                const Divider(height: 0.5, indent: 20, endIndent: 20),
                MiuixRadioButtonPreference(
                  title: 'AMOLED 纯黑',
                  summary: '极致纯黑底色，专为 OLED 屏幕极致省电与纯净对比优化',
                  selected: _themeManager.colorMode == ColorMode.amoled,
                  radioButtonLocation: MiuixRadioButtonLocation.end,
                  onClick: () => _themeManager.setColorMode(ColorMode.amoled),
                ),
                const Divider(height: 0.5, indent: 20, endIndent: 20),
                MiuixRadioButtonPreference(
                  title: '动态壁纸取色 (Monet)',
                  summary: '基于 Android 12+ Monet 引擎，从系统壁纸提取主色',
                  selected: _themeManager.colorMode == ColorMode.monet,
                  radioButtonLocation: MiuixRadioButtonLocation.end,
                  onClick: () => _themeManager.setColorMode(ColorMode.monet),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. 主题主色
          const MiuixSmallTitle('主题主色'),
          const SizedBox(height: 6),
          MiuixCard(
            cornerRadius: 18,
            insideMargin: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '预设精选色板',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: mc.onSurfaceVariantActions,
                  ),
                ),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1,
                  ),
                  itemCount: PresetColors.presets.length,
                  itemBuilder: (context, index) {
                    final color = PresetColors.presets[index];
                    final isSelected =
                        _themeManager.colorMode != ColorMode.monet &&
                        _themeManager.keyColor.toARGB32() == color.toARGB32();
                    return GestureDetector(
                      onTap: () => _themeManager.setKeyColor(color),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? mc.onSurface : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Divider(height: 0.5),
                const SizedBox(height: 14),
                Center(
                  child: MiuixPrimaryButton(
                    onPressed: () async {
                      final color = await _showColorPickerDialog(context);
                      if (color != null) {
                        await _themeManager.setKeyColor(color);
                      }
                    },
                    icon: const Icon(Icons.colorize_rounded, size: 20),
                    child: const Text('自定义高级取色器 (OkHSV)'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. 悬浮导航栏定制
          const MiuixSmallTitle('悬浮导航栏定制'),
          const SizedBox(height: 6),
          MiuixCard(
            cornerRadius: 18,
            child: Column(
              children: [
                MiuixSwitchPreference(
                  title: '悬浮底栏透明/毛玻璃',
                  summary: _themeManager.enableBottomBarTransparent
                      ? '已开启：液态毛玻璃半透明透视与边缘高光'
                      : '已关闭：纯色实底悬浮底栏，背景不透光',
                  value: _themeManager.enableBottomBarTransparent,
                  onChanged: (v) =>
                      _themeManager.setEnableBottomBarTransparent(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 6. 视觉特效与物理渲染
          const MiuixSmallTitle('视觉特效与物理渲染'),
          const SizedBox(height: 6),
          MiuixCard(
            cornerRadius: 18,
            child: Column(
              children: [
                MiuixSwitchPreference(
                  title: '背景高斯模糊',
                  summary: '为悬浮底栏和顶栏启用实时背景高斯模糊',
                  value: _themeManager.enableBlur,
                  onChanged: (v) => _themeManager.setEnableBlur(v),
                ),
                const Divider(height: 0.5, indent: 20, endIndent: 20),
                MiuixSwitchPreference(
                  title: '液态玻璃与边缘高光',
                  summary: '为悬浮组件启用 HyperOS 标志性 Bloom Stroke 高光润色',
                  value: _themeManager.enableLiquidGlass,
                  enabled: _themeManager.enableBlur,
                  onChanged: (v) => _themeManager.setEnableLiquidGlass(v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreviewCard(BuildContext context, MiuixColors mc) {
    return MiuixCard(
      cornerRadius: 20,
      insideMargin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: mc.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '实时效果预览 (${_themeManager.isMiuix ? "HyperOS Miuix" : "Material 3"} / ${_themeManager.currentColorModeName})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: mc.onSurfaceVariantActions,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: MiuixPrimaryButton(
                  onPressed: () {},
                  minimumSize: const Size.fromHeight(38),
                  borderRadius: 12,
                  child: const Text('主按钮', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MiuixButton(
                  onPressed: () {},
                  minHeight: 38,
                  cornerRadius: 12,
                  child: const Text('次级按钮', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: mc.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.favorite_rounded, color: mc.primary, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUiModeCards(BuildContext context, MiuixColors mc) {
    return Row(
      children: [
        Expanded(
          child: _uiStyleCard(
            title: 'Miuix',
            subtitle: 'HyperOS 风格\n连续圆角与弹簧动效',
            selected: _themeManager.isMiuix,
            icon: Icons.phone_iphone_rounded,
            mc: mc,
            onTap: () => _themeManager.setUiMode(UiMode.miuix),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _uiStyleCard(
            title: 'Material 3',
            subtitle: 'Material You\n原生 Google 规范',
            selected: _themeManager.isMaterial3,
            icon: Icons.widgets_outlined,
            mc: mc,
            onTap: () => _themeManager.setUiMode(UiMode.material3),
          ),
        ),
      ],
    );
  }

  Widget _uiStyleCard({
    required String title,
    required String subtitle,
    required bool selected,
    required IconData icon,
    required MiuixColors mc,
    required VoidCallback onTap,
  }) {
    return MiuixCard(
      cornerRadius: 18,
      onPressed: onTap,
      feedbackType: MiuixPressFeedbackType.sink,
      insideMargin: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      colors: MiuixCardColors(
        color: selected ? mc.primary.withOpacity(0.08) : mc.surfaceContainer,
        contentColor: mc.onSurfaceContainer,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? mc.primary : mc.outline.withOpacity(0.4),
            width: selected ? 2.0 : 0.8,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: selected ? mc.primary : mc.onSurfaceVariantActions,
                  size: 24,
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded, color: mc.primary, size: 20)
                else
                  Icon(
                    Icons.radio_button_unchecked,
                    color: mc.outline,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: selected ? mc.primary : mc.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: mc.onSurfaceVariantActions,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Color?> _showColorPickerDialog(BuildContext context) async {
    Color picked = _themeManager.keyColor;
    return showDialog<Color>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('自定义高级取色器 (OkHSV)'),
          content: StatefulBuilder(
            builder: (context, setDlgState) {
              return SizedBox(
                width: 320,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MiuixColorPicker(
                        color: picked,
                        colorSpace: MiuixColorSpace.okhsv,
                        showPreview: true,
                        onColorChanged: (c) => setDlgState(() => picked = c),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            MiuixTextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            MiuixTextButton(
              onPressed: () => Navigator.pop(context, picked),
              child: const Text('应用'),
            ),
          ],
        );
      },
    );
  }
}

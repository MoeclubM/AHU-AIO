import 'package:flutter/material.dart';
import '../theme_manager.dart';
import 'bloom_stroke_painter.dart';
import 'liquid_glass_filter.dart';
import 'miuix_drop_shadow.dart';
import 'miuix_theme.dart';

/// 液态玻璃质感的卡片容器。
///
/// 半透明填充 + 背景高斯模糊 + BloomStroke 边缘高光，高对比度模式下退化为
/// 不透明实色卡片。
///
/// 注意投影的实现方式：阴影走 [MiuixDropShadow]（只画在形状外侧）。直接给
/// 半透明表面加 [BoxShadow] 会让阴影内部的黑色透出来，整张卡片发暗。
class LiquidGlassCard extends StatelessWidget {
  const LiquidGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.blurSigma = 4,
    this.margin,
    this.padding,
    this.color,
    this.showHighlight = true,
    this.elevation,
  });

  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final Color? color;
  final bool showHighlight;
  final double? elevation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reduceTransparency = MediaQuery.highContrastOf(context);
    final tm = ThemeManager();
    final blurEnabled = tm.enableBlur && !reduceTransparency;
    final glassEnabled =
        tm.enableLiquidGlass && showHighlight && !reduceTransparency;

    final mc = MiuixTheme.of(context).colors;
    final baseColor = color ?? mc.surfaceContainer;
    final fillAlpha = blurEnabled ? 0.40 : (reduceTransparency ? 0.96 : 0.85);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    );

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        children: [
          if (blurEnabled)
            Positioned.fill(
              child: BackdropFilter(
                filter: liquidGlassImageFilter(blurSigma: blurSigma),
                child: Container(color: Colors.transparent),
              ),
            ),
          Positioned.fill(
            child: ColoredBox(color: baseColor.withValues(alpha: fillAlpha)),
          ),
          if (glassEnabled)
            Positioned.fill(
              child: BloomStrokeLayer(
                radius: borderRadius,
                isDark: isDark,
                enabled: glassEnabled,
              ),
            ),
          Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ],
      ),
    );

    if (elevation != null && elevation! > 0) {
      content = MiuixDropShadow(
        shape: shape,
        color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
        sigma: elevation! * 0.5,
        child: content,
      );
    }

    return Container(margin: margin, child: content);
  }
}

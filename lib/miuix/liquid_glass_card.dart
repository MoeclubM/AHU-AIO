import 'package:flutter/material.dart';
import '../theme_manager.dart';
import 'bloom_stroke_painter.dart';
import 'liquid_glass_layer.dart';
import 'miuix_drop_shadow.dart';
import 'miuix_theme.dart';

/// 液态玻璃质感的卡片容器。
///
/// 走完整 [LiquidGlassLayer] 管线：背景模糊 + 边缘折射（lens）+ 填充 +
/// 边缘高光；高对比度模式下退化为不透明实色卡片。
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

  /// 折射高度 / 强度（逻辑像素）：卡片用中等透镜，边缘轻微弯折背景。
  static const double _refraction = 10;

  /// 折射取样外扩，保证边缘能取到形状外的背景纹理。
  static const double _refractionPad = 12;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reduceTransparency = MediaQuery.highContrastOf(context);
    final tm = ThemeManager();
    final blurEnabled = tm.enableBlur && !reduceTransparency;
    final glassEnabled =
        tm.enableLiquidGlass && showHighlight && !reduceTransparency;
    final lensEnabled = glassEnabled && LiquidGlassLayer.isRefractionSupported;

    final mc = MiuixTheme.of(context).colors;
    final baseColor = color ?? mc.surfaceContainer;
    final fillAlpha = blurEnabled ? 0.40 : (reduceTransparency ? 0.96 : 0.85);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    );

    final Widget body = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: child,
    );

    Widget content;
    if (reduceTransparency || (!blurEnabled && !glassEnabled)) {
      content = DecoratedBox(
        decoration: ShapeDecoration(
          color: baseColor.withValues(alpha: fillAlpha),
          shape: shape,
        ),
        child: body,
      );
    } else if (lensEnabled || blurEnabled) {
      content = LiquidGlassLayer(
        cornerRadius: borderRadius,
        blurSigma: blurEnabled ? blurSigma : 0,
        refractionHeight: lensEnabled ? _refraction : 0,
        refractionAmount: lensEnabled ? _refraction : 0,
        padding: lensEnabled ? _refractionPad : 0,
        fillColor: baseColor.withValues(alpha: fillAlpha),
        showHighlight: glassEnabled,
        highlightColor: Colors.white.withValues(alpha: 0.5),
        highlightWidth: 0.5,
        highlightAngle: 45,
        fallbackHighlight: glassEnabled
            ? IgnorePointer(
                child: BloomStrokeLayer(
                  radius: borderRadius,
                  isDark: isDark,
                  enabled: true,
                ),
              )
            : null,
        child: body,
      );
    } else {
      content = DecoratedBox(
        decoration: ShapeDecoration(
          color: baseColor.withValues(alpha: fillAlpha),
          shape: shape,
        ),
        child: body,
      );
    }

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

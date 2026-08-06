import 'package:flutter/material.dart';
import '../theme_manager.dart';
import 'miuix_theme.dart';
import 'bloom_stroke_painter.dart';
import 'liquid_glass_filter.dart';

/// 液态玻璃质感的卡片容器。
///
/// 参考 SukiSU Ultra / compose-miuix-ui miuix 的 Liquid Glass 实现：
/// 背景模糊 (BackdropFilter) + BloomStroke 边缘高光 + 内阴影 +
/// 半透明覆盖层。高对比度模式下退化为不透明实色卡片。
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

    final mc = MiuixColors.of(context);
    final baseColor = color ?? mc.surfaceContainer;
    final fillAlpha = blurEnabled ? 0.40 : (reduceTransparency ? 0.96 : 0.85);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          if (elevation != null && elevation! > 0)
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
              blurRadius: elevation!,
              offset: Offset(0, elevation! * 0.4),
            ),
        ],
      ),
      child: ClipRRect(
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
              child: ColoredBox(color: baseColor.withOpacity(fillAlpha)),
            ),
            if (glassEnabled)
              Positioned.fill(
                child: BloomStrokeLayer(
                  radius: borderRadius,
                  isDark: isDark,
                  enabled: glassEnabled,
                ),
              ),
            if (glassEnabled)
              Positioned.fill(
                child: CustomPaint(
                  painter: _InnerShadowPainter(
                    radius: borderRadius,
                    isDark: isDark,
                  ),
                ),
              ),
            Padding(padding: padding ?? EdgeInsets.zero, child: child),
          ],
        ),
      ),
    );
  }
}

/// 内阴影绘制器，模拟玻璃边缘的凹陷感。
///
/// 在卡片内侧绘制一道柔和的深色阴影，增强玻璃的深度感。
class _InnerShadowPainter extends CustomPainter {
  const _InnerShadowPainter({required this.radius, required this.isDark});

  final double radius;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(radius),
    );

    // 内阴影：在卡片内侧边缘绘制深色渐变
    final shadowColor = Colors.black.withOpacity(isDark ? 0.20 : 0.06);
    final shadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment(0, 0.15),
        colors: [shadowColor, shadowColor.withOpacity(0)],
      ).createShader(Offset.zero & size);

    // 只在内侧绘制：用 clipPath 限制在 rrect 内
    canvas.save();
    canvas.clipRRect(rrect);

    // 顶部内阴影
    final topInner = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h * 0.12),
      Radius.circular(radius),
    );
    canvas.drawRRect(topInner, shadowPaint);

    // 底部内阴影（更弱）
    final bottomShadowColor = Colors.black.withOpacity(isDark ? 0.12 : 0.03);
    final bottomPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment(0, 0.85),
        colors: [bottomShadowColor, bottomShadowColor.withOpacity(0)],
      ).createShader(Offset.zero & size);
    final bottomInner = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, h * 0.88, w, h * 0.12),
      Radius.circular(radius),
    );
    canvas.drawRRect(bottomInner, bottomPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _InnerShadowPainter oldDelegate) =>
      isDark != oldDelegate.isDark || radius != oldDelegate.radius;
}

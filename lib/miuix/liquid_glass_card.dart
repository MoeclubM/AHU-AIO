import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme_manager.dart';

/// 液态玻璃质感的卡片容器。
///
/// 参考 SukiSU Ultra / miuix-blur 的 Liquid Glass 实现：
/// 背景模糊 (BackdropFilter) + 半透明覆盖层 + 顶部高光描边 + 底部反射 +
/// 内阴影增强深度感。高对比度模式下退化为不透明实色卡片。
class LiquidGlassCard extends StatelessWidget {
  const LiquidGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.blurSigma = 24,
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
    final glassEnabled = tm.enableLiquidGlass && showHighlight;
    final r = Radius.circular(borderRadius);

    final baseColor =
        color ?? (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7));
    // 玻璃半透明度：blur 开启时更通透，关闭时接近不透明但仍保留描边高光
    final fillAlpha = blurEnabled
        ? (isDark ? 0.50 : 0.60)
        : (reduceTransparency ? 0.96 : 0.88);

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
          fit: StackFit.passthrough,
          children: [
            // 背景模糊层
            if (blurEnabled)
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: SizedBox.expand(),
              ),
            // 填充层
            Container(
              decoration: BoxDecoration(
                color: baseColor.withOpacity(fillAlpha),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
            // 液态玻璃高光层（顶部高光 + 底部反射 + 内描边）
            if (glassEnabled && !reduceTransparency)
              Positioned.fill(
                child: CustomPaint(
                  painter: _LiquidGlassPainter(
                    radius: r,
                    isDark: isDark,
                  ),
                ),
              ),
            // 内容
            Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// 液态玻璃高光绘制器。
///
/// 绘制三层效果：
/// 1. 顶部高光渐变（模拟光源从上方照射）
/// 2. 底部反射光（模拟环境光反射）
/// 3. 内侧描边（顶部亮、底部暗，模拟玻璃边缘折射）
class _LiquidGlassPainter extends CustomPainter {
  const _LiquidGlassPainter({required this.radius, required this.isDark});

  final Radius radius;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, radius);

    // 1. 顶部高光
    final topHeight = size.height * 0.5;
    final topHighlight = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment(0, topHeight / size.height),
        colors: [
          Colors.white.withOpacity(isDark ? 0.10 : 0.45),
          Colors.white.withOpacity(0),
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect, topHighlight);

    // 2. 底部反射光
    final bottomHighlight = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment(0, 1 - 0.3),
        colors: [
          Colors.white.withOpacity(isDark ? 0.04 : 0.12),
          Colors.white.withOpacity(0),
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect, bottomHighlight);

    // 3. 内侧描边：顶部亮边 + 底部暗边
    final inset = RRect.fromRectAndRadius(rect.deflate(0.5), radius);

    final topStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment(0, 0.6),
        colors: [
          Colors.white.withOpacity(isDark ? 0.20 : 0.60),
          Colors.white.withOpacity(0),
        ],
      ).createShader(rect);
    canvas.drawRRect(inset, topStroke);

    final bottomStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment(0, 0.5),
        colors: [
          Colors.black.withOpacity(isDark ? 0.30 : 0.08),
          Colors.black.withOpacity(0),
        ],
      ).createShader(rect);
    canvas.drawRRect(inset, bottomStroke);
  }

  @override
  bool shouldRepaint(covariant _LiquidGlassPainter oldDelegate) =>
      isDark != oldDelegate.isDark || radius != oldDelegate.radius;
}
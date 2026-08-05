import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme_manager.dart';

/// 液态玻璃质感的卡片容器。
///
/// 参考 SukiSU Ultra / miuix-blur 的 Liquid Glass 实现：
/// 背景模糊 (BackdropFilter) + SDF 边缘光泽 (BloomStroke) + 内阴影 +
/// 半透明覆盖层。高对比度模式下退化为不透明实色卡片。
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
    final glassEnabled =
        tm.enableLiquidGlass && showHighlight && !reduceTransparency;

    final baseColor =
        color ?? (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7));
    final fillAlpha = blurEnabled
        ? (isDark ? 0.45 : 0.55)
        : (reduceTransparency ? 0.96 : 0.85);

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
                  filter: ImageFilter.blur(
                    sigmaX: blurSigma,
                    sigmaY: blurSigma,
                  ),
                  child: Container(color: Colors.transparent),
                ),
              ),
            Positioned.fill(
              child: ColoredBox(color: baseColor.withOpacity(fillAlpha)),
            ),
            if (glassEnabled)
              Positioned.fill(
                child: CustomPaint(
                  painter: _BloomStrokePainter(
                    radius: borderRadius,
                    isDark: isDark,
                  ),
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

/// SDF 圆角矩形边缘光泽绘制器。
///
/// 参考 SukiSU Ultra / miuix-blur 的 BloomStroke：沿圆角矩形边缘的法线光照。
/// 用 SweepGradient 描边模拟半球法线在双定向光源下的反射：
/// - 主光源从左上方照射，顶部+左侧最亮
/// - 副光源从右下方反射，底部+右侧次亮
/// 叠加一道内侧细高光描边模拟玻璃边缘的镜面反射。
class _BloomStrokePainter extends CustomPainter {
  const _BloomStrokePainter({required this.radius, required this.isDark});

  final double radius;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final rr = Radius.circular(
      radius.clamp(0.0, w * 0.5).clamp(0.0, h * 0.5).toDouble(),
    );
    final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), rr);

    // 边缘光泽描边宽度
    final strokeW = (w < h ? w : h) * 0.10;

    // 主边缘光泽：SweepGradient 沿边缘法线方向变化
    final baseAlpha = isDark ? 0.38 : 0.75;
    final primaryColor = Colors.white.withOpacity(baseAlpha);
    final secondaryColor = Colors.white.withOpacity(baseAlpha * 0.35);
    const darkColor = Color(0x00000000);

    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..blendMode = BlendMode.plus
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: -3.14159 / 2,
        endAngle: -3.14159 / 2 + 2 * 3.14159,
        colors: [
          primaryColor,
          secondaryColor,
          darkColor,
          secondaryColor,
          primaryColor,
        ],
        stops: const [0.0, 0.30, 0.55, 0.80, 1.0],
        transform: GradientRotation(-3.14159 / 2),
      ).createShader(Offset.zero & size);
    canvas.drawRRect(rrect.deflate(strokeW * 0.5), edgePaint);

    // 内侧细高光描边：模拟玻璃边缘锐利的镜面反射
    final innerHighlightW = strokeW * 0.28;
    final innerHighlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = innerHighlightW
      ..blendMode = BlendMode.plus
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(isDark ? 0.55 : 0.90),
          Colors.white.withOpacity(isDark ? 0.10 : 0.25),
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(isDark ? 0.05 : 0.15),
        ],
        stops: const [0.0, 0.35, 0.55, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(
      rrect.deflate(strokeW + innerHighlightW * 0.5),
      innerHighlight,
    );
  }

  @override
  bool shouldRepaint(covariant _BloomStrokePainter oldDelegate) =>
      isDark != oldDelegate.isDark || radius != oldDelegate.radius;
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

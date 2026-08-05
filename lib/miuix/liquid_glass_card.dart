import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme_manager.dart';

/// 液态玻璃质感的卡片容器。
///
/// 参考 SukiSU Ultra / miuix-blur 的 Liquid Glass 实现：
/// 背景模糊 (BackdropFilter) + 半透明覆盖层 + 内阴影 + 光泽描边。
/// 根据 [ThemeManager.enableBlur] 控制模糊，[ThemeManager.enableLiquidGlass]
/// 控制高光与 tint 绘制。高对比度模式下退化为不透明实色卡片。
class LiquidGlassCard extends StatelessWidget {
  const LiquidGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.blurSigma = 20,
    this.margin,
    this.padding,
    this.color,
    this.tint,
    this.showHighlight = true,
    this.elevation,
  });

  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final Color? color;
  final Color? tint;
  final bool showHighlight;
  final double? elevation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reduceTransparency = MediaQuery.highContrastOf(context);
    final tm = ThemeManager();
    final blurEnabled = tm.enableBlur && !reduceTransparency;
    final glassEnabled = tm.enableLiquidGlass && blurEnabled;
    final r = Radius.circular(borderRadius);

    final baseColor =
        color ?? (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF));
    final fillColor = !blurEnabled || reduceTransparency
        ? baseColor.withOpacity(reduceTransparency ? 0.96 : 0.92)
        : baseColor.withOpacity(isDark ? 0.55 : 0.65);
    final tintLayer = tint ?? (isDark
        ? Colors.white.withOpacity(0.04)
        : Colors.white.withOpacity(0.5));

    Widget inner = Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(reduceTransparency ? 0.2 : 0.08)
              : Colors.white.withOpacity(reduceTransparency ? 0.6 : 0.45),
          width: 0.5,
        ),
      ),
      padding: padding,
      child: glassEnabled && showHighlight
          ? CustomPaint(
              foregroundPainter: _GlassTintPainter(radius: r, tint: tintLayer),
              child: child,
            )
          : child,
    );

    if (glassEnabled && showHighlight) {
      inner = CustomPaint(
        painter: _GlassHighlightPainter(
          radius: r,
          isDark: isDark,
          showHighlight: showHighlight,
        ),
        child: inner,
      );
    }

    if (blurEnabled) {
      inner = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: inner,
        ),
      );
    } else {
      inner = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: inner,
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          if (elevation != null && elevation! > 0)
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: elevation!,
              offset: Offset(0, elevation! * 0.4),
            ),
        ],
      ),
      child: inner,
    );
  }
}

/// 在卡片顶部绘制一道柔和的高光渐变，模拟液态玻璃的光泽描边。
class _GlassHighlightPainter extends CustomPainter {
  const _GlassHighlightPainter({
    required this.radius,
    required this.isDark,
    required this.showHighlight,
  });

  final Radius radius;
  final bool isDark;
  final bool showHighlight;

  @override
  void paint(Canvas canvas, Size size) {
    if (!showHighlight) return;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, radius);

    final topHighlight = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment(0, 0.35),
        colors: [
          Colors.white.withOpacity(isDark ? 0.12 : 0.6),
          Colors.white.withOpacity(0),
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect, topHighlight);

    final innerStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(isDark ? 0.15 : 0.5),
          Colors.white.withOpacity(0),
        ],
      ).createShader(rect);
    final inset = RRect.fromRectAndRadius(rect.deflate(0.5), radius);
    canvas.drawRRect(inset, innerStroke);
  }

  @override
  bool shouldRepaint(covariant _GlassHighlightPainter oldDelegate) =>
      isDark != oldDelegate.isDark ||
      showHighlight != oldDelegate.showHighlight ||
      radius != oldDelegate.radius;
}

/// 绘制一层微弱的色彩润色，模拟 vibrancy 饱和度增强后的通透感。
class _GlassTintPainter extends CustomPainter {
  const _GlassTintPainter({required this.radius, required this.tint});

  final Radius radius;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, radius);
    canvas.drawRRect(rrect, Paint()..color = tint);
  }

  @override
  bool shouldRepaint(covariant _GlassTintPainter oldDelegate) =>
      tint != oldDelegate.tint || radius != oldDelegate.radius;
}
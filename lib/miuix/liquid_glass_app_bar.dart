import 'dart:ui';
import 'package:flutter/material.dart';
import 'miuix_theme.dart';
import '../theme_manager.dart';

/// 液态玻璃风格的 AppBar 胶囊标题栏。
///
/// 参考 SukiSU Ultra / miuix-blur 的 Liquid Glass 实现：
/// 背景模糊 + SDF 边缘光泽 (BloomStroke) + 内阴影。
/// 根据 [ThemeManager.enableBlur] 控制模糊，[ThemeManager.enableLiquidGlass]
/// 控制高光绘制。
class LiquidGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LiquidGlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = true,
  });

  final String title;
  final List<Widget>? actions;
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reduceTransparency = MediaQuery.highContrastOf(context);
    final tm = ThemeManager();
    final blurEnabled = tm.enableBlur && !reduceTransparency;
    final glassEnabled = tm.enableLiquidGlass && !reduceTransparency;
    const capsuleRadius = 99.0;

    // Material3 模式下使用标准 AppBar
    if (tm.isMaterial3) {
      return AppBar(
        toolbarHeight: 52,
        centerTitle: centerTitle,
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: actions,
      );
    }

    final mc = MiuixColors.of(context);
    final baseColor = isDark
        ? const Color(0xFF1C1C1E)
        : const Color(0xFFF2F2F7);
    final fillAlpha = blurEnabled
        ? (isDark ? 0.45 : 0.55)
        : (reduceTransparency ? 0.96 : 0.85);

    return AppBar(
      toolbarHeight: 52,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(capsuleRadius),
            child: Stack(
              children: [
                if (blurEnabled)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                Positioned.fill(
                  child: ColoredBox(color: baseColor.withOpacity(fillAlpha)),
                ),
                if (glassEnabled)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CapsuleBloomPainter(isDark: isDark),
                    ),
                  ),
                if (glassEnabled)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CapsuleInnerShadowPainter(isDark: isDark),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: mc.onSurface,
        ),
      ),
      actions: actions,
    );
  }
}

/// 胶囊形 SDF 边缘光泽。
class _CapsuleBloomPainter extends CustomPainter {
  const _CapsuleBloomPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    const r = 99.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(r),
    );

    final strokeW = h * 0.14;

    // 主边缘光泽：SweepGradient 描边
    final baseAlpha = isDark ? 0.40 : 0.78;
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

    // 内侧细高光描边
    final innerHighlightW = strokeW * 0.30;
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
  bool shouldRepaint(covariant _CapsuleBloomPainter oldDelegate) =>
      isDark != oldDelegate.isDark;
}

/// 胶囊内阴影。
class _CapsuleInnerShadowPainter extends CustomPainter {
  const _CapsuleInnerShadowPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    const r = 99.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(r),
    );

    canvas.save();
    canvas.clipRRect(rrect);

    // 顶部内阴影
    final topShadow = Colors.black.withOpacity(isDark ? 0.20 : 0.06);
    final topPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment(0, 0.2),
        colors: [topShadow, topShadow.withOpacity(0)],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h * 0.15),
        const Radius.circular(r),
      ),
      topPaint,
    );

    // 底部内阴影
    final bottomShadow = Colors.black.withOpacity(isDark ? 0.12 : 0.03);
    final bottomPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment(0, 0.8),
        colors: [bottomShadow, bottomShadow.withOpacity(0)],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, h * 0.85, w, h * 0.15),
        const Radius.circular(r),
      ),
      bottomPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CapsuleInnerShadowPainter oldDelegate) =>
      isDark != oldDelegate.isDark;
}

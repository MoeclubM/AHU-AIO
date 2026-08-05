import 'dart:ui';
import 'package:flutter/material.dart';
import 'miuix_theme.dart';
import '../theme_manager.dart';

/// 液态玻璃风格的 AppBar 胶囊标题栏。
///
/// 用于各主 tab 页面顶部，呈现悬浮的圆角胶囊玻璃效果。
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

    // Material3 模式下使用标准 AppBar，不应用胶囊玻璃效果
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
    final surfaceColor = theme.colorScheme.surface;

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
            borderRadius: BorderRadius.circular(99),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: blurEnabled ? 16 : 0,
                sigmaY: blurEnabled ? 16 : 0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: blurEnabled
                      ? mc.surface.withOpacity(isDark ? 0.55 : 0.65)
                      : surfaceColor.withOpacity(
                          reduceTransparency ? 0.96 : 0.92,
                        ),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(
                            reduceTransparency ? 0.2 : 0.08,
                          )
                        : Colors.white.withOpacity(
                            reduceTransparency ? 0.6 : 0.45,
                          ),
                    width: 0.5,
                  ),
                ),
                child: glassEnabled
                    ? CustomPaint(
                        painter: _AppBarHighlightPainter(isDark: isDark),
                        child: const SizedBox.expand(),
                      )
                    : null,
              ),
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

class _AppBarHighlightPainter extends CustomPainter {
  const _AppBarHighlightPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(99));

    // 顶部高光
    final topPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment(0, 0.6),
        colors: [
          Colors.white.withOpacity(isDark ? 0.15 : 0.55),
          Colors.white.withOpacity(0),
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect, topPaint);

    // 底部反射
    final bottomPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment(0, 0.6),
        colors: [
          Colors.white.withOpacity(isDark ? 0.04 : 0.12),
          Colors.white.withOpacity(0),
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect, bottomPaint);

    // 内侧亮边
    final inset = RRect.fromRectAndRadius(rect.deflate(0.5), const Radius.circular(99));
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment(0, 0.7),
        colors: [
          Colors.white.withOpacity(isDark ? 0.20 : 0.60),
          Colors.white.withOpacity(0),
        ],
      ).createShader(rect);
    canvas.drawRRect(inset, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _AppBarHighlightPainter oldDelegate) =>
      isDark != oldDelegate.isDark;
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'miuix_theme.dart';

/// 液态玻璃风格的 AppBar 胶囊标题栏。
///
/// 用于各主 tab 页面顶部，呈现悬浮的圆角胶囊玻璃效果。
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
    final mc = MiuixColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceTransparency = MediaQuery.highContrastOf(context);

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
                sigmaX: reduceTransparency ? 0 : 16,
                sigmaY: reduceTransparency ? 0 : 16,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: mc.surface.withOpacity(
                    reduceTransparency ? 0.96 : (isDark ? 0.55 : 0.65),
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
                child: CustomPaint(
                  painter: _AppBarHighlightPainter(isDark: isDark),
                  child: const SizedBox.expand(),
                ),
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
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment(0, 0.5),
        colors: [
          Colors.white.withOpacity(isDark ? 0.1 : 0.5),
          Colors.white.withOpacity(0),
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _AppBarHighlightPainter oldDelegate) =>
      isDark != oldDelegate.isDark;
}

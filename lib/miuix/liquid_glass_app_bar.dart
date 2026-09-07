import 'package:flutter/material.dart';
import 'miuix_theme.dart';
import 'liquid_glass_filter.dart';
import '../theme_manager.dart';

/// 渐变浸润式风格的 AppBar 顶栏。
///
/// 移除传统胶囊药丸气泡框，采用横向贯通的顶部平滑渐变背景层，
/// 居中显示页面标题文字，右侧保留操作按钮，与主流现代移动 App 规范统一。
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
    final reduceTransparency = MediaQuery.highContrastOf(context);
    final tm = ThemeManager();
    final blurEnabled = tm.enableBlur && !reduceTransparency;

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

    final mc = MiuixTheme.of(context).colors;
    final baseColor = theme.colorScheme.surface;

    return AppBar(
      toolbarHeight: 52,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      flexibleSpace: ClipRect(
        child: Stack(
          children: [
            if (blurEnabled)
              Positioned.fill(
                child: BackdropFilter(
                  filter: liquidGlassImageFilter(blurSigma: 6),
                  child: const SizedBox.expand(),
                ),
              ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      baseColor.withOpacity(
                        reduceTransparency ? 0.98 : (blurEnabled ? 0.85 : 0.94),
                      ),
                      baseColor.withOpacity(
                        reduceTransparency ? 0.92 : (blurEnabled ? 0.45 : 0.65),
                      ),
                      baseColor.withOpacity(
                        reduceTransparency ? 0.85 : (blurEnabled ? 0.05 : 0.20),
                      ),
                    ],
                    stops: const [0.0, 0.65, 1.0],
                  ),
                ),
              ),
            ),
          ],
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

import 'package:flutter/material.dart';
import 'miuix_theme.dart';
import 'liquid_glass_filter.dart';
import '../theme_manager.dart';

/// 渐变浸润式风格的 AppBar 顶栏。
///
/// 具备 HyperOS / MIUI 现代规范：
/// - Miuix 模式：横向通透渐变背景 + BackdropFilter 高斯模糊，文字样式与间距精准适配；
/// - Material 3 模式：自动优雅降级为规范的原生 AppBar。
class LiquidGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LiquidGlassAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.bottom,
    this.toolbarHeight = 52,
  });

  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;
  final double toolbarHeight;

  @override
  Size get preferredSize => Size.fromHeight(
        toolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceTransparency = MediaQuery.highContrastOf(context);
    final tm = ThemeManager();
    final blurEnabled = tm.enableBlur && !reduceTransparency;

    // Material3 模式下使用标准 AppBar
    if (tm.isMaterial3) {
      return AppBar(
        toolbarHeight: toolbarHeight,
        leading: leading,
        centerTitle: centerTitle,
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: actions,
        bottom: bottom,
      );
    }

    final mc = MiuixTheme.of(context).colors;
    final baseColor = theme.colorScheme.surface;

    return AppBar(
      toolbarHeight: toolbarHeight,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: leading,
      centerTitle: centerTitle,
      bottom: bottom,
      flexibleSpace: ClipRect(
        child: Stack(
          children: [
            if (blurEnabled)
              Positioned.fill(
                child: BackdropFilter(
                  filter: liquidGlassImageFilter(blurSigma: 8),
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
                        reduceTransparency ? 0.98 : (blurEnabled ? 0.88 : 0.95),
                      ),
                      baseColor.withOpacity(
                        reduceTransparency ? 0.92 : (blurEnabled ? 0.50 : 0.70),
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
          fontSize: 16.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: mc.onSurface,
        ),
      ),
      actions: actions,
    );
  }
}

/// 支持 MIUI / HyperOS 风格的大标题折叠顶栏 Sliver (SliverMiuixLargeTitleAppBar)
class SliverMiuixLargeTitleAppBar extends StatelessWidget {
  const SliverMiuixLargeTitleAppBar({
    super.key,
    required this.title,
    this.actions,
    this.expandedHeight = 110,
    this.collapsedHeight = 52,
  });

  final String title;
  final List<Widget>? actions;
  final double expandedHeight;
  final double collapsedHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tm = ThemeManager();
    final mc = MiuixTheme.of(context).colors;
    final reduceTransparency = MediaQuery.highContrastOf(context);
    final blurEnabled = tm.enableBlur && !reduceTransparency;
    final baseColor = theme.colorScheme.surface;

    if (tm.isMaterial3) {
      return SliverAppBar(
        expandedHeight: expandedHeight,
        toolbarHeight: collapsedHeight,
        pinned: true,
        centerTitle: false,
        actions: actions,
        flexibleSpace: FlexibleSpaceBar(
          title: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 14),
        ),
      );
    }

    return SliverAppBar(
      expandedHeight: expandedHeight,
      toolbarHeight: collapsedHeight,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      actions: actions,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final currentHeight = constraints.biggest.height;
          final isCollapsed = currentHeight <= collapsedHeight + 20;

          return Stack(
            fit: StackFit.expand,
            children: [
              if (blurEnabled && isCollapsed)
                ClipRect(
                  child: BackdropFilter(
                    filter: liquidGlassImageFilter(blurSigma: 8),
                    child: const SizedBox.expand(),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      baseColor.withOpacity(
                        reduceTransparency ? 0.98 : (isCollapsed ? 0.88 : 0.0),
                      ),
                      baseColor.withOpacity(
                        reduceTransparency ? 0.92 : (isCollapsed ? 0.50 : 0.0),
                      ),
                      baseColor.withOpacity(
                        reduceTransparency ? 0.85 : 0.0,
                      ),
                    ],
                    stops: const [0.0, 0.65, 1.0],
                  ),
                ),
              ),
              FlexibleSpaceBar(
                titlePadding: const EdgeInsetsDirectional.only(
                  start: 24,
                  bottom: 14,
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: mc.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

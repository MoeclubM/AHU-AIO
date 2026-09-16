import 'package:flutter/material.dart';

import '../theme_manager.dart';
import 'miuix_theme.dart';

/// 应用顶栏。
///
/// - Miuix 模式：实色 `surface` 背景 + 居中标题（对齐 miuix `SmallTopAppBar` 规范，
///   高度 52、标题 17sp/w500）；内容不会从顶栏下方滚过，因此不叠加毛玻璃，
///   避免无意义的 BackdropFilter 开销。
/// - Material 3 模式：完全交给标准 [AppBar] 与主题默认值，不做任何自定义样式。
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
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context) {
    if (ThemeManager().isMaterial3) {
      return AppBar(
        toolbarHeight: toolbarHeight,
        leading: leading,
        centerTitle: centerTitle,
        title: Text(title),
        actions: actions,
        bottom: bottom,
      );
    }

    final mc = MiuixTheme.of(context).colors;
    return AppBar(
      toolbarHeight: toolbarHeight,
      backgroundColor: mc.surface,
      foregroundColor: mc.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: leading,
      centerTitle: centerTitle,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: mc.onSurface,
        ),
      ),
      actions: actions,
      bottom: bottom,
    );
  }
}

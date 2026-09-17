import 'package:flutter/material.dart';

import '../theme_manager.dart';
import 'miuix_theme.dart';

/// 应用顶栏。
///
/// - Miuix 模式：对齐官方 `SmallTopAppBar` 规格——高度 50、标题用
///   `textStyles.title3`(20sp) + `FontWeight.w500` 并应用 Miuix 字重偏移、
///   实色 `surface` 背景；
/// - Material 3 模式：完全交给标准 [AppBar] 与主题默认值，不做任何自定义样式。
class LiquidGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LiquidGlassAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.bottom,
    this.toolbarHeight = MiuixTopAppBarDefaults.smallTopAppBarCenterHeight,
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

    final MiuixThemeData miuixTheme = MiuixTheme.of(context);
    final mc = miuixTheme.colors;
    // 官方 SmallTopAppBar 的标题规格：title3(20sp) + w500 + 字重偏移。
    final TextStyle titleStyle = miuixTheme.textStyles.title3
        .copyWith(color: mc.onSurface, fontWeight: FontWeight.w500)
        .withMiuixWeight(miuixTheme.fontWeightAdjustment);

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
        style: titleStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: actions,
      bottom: bottom,
    );
  }
}

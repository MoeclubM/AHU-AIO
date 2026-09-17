import 'package:flutter/material.dart';

import '../theme_manager.dart';
import 'miuix_kit.dart';
import 'miuix_theme.dart';

/// 自适应应用顶栏。
///
/// - **Miuix 模式**：用自研的 [MiuixTopAppBar]（对应 Compose
///   `SmallTopAppBar`）——高 50、实色 `surface` 背景、标题 `title3` + `w500`
///   居中；返回键是 [MiuixIconButton] + 自绘箭头，不带 Material 水波纹。
/// - **Material 3 模式**：**完全交给标准 [AppBar] 与主题默认值**——高度
///   `kToolbarHeight`(64)、标题按平台对齐（Android 左对齐）、颜色取
///   `colorScheme`，不套用任何 Miuix 尺寸。
///
/// [title] 收 [Widget] 而不是 `String`，这样调用处可以直接写
/// `title: const Text('设置')`，两种模式各自套用自己的文字规格。
class LiquidGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LiquidGlassAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.centerTitle,
    this.bottom,
    this.toolbarHeight,
  });

  final Widget title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool? centerTitle;
  final PreferredSizeWidget? bottom;
  final double? toolbarHeight;

  bool get _isMaterial3 => ThemeManager().isMaterial3;

  @override
  Size get preferredSize {
    if (_isMaterial3) {
      // 不指定高度时是框架默认（含 bottom 的偏好高度）。
      final double height = toolbarHeight ?? kToolbarHeight;
      return Size.fromHeight(height + (bottom?.preferredSize.height ?? 0.0));
    }
    return Size.fromHeight(
      (toolbarHeight ?? MiuixTopAppBarDefaults.smallTopAppBarCenterHeight) +
          (bottom?.preferredSize.height ?? 0.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isMaterial3) {
      return AppBar(
        leading: leading,
        title: title,
        actions: actions,
        bottom: bottom,
      );
    }

    // Miuix 的导航图标不自动推导，这里按可返回性补一个自绘返回箭头。
    Widget? navigationIcon = leading;
    if (navigationIcon == null) {
      final NavigatorState? navigator = Navigator.maybeOf(context);
      if (navigator != null && navigator.canPop()) {
        navigationIcon = MiuixIconButton(
          icon: MiuixIcons.arrowBack(),
          onPressed: () => Navigator.maybePop(context),
        );
      }
    }

    return MiuixTopAppBar(
      title: title,
      navigationIcon: navigationIcon,
      actions: actions ?? const <Widget>[],
      bottom: bottom,
      height:
          toolbarHeight ?? MiuixTopAppBarDefaults.smallTopAppBarCenterHeight,
    );
  }
}

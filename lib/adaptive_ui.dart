import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'miuix/miuix_components.dart';
import 'miuix/miuix_floating_bar.dart';
import 'theme_manager.dart';

/// 当前是否为 Miuix 风格。MD3 模式返回 false。
bool isMiuixUi() => ThemeManager().isMiuix;

/// 内容页底部预留高度。
///
/// Miuix 悬浮底栏会盖住内容，需要为其（主栏 + 二级栏 + 官方底部间距）预留；
/// Miuix 贴底栏与 MD3 的贴底栏都由 Scaffold 自动避让，只需少量留白。
/// [withSubBar] 为 false 时只预留主底栏高度（如设置页这类没有二级栏的页面）。
double adaptiveBottomPadding(BuildContext context, {bool withSubBar = true}) {
  final tm = ThemeManager();
  final bool floating = tm.isMiuix && tm.enableBottomBarTransparent;
  if (!floating) return 16;
  final base =
      MiuixFloatingBarDefaults.bottomPadding(context) +
      MiuixFloatingBarDefaults.height +
      16;
  if (!withSubBar) return base;
  return base + MiuixFloatingBarDefaults.subBarHeight + 8;
}

/// 内容页统一内边距，底部自动适配当前风格的底栏高度。
EdgeInsets adaptivePagePadding(
  BuildContext context, {
  double horizontal = 16,
  double top = 16,
  double? bottom,
}) {
  return EdgeInsets.fromLTRB(
    horizontal,
    top,
    horizontal,
    bottom ?? adaptiveBottomPadding(context),
  );
}

/// 分组小标题：Miuix 用原生小标题，MD3 用标准 titleSmall。
class AdaptiveSectionTitle extends StatelessWidget {
  const AdaptiveSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    if (isMiuixUi()) return MiuixSmallTitle(title);
    // M3 分组标题 = titleSmall + onSurfaceVariant（primary 不是标题角色）。
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// 设置分组卡片。
///
/// Miuix 使用官方 [MiuixCard]（实色 `surfaceContainer`，与 Compose 版设置页一致）；
/// MD3 使用标准 [Card]。
///
/// 这里刻意不用自绘的液态玻璃卡片：`BoxShadow` 会把形状内部一并填成黑色，
/// 而玻璃卡片的填充是半透明的，于是阴影内部的黑色会透出来，整张卡片发暗。
class AdaptiveCard extends StatelessWidget {
  const AdaptiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.color,
    this.onTap,
    this.elevation,
    this.border,
  });

  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;
  final Color? color;
  final VoidCallback? onTap;
  final double? elevation;
  final BorderSide? border;

  @override
  Widget build(BuildContext context) {
    if (isMiuixUi()) {
      final scheme = Theme.of(context).colorScheme;
      Widget content = MiuixCard(
        cornerRadius: borderRadius,
        insideMargin: padding ?? EdgeInsets.zero,
        colors: color == null
            ? null
            : MiuixCardColors(color: color!, contentColor: scheme.onSurface),
        child: child,
      );
      if (onTap != null) {
        content = MiuixNoRipple(onTap: onTap!, child: content);
      }
      return Padding(padding: margin ?? EdgeInsets.zero, child: content);
    }
    // M3：圆角、elevation、颜色全部交给 CardTheme / Card 默认值，
    // 不再套用 Miuix 的 20 圆角；调用方显式传 borderRadius 时才覆盖。
    Widget content = Padding(padding: padding ?? EdgeInsets.zero, child: child);
    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }
    return Card(
      margin: margin ?? EdgeInsets.zero,
      color: color,
      elevation: elevation,
      shape: (borderRadius == 20 && border == null)
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              side: border ?? BorderSide.none,
            ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}

/// 页面大标题栏：圆形返回按钮 + 左侧大标题，参考 LSPosed 管理器的设置页头部。
class AdaptivePageHeader extends StatelessWidget {
  const AdaptivePageHeader({super.key, required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bool miuix = isMiuixUi();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 设计稿：Miuix 用**普通返回箭头**（无底板），MD3 用**圆形实底按钮**。
          if (miuix)
            AdaptiveIconButton(
              onPressed: onBack ?? () => Navigator.maybePop(context),
              icon: MiuixIcons.arrowBack(),
              size: 24,
            )
          else
            Material(
              color: scheme.surfaceContainerHigh,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onBack ?? () => Navigator.maybePop(context),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.arrow_back, size: 22),
                ),
              ),
            ),
          SizedBox(height: miuix ? 18 : 8),
          Text(title, style: _headerStyle(context, miuix, scheme)),
        ],
      ),
    );
  }
}

/// 分组分隔线：两种风格各自使用主题分隔色。
class AdaptiveDivider extends StatelessWidget {
  const AdaptiveDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (isMiuixUi()) {
      return const Divider(height: 0.5, indent: 20, endIndent: 20);
    }
    // M3：分隔线直接用 outlineVariant 全不透明，不再叠 alpha。
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: scheme.outlineVariant,
    );
  }
}

/// 设置分组容器。
///
/// - Miuix：`surfaceContainer` 卡片包住整组，组内用 0.5dp 分隔线——与 HyperOS
///   设置页一致（一组一张卡）。
/// - Material 3：单个标准 [Card]（主题默认圆角 12）+ 连续 [ListTile]，
///   组内用 [Divider] 分隔。**不再逐项套卡片**，那是 iOS / Miuix 形态。
class AdaptiveSettingsGroup extends StatelessWidget {
  const AdaptiveSettingsGroup({
    super.key,
    required this.children,
    this.dividerIndent = 56,
  });

  final List<Widget> children;

  /// MD3 下分隔线的左侧缩进（对齐 M3 列表的图标列）。
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    final bool miuix = isMiuixUi();
    final List<Widget> rows = [];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(
          miuix
              ? const AdaptiveDivider()
              : Divider(
                  height: 1,
                  thickness: 1,
                  indent: dividerIndent,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
        );
      }
      rows.add(children[i]);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: miuix
          ? MiuixCard(
              cornerRadius: 20,
              insideMargin: EdgeInsets.zero,
              child: Column(mainAxisSize: MainAxisSize.min, children: rows),
            )
          : Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Column(mainAxisSize: MainAxisSize.min, children: rows),
            ),
    );
  }
}

/// 设置行：Miuix 用原生组件，MD3 用标准 ListTile。
class AdaptiveSettingsTile extends StatelessWidget {
  const AdaptiveSettingsTile({
    super.key,
    required this.title,
    this.summary,
    this.leading,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? summary;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (isMiuixUi()) {
      return MiuixComponent(
        title: title,
        summary: summary,
        leading: leading,
        trailing: trailing,
        onTap: onTap,
      );
    }
    return ListTile(
      title: Text(title),
      subtitle: summary != null ? Text(summary!) : null,
      leading: leading,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// 开关行：Miuix 用原生偏好开关，MD3 用标准 SwitchListTile。
class AdaptiveSwitchTile extends StatelessWidget {
  const AdaptiveSwitchTile({
    super.key,
    required this.title,
    this.summary,
    this.leading,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String title;
  final String? summary;
  final Widget? leading;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (isMiuixUi()) {
      return MiuixSwitchPreference(
        title: title,
        summary: summary,
        startAction: leading,
        value: value,
        enabled: enabled,
        onChanged: onChanged,
      );
    }
    return SwitchListTile(
      title: Text(title),
      subtitle: summary != null ? Text(summary!) : null,
      secondary: leading,
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}

/// 主按钮：Miuix 用原生主按钮，MD3 用标准 FilledButton。
class AdaptivePrimaryButton extends StatelessWidget {
  const AdaptivePrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.minimumSize = const Size.fromHeight(48),
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final Size minimumSize;

  @override
  Widget build(BuildContext context) {
    if (isMiuixUi()) {
      return MiuixPrimaryButton(
        onPressed: onPressed,
        icon: icon,
        minimumSize: minimumSize,
        child: child,
      );
    }
    // M3：几何用 FilledButton 默认值（高 40），不套 48/52 这类自定义高度。
    if (icon != null) {
      return FilledButton.icon(onPressed: onPressed, icon: icon!, label: child);
    }
    return FilledButton(onPressed: onPressed, child: child);
  }
}

/// 危险按钮：Miuix 用原生危险按钮，MD3 用错误配色的标准按钮。
class AdaptiveDangerButton extends StatelessWidget {
  const AdaptiveDangerButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.minimumSize = const Size.fromHeight(48),
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final Size minimumSize;

  @override
  Widget build(BuildContext context) {
    if (isMiuixUi()) {
      return MiuixDangerButton(
        onPressed: onPressed,
        icon: icon,
        minimumSize: minimumSize,
        child: child,
      );
    }
    // M3 没有「danger filled」概念：破坏性操作用 error 前景的 tonal 按钮，
    // 几何与配色角色都走主题默认值。
    final scheme = Theme.of(context).colorScheme;
    final TextStyle labelStyle = TextStyle(color: scheme.error);
    if (icon != null) {
      return FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: icon!,
        label: DefaultTextStyle.merge(style: labelStyle, child: child),
      );
    }
    return FilledButton.tonal(
      onPressed: onPressed,
      child: DefaultTextStyle.merge(style: labelStyle, child: child),
    );
  }
}

/// 文本按钮：Miuix 用原生文本按钮，MD3 用标准 TextButton。
class AdaptiveTextButton extends StatelessWidget {
  const AdaptiveTextButton({
    super.key,
    this.text,
    required this.onPressed,
    this.child,
    this.icon,
  });

  final String? text;
  final VoidCallback? onPressed;
  final Widget? child;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final Widget label = child ?? Text(text ?? '');
    if (isMiuixUi()) {
      return MiuixTextButton(onPressed: onPressed, icon: icon, child: label);
    }
    if (icon != null) {
      return TextButton.icon(onPressed: onPressed, icon: icon!, label: label);
    }
    return TextButton(onPressed: onPressed, child: label);
  }
}

/// 图标按钮：Miuix 用无水波纹、按下缩放的原生按钮，MD3 用标准 IconButton。
///
/// 顶栏和卡片里的操作图标都应走这个组件，否则 Miuix 模式会带出 Material 的
/// 水波纹与 48dp 触摸圈，看起来就不是 HyperOS 了。
class AdaptiveIconButton extends StatelessWidget {
  const AdaptiveIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.size,
    this.color,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (isMiuixUi()) {
      final Widget button = MiuixIconButton(
        icon: icon,
        onPressed: onPressed,
        size: size ?? MiuixTopAppBarDefaults.iconSize,
        color: color,
      );
      return tooltip == null
          ? button
          : Tooltip(message: tooltip!, child: button);
    }
    return IconButton(
      icon: icon,
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: size,
      color: color,
    );
  }
}

/// 次级按钮（Tonal 按钮）：Miuix 用原生次级按钮配色（secondaryVariant 底色），MD3 用 FilledButton.tonal。
class AdaptiveSecondaryButton extends StatelessWidget {
  const AdaptiveSecondaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.minimumSize = const Size.fromHeight(40),
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final Size minimumSize;

  @override
  Widget build(BuildContext context) {
    if (isMiuixUi()) {
      return MiuixButton(
        onPressed: onPressed,
        icon: icon,
        minWidth: minimumSize.width,
        minHeight: minimumSize.height,
        child: child,
      );
    }
    if (icon != null) {
      return FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: icon!,
        label: child,
      );
    }
    return FilledButton.tonal(onPressed: onPressed, child: child);
  }
}

/// 描边按钮：Miuix 用 Squircle 描边（无底色，带 outline 边框与按下微缩），MD3 用 OutlinedButton。
class AdaptiveOutlinedButton extends StatelessWidget {
  const AdaptiveOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.minimumSize = const Size.fromHeight(40),
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final Size minimumSize;

  @override
  Widget build(BuildContext context) {
    if (isMiuixUi()) {
      final scheme = Theme.of(context).colorScheme;
      return MiuixButton(
        onPressed: onPressed,
        icon: icon,
        minWidth: minimumSize.width,
        minHeight: minimumSize.height,
        borderSide: BorderSide(color: scheme.outline, width: 0.8),
        colors: MiuixButtonColors(
          color: Colors.transparent,
          disabledColor: Colors.transparent,
          contentColor: scheme.primary,
          disabledContentColor: scheme.onSurfaceVariant.withValues(alpha: 0.38),
        ),
        child: child,
      );
    }
    if (icon != null) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon!,
        label: child,
      );
    }
    return OutlinedButton(onPressed: onPressed, child: child);
  }
}

/// 自适应标签栏。
///
/// - Miuix 模式：完全去除 Material 水波纹与下划线指示器，采用 HyperOS 风格的胶囊滑动/圆角药丸背景，
///   选中项使用 `primary` 柔和底色，无下划线和点击涟漪。
/// - MD3 模式：纯标准 Material 3 TabBar 规范，保留系统默认指示器与主题色彩。
class AdaptiveTabBar extends StatelessWidget implements PreferredSizeWidget {
  const AdaptiveTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.onTap,
    this.isScrollable = false,
    this.padding,
    this.height,
  });

  final List<Widget> tabs;
  final TabController? controller;
  final ValueChanged<int>? onTap;
  final bool isScrollable;
  final EdgeInsetsGeometry? padding;
  final double? height;

  double _calculateHeight() {
    if (height != null) return height!;
    double maxHeight = 46.0;
    for (final Widget item in tabs) {
      if (item is PreferredSizeWidget) {
        maxHeight = math.max(item.preferredSize.height, maxHeight);
      }
    }
    return maxHeight;
  }

  @override
  Size get preferredSize => Size.fromHeight(_calculateHeight());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (isMiuixUi()) {
      return Padding(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: SizedBox(
          height: height,
          child: TabBar(
            controller: controller,
            onTap: onTap,
            isScrollable: isScrollable,
            tabAlignment: isScrollable ? TabAlignment.start : null,
            splashFactory: NoSplash.splashFactory,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: ShapeDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              shape: const MiuixSquircleBorder(cornerRadius: 12),
            ),
            labelColor: scheme.primary,
            unselectedLabelColor: scheme.onSurfaceVariant,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            tabs: tabs,
          ),
        ),
      );
    }
    return TabBar(
      controller: controller,
      onTap: onTap,
      isScrollable: isScrollable,
      tabAlignment: isScrollable ? TabAlignment.start : null,
      padding: padding,
      tabs: tabs,
    );
  }
}

/// 自适应悬浮操作按钮。
///
/// - Miuix 模式：采用 HyperOS 风格的平坦 squircle 形状（无 Material 投射阴影，无水波纹，按下轻微下沉缩放）。
/// - MD3 模式：纯标准 Material 3 FloatingActionButton（标准海拔与调色板）。
class AdaptiveFloatingActionButton extends StatelessWidget {
  const AdaptiveFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    if (isMiuixUi()) {
      final scheme = Theme.of(context).colorScheme;
      final Color bg = backgroundColor ?? scheme.primary;
      final Color fg = foregroundColor ?? scheme.onPrimary;

      Widget button = Container(
        width: 56,
        height: 56,
        decoration: ShapeDecoration(
          color: bg,
          shape: const MiuixSquircleBorder(cornerRadius: 18),
        ),
        child: Center(
          child: IconTheme(
            data: IconThemeData(color: fg, size: 24),
            child: child,
          ),
        ),
      );
      if (onPressed != null) {
        button = MiuixNoRipple(onTap: onPressed!, child: button);
      }
      if (tooltip != null) {
        button = Tooltip(message: tooltip!, child: button);
      }
      return button;
    }
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      child: child,
    );
  }
}

/// 自适应警告/消息弹窗：
///
/// - Miuix 模式：零海拔、24dp Squircle 弹窗，符合 HyperOS 规范。
/// - MD3 模式：标准 Material 3 AlertDialog，28dp 圆角与 tonal elevation。
class AdaptiveAlertDialog extends StatelessWidget {
  const AdaptiveAlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.contentPadding,
  });

  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    final bool miuix = isMiuixUi();
    return AlertDialog(
      title: title,
      content: content,
      contentPadding:
          contentPadding ?? EdgeInsets.fromLTRB(24, 20, 24, miuix ? 16 : 24),
      actions: actions,
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}

/// 打开自适应应用弹窗（避免与 Flutter Material 的 showAdaptiveDialog 冲突）。
Future<T?> showAdaptiveAppDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: builder,
  );
}

/// 自适应确认弹窗。
Future<bool?> showAdaptiveConfirmDialog({
  required BuildContext context,
  required String title,
  required Widget content,
  String confirmText = '确定',
  String cancelText = '取消',
  bool isDanger = false,
}) {
  return showAdaptiveAppDialog<bool>(
    context: context,
    builder: (ctx) {
      return AdaptiveAlertDialog(
        title: Text(title),
        content: content,
        actions: [
          AdaptiveTextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelText),
          ),
          if (isDanger)
            AdaptiveDangerButton(
              minimumSize: const Size(80, 38),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirmText),
            )
          else
            AdaptivePrimaryButton(
              minimumSize: const Size(80, 38),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirmText),
            ),
        ],
      );
    },
  );
}

/// 选项弹窗中的一项。
@immutable
class AdaptiveChoice<T> {
  const AdaptiveChoice({
    required this.value,
    required this.label,
    this.summary,
  });

  final T value;
  final String label;
  final String? summary;
}

/// 单选弹窗：Miuix 用原生单选偏好，MD3 用标准 RadioListTile。
///
/// 参考 LSPosed 管理器的做法——列表只显示当前值，点按后用弹窗完成选择。
Future<T?> showAdaptiveChoiceDialog<T>({
  required BuildContext context,
  required String title,
  required List<AdaptiveChoice<T>> options,
  required T current,
}) {
  return showDialog<T>(
    context: context,
    builder: (ctx) {
      final bool miuix = isMiuixUi();
      return AlertDialog(
        title: Text(title),
        contentPadding: EdgeInsets.symmetric(vertical: miuix ? 6 : 12),
        content: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < options.length; i++) ...[
                  if (i > 0 && !miuix) const SizedBox(height: 2),
                  if (miuix)
                    MiuixRadioButtonPreference(
                      title: options[i].label,
                      summary: options[i].summary,
                      selected: options[i].value == current,
                      radioButtonLocation: MiuixRadioButtonLocation.end,
                      onClick: () => Navigator.pop(ctx, options[i].value),
                    )
                  else
                    RadioListTile<T>(
                      title: Text(options[i].label),
                      subtitle: options[i].summary != null
                          ? Text(options[i].summary!)
                          : null,
                      value: options[i].value,
                      groupValue: current,
                      onChanged: (v) => Navigator.pop(ctx, v),
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          AdaptiveTextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
        ],
      );
    },
  );
}

/// 页头大标题样式。
///
/// Miuix 走官方大标题规格：`textStyles.title1`(32sp) + 常规字重 + 字重偏移
/// （对应官方 `MiuixTopAppBar` 的 largeTitle）；MD3 用框架 headlineLarge。
TextStyle _headerStyle(BuildContext context, bool miuix, ColorScheme scheme) {
  if (!miuix) {
    // M3：大标题取 headlineMedium，字号/字重/字距全由主题决定。
    final theme = Theme.of(context);
    return theme.textTheme.headlineMedium?.copyWith(color: scheme.onSurface) ??
        TextStyle(fontSize: 28, color: scheme.onSurface);
  }
  final theme = MiuixTheme.of(context);
  return theme.textStyles.title1
      .copyWith(color: scheme.onSurface, fontWeight: FontWeight.normal)
      .withMiuixWeight(theme.fontWeightAdjustment);
}

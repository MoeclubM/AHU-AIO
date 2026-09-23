/// Miuix 组件适配层：在自研组件（[miuix_kit.dart]）之上提供项目内统一的
/// 便捷封装（按钮统一带 `icon`、`enabled`、圆角等参数），全部不依赖
/// flutter_miuix 移植包。
library;

import 'package:flutter/material.dart';

import 'miuix_kit.dart' as kit;

export 'miuix_kit.dart' hide MiuixButton;

/// Miuix 风格设置项行组件：基于 [kit.MiuixBasicComponent] 实现。
class MiuixComponent extends StatelessWidget {
  const MiuixComponent({
    super.key,
    required this.title,
    this.summary,
    this.leading,
    this.trailing,
    this.onTap,
    this.padding,
  });

  final String title;
  final String? summary;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return kit.MiuixBasicComponent(
      title: title,
      summary: summary,
      startAction: leading,
      endActions: trailing != null ? [trailing!] : null,
      onClick: onTap,
      insideMargin:
          padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    );
  }
}

/// Miuix 风格按钮：支持 `child`、`icon` 与自定义配色。
///
/// 默认使用次级按钮配色（`secondaryVariant` 底），需要主色时传
/// [kit.MiuixButtonDefaults.buttonColorsPrimary]。
class MiuixButton extends StatelessWidget {
  const MiuixButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.enabled = true,
    this.cornerRadius = kit.MiuixButtonDefaults.cornerRadius,
    this.minWidth = kit.MiuixButtonDefaults.minWidth,
    this.minHeight = kit.MiuixButtonDefaults.minHeight,
    this.colors,
    this.insideMargin = kit.MiuixButtonDefaults.insideMargin,
    this.borderSide,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final bool enabled;
  final double cornerRadius;
  final double minWidth;
  final double minHeight;
  final kit.MiuixButtonColors? colors;
  final EdgeInsetsGeometry insideMargin;
  final BorderSide? borderSide;

  @override
  Widget build(BuildContext context) {
    final bool active = enabled && onPressed != null;
    final kit.MiuixButtonColors c =
        colors ?? kit.MiuixButtonDefaults.buttonColors(context);

    Widget label = child;
    if (icon != null) {
      label = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconTheme.merge(
            data: IconThemeData(
              color: active ? c.contentColor : c.disabledContentColor,
              size: 20,
            ),
            child: icon!,
          ),
          const SizedBox(width: 8),
          child,
        ],
      );
    }

    return kit.MiuixButton(
      onPressed: onPressed,
      enabled: enabled,
      colors: colors,
      cornerRadius: cornerRadius,
      minWidth: minWidth,
      minHeight: minHeight,
      insideMargin: insideMargin,
      borderSide: borderSide,
      child: label,
    );
  }
}

/// Miuix 风格主按钮：主色底 + `onPrimary` 内容。
class MiuixPrimaryButton extends StatelessWidget {
  const MiuixPrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.minimumSize = const Size.fromHeight(48),
    this.borderRadius = kit.MiuixButtonDefaults.cornerRadius,
    this.padding,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final Size minimumSize;
  final double borderRadius;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return MiuixButton(
      onPressed: onPressed,
      icon: icon,
      colors: kit.MiuixButtonDefaults.buttonColorsPrimary(context),
      cornerRadius: borderRadius,
      minWidth: minimumSize.width,
      minHeight: minimumSize.height,
      insideMargin: padding ?? kit.MiuixButtonDefaults.insideMargin,
      child: child,
    );
  }
}

/// Miuix 风格危险按钮：错误色底，用于退出登录等破坏性操作。
class MiuixDangerButton extends StatelessWidget {
  const MiuixDangerButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.minimumSize = const Size.fromHeight(48),
    this.borderRadius = kit.MiuixButtonDefaults.cornerRadius,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final Size minimumSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final kit.MiuixColors c = kit.MiuixTheme.of(context).colors;
    return MiuixButton(
      onPressed: onPressed,
      icon: icon,
      colors: kit.MiuixButtonColors(
        color: c.error,
        disabledColor: c.error.withValues(alpha: 0.38),
        contentColor: c.onError,
        disabledContentColor: c.onError.withValues(alpha: 0.5),
      ),
      cornerRadius: borderRadius,
      minWidth: minimumSize.width,
      minHeight: minimumSize.height,
      child: child,
    );
  }
}

/// Miuix 风格文本按钮：对应 Compose `TextButton`。
///
/// 官方 `textButtonColors` 与默认按钮同为 `secondaryVariant` 底 +
/// `onSecondaryVariant` 内容，只是内容收文字/图标。支持 positional
/// `text` 或 named `child`。
class MiuixTextButton extends StatelessWidget {
  const MiuixTextButton({
    super.key,
    this.text,
    required this.onPressed,
    this.child,
    this.icon,
    this.enabled = true,
    this.borderRadius = kit.MiuixButtonDefaults.cornerRadius,
  });

  final String? text;
  final VoidCallback? onPressed;
  final Widget? child;
  final Widget? icon;
  final bool enabled;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final Widget label = child ?? Text(text ?? '');

    return MiuixButton(
      onPressed: onPressed,
      enabled: enabled,
      icon: icon,
      colors: kit.MiuixButtonDefaults.buttonColors(context),
      cornerRadius: borderRadius,
      child: label,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_miuix/miuix.dart' as miuix_pkg;
import 'package:flutter_miuix/miuix.dart' hide MiuixButton, MiuixTextButton;

export 'package:flutter_miuix/miuix.dart' hide MiuixButton, MiuixTextButton;

/// Miuix 风格设置项行组件，兼容原 [MiuixComponent] 接口并基于 [MiuixBasicComponent] 与 [MiuixTheme] 实现。
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
    return MiuixBasicComponent(
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

/// Miuix 风格按钮，封装 [flutter_miuix] 的 [MiuixButton]，支持 child、icon 以及自定义样式。
class MiuixButton extends StatelessWidget {
  const MiuixButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.enabled = true,
    this.cornerRadius = 16,
    this.minWidth = 58,
    this.minHeight = 40,
    this.colors,
    this.insideMargin = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 13,
    ),
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final bool enabled;
  final double cornerRadius;
  final double minWidth;
  final double minHeight;
  final miuix_pkg.MiuixButtonColors? colors;
  final EdgeInsetsGeometry insideMargin;

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = enabled && onPressed != null;
    final c = colors ?? miuix_pkg.MiuixButtonDefaults.buttonColors(context);
    final txtColor = effectiveEnabled ? c.contentColor : c.disabledContentColor;

    Widget label = child;
    if (icon != null) {
      label = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconTheme.merge(
            data: IconThemeData(color: txtColor, size: 20),
            child: icon!,
          ),
          const SizedBox(width: 8),
          child,
        ],
      );
    }
    return miuix_pkg.MiuixButton(
      onPressed: onPressed,
      enabled: enabled,
      cornerRadius: cornerRadius,
      minWidth: minWidth,
      minHeight: minHeight,
      colors: colors,
      insideMargin: insideMargin,
      child: Center(widthFactor: 1, heightFactor: 1, child: label),
    );
  }
}

/// Miuix 风格主按钮，基于 [MiuixButton] 并使用 primary 配色。
class MiuixPrimaryButton extends StatelessWidget {
  const MiuixPrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.minimumSize = const Size.fromHeight(48),
    this.borderRadius = 16,
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
      colors: miuix_pkg.MiuixButtonDefaults.buttonColorsPrimary(context),
      cornerRadius: borderRadius,
      minHeight: minimumSize.height,
      minWidth: minimumSize.width,
      insideMargin:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: child,
    );
  }
}

/// Miuix 风格危险按钮，用于退出登录等破坏性操作。
class MiuixDangerButton extends StatelessWidget {
  const MiuixDangerButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.minimumSize = const Size.fromHeight(48),
    this.borderRadius = 16,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final Size minimumSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = MiuixTheme.of(context).colors;
    return MiuixButton(
      onPressed: onPressed,
      icon: icon,
      colors: miuix_pkg.MiuixButtonColors(
        color: colors.error,
        disabledColor: colors.error.withOpacity(0.38),
        contentColor: colors.onError,
        disabledContentColor: colors.onError.withOpacity(0.5),
      ),
      cornerRadius: borderRadius,
      minHeight: minimumSize.height,
      minWidth: minimumSize.width,
      child: child,
    );
  }
}

/// Miuix 风格文本按钮，支持 positional text 或 named child/text。
class MiuixTextButton extends StatelessWidget {
  const MiuixTextButton({
    super.key,
    this.text,
    required this.onPressed,
    this.child,
    this.icon,
    this.enabled = true,
    this.borderRadius = 16,
  });

  final String? text;
  final VoidCallback? onPressed;
  final Widget? child;
  final Widget? icon;
  final bool enabled;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    if (text != null && child == null && icon == null) {
      return miuix_pkg.MiuixTextButton(
        text!,
        onPressed: onPressed,
        enabled: enabled,
        cornerRadius: borderRadius,
      );
    }
    final theme = MiuixTheme.of(context);
    final style = TextButton.styleFrom(
      foregroundColor: theme.colors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
    final Widget label = child ?? Text(text ?? '');
    if (icon != null) {
      return TextButton.icon(
        onPressed: enabled ? onPressed : null,
        style: style,
        icon: icon!,
        label: label,
      );
    }
    return TextButton(
      onPressed: enabled ? onPressed : null,
      style: style,
      child: label,
    );
  }
}

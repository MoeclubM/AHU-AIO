import 'package:flutter/material.dart';
import 'miuix_theme.dart';

/// Miuix 风格卡片，对应 miuix 的 [Card] 组件。
///
/// 使用 surfaceContainer 作为底色，16dp 圆角，浅描边。
class MiuixCard extends StatelessWidget {
  const MiuixCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.radius = 16,
    this.color,
    this.onTap,
    this.onLongPress,
  });

  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final mc = MiuixColors.of(context);
    final cardColor = color ?? mc.surfaceContainer;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    final content = Container(
      margin: margin,
      decoration: ShapeDecoration(color: cardColor, shape: shape),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
    if (onTap == null && onLongPress == null) return content;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(radius),
      child: content,
    );
  }
}

/// Miuix 风格小标题，对应 miuix 的 [SmallTitle] 组件。
///
/// 使用 onBackgroundVariant 色，14sp 加粗。
class MiuixSmallTitle extends StatelessWidget {
  const MiuixSmallTitle(this.text, {super.key, this.padding});

  final String text;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final mc = MiuixColors.of(context);
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(28, 8, 28, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: mc.onBackgroundVariant,
        ),
      ),
    );
  }
}

/// Miuix 风格设置项行，对应 miuix 的 [Component] / preference 项。
///
/// 左侧图标 + 标题/副标题，右侧 trailing，点击回调。
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
    final mc = MiuixColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 14)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 16, color: mc.onSurface),
                  ),
                  if (summary != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      summary!,
                      style: TextStyle(
                        fontSize: 13,
                        color: mc.onSurfaceVariantSummary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}

/// Miuix 风格主按钮，对应 miuix 的 [Button] (buttonColorsPrimary)。
///
/// primary 色填充，白色文字，16dp 圆角。
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
    final mc = MiuixColors.of(context);
    final enabled = onPressed != null;
    final color = enabled ? mc.primary : mc.primary.withOpacity(0.38);
    final style = FilledButton.styleFrom(
      backgroundColor: color,
      foregroundColor: mc.onPrimary,
      disabledBackgroundColor: color,
      disabledForegroundColor: mc.onPrimary,
      minimumSize: minimumSize,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      elevation: 0,
    );
    if (icon != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        style: style,
        icon: icon!,
        label: child,
      );
    }
    return FilledButton(onPressed: onPressed, style: style, child: child);
  }
}

/// Miuix 风格次按钮，对应 miuix 的 [Button] (buttonColors)。
///
/// secondaryVariant 灰色填充，onSecondaryVariant 文字，16dp 圆角。
class MiuixButton extends StatelessWidget {
  const MiuixButton({
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
    final mc = MiuixColors.of(context);
    final enabled = onPressed != null;
    final style = FilledButton.styleFrom(
      backgroundColor: enabled
          ? mc.secondaryVariant
          : mc.secondaryVariant.withOpacity(0.38),
      foregroundColor: mc.onSecondaryVariant,
      disabledBackgroundColor: mc.secondaryVariant.withOpacity(0.38),
      disabledForegroundColor: mc.onSecondaryVariant.withOpacity(0.5),
      minimumSize: minimumSize,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      elevation: 0,
    );
    if (icon != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        style: style,
        icon: icon!,
        label: child,
      );
    }
    return FilledButton(onPressed: onPressed, style: style, child: child);
  }
}

/// Miuix 风格文本按钮，对应 miuix 的 [TextButton]。
///
/// 透明背景，primary 色文字，16dp 圆角。
class MiuixTextButton extends StatelessWidget {
  const MiuixTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.borderRadius = 16,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final mc = MiuixColors.of(context);
    final style = TextButton.styleFrom(
      foregroundColor: mc.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
    if (icon != null) {
      return TextButton.icon(
        onPressed: onPressed,
        style: style,
        icon: icon!,
        label: child,
      );
    }
    return TextButton(onPressed: onPressed, style: style, child: child);
  }
}

/// Miuix 风格危险按钮，用于退出登录等破坏性操作。
///
/// error 色填充，onError 文字，16dp 圆角。
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
    final theme = Theme.of(context);
    final enabled = onPressed != null;
    final style = FilledButton.styleFrom(
      backgroundColor: enabled
          ? theme.colorScheme.error
          : theme.colorScheme.error.withOpacity(0.38),
      foregroundColor: theme.colorScheme.onError,
      disabledBackgroundColor: theme.colorScheme.error.withOpacity(0.38),
      disabledForegroundColor: theme.colorScheme.onError.withOpacity(0.5),
      minimumSize: minimumSize,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      elevation: 0,
    );
    if (icon != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        style: style,
        icon: icon!,
        label: child,
      );
    }
    return FilledButton(onPressed: onPressed, style: style, child: child);
  }
}

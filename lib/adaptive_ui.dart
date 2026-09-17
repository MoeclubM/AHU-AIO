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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
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
  });

  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (isMiuixUi()) {
      final scheme = Theme.of(context).colorScheme;
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: MiuixCard(
          cornerRadius: borderRadius,
          insideMargin: padding ?? EdgeInsets.zero,
          colors: color == null
              ? null
              : MiuixCardColors(color: color!, contentColor: scheme.onSurface),
          child: child,
        ),
      );
    }
    return Card(
      margin: margin ?? EdgeInsets.zero,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.symmetric(vertical: 4),
        child: child,
      ),
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
          const SizedBox(height: 18),
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
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: scheme.outlineVariant.withValues(alpha: 0.5),
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
    final style = FilledButton.styleFrom(minimumSize: minimumSize);
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
    final scheme = Theme.of(context).colorScheme;
    final style = FilledButton.styleFrom(
      backgroundColor: scheme.error,
      foregroundColor: scheme.onError,
      minimumSize: minimumSize,
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
    return TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: scheme.onSurface,
    );
  }
  final theme = MiuixTheme.of(context);
  return theme.textStyles.title1
      .copyWith(color: scheme.onSurface, fontWeight: FontWeight.normal)
      .withMiuixWeight(theme.fontWeightAdjustment);
}

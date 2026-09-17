/// 下拉选择：Flutter 的 `DropdownButton` / `DropdownButtonFormField` 属于
/// Material 2 时代组件，从未升级到 M3，所以**两种模式下都会渲染成 MD2**。
/// 这里按风格各给一套实现，替换掉它们：
///
/// - **Miuix**：`surfaceContainer` 卡片式菜单 + squircle 圆角，选中项打勾，
///   条目无 Material 水波纹；触发器是纯文本行（按下只有轻微压暗）；
/// - **Material 3**：`MenuAnchor` + `MenuItemButton`，完全用框架的 M3 菜单
///   默认样式（容器色、圆角、状态层都由主题决定），触发器用 `InkWell`。
library;

import 'package:flutter/material.dart';

import 'adaptive_ui.dart' show isMiuixUi;
import 'miuix/miuix_components.dart';

/// 下拉选项。
@immutable
class AdaptiveDropdownItem<T> {
  const AdaptiveDropdownItem({
    required this.value,
    required this.label,
    this.labelStyle,
  });

  /// 选项值。允许为 null（例如「全部学期」这类无筛选项）。
  final T? value;

  final String label;

  /// 覆盖该项的文字样式（例如把「本周」标成主色加粗）。
  final TextStyle? labelStyle;
}

/// 自适应下拉选择器（点按弹出锚定菜单）。
class AdaptiveDropdown<T> extends StatelessWidget {
  const AdaptiveDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.isExpanded = false,
    this.enabled = true,
    this.textStyle,
    this.chevronSize = 22,
    this.chevronColor,
  });

  final T? value;
  final List<AdaptiveDropdownItem<T>> items;
  final ValueChanged<T?>? onChanged;

  /// 未选中时显示的占位文本。
  final String? hint;

  /// 是否占满可用宽度（等价 `DropdownButton.isExpanded`）。
  final bool isExpanded;

  final bool enabled;
  final TextStyle? textStyle;
  final double chevronSize;

  /// 覆盖箭头颜色（默认取 `onSurfaceVariant`）。
  final Color? chevronColor;

  bool get _enabled => enabled && onChanged != null;

  AdaptiveDropdownItem<T>? get _selected {
    for (final AdaptiveDropdownItem<T> item in items) {
      if (item.value == value) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bool miuix = isMiuixUi();
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AdaptiveDropdownItem<T>? selected = _selected;
    final bool hasValue = selected != null;

    final Color fg = _enabled
        ? scheme.onSurface
        : scheme.onSurface.withValues(alpha: 0.38);

    final Widget content = Row(
      mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
      children: <Widget>[
        Flexible(
          child: Text(
            hasValue ? selected.label : (hint ?? '请选择'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (textStyle ?? theme.textTheme.bodyLarge)?.copyWith(
              color: hasValue ? fg : scheme.onSurfaceVariant,
            ),
          ),
        ),
        if (isExpanded) const Spacer(),
        if (miuix)
          // HyperOS 的展开标记是上下两个细 chevron，不是 Material 的实心三角。
          MiuixIcons.chevronExpand(
            size: chevronSize * 0.6,
            color: _enabled
                ? (chevronColor ?? scheme.onSurfaceVariant)
                : scheme.onSurfaceVariant.withValues(alpha: 0.5),
          )
        else
          Icon(
            Icons.arrow_drop_down_rounded,
            size: chevronSize,
            color: !_enabled
                ? scheme.onSurfaceVariant.withValues(alpha: 0.5)
                : (chevronColor ?? scheme.onSurfaceVariant),
          ),
      ],
    );

    return MenuAnchor(
      // Miuix 自己定菜单外观；MD3 交给框架默认（M3 菜单规范）。
      style: miuix ? _miuixMenuStyle(context) : null,
      menuChildren: <Widget>[
        for (final AdaptiveDropdownItem<T> item in items)
          if (miuix)
            _MiuixMenuItem(
              label: item.label,
              labelStyle: item.labelStyle,
              selected: item.value == value,
              onTap: _enabled
                  ? () {
                      onChanged!(item.value);
                    }
                  : null,
            )
          else
            MenuItemButton(
              onPressed: _enabled ? () => onChanged!(item.value) : null,
              leadingIcon: item.value == value
                  ? const Icon(Icons.check, size: 20)
                  : const SizedBox(width: 20),
              child: Text(item.label, style: item.labelStyle),
            ),
      ],
      builder:
          (BuildContext context, MenuController controller, Widget? child) {
            final Widget trigger = SizedBox(
              width: isExpanded ? double.infinity : null,
              child: content,
            );
            if (!_enabled) return trigger;
            return miuix
                ? MiuixNoRipple(
                    onTap: () => controller.isOpen
                        ? controller.close()
                        : controller.open(),
                    child: trigger,
                  )
                : InkWell(
                    onTap: () => controller.isOpen
                        ? controller.close()
                        : controller.open(),
                    child: trigger,
                  );
          },
    );
  }

  /// Miuix 菜单外观：`surfaceContainer` 底、squircle 圆角 16、无 Material 高度感。
  MenuStyle _miuixMenuStyle(BuildContext context) {
    final MiuixColors c = MiuixTheme.of(context).colors;
    return MenuStyle(
      backgroundColor: WidgetStatePropertyAll<Color>(c.surfaceContainer),
      surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      elevation: const WidgetStatePropertyAll<double>(0),
      shadowColor: WidgetStatePropertyAll<Color>(
        Colors.black.withValues(alpha: 0.12),
      ),
      shape: const WidgetStatePropertyAll<OutlinedBorder>(
        MiuixSquircleBorder(cornerRadius: 16),
      ),
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(vertical: 6),
      ),
      minimumSize: const WidgetStatePropertyAll<Size>(Size(180, 0)),
    );
  }
}

/// Miuix 菜单条目：16dp 内边距、选中项在尾部打勾、无水波纹。
class _MiuixMenuItem extends StatelessWidget {
  const _MiuixMenuItem({
    required this.label,
    required this.selected,
    required this.onTap,
    this.labelStyle,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final MiuixThemeData theme = MiuixTheme.of(context);
    final MiuixColors c = theme.colors;
    final Widget row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  labelStyle ??
                  theme.textStyles.body1
                      .copyWith(color: c.onSurface)
                      .withMiuixWeight(theme.fontWeightAdjustment),
            ),
          ),
          if (selected) ...<Widget>[
            const SizedBox(width: 12),
            Icon(Icons.check, size: 20, color: c.primary),
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return MiuixNoRipple(onTap: onTap!, child: row);
  }
}

/// 表单风格的下拉选择：带标签与容器，替换 `DropdownButtonFormField`。
///
/// - MD3：用 [InputDecorator] 承载标准 Material 装饰（下划线 / 边框由
///   [decoration] 决定），内部是 M3 菜单；
/// - Miuix：`surfaceContainer` 卡片 + squircle 圆角，标签在上、取值在下，
///   不用 Material 的输入框边框。
class AdaptiveDropdownFormField<T> extends StatelessWidget {
  const AdaptiveDropdownFormField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.decoration,
    this.hint,
    this.enabled = true,
  });

  final T? value;
  final List<AdaptiveDropdownItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final InputDecoration? decoration;
  final String? hint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? label = decoration?.labelText;

    if (!isMiuixUi()) {
      return InputDecorator(
        decoration: decoration ?? const InputDecoration(),
        isEmpty: value == null,
        child: AdaptiveDropdown<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          hint: hint,
          isExpanded: true,
          enabled: enabled,
          textStyle: theme.textTheme.bodyLarge,
        ),
      );
    }

    final MiuixThemeData miuix = MiuixTheme.of(context);
    final MiuixColors c = miuix.colors;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: c.surfaceContainer,
        shape: const MiuixSquircleBorder(cornerRadius: 12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (label != null) ...<Widget>[
              Text(
                label,
                style: miuix.textStyles.footnote1
                    .copyWith(color: c.onSurfaceVariantSummary)
                    .withMiuixWeight(miuix.fontWeightAdjustment),
              ),
              const SizedBox(height: 4),
            ],
            AdaptiveDropdown<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              hint: hint,
              isExpanded: true,
              enabled: enabled,
              textStyle: miuix.textStyles.body1
                  .copyWith(color: c.onSurface)
                  .withMiuixWeight(miuix.fontWeightAdjustment),
            ),
          ],
        ),
      ),
    );
  }
}

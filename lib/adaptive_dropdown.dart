/// 下拉选择：Flutter 的 `DropdownButton` / `DropdownButtonFormField` 属于
/// Material 2 时代组件，从未升级到 M3，所以**两种模式下都会渲染成 MD2**。
/// 这里按风格各给一套实现，替换掉它们：
///
/// - **Miuix**：自研专属弹簧弹出动效（弹性缩放 0.82->1.0 + 渐变 + 箭头翻转），
///   `surfaceContainer` 卡片式菜单 + squircle 圆角，选中项打勾，条目按下即时高光；
/// - **Material 3**：`MenuAnchor` + `MenuItemButton`，完全用框架的 M3 菜单
///   默认样式（容器色、圆角、状态层都由主题决定），触发器用 `InkWell`。
library;

import 'dart:math' as math;
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
class AdaptiveDropdown<T> extends StatefulWidget {
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

  @override
  State<AdaptiveDropdown<T>> createState() => _AdaptiveDropdownState<T>();
}

class _AdaptiveDropdownState<T> extends State<AdaptiveDropdown<T>> {
  bool _isOpen = false;

  bool get _enabled => widget.enabled && widget.onChanged != null;

  AdaptiveDropdownItem<T>? get _selected {
    for (final AdaptiveDropdownItem<T> item in widget.items) {
      if (item.value == widget.value) return item;
    }
    return null;
  }

  Future<void> _openMiuixMenu() async {
    if (!_enabled) return;
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final Offset target = box.localToGlobal(Offset.zero);
    final Size size = box.size;
    final Rect triggerRect = target & size;

    setState(() => _isOpen = true);
    final result = await Navigator.of(context).push<_MiuixDropdownResult<T>>(
      _MiuixDropdownRoute<T>(
        triggerRect: triggerRect,
        items: widget.items,
        selectedValue: widget.value,
        isExpanded: widget.isExpanded,
      ),
    );
    if (mounted) {
      setState(() => _isOpen = false);
    }
    if (result != null) {
      widget.onChanged?.call(result.value);
    }
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

    final Widget chevron = AnimatedRotation(
      turns: (miuix && _isOpen) ? 0.5 : 0.0,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      child: miuix
          ? MiuixIcons.chevronExpand(
              size: widget.chevronSize * 0.6,
              color: _enabled
                  ? (widget.chevronColor ?? scheme.onSurfaceVariant)
                  : scheme.onSurfaceVariant.withValues(alpha: 0.5),
            )
          : Icon(
              Icons.arrow_drop_down_rounded,
              size: widget.chevronSize,
              color: !_enabled
                  ? scheme.onSurfaceVariant.withValues(alpha: 0.5)
                  : (widget.chevronColor ?? scheme.onSurfaceVariant),
            ),
    );

    final Widget content = Row(
      mainAxisSize: widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
      children: <Widget>[
        Flexible(
          child: Text(
            hasValue ? selected.label : (widget.hint ?? '请选择'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (widget.textStyle ?? theme.textTheme.bodyLarge)?.copyWith(
              color: hasValue ? fg : scheme.onSurfaceVariant,
            ),
          ),
        ),
        if (widget.isExpanded) const Spacer(),
        chevron,
      ],
    );

    final Widget trigger = SizedBox(
      width: widget.isExpanded ? double.infinity : null,
      child: content,
    );

    if (miuix) {
      if (!_enabled) return trigger;
      return MiuixNoRipple(
        onTap: _openMiuixMenu,
        child: trigger,
      );
    }

    // Material 3 模式：采用标准 MenuAnchor
    return MenuAnchor(
      menuChildren: <Widget>[
        for (final AdaptiveDropdownItem<T> item in widget.items)
          MenuItemButton(
            onPressed: _enabled ? () => widget.onChanged!(item.value) : null,
            leadingIcon: item.value == widget.value
                ? const Icon(Icons.check, size: 20)
                : const SizedBox(width: 20),
            child: Text(item.label, style: item.labelStyle),
          ),
      ],
      builder:
          (BuildContext context, MenuController controller, Widget? child) {
        if (!_enabled) return trigger;
        return InkWell(
          onTap: () => controller.isOpen ? controller.close() : controller.open(),
          child: trigger,
        );
      },
    );
  }
}

class _MiuixDropdownResult<T> {
  const _MiuixDropdownResult(this.value);
  final T? value;
}

/// Miuix 风格弹出菜单路由：支持 HyperOS 弹簧展开、透明度渐变与反向折叠动画。
class _MiuixDropdownRoute<T> extends PopupRoute<_MiuixDropdownResult<T>> {
  _MiuixDropdownRoute({
    required this.triggerRect,
    required this.items,
    required this.selectedValue,
    required this.isExpanded,
    this.barrierLabel = '关闭菜单',
  });

  final Rect triggerRect;
  final List<AdaptiveDropdownItem<T>> items;
  final T? selectedValue;
  final bool isExpanded;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 240);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 180);

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => Colors.black.withValues(alpha: 0.10);

  @override
  final String? barrierLabel;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final Size screenSize = MediaQuery.sizeOf(context);
        final EdgeInsets padding = MediaQuery.paddingOf(context);

        final double spaceBelow =
            screenSize.height - padding.bottom - triggerRect.bottom - 10;
        final double spaceAbove = triggerRect.top - padding.top - 10;
        final bool showBelow = spaceBelow >= 150 || spaceBelow >= spaceAbove;

        final double menuWidth = isExpanded
            ? triggerRect.width
            : math.max(
                180.0,
                math.min(triggerRect.width + 48, screenSize.width - 32),
              );

        final double left = triggerRect.left.clamp(
          16.0,
          math.max(16.0, screenSize.width - 16.0 - menuWidth),
        );

        final double maxHeight =
            math.min(380.0, showBelow ? spaceBelow : spaceAbove);

        return CustomSingleChildLayout(
          delegate: _MiuixDropdownPositionDelegate(
            targetRect: triggerRect,
            menuWidth: menuWidth,
            maxHeight: maxHeight,
            showBelow: showBelow,
            left: left,
          ),
          child: _MiuixMenuCard<T>(
            width: menuWidth,
            maxHeight: maxHeight,
            items: items,
            selectedValue: selectedValue,
          ),
        );
      },
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final Size screenSize = MediaQuery.sizeOf(context);
    final EdgeInsets padding = MediaQuery.paddingOf(context);
    final double spaceBelow =
        screenSize.height - padding.bottom - triggerRect.bottom - 10;
    final double spaceAbove = triggerRect.top - padding.top - 10;
    final bool showBelow = spaceBelow >= 150 || spaceBelow >= spaceAbove;

    final double menuWidth = isExpanded
        ? triggerRect.width
        : math.max(
            180.0,
            math.min(triggerRect.width + 48, screenSize.width - 32),
          );
    final double left = triggerRect.left.clamp(
      16.0,
      math.max(16.0, screenSize.width - 16.0 - menuWidth),
    );
    final double horizontalBias =
        ((triggerRect.center.dx - left) / menuWidth * 2 - 1.0).clamp(-1.0, 1.0);

    final Alignment alignment =
        Alignment(horizontalBias, showBelow ? -1.0 : 1.0);

    final Animation<double> scaleAnimation = CurvedAnimation(
      parent: animation,
      curve: const Cubic(0.2, 0.95, 0.25, 1.04), // HyperOS spring curve
      reverseCurve: Curves.easeInCubic,
    );

    final Animation<double> fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      reverseCurve: Curves.easeIn,
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.82, end: 1.0).animate(scaleAnimation),
        alignment: alignment,
        child: child,
      ),
    );
  }
}

class _MiuixDropdownPositionDelegate extends SingleChildLayoutDelegate {
  const _MiuixDropdownPositionDelegate({
    required this.targetRect,
    required this.menuWidth,
    required this.maxHeight,
    required this.showBelow,
    required this.left,
  });

  final Rect targetRect;
  final double menuWidth;
  final double maxHeight;
  final bool showBelow;
  final double left;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: menuWidth,
      maxWidth: menuWidth,
      minHeight: 0.0,
      maxHeight: maxHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final double top = showBelow
        ? (targetRect.bottom + 6)
        : (targetRect.top - childSize.height - 6);
    return Offset(left, top);
  }

  @override
  bool shouldRelayout(covariant _MiuixDropdownPositionDelegate oldDelegate) {
    return targetRect != oldDelegate.targetRect ||
        menuWidth != oldDelegate.menuWidth ||
        maxHeight != oldDelegate.maxHeight ||
        showBelow != oldDelegate.showBelow ||
        left != oldDelegate.left;
  }
}

/// Miuix 菜单卡片：`surfaceContainer` 底、squircle 圆角 16、柔和扩散阴影。
class _MiuixMenuCard<T> extends StatelessWidget {
  const _MiuixMenuCard({
    required this.width,
    required this.maxHeight,
    required this.items,
    required this.selectedValue,
  });

  final double width;
  final double maxHeight;
  final List<AdaptiveDropdownItem<T>> items;
  final T? selectedValue;

  @override
  Widget build(BuildContext context) {
    final MiuixThemeData theme = MiuixTheme.of(context);
    final MiuixColors c = theme.colors;
    final bool isDark = theme.brightness == Brightness.dark;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: width,
        decoration: ShapeDecoration(
          color: c.surfaceContainer,
          shape: MiuixSquircleBorder(
            cornerRadius: 16,
            side: BorderSide(
              color: c.outline.withValues(alpha: isDark ? 0.35 : 0.5),
              width: 0.6,
            ),
          ),
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.12),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipPath(
          clipper: const ShapeBorderClipper(
            shape: MiuixSquircleBorder(cornerRadius: 16),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final item in items)
                  _MiuixMenuItem(
                    label: item.label,
                    selected: item.value == selectedValue,
                    labelStyle: item.labelStyle,
                    onTap: () {
                      Navigator.of(context)
                          .pop(_MiuixDropdownResult(item.value));
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Miuix 菜单条目：16dp 内边距、选中项在尾部打勾、按压背景平滑高光动画。
class _MiuixMenuItem extends StatefulWidget {
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
  State<_MiuixMenuItem> createState() => _MiuixMenuItemState();
}

class _MiuixMenuItemState extends State<_MiuixMenuItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final MiuixThemeData theme = MiuixTheme.of(context);
    final MiuixColors c = theme.colors;

    final Widget row = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: _pressed
            ? c.secondaryVariant.withValues(alpha: 0.65)
            : Colors.transparent,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (widget.labelStyle ?? theme.textStyles.body1)
                  .copyWith(
                    color: widget.selected ? c.primary : c.onSurface,
                    fontWeight:
                        widget.selected ? FontWeight.w600 : FontWeight.normal,
                  )
                  .withMiuixWeight(theme.fontWeightAdjustment),
            ),
          ),
          if (widget.selected) ...<Widget>[
            const SizedBox(width: 12),
            Icon(Icons.check, size: 20, color: c.primary),
          ],
        ],
      ),
    );

    if (widget.onTap == null) return row;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: row,
    );
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

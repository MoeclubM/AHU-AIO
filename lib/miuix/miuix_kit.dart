/// 自实现的 Miuix 组件集。
///
/// 每个组件的几何与交互都按 compose-miuix-ui 的 Kotlin 源码逐项对齐，**不使用
/// flutter_miuix 移植控件**。主题令牌（颜色 / 字号 / 字重偏移）来自
/// [MiuixTheme]，那是 HyperOS 设计基准。
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart' show SpringDescription, SpringSimulation;
import 'package:flutter/services.dart' show HapticFeedback;

import 'miuix_tokens.dart';

// 令牌随组件一起暴露，使用方 import 本文件即可拿到 MiuixTheme / MiuixColors。
export 'miuix_tokens.dart';

// ---------------------------------------------------------------------------
// 形状
// ---------------------------------------------------------------------------

/// Miuix 的 squircle 形状（连续圆角）。
///
/// 算法对齐 compose-miuix-ui `miuix-squircle` 的 `Path.addSquircleRect`：
/// 三次贝塞尔连续曲率圆角，`control = 0.643`，角部区域 `extension = 1.1`
/// （角部平铺边长 = `cornerRadius * 1.1`）。半径达到短边一半时退化为胶囊。
class MiuixSquircleBorder extends OutlinedBorder {
  const MiuixSquircleBorder({this.cornerRadius = 16, super.side});

  final double cornerRadius;

  /// 三次贝塞尔控制柄比例，与上游 `SQUIRCLE_CONTROL` 一致。
  static const double _control = 0.643;

  /// 角部区域相对 [cornerRadius] 的倍数，与上游 `SquircleDefaults.Extension` 一致。
  static const double extension = 1.1;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _buildPath(rect, cornerRadius);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _buildPath(
    rect.deflate(side.width),
    math.max(0, cornerRadius - side.width),
  );

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width <= 0) return;
    canvas.drawPath(getOuterPath(rect), side.toPaint());
  }

  @override
  ShapeBorder scale(double t) =>
      MiuixSquircleBorder(cornerRadius: cornerRadius * t, side: side.scale(t));

  @override
  OutlinedBorder copyWith({BorderSide? side}) =>
      MiuixSquircleBorder(cornerRadius: cornerRadius, side: side ?? this.side);

  @override
  bool operator ==(Object other) =>
      other is MiuixSquircleBorder &&
      other.cornerRadius == cornerRadius &&
      other.side == side;

  @override
  int get hashCode => Object.hash(cornerRadius, side);

  static Path _buildPath(Rect rect, double radius) {
    final Path path = Path();
    if (rect.isEmpty) return path;
    final double width = rect.width;
    final double height = rect.height;
    final double halfMin = math.min(width, height) * 0.5;
    final double tile = math
        .max(0.0, radius * extension)
        .clamp(0.0, halfMin);
    if (tile <= 0.01) {
      path.addRect(rect);
      return path;
    }
    // 角部区域覆盖到短边一半时是胶囊，用 RRect 保证端点完全圆。
    if (tile >= halfMin - 0.01) {
      path.addRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(halfMin)),
      );
      return path;
    }

    final double handle = tile * (1 - _control);
    final double left = rect.left;
    final double top = rect.top;
    final double right = rect.right;
    final double bottom = rect.bottom;

    path.moveTo(left + tile, top);
    path.lineTo(right - tile, top);
    path.cubicTo(
      right - handle,
      top,
      right,
      top + handle,
      right,
      top + tile,
    );
    path.lineTo(right, bottom - tile);
    path.cubicTo(
      right,
      bottom - handle,
      right - handle,
      bottom,
      right - tile,
      bottom,
    );
    path.lineTo(left + tile, bottom);
    path.cubicTo(
      left + handle,
      bottom,
      left,
      bottom - handle,
      left,
      bottom - tile,
    );
    path.lineTo(left, top + tile);
    path.cubicTo(left, top + handle, left + handle, top, left + tile, top);
    path.close();
    return path;
  }
}

// ---------------------------------------------------------------------------
// 小标题
// ---------------------------------------------------------------------------

/// 分组小标题。对应 Compose `SmallTitle`。
///
/// `subtitle`(14sp 加粗) + `onBackgroundVariant`，内边距 28×8。
class MiuixSmallTitle extends StatelessWidget {
  const MiuixSmallTitle(
    this.text, {
    super.key,
    this.textColor,
    this.insideMargin = const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
  });

  final String text;
  final Color? textColor;
  final EdgeInsetsGeometry insideMargin;

  @override
  Widget build(BuildContext context) {
    final MiuixThemeData theme = MiuixTheme.of(context);
    return Padding(
      padding: insideMargin,
      child: Text(
        text,
        style: theme.textStyles.subtitle
            .copyWith(color: textColor ?? theme.colors.onBackgroundVariant)
            .withMiuixWeight(theme.fontWeightAdjustment),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 卡片
// ---------------------------------------------------------------------------

/// 卡片配色覆盖。对应 Compose `CardColors`。
@immutable
class MiuixCardColors {
  const MiuixCardColors({required this.color, required this.contentColor});

  final Color color;
  final Color contentColor;
}

/// Miuix 卡片。对应 Compose `Card`。
///
/// squircle 圆角 16、`surfaceContainer` 底色、`onSurfaceContainer` 内容色；
/// 传入 [onTap] 后可点击（HyperOS 列表项不显示水波纹）。
class MiuixCard extends StatelessWidget {
  const MiuixCard({
    super.key,
    required this.child,
    this.cornerRadius = 16,
    this.insideMargin = EdgeInsets.zero,
    this.colors,
    this.onTap,
  });

  final Widget child;
  final double cornerRadius;
  final EdgeInsetsGeometry insideMargin;
  final MiuixCardColors? colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final MiuixColors c = MiuixTheme.of(context).colors;
    final Color bg = colors?.color ?? c.surfaceContainer;
    final Color fg = colors?.contentColor ?? c.onSurfaceContainer;

    final Widget content = DecoratedBox(
      decoration: ShapeDecoration(
        color: bg,
        shape: MiuixSquircleBorder(cornerRadius: cornerRadius),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: fg),
          child: IconTheme.merge(
            data: IconThemeData(color: fg),
            child: Padding(padding: insideMargin, child: child),
          ),
        ),
      ),
    );

    if (onTap == null) return content;
    return MiuixNoRipple(onTap: onTap!, child: content);
  }
}

// ---------------------------------------------------------------------------
// 可点击容器
// ---------------------------------------------------------------------------

/// 无涟漪点按包装：HyperOS 的列表项与卡片不显示水波纹，只有按压反馈。
class MiuixNoRipple extends StatefulWidget {
  const MiuixNoRipple({
    super.key,
    required this.onTap,
    required this.child,
    this.onLongPress,
  });

  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget child;

  @override
  State<MiuixNoRipple> createState() => _MiuixNoRippleState();
}

class _MiuixNoRippleState extends State<MiuixNoRipple> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: _pressed
            ? ColoredBox(color: const Color(0x0A000000), child: widget.child)
            : widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 设置行
// ---------------------------------------------------------------------------

/// 设置行。对应 Compose `BasicComponent`。
///
/// 标题 `headline1`(17sp) / `onBackground`，摘要 `body2`(14sp) /
/// `onSurfaceVariantSummary`，四周内边距 16。
class MiuixBasicComponent extends StatelessWidget {
  const MiuixBasicComponent({
    super.key,
    required this.title,
    this.summary,
    this.startAction,
    this.endActions,
    this.onClick,
    this.insideMargin = const EdgeInsets.all(16),
  });

  final String title;
  final String? summary;
  final Widget? startAction;
  final List<Widget>? endActions;
  final VoidCallback? onClick;
  final EdgeInsetsGeometry insideMargin;

  @override
  Widget build(BuildContext context) {
    final MiuixThemeData theme = MiuixTheme.of(context);
    final MiuixColors c = theme.colors;
    final int weight = theme.fontWeightAdjustment;

    final Widget texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: theme.textStyles.headline1
              .copyWith(color: c.onBackground)
              .withMiuixWeight(weight),
        ),
        if (summary != null && summary!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            summary!,
            style: theme.textStyles.body2
                .copyWith(color: c.onSurfaceVariantSummary)
                .withMiuixWeight(weight),
          ),
        ],
      ],
    );

    final Widget row = Row(
      children: [
        if (startAction != null) ...[
          IconTheme.merge(
            data: IconThemeData(color: c.onBackground, size: 24),
            child: startAction!,
          ),
          const SizedBox(width: 16),
        ],
        // 标题区占据剩余空间，右侧动作贴尾。
        Expanded(child: texts),
        if (endActions != null && endActions!.isNotEmpty) ...[
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < endActions!.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                endActions![i],
              ],
            ],
          ),
        ],
      ],
    );

    final Widget padded = Padding(padding: insideMargin, child: row);
    if (onClick == null) return padded;
    return MiuixNoRipple(onTap: onClick!, child: padded);
  }
}

// ---------------------------------------------------------------------------
// 开关
// ---------------------------------------------------------------------------

/// Miuix 开关。对应 Compose `Switch`。
///
/// 轨道 49×28（胶囊）、滑块 20、关闭偏移 4 / 开启偏移 25。
/// 交互对齐 Kotlin 源：点按 / 水平拖拽切换、按压与拖拽时滑块放大 1.127、
/// 位移与缩放用 `spring(0.7/0.6, 987)`，越过半程松手才提交，并带触感反馈。
class MiuixSwitch extends StatefulWidget {
  const MiuixSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  static const double trackWidth = 49;
  static const double trackHeight = 28;
  static const double thumbSize = 20;
  static const double thumbOffsetOff = 4;
  static const double thumbOffsetOn = 25;

  /// 拖拽行程（与 Kotlin `coerceIn(0, 21)` 一致）。
  static const double dragRange = thumbOffsetOn - thumbOffsetOff;

  /// 按压 / 拖拽 / 悬停时的滑块放大倍数。
  static const double thumbPressedScale = 1.127;

  /// 滑块位移弹簧（官方 `spring(0.7, 987)`）。
  static SpringDescription get thumbOffsetSpring =>
      SpringDescription.withDampingRatio(mass: 1, stiffness: 987, ratio: 0.7);

  /// 滑块缩放弹簧（官方 `spring(0.6, 987)`）。
  static SpringDescription get thumbScaleSpring =>
      SpringDescription.withDampingRatio(mass: 1, stiffness: 987, ratio: 0.6);

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  @override
  State<MiuixSwitch> createState() => _MiuixSwitchState();
}

class _MiuixSwitchState extends State<MiuixSwitch>
    with TickerProviderStateMixin {
  late final AnimationController _offsetCtrl;
  late final AnimationController _scaleCtrl;

  /// 本次拖拽的原始位移（dp），仅拖拽中非零。
  double _dragOffset = 0;

  /// 进入拖拽前的累计位移，用于越过 [kTouchSlop]。
  double _preDragDx = 0;
  bool _dragging = false;
  bool _pressed = false;
  bool _hovered = false;
  bool _hasVibrated = false;
  bool _hasVibratedOnce = false;

  @override
  void initState() {
    super.initState();
    _offsetCtrl = AnimationController.unbounded(
      vsync: this,
      value: widget.value
          ? MiuixSwitch.thumbOffsetOn
          : MiuixSwitch.thumbOffsetOff,
    );
    _scaleCtrl = AnimationController.unbounded(vsync: this, value: 1);
  }

  @override
  void didUpdateWidget(MiuixSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_dragging) {
      _animateOffset(_targetOffset);
    }
  }

  @override
  void dispose() {
    _offsetCtrl.dispose();
    _scaleCtrl.dispose();
    super.dispose();
  }

  double get _targetOffset {
    final double base = widget.value
        ? MiuixSwitch.thumbOffsetOn
        : MiuixSwitch.thumbOffsetOff;
    return (base + _dragOffset).clamp(
      MiuixSwitch.thumbOffsetOff,
      MiuixSwitch.thumbOffsetOn,
    );
  }

  bool get _active => widget.enabled && widget.onChanged != null;

  bool get _scaleUp =>
      _active && (_pressed || _dragging || _hovered);

  void _animateOffset(double target, {double velocity = 0}) {
    _offsetCtrl.animateWith(
      SpringSimulation(
        MiuixSwitch.thumbOffsetSpring,
        _offsetCtrl.value,
        target,
        velocity,
      )..tolerance = const Tolerance(distance: 0.05),
    );
  }

  void _animateScale(double target) {
    _scaleCtrl.animateWith(
      SpringSimulation(
        MiuixSwitch.thumbScaleSpring,
        _scaleCtrl.value,
        target,
        0,
      )..tolerance = const Tolerance(distance: 0.001),
    );
  }

  void _syncScale() {
    _animateScale(_scaleUp ? MiuixSwitch.thumbPressedScale : 1);
  }

  void _commit(bool next) {
    if (!_active || next == widget.value) return;
    HapticFeedback.selectionClick();
    widget.onChanged!(next);
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!_active) return;
    _pressed = true;
    _dragging = false;
    _dragOffset = 0;
    _preDragDx = 0;
    _hasVibrated = true;
    _hasVibratedOnce = false;
    _syncScale();
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_active) return;
    final double dx = event.localDelta.dx;
    if (!_dragging) {
      _preDragDx += dx;
      if (_preDragDx.abs() <= kTouchSlop) return;
      _dragging = true;
      _hasVibrated = true;
      _hasVibratedOnce = false;
      _dragOffset = 0;
      _syncScale();
    }

    final double raw = _dragOffset + dx;
    _dragOffset = widget.value
        ? raw.clamp(-MiuixSwitch.dragRange, 0.0)
        : raw.clamp(0.0, MiuixSwitch.dragRange);

    // 对应 Kotlin 的中途 / 到端触感阈值。
    final double a = _dragOffset.abs();
    if (a >= 10 && a <= 11) {
      _hasVibratedOnce = false;
    } else if (a >= 1 && a <= 20) {
      _hasVibrated = false;
    } else if (!_hasVibrated) {
      final bool reached =
          (widget.value && _dragOffset <= -MiuixSwitch.dragRange) ||
          (!widget.value && _dragOffset >= MiuixSwitch.dragRange);
      final bool returned =
          (widget.value && _dragOffset >= 0) ||
          (!widget.value && _dragOffset <= 0);
      if (reached || returned) {
        HapticFeedback.selectionClick();
        _hasVibrated = true;
        _hasVibratedOnce = true;
      }
    }

    _offsetCtrl.value = _targetOffset;
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!_active) return;
    final bool wasDrag = _dragging;
    final double drag = _dragOffset;
    _pressed = false;
    _dragging = false;
    _dragOffset = 0;
    _preDragDx = 0;
    _syncScale();

    if (wasDrag) {
      if (drag.abs() > MiuixSwitch.dragRange / 2) {
        _commit(!widget.value);
      } else {
        _animateOffset(_targetOffset);
      }
      if (!_hasVibratedOnce && drag.abs() >= 1) {
        HapticFeedback.selectionClick();
      }
      return;
    }
    _commit(!widget.value);
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pressed = false;
    _dragging = false;
    _dragOffset = 0;
    _preDragDx = 0;
    _syncScale();
    _animateOffset(_targetOffset);
  }

  @override
  Widget build(BuildContext context) {
    final MiuixThemeData theme = MiuixTheme.of(context);
    final MiuixColors c = theme.colors;
    final bool on = widget.value;

    // 配色对齐 Kotlin `SwitchDefaults.switchColors`：动态取色时关闭态滑块
    // 为 onSurface@38%、禁用开启态滑块为 surface，与静态方案不同。
    final Color track = on
        ? (widget.enabled ? c.primary : c.disabledPrimary)
        : (widget.enabled ? c.secondary : c.disabledSecondary);
    final Color thumb;
    if (on) {
      thumb = widget.enabled
          ? c.onPrimary
          : (theme.isDynamic ? c.surface : c.disabledOnPrimary);
    } else {
      thumb = widget.enabled
          ? (theme.isDynamic
                ? c.onSurface.withValues(alpha: 0.38)
                : c.onSecondary)
          : c.disabledOnSecondary;
    }

    return Semantics(
      toggled: widget.value,
      enabled: widget.enabled,
      child: MouseRegion(
        onEnter: (_) {
          if (!_active) return;
          _hovered = true;
          _syncScale();
        },
        onExit: (_) {
          _hovered = false;
          _syncScale();
        },
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: SizedBox(
            width: MiuixSwitch.trackWidth,
            height: MiuixSwitch.trackHeight,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: track,
                shape: const MiuixSquircleBorder(
                  cornerRadius: MiuixSwitch.trackHeight / 2,
                ),
              ),
              child: AnimatedBuilder(
                animation: Listenable.merge([_offsetCtrl, _scaleCtrl]),
                builder: (context, _) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: MiuixSwitch.thumbOffsetOff,
                        top:
                            (MiuixSwitch.trackHeight - MiuixSwitch.thumbSize) /
                            2,
                      ),
                      child: Transform.translate(
                        offset: Offset(
                          _offsetCtrl.value - MiuixSwitch.thumbOffsetOff,
                          0,
                        ),
                        child: Transform.scale(
                          scale: _scaleCtrl.value,
                          child: DecoratedBox(
                            decoration: ShapeDecoration(
                              color: thumb,
                              shape: const MiuixSquircleBorder(
                                cornerRadius: MiuixSwitch.thumbSize / 2,
                              ),
                            ),
                            child: const SizedBox(
                              width: MiuixSwitch.thumbSize,
                              height: MiuixSwitch.thumbSize,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 开关设置行。对应 Compose `SwitchPreference`。
///
/// 整行可点：点标题区也会切换开关。
class MiuixSwitchPreference extends StatelessWidget {
  const MiuixSwitchPreference({
    super.key,
    required this.title,
    this.summary,
    this.startAction,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.insideMargin = const EdgeInsets.all(16),
  });

  final String title;
  final String? summary;
  final Widget? startAction;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;
  final EdgeInsetsGeometry insideMargin;

  @override
  Widget build(BuildContext context) {
    return MiuixBasicComponent(
      title: title,
      summary: summary,
      startAction: startAction,
      insideMargin: insideMargin,
      endActions: [
        MiuixSwitch(value: value, enabled: enabled, onChanged: onChanged),
      ],
      onClick: enabled ? () => onChanged(!value) : null,
    );
  }
}

/// 单选按钮位置。对应 Compose `RadioButtonLocation`。
enum MiuixRadioButtonLocation { start, end }

/// 单选设置行。对应 Compose `RadioButtonPreference`。
class MiuixRadioButtonPreference extends StatelessWidget {
  const MiuixRadioButtonPreference({
    super.key,
    required this.title,
    this.summary,
    required this.selected,
    required this.onClick,
    this.radioButtonLocation = MiuixRadioButtonLocation.start,
    this.insideMargin = const EdgeInsets.all(16),
  });

  final String title;
  final String? summary;
  final bool selected;
  final VoidCallback onClick;
  final MiuixRadioButtonLocation radioButtonLocation;
  final EdgeInsetsGeometry insideMargin;

  @override
  Widget build(BuildContext context) {
    final MiuixColors c = MiuixTheme.of(context).colors;
    final Widget radio = Icon(
      selected ? Icons.check_circle : Icons.radio_button_unchecked,
      size: 22,
      color: selected ? c.primary : c.outline,
    );

    return MiuixBasicComponent(
      title: title,
      summary: summary,
      insideMargin: insideMargin,
      startAction: radioButtonLocation == MiuixRadioButtonLocation.start
          ? radio
          : null,
      endActions: radioButtonLocation == MiuixRadioButtonLocation.end
          ? [radio]
          : null,
      onClick: onClick,
    );
  }
}

// ---------------------------------------------------------------------------
// 按钮
// ---------------------------------------------------------------------------

/// 按钮配色。对应 Compose `ButtonColors`。
@immutable
class MiuixButtonColors {
  const MiuixButtonColors({
    required this.color,
    required this.disabledColor,
    required this.contentColor,
    required this.disabledContentColor,
  });

  final Color color;
  final Color disabledColor;
  final Color contentColor;
  final Color disabledContentColor;
}

/// 按钮默认规格。对应 Compose `ButtonDefaults`。
abstract final class MiuixButtonDefaults {
  /// 默认（次级）按钮：`secondaryVariant` 底 + `onSecondaryVariant` 内容。
  static MiuixButtonColors buttonColors(BuildContext context) {
    final MiuixColors c = MiuixTheme.of(context).colors;
    return MiuixButtonColors(
      color: c.secondaryVariant,
      disabledColor: c.disabledSecondaryVariant,
      contentColor: c.onSecondaryVariant,
      disabledContentColor: c.disabledOnSecondaryVariant,
    );
  }

  /// 主按钮：`primary` 底 + `onPrimary` 内容。
  static MiuixButtonColors buttonColorsPrimary(BuildContext context) {
    final MiuixColors c = MiuixTheme.of(context).colors;
    return MiuixButtonColors(
      color: c.primary,
      disabledColor: c.disabledPrimaryButton,
      contentColor: c.onPrimary,
      disabledContentColor: c.disabledOnPrimaryButton,
    );
  }

  static const double minWidth = 58;
  static const double minHeight = 40;
  static const double cornerRadius = 16;
  static const EdgeInsets insideMargin = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 13,
  );
}

/// Miuix 按钮。对应 Compose `Button`。
///
/// 最小 58×40、圆角 16、内边距 16×13；按下时整体轻微下沉（无涟漪）。
class MiuixButton extends StatelessWidget {
  const MiuixButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.enabled = true,
    this.colors,
    this.cornerRadius = MiuixButtonDefaults.cornerRadius,
    this.minWidth = MiuixButtonDefaults.minWidth,
    this.minHeight = MiuixButtonDefaults.minHeight,
    this.insideMargin = MiuixButtonDefaults.insideMargin,
    this.borderSide,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool enabled;
  final MiuixButtonColors? colors;
  final double cornerRadius;
  final double minWidth;
  final double minHeight;
  final EdgeInsetsGeometry insideMargin;
  final BorderSide? borderSide;

  @override
  Widget build(BuildContext context) {
    final bool active = enabled && onPressed != null;
    final MiuixButtonColors c =
        colors ?? MiuixButtonDefaults.buttonColors(context);

    return Semantics(
      button: true,
      enabled: active,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth, minHeight: minHeight),
        child: _MiuixButtonSurface(
          enabled: active,
          cornerRadius: cornerRadius,
          backgroundColor: active ? c.color : c.disabledColor,
          foregroundColor: active ? c.contentColor : c.disabledContentColor,
          borderSide: borderSide,
          onTap: onPressed,
          child: Padding(
            padding: insideMargin,
            child: Center(widthFactor: 1, heightFactor: 1, child: child),
          ),
        ),
      ),
    );
  }
}

/// 按钮底层：squircle 背景 + 按压下沉。
class _MiuixButtonSurface extends StatefulWidget {
  const _MiuixButtonSurface({
    required this.enabled,
    required this.cornerRadius,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderSide,
    required this.onTap,
    required this.child,
  });

  final bool enabled;
  final double cornerRadius;
  final Color backgroundColor;
  final Color foregroundColor;
  final BorderSide? borderSide;
  final VoidCallback? onTap;
  final Widget child;

  @override
  State<_MiuixButtonSurface> createState() => _MiuixButtonSurfaceState();
}

class _MiuixButtonSurfaceState extends State<_MiuixButtonSurface> {
  bool _pressed = false;

  void _set(bool v) {
    if (!widget.enabled || _pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: widget.foregroundColor),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: widget.backgroundColor,
              shape: MiuixSquircleBorder(
                cornerRadius: widget.cornerRadius,
                side: widget.borderSide ?? BorderSide.none,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 贴底导航栏
// ---------------------------------------------------------------------------

/// 贴底导航栏。对应 Compose `NavigationBar`。
///
/// 实色 `surface` 背景、顶部 0.5dp `dividerLine` 分隔线、无外边距与胶囊；
/// 条目高 64、图标 26（上边距 8）、标签 12sp（下边距 8）、等宽排列。
class MiuixNavigationBar extends StatelessWidget {
  const MiuixNavigationBar({
    super.key,
    required this.children,
    this.color,
    this.showDivider = true,
    this.defaultWindowInsetsPadding = true,
  });

  static const double itemHeight = 64;
  static const double iconSize = 26;
  static const double iconTopPadding = 8;
  static const double bottomPadding = 8;
  static const double labelFontSize = 12;

  /// 按压 / 未选中的内容不透明度（Compose `NavigationBarDefaults`）。
  static const double selectedPressedAlpha = 0.5;
  static const double unselectedPressedAlpha = 0.6;
  static const double unselectedAlpha = 0.4;

  final List<Widget> children;
  final Color? color;
  final bool showDivider;
  final bool defaultWindowInsetsPadding;

  @override
  Widget build(BuildContext context) {
    final MiuixColors c = MiuixTheme.of(context).colors;
    final double bottomInset = !defaultWindowInsetsPadding
        ? 0
        : (defaultTargetPlatform == TargetPlatform.iOS
              ? 20
              : MediaQuery.viewPaddingOf(context).bottom);

    return ColoredBox(
      color: color ?? c.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDivider)
            SizedBox(
              height: 0.5,
              width: double.infinity,
              child: ColoredBox(color: c.dividerLine),
            ),
          Semantics(
            container: true,
            explicitChildNodes: true,
            child: Row(
              children: [
                for (final Widget child in children) Expanded(child: child),
              ],
            ),
          ),
          if (defaultWindowInsetsPadding)
            SizedBox(width: double.infinity, height: bottomInset),
        ],
      ),
    );
  }
}

/// 贴底导航栏条目。对应 Compose `NavigationBarItem`。
class MiuixNavigationBarItem extends StatefulWidget {
  const MiuixNavigationBarItem({
    super.key,
    required this.selected,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.enabled = true,
  });

  final bool selected;
  final VoidCallback onPressed;
  final Widget icon;
  final String label;
  final bool enabled;

  @override
  State<MiuixNavigationBarItem> createState() => _MiuixNavigationBarItemState();
}

class _MiuixNavigationBarItemState extends State<MiuixNavigationBarItem> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (!widget.enabled || _pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final MiuixThemeData theme = MiuixTheme.of(context);
    final Color base = theme.colors.onSurfaceContainer;

    // 三档不透明度：选中 1.0 / 未选中 0.4 / 按压 0.5 或 0.6。
    final Color tint = _pressed
        ? base.withValues(
            alpha: widget.selected
                ? MiuixNavigationBar.selectedPressedAlpha
                : MiuixNavigationBar.unselectedPressedAlpha,
          )
        : (widget.selected
              ? base
              : base.withValues(alpha: MiuixNavigationBar.unselectedAlpha));

    return Semantics(
      container: true,
      button: true,
      selected: widget.selected,
      label: widget.label,
      onTap: widget.enabled ? widget.onPressed : null,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: widget.enabled ? widget.onPressed : null,
          child: SizedBox(
            height: MiuixNavigationBar.itemHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: MiuixNavigationBar.iconTopPadding,
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(
                      color: tint,
                      size: MiuixNavigationBar.iconSize,
                    ),
                    child: SizedBox.square(
                      dimension: MiuixNavigationBar.iconSize,
                      child: Center(child: widget.icon),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: MiuixNavigationBar.bottomPadding,
                  ),
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: tint,
                      fontSize: MiuixNavigationBar.labelFontSize,
                      fontWeight: widget.selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ).withMiuixWeight(theme.fontWeightAdjustment),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 标签行
// ---------------------------------------------------------------------------

/// 分段标签行。对应 Compose `TabRow`。
///
/// 高 42、圆角 12、条目宽 76–98、间距 9、条目水平内边距 12；选中项以
/// `surfaceContainer` 胶囊标出，未选中项有 1dp `outline` 描边。指示器即时
/// 切换；内容溢出时选中项滚动居中（275ms 减速，首次不播放动画）。
class MiuixTabRow extends StatefulWidget {
  const MiuixTabRow({
    super.key,
    required this.tabs,
    required this.selectedTabIndex,
    required this.onTabSelected,
    this.height = 42,
    this.cornerRadius = 12,
    this.minTabWidth = 76,
    this.maxTabWidth = 98,
    this.itemSpacing = 9,
    this.itemHorizontalPadding = 12,
    this.scrollController,
  });

  final List<String> tabs;
  final int selectedTabIndex;
  final ValueChanged<int> onTabSelected;
  final double height;
  final double cornerRadius;
  final double minTabWidth;
  final double maxTabWidth;
  final double itemSpacing;
  final double itemHorizontalPadding;
  final ScrollController? scrollController;

  @override
  State<MiuixTabRow> createState() => _MiuixTabRowState();
}

class _MiuixTabRowState extends State<MiuixTabRow> {
  late ScrollController _controller;
  int _lastSettled = -1;

  @override
  void initState() {
    super.initState();
    _controller = widget.scrollController ?? ScrollController();
  }

  @override
  void didUpdateWidget(MiuixTabRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      if (oldWidget.scrollController == null) _controller.dispose();
      _controller = widget.scrollController ?? ScrollController();
      _lastSettled = -1;
    }
  }

  @override
  void dispose() {
    if (widget.scrollController == null) _controller.dispose();
    super.dispose();
  }

  /// 条目宽度：`calculateTabWidth`——放得下就等分，否则夹在最小/最大宽度之间。
  double _tabWidth(double available) {
    final int count = widget.tabs.length;
    if (count == 0) return widget.minTabWidth;
    final double totalSpacing = count > 1
        ? (count - 1) * widget.itemSpacing
        : 0;
    final double content = available - totalSpacing;
    if (content <= 0) return widget.minTabWidth;
    final double ideal = content / count;
    if (ideal < widget.minTabWidth) return widget.minTabWidth;
    if (ideal > widget.maxTabWidth) return widget.maxTabWidth;
    return ideal;
  }

  /// 溢出时把选中项滚动到居中。
  void _centerSelected(double available, double tabWidth) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_controller.hasClients || widget.tabs.isEmpty) return;
      final int index = widget.selectedTabIndex.clamp(
        0,
        widget.tabs.length - 1,
      );
      final double pitch = tabWidth + widget.itemSpacing;
      final double target = (index * pitch - (available - tabWidth) / 2).clamp(
        0.0,
        _controller.position.maxScrollExtent,
      );
      final bool animate = _lastSettled >= 0 && _lastSettled != index;
      _lastSettled = index;
      if (_controller.position.pixels == target) return;
      if (animate) {
        try {
          await _controller.animateTo(
            target,
            duration: const Duration(milliseconds: 275),
            curve: Curves.decelerate,
          );
        } catch (_) {
          // 组件在动画途中被销毁时 controller 已释放，忽略这个竞争即可。
        }
      } else if (_controller.hasClients) {
        _controller.jumpTo(target);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final MiuixThemeData theme = MiuixTheme.of(context);
    final MiuixColors c = theme.colors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double available = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 0;
        final double tabWidth = _tabWidth(available);
        _centerSelected(available, tabWidth);

        final int selected = widget.tabs.isEmpty
            ? 0
            : widget.selectedTabIndex.clamp(0, widget.tabs.length - 1);
        final double totalWidth = widget.tabs.isEmpty
            ? 0
            : tabWidth * widget.tabs.length +
                  widget.itemSpacing * (widget.tabs.length - 1);

        final Widget content = SizedBox(
          width: totalWidth,
          height: widget.height,
          child: Stack(
            children: [
              // 选中指示器：即时切换，与 Compose 版一致。
              Positioned(
                left: selected * (tabWidth + widget.itemSpacing),
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: c.surfaceContainer,
                    shape: MiuixSquircleBorder(
                      cornerRadius: widget.cornerRadius,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (int i = 0; i < widget.tabs.length; i++) ...[
                    if (i > 0) SizedBox(width: widget.itemSpacing),
                    _MiuixTabRowItem(
                      text: widget.tabs[i],
                      selected: selected == i,
                      width: tabWidth,
                      cornerRadius: widget.cornerRadius,
                      horizontalPadding: widget.itemHorizontalPadding,
                      color: selected == i
                          ? c.onBackground
                          : c.onSurfaceVariantSummary,
                      outlineColor: c.outline,
                      fontSize: theme.textStyles.body1.fontSize ?? 16,
                      weightAdjustment: theme.fontWeightAdjustment,
                      onTap: () => widget.onTabSelected(i),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );

        return SizedBox(
          height: widget.height,
          child: SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: content,
          ),
        );
      },
    );
  }
}

class _MiuixTabRowItem extends StatelessWidget {
  const _MiuixTabRowItem({
    required this.text,
    required this.selected,
    required this.width,
    required this.cornerRadius,
    required this.horizontalPadding,
    required this.color,
    required this.outlineColor,
    required this.fontSize,
    required this.weightAdjustment,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final double width;
  final double cornerRadius;
  final double horizontalPadding;
  final Color color;
  final Color outlineColor;
  final double fontSize;
  final int weightAdjustment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: double.infinity,
          child: CustomPaint(
            // 未选中项描 1dp outline，对应 Kotlin 的 `squircleBorder(width = 1.dp)`。
            foregroundPainter: selected
                ? null
                : _MiuixInsetBorderPainter(
                    color: outlineColor,
                    radius: cornerRadius,
                  ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Center(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: fontSize,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ).withMiuixWeight(weightAdjustment),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 内缩 0.5dp 的 squircle 描边（避免描边被形状边界裁掉一半）。
class _MiuixInsetBorderPainter extends CustomPainter {
  const _MiuixInsetBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 1;
    const double inset = stroke / 2;
    final Path path =
        MiuixSquircleBorder(
          cornerRadius: math.max(0, radius - inset),
        ).getOuterPath(
          Rect.fromLTWH(
            inset,
            inset,
            size.width - stroke,
            size.height - stroke,
          ),
        );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_MiuixInsetBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

// ---------------------------------------------------------------------------
// 顶栏规格
// ---------------------------------------------------------------------------

/// 顶栏默认规格。对应 Compose `TopAppBarDefaults`。
abstract final class MiuixTopAppBarDefaults {
  /// 小顶栏（居中标题）的高度。
  static const double smallTopAppBarCenterHeight = 50;

  /// 标题的水平内边距。
  static const double titlePadding = 26;

  /// 导航图标距左边缘的内边距。
  static const double navigationIconPadding = 16;

  /// 操作图标距右边缘的内边距。
  static const double actionIconPadding = 16;

  /// 图标按钮的触摸区边长。
  static const double iconButtonSize = 40;

  /// 图标本身尺寸。
  static const double iconSize = 24;
}

/// 小顶栏。对应 Compose `SmallTopAppBar`。
///
/// 规格对齐 Kotlin 源码：高 50、实色 `surface` 背景、无高度感也不随滚动染色；
/// 导航图标左内边距 16，操作图标右内边距 16，标题左右各 26 且居中、
/// `title3` 字号 + `w500`、最多一行省略。
///
/// 与 Material 的 [AppBar] 不同，这里左侧返回键由 [MiuixIconButton] 提供
/// （无水波纹、按下缩放），所以不会带出 Material 的触摸反馈。
class MiuixTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MiuixTopAppBar({
    super.key,
    this.title,
    this.navigationIcon,
    this.actions = const <Widget>[],
    this.bottom,
    this.height = MiuixTopAppBarDefaults.smallTopAppBarCenterHeight,
    this.backgroundColor,
    this.titleColor,
  });

  final Widget? title;
  final Widget? navigationIcon;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  final double height;
  final Color? backgroundColor;
  final Color? titleColor;

  @override
  Size get preferredSize =>
      Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final MiuixThemeData theme = MiuixTheme.of(context);
    final MiuixColors c = theme.colors;

    // 官方 SmallTopAppBar 的标题规格：title3 + w500 + 字重偏移。
    final TextStyle titleStyle = theme.textStyles.title3
        .copyWith(color: titleColor ?? c.onSurface, fontWeight: FontWeight.w500)
        .withMiuixWeight(theme.fontWeightAdjustment);

    // 两侧槽位按「图标按钮 + 内边距」预留，使标题在视觉上居中且永不与图标重叠。
    const double navSlot =
        MiuixTopAppBarDefaults.navigationIconPadding +
        MiuixTopAppBarDefaults.iconButtonSize;
    const double actionSlot =
        MiuixTopAppBarDefaults.actionIconPadding +
        MiuixTopAppBarDefaults.iconButtonSize;

    final Widget bar = Row(
      children: <Widget>[
        SizedBox(
          width: navSlot,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: MiuixTopAppBarDefaults.navigationIconPadding,
              ),
              child: navigationIcon ?? const SizedBox.shrink(),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MiuixTopAppBarDefaults.titlePadding,
            ),
            child: DefaultTextStyle(
              style: titleStyle,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              child: title ?? const SizedBox.shrink(),
            ),
          ),
        ),
        SizedBox(
          // 无论有没有操作图标都占满槽位，否则标题会偏离中心。
          width: actionSlot,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                end: MiuixTopAppBarDefaults.actionIconPadding,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: actions),
            ),
          ),
        ),
      ],
    );

    // 与 Material AppBar 的 primary 行为一致：状态栏高度由顶栏自己吃掉，
    // preferredSize 里不含它（Scaffold 会按实际高度布局）。
    final double topPadding = MediaQuery.paddingOf(context).top;
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: Material(
        color: backgroundColor ?? c.surface,
        elevation: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(height: topPadding),
            SizedBox(height: height, child: bar),
            ?bottom,
          ],
        ),
      ),
    );
  }
}

/// Miuix 图标按钮：40×40 触摸区、无水波纹，按下时图标缩到 0.88。
class MiuixIconButton extends StatefulWidget {
  const MiuixIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = MiuixTopAppBarDefaults.iconSize,
    this.color,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;

  @override
  State<MiuixIconButton> createState() => _MiuixIconButtonState();
}

class _MiuixIconButtonState extends State<MiuixIconButton> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final MiuixColors c = MiuixTheme.of(context).colors;
    final Color color = widget.color ?? c.onSurface;
    final bool enabled = widget.onPressed != null;
    final Widget content = IconTheme.merge(
      data: IconThemeData(
        size: widget.size,
        color: enabled ? color : color.withValues(alpha: 0.38),
      ),
      child: SizedBox(
        width: MiuixTopAppBarDefaults.iconButtonSize,
        height: MiuixTopAppBarDefaults.iconButtonSize,
        child: Center(child: widget.icon),
      ),
    );

    if (!enabled) return content;

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.88 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: content,
        ),
      ),
    );
  }
}

/// Miuix 图标：按 HyperOS 的字形自绘，避免带出 Material 图标风格。
abstract final class MiuixIcons {
  /// 返回箭头：一根横杆 + 左向箭头。
  static Widget arrowBack({double size = MiuixTopAppBarDefaults.iconSize}) =>
      _MiuixArrowBackPainter(size: size);

  /// 展开指示：上下两个细 chevron（HyperOS 下拉行的尾部标记）。
  static Widget chevronExpand({
    double size = 14,
    Color? color,
    double strokeWidth = 1.6,
  }) => _MiuixChevronExpandPainter(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
  );
}

class _MiuixChevronExpandPainter extends StatelessWidget {
  const _MiuixChevronExpandPainter({
    required this.size,
    required this.color,
    required this.strokeWidth,
  });

  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 1.5),
      painter: _ChevronExpandPainter(
        color: color ?? IconTheme.of(context).color ?? const Color(0xFF000000),
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _ChevronExpandPainter extends CustomPainter {
  const _ChevronExpandPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final double w = size.width;
    final double h = size.height;
    final double mid = w / 2;
    // 上半：^
    final Path up = Path()
      ..moveTo(w * 0.08, h * 0.42)
      ..lineTo(mid, h * 0.20)
      ..lineTo(w * 0.92, h * 0.42);
    // 下半：v
    final Path down = Path()
      ..moveTo(w * 0.08, h * 0.58)
      ..lineTo(mid, h * 0.80)
      ..lineTo(w * 0.92, h * 0.58);
    canvas.drawPath(up, paint);
    canvas.drawPath(down, paint);
  }

  @override
  bool shouldRepaint(covariant _ChevronExpandPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

class _MiuixArrowBackPainter extends StatelessWidget {
  const _MiuixArrowBackPainter({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _ArrowBackPainter(
        color: IconTheme.of(context).color ?? const Color(0xFF000000),
      ),
    );
  }
}

class _ArrowBackPainter extends CustomPainter {
  const _ArrowBackPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final double w = size.width;
    final double h = size.height;
    final Offset tip = Offset(w * 0.20, h * 0.5);
    canvas.drawLine(
      Offset(w * 0.20, h * 0.5),
      Offset(w * 0.82, h * 0.5),
      paint,
    );
    canvas.drawLine(tip, Offset(w * 0.46, h * 0.24), paint);
    canvas.drawLine(tip, Offset(w * 0.46, h * 0.76), paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowBackPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ---------------------------------------------------------------------------
// 取色器
// ---------------------------------------------------------------------------

/// 取色器色彩空间。
enum MiuixColorSpace {
  /// OKLCH：感知均匀，明度 / 彩度 / 色相相互独立（默认）。
  oklch,

  /// HSV：Flutter 标准色相 / 饱和度 / 明度。
  hsv,
}

/// Miuix 取色器：2D 面板 + 色相条 + 可选预览。
///
/// 自实现取色器，默认走 OKLCH（感知均匀，改明度不会带动色相偏移），也可以
/// 切到 [MiuixColorSpace.hsv]。结构对应 HyperOS 取色弹窗：上方 2D 面板、
/// 下方色相条、底部预览与十六进制值。
class MiuixColorPicker extends StatefulWidget {
  const MiuixColorPicker({
    super.key,
    required this.color,
    required this.onColorChanged,
    this.colorSpace = MiuixColorSpace.oklch,
    this.showPreview = true,
    this.panelHeight = 180,
  });

  final Color color;
  final ValueChanged<Color> onColorChanged;
  final MiuixColorSpace colorSpace;
  final bool showPreview;
  final double panelHeight;

  @override
  State<MiuixColorPicker> createState() => _MiuixColorPickerState();
}

class _MiuixColorPickerState extends State<MiuixColorPicker> {
  /// 色相（0–1）。
  double _h = 0;

  /// 面板横轴：OKLCH 为彩度，HSV 为饱和度。
  double _axisX = 0;

  /// 面板纵轴取值：明度（0–1），显示时上下翻转。
  double _lightness = 1;

  @override
  void initState() {
    super.initState();
    _syncFromColor(widget.color);
  }

  @override
  void didUpdateWidget(MiuixColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 外部换色（例如点了预设色）时重新同步，避免面板停在旧位置。
    if (oldWidget.color != widget.color) _syncFromColor(widget.color);
  }

  void _syncFromColor(Color color) {
    if (widget.colorSpace == MiuixColorSpace.oklch) {
      final Oklch v = Oklch.fromColor(color);
      _h = v.h;
      _axisX = v.c;
      _lightness = v.l;
    } else {
      final HSVColor v = HSVColor.fromColor(color);
      _h = v.hue / 360;
      _axisX = v.saturation;
      _lightness = v.value;
    }
  }

  Color get _current => widget.colorSpace == MiuixColorSpace.oklch
      ? Oklch(h: _h, c: _axisX, l: _lightness).toColor()
      : HSVColor.fromAHSV(1, _h * 360, _axisX, _lightness).toColor();

  @override
  Widget build(BuildContext context) {
    final MiuixThemeData theme = MiuixTheme.of(context);
    final MiuixColors c = theme.colors;
    final bool oklch = widget.colorSpace == MiuixColorSpace.oklch;
    final double axisMax = oklch ? Oklch.maxChroma : 1.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: widget.panelHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LayoutBuilder(
              builder: (context, constraints) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanDown: (d) => _onPanel(
                  d.localPosition,
                  Size(constraints.maxWidth, constraints.maxHeight),
                  axisMax,
                ),
                onPanUpdate: (d) => _onPanel(
                  d.localPosition,
                  Size(constraints.maxWidth, constraints.maxHeight),
                  axisMax,
                ),
                child: CustomPaint(
                  painter: _MiuixPickerPanelPainter(
                    oklch: oklch,
                    hue: _h,
                    x: (_axisX / axisMax).clamp(0.0, 1.0),
                    y: (1 - _lightness).clamp(0.0, 1.0),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 28,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: LayoutBuilder(
              builder: (context, constraints) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanDown: (d) => _onHue(
                  d.localPosition,
                  Size(constraints.maxWidth, constraints.maxHeight),
                ),
                onPanUpdate: (d) => _onHue(
                  d.localPosition,
                  Size(constraints.maxWidth, constraints.maxHeight),
                ),
                child: CustomPaint(painter: _MiuixHueBarPainter(hue: _h)),
              ),
            ),
          ),
        ),
        if (widget.showPreview) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _current,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.outline, width: 0.5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _hex(_current),
                  style: theme.textStyles.body1.copyWith(
                    color: c.onSurfaceVariantSummary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _onPanel(Offset local, Size size, double axisMax) {
    if (size.isEmpty) return;
    setState(() {
      _axisX = (local.dx / size.width).clamp(0.0, 1.0) * axisMax;
      _lightness = 1 - (local.dy / size.height).clamp(0.0, 1.0);
    });
    widget.onColorChanged(_current);
  }

  void _onHue(Offset local, Size size) {
    if (size.isEmpty) return;
    setState(() => _h = (local.dx / size.width).clamp(0.0, 1.0));
    widget.onColorChanged(_current);
  }

  static String _hex(Color color) {
    final String argb = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${argb.substring(2).toUpperCase()}';
  }
}

/// 取色面板：横轴彩度 / 饱和度，纵轴明度，底图按当前色相预渲染。
class _MiuixPickerPanelPainter extends CustomPainter {
  const _MiuixPickerPanelPainter({
    required this.oklch,
    required this.hue,
    required this.x,
    required this.y,
  });

  final bool oklch;
  final double hue;
  final double x;
  final double y;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    // 用网格填充代替逐像素着色，24×24 在 200px 高度下已看不出色阶。
    const int cols = 24;
    const int rows = 24;
    final double cw = size.width / cols;
    final double ch = size.height / rows;
    final double axisMax = oklch ? Oklch.maxChroma : 1.0;

    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        final double cx = ((i + 0.5) / cols) * axisMax;
        final double lightness = 1 - (j + 0.5) / rows;
        final Color color = oklch
            ? Oklch(h: hue, c: cx, l: lightness).toColor()
            : HSVColor.fromAHSV(1, hue * 360, cx, lightness).toColor();
        canvas.drawRect(
          Rect.fromLTWH(i * cw, j * ch, cw + 0.5, ch + 0.5),
          Paint()..color = color,
        );
      }
    }

    // 圆形选择指示器：白环 + 深色描边，保证在任何底色上都可见。
    final Offset center = Offset(x * size.width, y * size.height);
    canvas.drawCircle(
      center,
      9,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(
      center,
      9,
      Paint()
        ..color = const Color(0x66000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_MiuixPickerPanelPainter oldDelegate) =>
      oldDelegate.oklch != oklch ||
      oldDelegate.hue != hue ||
      oldDelegate.x != x ||
      oldDelegate.y != y;
}

/// 色相条：按恒定明度 / 彩度铺开整个色相环。
class _MiuixHueBarPainter extends CustomPainter {
  const _MiuixHueBarPainter({required this.hue});

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    const int steps = 48;
    final double w = size.width / steps;
    for (int i = 0; i < steps; i++) {
      canvas.drawRect(
        Rect.fromLTWH(i * w, 0, w + 0.5, size.height),
        Paint()
          ..color = Oklch(h: (i + 0.5) / steps, c: 0.18, l: 0.62).toColor(),
      );
    }
    final double cx = hue * size.width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          (cx - 3).clamp(1.0, math.max(1.0, size.width - 7)),
          1,
          6,
          math.max(0, size.height - 2),
        ),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFFFFFFF),
    );
  }

  @override
  bool shouldRepaint(_MiuixHueBarPainter oldDelegate) => oldDelegate.hue != hue;
}

/// OKLCH 颜色：h ∈ [0,1]，c ∈ [0, maxChroma]，l ∈ [0,1]。
///
/// 用 Björn Ottosson 的 OKLab 定义：线性 sRGB → 立方根 LMS → 近似感知均匀的
/// Lab；转回时按标准矩阵回到线性 sRGB 再做 gamma 编码。
@immutable
class Oklch {
  const Oklch({required this.h, required this.c, required this.l});

  /// 彩度上限：OKLab 的 a/b 在 ±0.4 内基本覆盖 sRGB 色域。
  static const double maxChroma = 0.4;

  final double h;
  final double c;
  final double l;

  factory Oklch.fromColor(Color color) {
    final double r = _linearize(color.r);
    final double g = _linearize(color.g);
    final double b = _linearize(color.b);

    final double l_ = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b;
    final double m_ = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b;
    final double s_ = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b;

    final double lc = math.pow(l_, 1 / 3).toDouble();
    final double mc = math.pow(m_, 1 / 3).toDouble();
    final double sc = math.pow(s_, 1 / 3).toDouble();

    final double lightness =
        0.2104542553 * lc + 0.7936177850 * mc - 0.0040720468 * sc;
    final double a = 1.9779984951 * lc - 2.4285922050 * mc + 0.4505937099 * sc;
    final double bb = 0.0259040371 * lc + 0.7827717662 * mc - 0.8086757660 * sc;

    double hue = math.atan2(bb, a) / (2 * math.pi);
    if (hue < 0) hue += 1;
    return Oklch(h: hue, c: math.sqrt(a * a + bb * bb), l: lightness);
  }

  Color toColor() {
    final double a = c * math.cos(2 * math.pi * h);
    final double b = c * math.sin(2 * math.pi * h);

    final double l_ = l + 0.3963377774 * a + 0.2158037573 * b;
    final double m_ = l - 0.1055613458 * a - 0.0638541728 * b;
    final double s_ = l - 0.0894841775 * a - 1.2914855480 * b;

    final double lc = l_ * l_ * l_;
    final double mc = m_ * m_ * m_;
    final double sc = s_ * s_ * s_;

    final double r = 4.0767416621 * lc - 3.3077115913 * mc + 0.2309699292 * sc;
    final double g = -1.2684380046 * lc + 2.6097574011 * mc - 0.3413193965 * sc;
    final double bb =
        -0.0041960863 * lc - 0.7034186147 * mc + 1.7076147010 * sc;

    return Color.from(
      alpha: 1,
      red: _encode(r),
      green: _encode(g),
      blue: _encode(bb),
    );
  }

  /// sRGB 电光转换 → 线性。
  static double _linearize(double v) =>
      v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

  /// 线性 → sRGB 电光转换（越界值裁剪到色域内）。
  static double _encode(double v) {
    final double clamped = v.clamp(0.0, 1.0);
    return clamped <= 0.0031308
        ? clamped * 12.92
        : 1.055 * math.pow(clamped, 1 / 2.4) - 0.055;
  }
}

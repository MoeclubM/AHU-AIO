import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../theme_manager.dart';
import 'liquid_glass_filter.dart';
import 'miuix_drop_shadow.dart';
import 'miuix_theme.dart';

/// 悬浮胶囊底栏的官方几何、配色与动效常量。
///
/// 数值取自 Compose 版 miuix：
/// - 液态玻璃栏 `example/.../liquid/LiquidGlassNavigationBar.kt`：高度 64（内层 56）、
///   内边距 4、外边距 24、图标 22、标签 11sp、条目等宽、填充 `surfaceContainer@0.4`、
///   高光 alpha 0.75、阴影 radius 10 黑 10%/20%、指示器 `accent@0.15`；
/// - 阻尼拖拽 `component/animation/DampedDragAnimation.kt`：指示器位移弹簧
///   `spring(1.0, 1000)`、按压弹簧 `spring(1.0, 1000)`、缩放 `spring(0.6/0.7, 250)`、
///   速度驱动的拉伸/压缩、外侧橡皮筋 4dp。
class MiuixFloatingBarDefaults {
  MiuixFloatingBarDefaults._();

  /// 主底栏高度（官方 64dp）。
  static const double height = 64;

  /// 二级底栏高度（官方内层内容高 56dp）。
  static const double subBarHeight = 56;

  /// 胶囊内四周留白（官方 4dp）。
  static const EdgeInsets insidePadding = EdgeInsets.all(4);

  /// 胶囊左右外边距（官方 24dp）。
  static const double horizontalMargin = 24;

  /// 主底栏图标尺寸（官方 22dp）。
  static const double iconSize = 22;

  /// 二级底栏图标尺寸。
  static const double subIconSize = 18;

  /// 主底栏标签字号（官方 11sp）。
  static const double labelFontSize = 11;

  /// 二级底栏标签字号。
  static const double subLabelFontSize = 10;

  /// 选中胶囊底色不透明度（官方 `accentColor @ 0.15`）。
  static const double pillAlpha = 0.15;

  /// 玻璃填充不透明度（官方 `surfaceContainer @ 0.4`）。
  static const double fillAlpha = 0.4;

  /// 边缘高光不透明度（官方 `baseHighlight.copy(alpha = 0.75f)`）。
  static const double highlightAlpha = 0.75;

  /// 阴影模糊 sigma：官方 shadow radius 10dp，高斯 sigma ≈ radius / 2。
  static const double shadowSigma = 5;

  /// 浅色/深色下的阴影不透明度（官方 10% / 20%）。
  static const double shadowAlphaLight = 0.1;
  static const double shadowAlphaDark = 0.2;

  /// 拖到两端时内容可位移的最大距离（官方 4dp 橡皮筋）。
  static const double panelRubberBand = 4;

  /// 按压时指示器缩放增量（官方 16dp / 栏宽）。
  static const double pressScaleDelta = 16;

  /// 指示器位移弹簧：临界阻尼，快速无过冲（官方 `spring(1f, 1000f)`）。
  static SpringDescription get valueSpring =>
      SpringDescription.withDampingRatio(mass: 1, stiffness: 1000, ratio: 1);

  /// 按压进度弹簧（官方 `spring(1f, 1000f)`）。
  static SpringDescription get pressSpring =>
      SpringDescription.withDampingRatio(mass: 1, stiffness: 1000, ratio: 1);

  /// 横向缩放弹簧（官方 `spring(0.6f, 250f)`）。
  static SpringDescription get scaleXSpring =>
      SpringDescription.withDampingRatio(mass: 1, stiffness: 250, ratio: 0.6);

  /// 纵向缩放弹簧（官方 `spring(0.7f, 250f)`）。
  static SpringDescription get scaleYSpring =>
      SpringDescription.withDampingRatio(mass: 1, stiffness: 250, ratio: 0.7);

  /// 橡皮筋回位弹簧（官方 `spring(1f, 300f)`）。
  static SpringDescription get panelSpring =>
      SpringDescription.withDampingRatio(mass: 1, stiffness: 300, ratio: 1);

  /// 底栏距屏幕底部距离。
  ///
  /// 官方规则：iOS 20dp；Android 存在导航栏内边距时为 `8dp + inset`，
  /// 否则 36dp。
  static double bottomPadding(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) return 20;
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    return inset != 0 ? 8 + inset : 36;
  }
}

/// 悬浮底栏中的一项。
@immutable
class MiuixFloatingBarItemData {
  const MiuixFloatingBarItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// 液态玻璃悬浮胶囊底栏。
///
/// 动效对齐官方 `DampedDragAnimation`：
/// - 指示器位移由弹簧驱动，拖动时**阻尼跟随**手指而非 1:1 硬跟；
/// - 按压进度、缩放均为弹簧；松手后等指示器到位再收起按压反馈；
/// - 带速度时指示器横向拉伸、纵向压缩（`velocity / 10`）；
/// - 拖到两端时内容按 4dp 橡皮筋偏移，回位用 `spring(1.0, 300)`。
///
/// 材质：`surfaceContainer@0.4` + 高斯模糊 + BloomStroke 边缘高光；
/// 阴影只在胶囊**外侧**绘制（半透明填充下不会透出阴影内部的黑色）。
class MiuixFloatingTabBar extends StatefulWidget {
  const MiuixFloatingTabBar({
    super.key,
    required this.controller,
    required this.items,
    this.height = MiuixFloatingBarDefaults.height,
    this.iconSize = MiuixFloatingBarDefaults.iconSize,
    this.fontSize = MiuixFloatingBarDefaults.labelFontSize,
    this.showLabels = true,
  });

  /// 与该底栏联动的页面控制器；拖动或点击底栏会驱动它翻页。
  final PageController controller;

  /// 标签数据。
  final List<MiuixFloatingBarItemData> items;

  /// 胶囊高度。
  final double height;

  /// 图标尺寸。
  final double iconSize;

  /// 标签字号。
  final double fontSize;

  /// 是否显示文字标签（主底栏为 false）。
  final bool showLabels;

  @override
  State<MiuixFloatingTabBar> createState() => _MiuixFloatingTabBarState();
}

class _MiuixFloatingTabBarState extends State<MiuixFloatingTabBar>
    with TickerProviderStateMixin {
  /// 指示器位置（以「条目」为单位，可为小数）。
  late final AnimationController _valueCtrl;

  /// 按压进度 0→1。
  late final AnimationController _pressCtrl;

  /// 指示器缩放（受按压与速度共同影响）。
  late final AnimationController _scaleXCtrl;
  late final AnimationController _scaleYCtrl;

  /// 两端橡皮筋位移（原始像素）。
  late final AnimationController _panelCtrl;

  /// 指示器速度（条目/秒），由弹簧值采样得到，驱动拉伸/压缩。
  double _velocity = 0;
  final List<double> _sampleTime = <double>[];
  final List<double> _sampleValue = <double>[];

  bool _dragging = false;
  bool _pressing = false;

  /// 供按压高光定位的触点位置（相对内容区）。
  Offset _touch = Offset.zero;

  /// 拖动时累计的原始位移，用于橡皮筋。
  double _panelRaw = 0;

  @override
  void initState() {
    super.initState();
    final double initial = (widget.controller.initialPage).toDouble();
    _valueCtrl = AnimationController.unbounded(vsync: this, value: initial)
      ..addListener(_sampleVelocity);
    _pressCtrl = AnimationController.unbounded(vsync: this, value: 0);
    _scaleXCtrl = AnimationController.unbounded(vsync: this, value: 1);
    _scaleYCtrl = AnimationController.unbounded(vsync: this, value: 1);
    _panelCtrl = AnimationController.unbounded(vsync: this, value: 0);
    widget.controller.addListener(_onControllerChanged);
    // PageView 首次布局前拿不到 page，帧后补一次真实值。
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromController());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _valueCtrl.dispose();
    _pressCtrl.dispose();
    _scaleXCtrl.dispose();
    _scaleYCtrl.dispose();
    _panelCtrl.dispose();
    super.dispose();
  }

  bool get _reduceMotion =>
      MediaQuery.disableAnimationsOf(context) ||
      View.of(context).platformDispatcher.accessibilityFeatures.reduceMotion;

  double get _maxIndex =>
      (widget.items.isEmpty ? 0 : widget.items.length - 1).toDouble();

  void _onControllerChanged() {
    if (_dragging) return;
    _syncFromController();
  }

  /// 外部翻页（点击底栏、程序切换）时让指示器弹簧跟随。
  void _syncFromController() {
    if (!widget.controller.hasClients) return;
    final double target = (widget.controller.page ?? 0.0).clamp(0.0, _maxIndex);
    if ((_valueCtrl.value - target).abs() < 0.001) return;
    _animateValueTo(target);
  }

  // ---- 弹簧驱动 ----

  void _animateValueTo(double target, {double velocity = 0}) {
    final double clamped = target.clamp(0.0, _maxIndex);
    if (_reduceMotion) {
      _valueCtrl.value = clamped;
      return;
    }
    _valueCtrl.animateWith(
      SpringSimulation(
        MiuixFloatingBarDefaults.valueSpring,
        _valueCtrl.value,
        clamped,
        velocity,
      )..tolerance = const Tolerance(distance: 0.001),
    );
  }

  void _animatePanelTo(double target) {
    _panelCtrl.animateWith(
      SpringSimulation(
        MiuixFloatingBarDefaults.panelSpring,
        _panelCtrl.value,
        target,
        0,
      )..tolerance = const Tolerance(distance: 0.5),
    );
  }

  void _press() {
    if (_pressing) return;
    _pressing = true;
    if (_reduceMotion) {
      _pressCtrl.value = 1;
      _scaleXCtrl.value = 1;
      _scaleYCtrl.value = 1;
      return;
    }
    _pressCtrl.animateWith(
      SpringSimulation(
        MiuixFloatingBarDefaults.pressSpring,
        _pressCtrl.value,
        1,
        0,
      )..tolerance = const Tolerance(distance: 0.001),
    );
    _animatePressScale(
      1 + MiuixFloatingBarDefaults.pressScaleDelta / _barWidth,
    );
  }

  void _release() {
    if (!_pressing) return;
    _pressing = false;
    if (_reduceMotion) {
      _pressCtrl.value = 0;
      _scaleXCtrl.value = 1;
      _scaleYCtrl.value = 1;
      return;
    }
    // 官方 release()：先等指示器就位，再收起按压反馈，避免"松手立刻回弹"的割裂感。
    _whenValueSettled().then((_) {
      if (!mounted) return;
      _pressCtrl.animateWith(
        SpringSimulation(
          MiuixFloatingBarDefaults.pressSpring,
          _pressCtrl.value,
          0,
          0,
        )..tolerance = const Tolerance(distance: 0.001),
      );
      _animatePressScale(1);
    });
  }

  void _animatePressScale(double target) {
    _scaleXCtrl.animateWith(
      SpringSimulation(
        MiuixFloatingBarDefaults.scaleXSpring,
        _scaleXCtrl.value,
        target,
        0,
      )..tolerance = const Tolerance(distance: 0.001),
    );
    _scaleYCtrl.animateWith(
      SpringSimulation(
        MiuixFloatingBarDefaults.scaleYSpring,
        _scaleYCtrl.value,
        target,
        0,
      )..tolerance = const Tolerance(distance: 0.001),
    );
  }

  /// 指示器是否已基本到位（官方 `visibilityThreshold` 取区间 2.5%）。
  bool get _valueSettled {
    final double target = _valueCtrl.value.roundToDouble().clamp(
      0.0,
      _maxIndex,
    );
    final double threshold = _maxIndex <= 0 ? 0.001 : _maxIndex * 0.025;
    return (_valueCtrl.value - target).abs() < threshold;
  }

  Future<void> _whenValueSettled() async {
    if (_valueSettled) return;
    while (mounted && !_valueSettled) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  }

  /// 采样指示器速度（官方 VelocityTracker 等价实现，窗口 ~100ms）。
  void _sampleVelocity() {
    final double now = DateTime.now().microsecondsSinceEpoch / 1e6;
    _sampleTime.add(now);
    _sampleValue.add(_valueCtrl.value);
    while (_sampleTime.length > 2 && now - _sampleTime.first > 0.1) {
      _sampleTime.removeAt(0);
      _sampleValue.removeAt(0);
    }
    if (_sampleTime.length >= 2) {
      final double dt = _sampleTime.last - _sampleTime.first;
      if (dt > 1e-4) {
        _velocity = (_sampleValue.last - _sampleValue.first) / dt;
      }
    }
  }

  double get _barWidth {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    return (box != null && box.hasSize && box.size.width > 0)
        ? box.size.width
        : 1;
  }

  // ---- 手势 ----

  void _onDragStart(DragStartDetails details, double tabWidth) {
    _dragging = true;
    _panelRaw = 0;
    if (widget.controller.hasClients) {
      (widget.controller.position as ScrollPositionWithSingleContext).goIdle();
    }
    _touch = details.localPosition;
    _press();
    // 官方：按下即跳到触点所在条目（弹簧过去，不是硬跳）。
    final int index = _indexAt(details.localPosition.dx, tabWidth);
    _animateValueTo(index.toDouble(), velocity: _velocity);
  }

  void _onDragUpdate(DragUpdateDetails details, double tabWidth) {
    _touch = details.localPosition;
    final double dx = details.delta.dx;
    if (tabWidth <= 0 || dx == 0) return;

    // 指示器：弹簧跟随（滞后阻尼），而非 1:1 硬跟。
    _animateValueTo(
      (_valueCtrl.value + dx / tabWidth).clamp(0.0, _maxIndex),
      velocity: _velocity,
    );

    // 橡皮筋：累计原始位移，端点外由面板整体轻微偏移。
    _panelRaw += dx;
    _panelCtrl.value = _panelRaw;

    // 页面与手指同步。
    if (!widget.controller.hasClients) return;
    final ScrollPosition position = widget.controller.position;
    final double viewport = position.viewportDimension;
    double target = widget.controller.offset + dx * (viewport / tabWidth);
    if (target < position.minScrollExtent) {
      final double overshoot = target - position.minScrollExtent;
      target =
          position.minScrollExtent +
          (overshoot * viewport * 0.55) / (viewport + 0.55 * overshoot.abs());
    } else if (target > position.maxScrollExtent) {
      final double overshoot = target - position.maxScrollExtent;
      target =
          position.maxScrollExtent +
          (overshoot * viewport * 0.55) / (viewport + 0.55 * overshoot.abs());
    }
    widget.controller.jumpTo(target);
  }

  void _onDragEnd(DragEndDetails details, double tabWidth) {
    _dragging = false;
    final int target = _valueCtrl.value.round().clamp(
      0,
      widget.items.isEmpty ? 0 : widget.items.length - 1,
    );
    _animateValueTo(target.toDouble(), velocity: _velocity);
    _panelRaw = 0;
    _animatePanelTo(0);
    _settleVelocity();
    // 让页面落到最近的一页。
    if (widget.controller.hasClients) {
      if (_reduceMotion) {
        widget.controller.jumpToPage(target);
      } else {
        final ScrollPositionWithSingleContext position =
            widget.controller.position as ScrollPositionWithSingleContext;
        position.goBallistic(
          details.velocity.pixelsPerSecond.dx *
              (position.viewportDimension / tabWidth),
        );
      }
    }
    _release();
  }

  void _onDragCancel(double tabWidth) {
    _dragging = false;
    final int target = _valueCtrl.value.round().clamp(
      0,
      widget.items.isEmpty ? 0 : widget.items.length - 1,
    );
    _animateValueTo(target.toDouble());
    _panelRaw = 0;
    _animatePanelTo(0);
    _settleVelocity();
    if (widget.controller.hasClients) {
      if (_reduceMotion) {
        widget.controller.jumpToPage(target);
      } else {
        (widget.controller.position as ScrollPositionWithSingleContext)
            .goBallistic(0);
      }
    }
    _release();
  }

  /// 松手后速度按 `spring(0.5, 300)` 衰减到 0（官方 velocityAnimationSpec）。
  void _settleVelocity() {
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (mounted && !_dragging) _velocity = 0;
    });
  }

  int _indexAt(double localX, double tabWidth) {
    if (tabWidth <= 0) return 0;
    // localX 已相对内容区（外层 Padding(24) 不计入 GestureDetector 坐标）。
    final int raw = (localX / tabWidth).floor();
    return raw.clamp(0, widget.items.isEmpty ? 0 : widget.items.length - 1);
  }

  void _select(int index, double tabWidth) {
    _press();
    _animateValueTo(index.toDouble(), velocity: _velocity);
    if (widget.controller.hasClients) {
      if (_reduceMotion) {
        widget.controller.jumpToPage(index);
      } else {
        widget.controller.animateToPage(
          index,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
    }
    _release();
  }

  @override
  Widget build(BuildContext context) {
    final mc = MiuixTheme.of(context).colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceTransparency = MediaQuery.highContrastOf(context);
    final tm = ThemeManager();
    final transparent = tm.enableBottomBarTransparent;
    final blurEnabled = transparent && tm.enableBlur && !reduceTransparency;
    final glassEnabled =
        transparent && tm.enableLiquidGlass && !reduceTransparency;
    final int count = widget.items.length;
    final double pillHeight =
        widget.height - MiuixFloatingBarDefaults.insidePadding.vertical;
    final bool ltr = Directionality.of(context) == TextDirection.ltr;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MiuixFloatingBarDefaults.horizontalMargin,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 胶囊内边距由 _GlassBarSurface 施加，故内容宽为栏宽减去四周留白。
          final double contentWidth =
              (constraints.maxWidth -
                      MiuixFloatingBarDefaults.insidePadding.horizontal)
                  .clamp(0.0, double.infinity);
          final double tabWidth = count == 0
              ? contentWidth
              : contentWidth / count;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (d) => _onDragStart(d, tabWidth),
            onHorizontalDragUpdate: (d) => _onDragUpdate(d, tabWidth),
            onHorizontalDragEnd: (d) => _onDragEnd(d, tabWidth),
            onHorizontalDragCancel: () => _onDragCancel(tabWidth),
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _valueCtrl,
                _pressCtrl,
                _scaleXCtrl,
                _scaleYCtrl,
                _panelCtrl,
              ]),
              builder: (context, _) {
                final double value = _valueCtrl.value.clamp(0.0, _maxIndex);
                final double press = _pressCtrl.value;
                // 官方 layerBlock：速度驱动横向拉伸 / 纵向压缩。
                final double v = _velocity / 10;
                final double stretch = (v * 0.75).clamp(-0.2, 0.2);
                final double squash = (v * 0.25).clamp(-0.2, 0.2);
                final double scaleX = _scaleXCtrl.value / (1 - stretch);
                final double scaleY = _scaleYCtrl.value * (1 - squash);
                final double panelOffset = ltr
                    ? _rubberBandOffset(_panelCtrl.value, contentWidth)
                    : -_rubberBandOffset(_panelCtrl.value, contentWidth);

                return _GlassBarSurface(
                  height: widget.height,
                  blurEnabled: blurEnabled,
                  glassEnabled: glassEnabled,
                  isDark: isDark,
                  child: Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: [
                      // 内容整体（含图标/标签）按橡皮筋偏移。
                      Transform.translate(
                        offset: Offset(panelOffset, 0),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // 选中胶囊指示器（坐标基于已内缩 4dp 的内容区）。
                            Positioned(
                              left: value * tabWidth,
                              top: 0,
                              width: tabWidth.clamp(0.0, double.infinity),
                              height: pillHeight,
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..scale(scaleX, scaleY),
                                child: _PillIndicator(
                                  color: mc.primary.withValues(
                                    alpha: MiuixFloatingBarDefaults.pillAlpha,
                                  ),
                                  radius: pillHeight / 2,
                                  press: press,
                                  glassEnabled: glassEnabled,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                for (int i = 0; i < count; i++)
                                  Expanded(
                                    child: _MiuixFloatingBarItem(
                                      data: widget.items[i],
                                      selected: value.round() == i,
                                      highlight: (1.0 - (value - i).abs())
                                          .clamp(0.0, 1.0),
                                      iconSize: widget.iconSize,
                                      fontSize: widget.fontSize,
                                      showLabel: widget.showLabels,
                                      onPressed: () => _select(i, tabWidth),
                                      onPressChanged: (v) =>
                                          v ? _press() : _release(),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // 按压高光（官方 InteractiveHighlight：整体白扫 + 触点径向光）。
                      if (blurEnabled && press > 0.01)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: ClipPath(
                              clipper: ShapeBorderClipper(
                                shape: MiuixSquircleBorder(
                                  cornerRadius: widget.height / 2,
                                ),
                              ),
                              child: CustomPaint(
                                painter: _InteractiveHighlightPainter(
                                  // 触点相对栏外侧坐标，换算到已内缩 4dp 的内容区。
                                  position:
                                      _touch -
                                      Offset(
                                        MiuixFloatingBarDefaults
                                            .insidePadding
                                            .left,
                                        MiuixFloatingBarDefaults
                                            .insidePadding
                                            .top,
                                      ),
                                  progress: press,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// 官方 panelOffset：`rubberBand * sign * EaseOut(|fraction|)`。
  double _rubberBandOffset(double raw, double contentWidth) {
    if (contentWidth <= 0) return 0;
    final double fraction = (raw / contentWidth).clamp(-1.0, 1.0);
    if (fraction == 0) return 0;
    final double eased = Curves.easeOut.transform(fraction.abs());
    return MiuixFloatingBarDefaults.panelRubberBand * fraction.sign * eased;
  }
}

/// 选中胶囊：底色 + 按压时的边缘高光与轻微压暗。
class _PillIndicator extends StatelessWidget {
  const _PillIndicator({
    required this.color,
    required this.radius,
    required this.press,
    required this.glassEnabled,
    required this.isDark,
  });

  final Color color;
  final double radius;
  final double press;
  final bool glassEnabled;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final shape = MiuixSquircleBorder(cornerRadius: radius);
    final child = DecoratedBox(
      decoration: ShapeDecoration(color: color, shape: shape),
      child: press <= 0.01
          ? null
          : ColoredBox(
              color: Colors.black.withValues(alpha: 0.03 * press),
              child: const SizedBox.expand(),
            ),
    );
    if (!glassEnabled) return child;
    return MiuixHighlight(
      highlight: Highlight(
        alpha: press,
        style: isDark
            ? BloomStroke.glassStrokeSmallDark
            : BloomStroke.glassStrokeSmallLight,
      ),
      shape: shape,
      child: child,
    );
  }
}

/// 玻璃胶囊容器：外侧阴影 + 填充 + 模糊 + 边缘高光。
///
/// 阴影通过 [MiuixDropShadow] 只在形状外侧绘制：半透明填充不会露出阴影
/// 内部的纯黑区域（`BoxShadow` 会把形状内部一并填黑，叠加半透明填充后
/// 整块底栏都会发暗）。
class _GlassBarSurface extends StatelessWidget {
  const _GlassBarSurface({
    required this.child,
    required this.height,
    required this.blurEnabled,
    required this.glassEnabled,
    required this.isDark,
  });

  final Widget child;
  final double height;
  final bool blurEnabled;
  final bool glassEnabled;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final mc = MiuixTheme.of(context).colors;
    final shape = MiuixSquircleBorder(cornerRadius: height / 2);
    final fill = blurEnabled
        ? mc.surfaceContainer.withValues(
            alpha: MiuixFloatingBarDefaults.fillAlpha,
          )
        : mc.surfaceContainer;

    return MiuixDropShadow(
      shape: shape,
      color: Colors.black.withValues(
        alpha: isDark
            ? MiuixFloatingBarDefaults.shadowAlphaDark
            : MiuixFloatingBarDefaults.shadowAlphaLight,
      ),
      sigma: MiuixFloatingBarDefaults.shadowSigma,
      child: SizedBox(
        height: height,
        child: ClipPath(
          clipper: ShapeBorderClipper(shape: shape),
          child: Stack(
            children: [
              if (blurEnabled)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: _barBlurFilter,
                    child: const SizedBox.expand(),
                  ),
                ),
              Positioned.fill(child: ColoredBox(color: fill)),
              if (glassEnabled)
                Positioned.fill(
                  child: IgnorePointer(
                    child: MiuixHighlight(
                      highlight: Highlight(
                        alpha: MiuixFloatingBarDefaults.highlightAlpha,
                        style: isDark
                            ? BloomStroke.glassStrokeMiddleDark
                            : BloomStroke.glassStrokeMiddleLight,
                      ),
                      shape: shape,
                    ),
                  ),
                ),
              Padding(
                padding: MiuixFloatingBarDefaults.insidePadding,
                // 撑满内缩后的内容区，让条目在胶囊内垂直居中。
                child: SizedBox.expand(child: child),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 底栏模糊滤镜：官方 blur 半径 4dp，按 `radius * 0.45` 换算 sigma。
final ImageFilter _barBlurFilter = liquidGlassImageFilter(blurSigma: 4);

/// 单个底栏项：图标 + 可选标签，选中态按指示器位置连续着色。
class _MiuixFloatingBarItem extends StatelessWidget {
  const _MiuixFloatingBarItem({
    required this.data,
    required this.selected,
    required this.highlight,
    required this.iconSize,
    required this.fontSize,
    required this.showLabel,
    required this.onPressed,
    required this.onPressChanged,
  });

  final MiuixFloatingBarItemData data;
  final bool selected;
  final double highlight;
  final double iconSize;
  final double fontSize;
  final bool showLabel;
  final VoidCallback onPressed;
  final ValueChanged<bool> onPressChanged;

  @override
  Widget build(BuildContext context) {
    final mc = MiuixTheme.of(context).colors;
    final Color idle = mc.onSurfaceVariantActions;
    final Color tint = Color.lerp(idle, mc.primary, highlight) ?? mc.primary;
    final Color labelTint =
        Color.lerp(idle.withValues(alpha: 0.9), mc.primary, highlight) ??
        mc.primary;

    return Semantics(
      button: true,
      selected: selected,
      label: data.label,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => onPressChanged(true),
          onTapUp: (_) => onPressChanged(false),
          onTapCancel: () => onPressChanged(false),
          onTap: onPressed,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? data.activeIcon : data.icon,
                color: tint,
                size: iconSize,
              ),
              if (showLabel) ...[
                const SizedBox(height: 1),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.normal,
                    color: labelTint,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 官方 InteractiveHighlight 等效：整体白色淡扫 + 触点径向高光。
class _InteractiveHighlightPainter extends CustomPainter {
  const _InteractiveHighlightPainter({
    required this.position,
    required this.progress,
  });

  final Offset position;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || progress <= 0) return;

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06 * progress)
        ..blendMode = BlendMode.plus,
    );

    final clamped = Offset(
      position.dx.clamp(0.0, size.width),
      position.dy.clamp(0.0, size.height),
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: FractionalOffset.fromOffsetAndRect(
            clamped,
            Offset.zero & size,
          ),
          radius: 1.0,
          colors: [
            Colors.white.withValues(alpha: 0.12 * progress),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size)
        ..blendMode = BlendMode.plus,
    );
  }

  @override
  bool shouldRepaint(covariant _InteractiveHighlightPainter oldDelegate) =>
      position != oldDelegate.position || progress != oldDelegate.progress;
}

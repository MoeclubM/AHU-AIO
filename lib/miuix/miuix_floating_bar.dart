import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../theme_manager.dart';
import 'bloom_stroke_painter.dart';
import 'liquid_glass_filter.dart';
import 'liquid_glass_layer.dart';
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

  /// 二级底栏高度（紧凑小巧，突出主次层级）。
  static const double subBarHeight = 44;

  /// 胶囊内四周留白（官方 4dp）。
  static const EdgeInsets insidePadding = EdgeInsets.all(4);

  /// 主底栏左右外边距（官方 24dp）。
  static const double horizontalMargin = 24;

  /// 二级底栏左右外边距（稍作内收，更精致）。
  static const double subHorizontalMargin = 32;

  /// 主底栏图标尺寸（官方 `LiquidGlassNavigationBar` 22dp）。
  static const double iconSize = 22;

  /// 二级底栏图标尺寸。
  static const double subIconSize = 17;

  /// 主底栏标签字号（官方 11sp）。
  static const double labelFontSize = 11;

  /// 二级底栏标签字号。
  static const double subLabelFontSize = 10;

  /// 选中胶囊底色不透明度（官方 `accentColor @ 0.15`）。
  static const double pillAlpha = 0.15;

  /// 玻璃填充不透明度（官方 `surfaceContainer @ 0.4`）。
  static const double fillAlpha = 0.4;

  /// 边缘高光基础不透明度（官方栏体 `baseHighlight.alpha = 0.75`）。
  static const double highlightAlpha = 0.75;

  /// 底栏背景模糊半径（参考库 `blur(8.dp)`）。
  static const double blurRadius = 8;

  /// 背景模糊的高斯 sigma。
  ///
  /// 参考库 `blur(8.dp)` 的 radius 直接作为 RenderEffect 的 sigma 传入，
  /// Flutter 的 [ImageFilter.blur] 同样吃 sigma，因此 1:1 使用。
  static const double blurSigma = blurRadius;

  /// 按压时胶囊的放大倍数（参考库 `pressedScale = 78f / 56f`）。
  ///
  /// 这是按压最抢眼的「液滴」效果：胶囊自身胀大，而底栏与其余条目保持不动。
  static const double pillPressedScale = 78 / 56;

  /// 底栏本体在按压时的额外放大量（参考库 `layerBlock` 的 16dp 触达半径）。
  ///
  /// 整条栏按 `1 + 16dp / 栏宽` 同步胀大，与胶囊的 78/56 是两层缩放。
  static const double barPressReach = 16;

  /// 条目内容（图标/标签）在按压时的放大倍数（官方内层 `1 → 1.2`）。
  static const double tabPressedScale = 1.2;

  /// 折射取样外扩距离（逻辑像素）。
  ///
  /// 形状周围必须留出背景供边缘折射取样；这段区域向盒子外溢出绘制，
  /// 不参与布局，但**外层容器不能裁掉它**，否则玻璃的上/下半边会缺一块。
  static const double refractionPad = 24;

  /// 胶囊投影的模糊半径（参考库 `Shadow(radius = 24.dp)`）。
  static const double pillShadowRadius = 24;

  /// 胶囊投影基础不透明度（参考库 `Color.Black.copy(alpha = 0.1f)`）。
  static const double pillShadowAlpha = 0.1;

  /// 胶囊投影的纵向偏移（参考库 `DpOffset(0, radius / 6)`）。
  static const double pillShadowOffsetY = pillShadowRadius / 6;

  /// 阴影模糊 sigma：官方 shadow radius 10dp，高斯 sigma ≈ radius / 2。
  static const double shadowSigma = 5;

  /// 浅色/深色下的阴影不透明度（官方 10% / 20%）。
  static const double shadowAlphaLight = 0.1;
  static const double shadowAlphaDark = 0.2;

  /// 拖到两端时内容可位移的最大距离（官方 4dp 橡皮筋）。
  static const double panelRubberBand = 4;

  /// 指示器位移弹簧：临界阻尼，快速无过冲（官方 `spring(1f, 1000f)`）。
  static SpringDescription get valueSpring =>
      SpringDescription.withDampingRatio(mass: 1, stiffness: 1000, ratio: 1);

  /// 胶囊按压进度弹簧（官方 `spring(1f, 1000f)`）。
  static SpringDescription get pressSpring =>
      SpringDescription.withDampingRatio(mass: 1, stiffness: 1000, ratio: 1);

  /// 底栏交互高光的弹簧。
  ///
  /// 与胶囊不同：参考库 `InteractiveHighlight.pressProgress` 用的是
  /// `spring(0.5f, 300f)` —— 欠阻尼，所以高光是「亮起时有轻微过冲」的，
  /// 而不是跟着胶囊一起干脆地弹到位。
  static SpringDescription get highlightSpring =>
      SpringDescription.withDampingRatio(mass: 1, stiffness: 300, ratio: 0.5);

  /// 横向缩放弹簧（官方 `spring(0.6f, 250f)`）。
  static SpringDescription get scaleXSpring =>
      SpringDescription.withDampingRatio(mass: 1, stiffness: 250, ratio: 0.6);

  /// 纵向缩放弹簧（官方 `spring(0.7f, 250f)`）。
  static SpringDescription get scaleYSpring =>
      SpringDescription.withDampingRatio(mass: 1, stiffness: 250, ratio: 0.7);

  /// 橡皮筋回位弹簧（官方 `spring(1f, 300f)`）。
  static SpringDescription get panelSpring =>
      SpringDescription.withDampingRatio(mass: 1, stiffness: 300, ratio: 1);

  /// 指示器速度衰减弹簧（官方 `spring(0.5f, 300f)`）。
  static SpringDescription get velocitySpring =>
      SpringDescription.withDampingRatio(mass: 1, stiffness: 300, ratio: 0.5);

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

/// 悬浮子栏（二级标签栏）的槽位。
///
/// 两件事：
/// 1. **收起动画**用裁剪 + 下移实现（不用透明度：半透明玻璃一旦半隐，底下的
///    深色文字会透上来显得整条发暗，交叉淡入还会让两层玻璃叠加变黑）；
/// 2. **给玻璃留出取样空间**——玻璃的折射要往形状外扩
///    [MiuixFloatingBarDefaults.refractionPad]，而裁剪窗口正好贴着子栏时，
///    上半边的折射取样会被裁掉，看起来就像玻璃缺了上半部分。所以槽位上方
///    必须多留出这段距离，子栏在槽位内相应下移，实际位置保持不变
///    （Column 底部对齐，下移量与槽位高度增量相抵）。
class MiuixFloatingSubBarSlot extends StatelessWidget {
  const MiuixFloatingSubBarSlot({
    super.key,
    required this.visibility,
    required this.child,
  });

  /// 子栏与主栏之间的间距。
  static const double gap = 8;

  /// 槽位高度 = 折射外扩 + 子栏 + 与主栏的间距。
  static const double slotHeight =
      MiuixFloatingBarDefaults.refractionPad +
      MiuixFloatingBarDefaults.subBarHeight +
      gap;

  /// 0–1：0 完全收起（滑到主栏后面），1 完全展示。
  final double visibility;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: slotHeight,
      child: ClipRect(
        child: Transform.translate(
          offset: Offset(0, (1 - visibility) * slotHeight),
          child: IgnorePointer(
            ignoring: visibility < 0.5,
            child: Padding(
              padding: const EdgeInsets.only(
                top: MiuixFloatingBarDefaults.refractionPad,
                bottom: gap,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
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
/// - 拖动时指示器与联动页面都 **1:1 跟手**（Compose 版拖动中也用弹簧，但那边
///   没有联动页面；这里若让页面跟着弹簧走，临界阻尼在快速滑动下的稳态滞后
///   可达 0.6 个条目，手感就是"不跟手"）；
/// - 松手后按 `spring(1.0, 1000)` 回位，页面与指示器**共用同一个值**，
///   因此不可能出现「指示器到位了页面还没到」的不一致；
/// - 按压进度、缩放为弹簧；松手后等指示器就位再收起按压反馈；
/// - 带速度时指示器横向拉伸、纵向压缩（`velocity / 10`），松手后按
///   `spring(0.5, 300)` 衰减；
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
    this.horizontalMargin = MiuixFloatingBarDefaults.horizontalMargin,
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

  /// 胶囊左右外边距。
  final double horizontalMargin;

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
  /// 指示器位置（以「条目」为单位，可为小数），同时决定页面位置。
  late final AnimationController _valueCtrl;

  /// 按压进度 0→1。
  late final AnimationController _pressCtrl;
  late final AnimationController _highlightCtrl;

  /// 指示器缩放（受按压与速度共同影响）。
  late final AnimationController _scaleXCtrl;
  late final AnimationController _scaleYCtrl;

  /// 两端橡皮筋位移（原始像素）。
  late final AnimationController _panelCtrl;

  /// 指示器速度（条目/秒）。拖动时由采样写入，松手后按弹簧衰减到 0。
  late final AnimationController _velocityCtrl;

  /// 拖动目标（条目单位）。
  ///
  /// 必须从**目标**累积：若从当前动画值累积，弹簧的滞后会逐帧累加成永久
  /// 落后，表现为「滑动不跟手」。从目标累积则总位移恒等于手指位移。
  double _dragTarget = 0;

  /// 当前弹簧的目的地，用于判断指示器是否已就位。
  double _springTarget = 0;

  bool _pressing = false;

  /// 底栏正在驱动页面（拖动与回位期间）。此时忽略 PageController 的回调，
  /// 避免「底栏驱动页面 → 页面回调又改指示器」的相互拉扯。
  bool _driving = false;
  bool _ignoreController = false;

  /// 供按压高光定位的触点位置（相对栏外侧）。

  /// 正在跟踪的指针（多点触控时只认第一根）。
  int? _activePointer;

  /// 本次手势是否已经越过触摸阈值、进入拖动。
  bool _dragStarted = false;

  /// 按下点（用于判定点按 / 拖动）。
  double _downX = 0;

  /// 指针轨迹采样，用于松手时的速度（像素/秒）。
  final List<double> _trackTimes = <double>[];
  final List<double> _trackPositions = <double>[];

  /// 最近一次布局的内容区宽度（条目换算与 RTL 镜像都要用）。
  double _lastContentWidth = 0;

  double get _nowSeconds => DateTime.now().microsecondsSinceEpoch / 1e6;

  @override
  void initState() {
    super.initState();
    final double initial = widget.controller.initialPage.toDouble();
    _valueCtrl = AnimationController.unbounded(vsync: this, value: initial)
      ..addListener(_onValueTick);
    _pressCtrl = AnimationController.unbounded(vsync: this, value: 0);
    _highlightCtrl = AnimationController.unbounded(vsync: this, value: 0);
    _scaleXCtrl = AnimationController.unbounded(vsync: this, value: 1);
    _scaleYCtrl = AnimationController.unbounded(vsync: this, value: 1);
    _panelCtrl = AnimationController.unbounded(vsync: this, value: 0);
    _velocityCtrl = AnimationController.unbounded(vsync: this, value: 0);
    _dragTarget = initial;
    _springTarget = initial;
    widget.controller.addListener(_onControllerChanged);
    // PageView 首次布局前拿不到 page，帧后补一次真实值。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncFromController(snap: true);
    });
  }

  ModalRoute<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<dynamic>? newRoute = ModalRoute.of(context);
    if (newRoute != _route) {
      _route?.secondaryAnimation?.removeListener(_onRouteAnimation);
      _route = newRoute;
      _route?.secondaryAnimation?.addListener(_onRouteAnimation);
    }
  }

  void _onRouteAnimation() {
    // 当上层子页面出栈就位时，强制同步指示器并刷新。
    if (mounted) {
      _syncFromController();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _route?.secondaryAnimation?.removeListener(_onRouteAnimation);
    widget.controller.removeListener(_onControllerChanged);
    _valueCtrl.dispose();
    _pressCtrl.dispose();
    _highlightCtrl.dispose();
    _scaleXCtrl.dispose();
    _scaleYCtrl.dispose();
    _panelCtrl.dispose();
    _velocityCtrl.dispose();
    super.dispose();
  }

  bool get _reduceMotion =>
      MediaQuery.disableAnimationsOf(context) ||
      View.of(context).platformDispatcher.accessibilityFeatures.reduceMotion;

  double get _maxIndex =>
      (widget.items.isEmpty ? 0 : widget.items.length - 1).toDouble();

  void _onControllerChanged() {
    if (_ignoreController || _driving) return;
    _syncFromController();
  }

  /// 外部翻页（程序切换、设置页跳转）时让指示器跟随。
  void _syncFromController({bool snap = false}) {
    if (!widget.controller.hasClients) return;
    final double target = (widget.controller.page ?? 0.0).clamp(0.0, _maxIndex);
    final double delta = (target - _valueCtrl.value).abs();
    if (delta < 0.001) return;
    _dragTarget = target;
    // 跨度大（如重置回首页）时直接对齐，否则弹簧会把内容一路拖过多页。
    if (snap || delta > 0.5) {
      _valueCtrl.value = target;
      _springTarget = target;
      _pushToController();
    } else {
      _animateValueTo(target);
    }
  }

  /// 把指示器位置写回 PageController —— 指示器与页面因此同源，
  /// 不会出现「指示器到位了页面还没到」的不一致。
  void _pushToController() {
    if (!widget.controller.hasClients) return;
    final ScrollPosition position = widget.controller.position;
    if (position.viewportDimension <= 0) return;
    _ignoreController = true;
    widget.controller.jumpTo(
      _valueCtrl.value.clamp(0.0, _maxIndex) * position.viewportDimension,
    );
    _ignoreController = false;
  }

  void _onValueTick() {
    // 指示器是唯一的真值来源：它每动一次就把页面同步到同一位置。
    if (_driving) _pushToController();
  }

  // ---- 弹簧驱动 ----

  void _springTo(
    AnimationController controller,
    double target,
    SpringDescription spring, {
    double velocity = 0,
  }) {
    controller.animateWith(
      SpringSimulation(spring, controller.value, target, velocity)
        ..tolerance = const Tolerance(distance: 0.001),
    );
  }

  void _animateValueTo(double target, {double velocity = 0}) {
    _springTarget = target.clamp(0.0, _maxIndex);
    if (_reduceMotion) {
      _valueCtrl.value = _springTarget;
      _pushToController();
      return;
    }
    _springTo(
      _valueCtrl,
      _springTarget,
      MiuixFloatingBarDefaults.valueSpring,
      velocity: velocity,
    );
  }

  void _press() {
    if (_pressing) return;
    _pressing = true;
    if (_reduceMotion) {
      _pressCtrl.value = 1;
      _highlightCtrl.value = 1;
      return;
    }
    _springTo(_pressCtrl, 1, MiuixFloatingBarDefaults.pressSpring);
    // 高光用更软的弹簧（参考库 InteractiveHighlight 的 spring(0.5, 300)）。
    _springTo(_highlightCtrl, 1, MiuixFloatingBarDefaults.highlightSpring);
    // 参考库：胶囊整体放大到 pressedScale（78/56），与底栏宽度无关。
    const double target = MiuixFloatingBarDefaults.pillPressedScale;
    _springTo(_scaleXCtrl, target, MiuixFloatingBarDefaults.scaleXSpring);
    _springTo(_scaleYCtrl, target, MiuixFloatingBarDefaults.scaleYSpring);
  }

  /// 收起按压反馈。
  void _collapsePress() {
    if (!_pressing) return;
    _pressing = false;
    if (_reduceMotion) {
      _pressCtrl.value = 0;
      _highlightCtrl.value = 0;
      _scaleXCtrl.value = 1;
      _scaleYCtrl.value = 1;
      return;
    }
    _springTo(_pressCtrl, 0, MiuixFloatingBarDefaults.pressSpring);
    _springTo(_highlightCtrl, 0, MiuixFloatingBarDefaults.highlightSpring);
    _springTo(_scaleXCtrl, 1, MiuixFloatingBarDefaults.scaleXSpring);
    _springTo(_scaleYCtrl, 1, MiuixFloatingBarDefaults.scaleYSpring);
  }

  /// 结束一次「底栏驱动」：指示器回位、橡皮筋与速度归零，
  /// 并在指示器就位后收起按压反馈（官方 release() 的时序）。
  void _finishDriving(double target, {double velocity = 0}) {
    // 把松手瞬间的速度交给指示器，拉伸/压缩会随之自然回落。
    _velocityCtrl.value = velocity.clamp(-40.0, 40.0);
    _animateValueTo(target, velocity: velocity);
    _springTo(_panelCtrl, 0, MiuixFloatingBarDefaults.panelSpring);
    _springTo(_velocityCtrl, 0, MiuixFloatingBarDefaults.velocitySpring);
    _whenSettled().then((_) {
      if (!mounted) return;
      _pushToController();
      _driving = false;
      _collapsePress();
    });
  }

  /// 指示器是否已到达弹簧目的地。
  bool get _settled => (_valueCtrl.value - _springTarget).abs() < 0.002;

  /// 等待指示器就位。
  ///
  /// 带上限：若动画被抢占导致始终不收敛，也不能让 [_driving] 永久卡住
  /// （那会让后续拖动与外部翻页都失去同步）。
  Future<void> _whenSettled() async {
    final Stopwatch watch = Stopwatch()..start();
    while (mounted && !_settled && watch.elapsedMilliseconds < 1200) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  }

  /// 松手后落到的条目。
  double get _nearestIndex => _dragTarget.roundToDouble().clamp(0.0, _maxIndex);

  /// 点击：指示器与页面共用同一个弹簧，因此两者必然同步到位。
  void _select(int index) {
    _driving = true;
    _press();
    _dragTarget = index.toDouble();
    _finishDriving(index.toDouble(), velocity: 0);
  }

  // ---- 手势：直接处理原始指针事件 ----
  //
  // 不用 GestureDetector：外层的横向拖动识别器与每个条目的点按识别器会在手势
  // 竞技场里互相等待（拖动要等按下后位移、点按要等抬起且对手放弃），实际表现
  // 就是「按住拖动完全没反应」。Compose 版是同一套指针逻辑同时判定点按与拖动
  // （inspectDragGestures），这里用 Listener 复刻同样的语义。

  void _onPointerDown(PointerDownEvent event, double tabWidth) {
    if (_activePointer != null) return;
    _activePointer = event.pointer;
    _dragStarted = false;
    _downX = event.localPosition.dx;
    _trackTimes
      ..clear()
      ..add(_nowSeconds);
    _trackPositions
      ..clear()
      ..add(event.localPosition.dx);

    _driving = true;
    _panelCtrl.value = 0;
    if (widget.controller.hasClients) {
      (widget.controller.position as ScrollPositionWithSingleContext).goIdle();
    }
    _press();
    // 官方：按下即把指示器弹向触点所在条目（弹簧过去，而不是硬跳）。
    _dragTarget = _indexAt(event.localPosition.dx, tabWidth).toDouble();
    _animateValueTo(_dragTarget);
  }

  void _onPointerMove(PointerMoveEvent event, double tabWidth) {
    if (event.pointer != _activePointer) return;

    final double now = _nowSeconds;
    _trackTimes.add(now);
    _trackPositions.add(event.localPosition.dx);
    while (_trackTimes.length > 2 && now - _trackTimes.first > 0.1) {
      _trackTimes.removeAt(0);
      _trackPositions.removeAt(0);
    }

    // 越过来回抖动阈值之前视为点按，避免手指微动被当成拖动。
    if (!_dragStarted) {
      if ((event.localPosition.dx - _downX).abs() <= kTouchSlop) return;
      _dragStarted = true;
    }

    final double dx = event.delta.dx;
    if (dx == 0 || tabWidth <= 0) return;

    // 从**目标**累积：总位移恒等于手指位移，不会因弹簧滞后而落后。
    _dragTarget = (_dragTarget + dx / tabWidth).clamp(-0.4, _maxIndex + 0.4);
    _valueCtrl.value = _dragTarget.clamp(0.0, _maxIndex);
    _springTarget = _valueCtrl.value;
    _panelCtrl.value += dx;

    // 拖动过程中实时喂速度：参考库每帧都在跟踪指示器速度并让 velocity 弹簧
    // 追过去（`spring(0.5f, 300f)`），胶囊据此横向拉伸、纵向压缩。
    // 只在松手时给速度的话，整个拖动过程都是「硬」的、没有液态感。
    final double tabsPerSecond = _trackVelocity / tabWidth;
    if (tabsPerSecond != 0 && !_reduceMotion) {
      _springTo(
        _velocityCtrl,
        tabsPerSecond.clamp(-40.0, 40.0),
        MiuixFloatingBarDefaults.velocitySpring,
      );
    }

    _pushToController();
  }

  void _onPointerUp(PointerUpEvent event, double tabWidth) {
    if (event.pointer != _activePointer) return;
    final bool wasTap = !_dragStarted;
    final double velocity = _trackVelocity / (tabWidth <= 0 ? 1 : tabWidth);
    _resetTracking();
    if (wasTap) {
      _select(_indexAt(event.localPosition.dx, tabWidth));
    } else {
      _finishDriving(_nearestIndex, velocity: velocity);
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer != _activePointer) return;
    _resetTracking();
    _finishDriving(_nearestIndex);
  }

  void _resetTracking() {
    _activePointer = null;
    _dragStarted = false;
    _trackTimes.clear();
    _trackPositions.clear();
  }

  /// 指针位移速度（像素/秒），用于松手后的拉伸与吸附。
  double get _trackVelocity {
    if (_trackTimes.length < 2) return 0;
    final double dt = _trackTimes.last - _trackTimes.first;
    if (dt <= 1e-4) return 0;
    return (_trackPositions.last - _trackPositions.first) / dt;
  }

  /// 触点落在哪个条目上（已折算内容区内边距与 RTL 镜像）。
  int _indexAt(double localX, double tabWidth) {
    if (tabWidth <= 0 || widget.items.isEmpty) return 0;
    final double inner = localX - MiuixFloatingBarDefaults.insidePadding.left;
    final bool ltr = Directionality.of(context) == TextDirection.ltr;
    final double x = ltr ? inner : _lastContentWidth - inner;
    final int raw = (x / tabWidth).floor();
    return raw.clamp(0, widget.items.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final mc = MiuixTheme.of(context).colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceTransparency = MediaQuery.highContrastOf(context);
    final tm = ThemeManager();
    // 悬浮栏只在「悬浮底栏」开启时渲染；此处只受模糊/高光开关与高对比度影响。
    final blurEnabled = tm.enableBlur && !reduceTransparency;
    final glassEnabled = tm.enableLiquidGlass && !reduceTransparency;
    final int count = widget.items.length;
    final double pillHeight =
        widget.height - MiuixFloatingBarDefaults.insidePadding.vertical;
    final bool ltr = Directionality.of(context) == TextDirection.ltr;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.horizontalMargin),
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
          // 供指针回调换算条目与 RTL 镜像。
          _lastContentWidth = contentWidth;

          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) => _onPointerDown(e, tabWidth),
            onPointerMove: (e) => _onPointerMove(e, tabWidth),
            onPointerUp: (e) => _onPointerUp(e, tabWidth),
            onPointerCancel: _onPointerCancel,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _valueCtrl,
                _pressCtrl,
                _highlightCtrl,
                _scaleXCtrl,
                _scaleYCtrl,
                _panelCtrl,
                _velocityCtrl,
              ]),
              builder: (context, _) {
                final double value = _valueCtrl.value.clamp(0.0, _maxIndex);
                final double press = _pressCtrl.value;
                // 官方 layerBlock：速度驱动横向拉伸 / 纵向压缩。
                final double v = _velocityCtrl.value / 10;
                final double stretch = (v * 0.75).clamp(-0.2, 0.2);
                final double squash = (v * 0.25).clamp(-0.2, 0.2);
                final double scaleX = _scaleXCtrl.value / (1 - stretch);
                final double scaleY = _scaleYCtrl.value * (1 - squash);
                final double panelOffset = ltr
                    ? _rubberBandOffset(_panelCtrl.value, contentWidth)
                    : -_rubberBandOffset(_panelCtrl.value, contentWidth);
                // 官方 layerBlock：底栏整体按 `1 + 16dp / 宽` 胀大；
                // 胶囊另按 78/56 独立放大（液滴效果）。
                final double barScale =
                    1 +
                    MiuixFloatingBarDefaults.barPressReach *
                        press /
                        math.max(constraints.maxWidth, 1);
                final double tabScale =
                    1 +
                    (MiuixFloatingBarDefaults.tabPressedScale - 1) * press;
                return Transform.scale(
                  scale: barScale,
                  child: _GlassBarSurface(
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
                              // 强调色条目层：画在胶囊之下，供 lens 折射取样
                              // （对应官方 alpha=0 的 layerBackdrop 内层）。
                              // 裁到胶囊区域，避免在栏体其他位置露出。
                              if (glassEnabled && press > 0.01)
                                Positioned(
                                  left: ltr
                                      ? value * tabWidth
                                      : contentWidth - (value + 1) * tabWidth,
                                  top: 0,
                                  width: tabWidth.clamp(0.0, double.infinity),
                                  height: pillHeight,
                                  child: IgnorePointer(
                                    child: ClipPath(
                                      clipper: ShapeBorderClipper(
                                        shape: MiuixSquircleBorder(
                                          cornerRadius: pillHeight / 2,
                                        ),
                                      ),
                                      child: Transform.scale(
                                        scale: tabScale,
                                        child: _AccentTabLayer(
                                          items: widget.items,
                                          tabWidth: tabWidth,
                                          contentWidth: contentWidth,
                                          value: value,
                                          ltr: ltr,
                                          iconSize: widget.iconSize,
                                          fontSize: widget.fontSize,
                                          showLabels: widget.showLabels,
                                          color: mc.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              // 选中胶囊指示器（坐标基于已内缩 4dp 的内容区，
                              // RTL 下按内容宽度镜像）。
                              Positioned(
                                left: ltr
                                    ? value * tabWidth
                                    : contentWidth - (value + 1) * tabWidth,
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
                                    blurEnabled: blurEnabled,
                                    glassEnabled: glassEnabled,
                                    isDark: isDark,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  for (int i = 0; i < count; i++)
                                    Expanded(
                                      child: Transform.scale(
                                        scale: tabScale,
                                        child: _MiuixFloatingBarItem(
                                          data: widget.items[i],
                                          selected: value.round() == i,
                                          highlight: (1.0 - (value - i).abs())
                                              .clamp(0.0, 1.0),
                                          iconSize: widget.iconSize,
                                          fontSize: widget.fontSize,
                                          showLabel: widget.showLabels,
                                          onTap: () => _select(i),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // 按压高光：与选中胶囊轮廓吻合的圆弧胶囊形亮斑。
                        if (blurEnabled && _highlightCtrl.value > 0.01)
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
                                    // 光晕中心落在当前选中胶囊中心，跟随位移与橡皮筋偏移。
                                    position: Offset(
                                      (ltr
                                              ? (value + 0.5) * tabWidth
                                              : contentWidth -
                                                    (value + 0.5) * tabWidth) +
                                          panelOffset,
                                      pillHeight / 2,
                                    ),
                                    width: tabWidth * scaleX,
                                    height: pillHeight * scaleY,
                                    radius: (pillHeight / 2) * scaleY,
                                    progress: _highlightCtrl.value,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
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

/// 强调色条目层：供胶囊 lens 折射取样（官方 alpha=0 的 layerBackdrop 内层）。
///
/// 只画在胶囊裁剪区内，颜色固定为 primary，配合按压缩放形成「液滴放大」。
class _AccentTabLayer extends StatelessWidget {
  const _AccentTabLayer({
    required this.items,
    required this.tabWidth,
    required this.contentWidth,
    required this.value,
    required this.ltr,
    required this.iconSize,
    required this.fontSize,
    required this.showLabels,
    required this.color,
  });

  final List<MiuixFloatingBarItemData> items;
  final double tabWidth;
  final double contentWidth;
  final double value;
  final bool ltr;
  final double iconSize;
  final double fontSize;
  final bool showLabels;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double offset = ltr ? -value * tabWidth : value * tabWidth;
    final double rowWidth = tabWidth.clamp(0.0, double.infinity) * items.length;
    // 整行比胶囊宽，必须允许布局溢出：外层 ClipPath 负责裁到胶囊，
    // 这里用 OverflowBox 避免 RenderFlex overflow 断言。
    return OverflowBox(
      minWidth: 0,
      maxWidth: rowWidth,
      minHeight: 0,
      maxHeight: double.infinity,
      alignment: Alignment.centerLeft,
      child: Transform.translate(
        offset: Offset(offset, 0),
        child: SizedBox(
          width: rowWidth,
          child: Row(
            children: [
              for (final MiuixFloatingBarItemData item in items)
                SizedBox(
                  width: tabWidth.clamp(0.0, double.infinity),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.activeIcon, color: color, size: iconSize),
                      if (showLabels) ...[
                        const SizedBox(height: 1),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: fontSize, color: color),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 选中胶囊：静止时是「玻璃面纱」，按压时亮起边缘高光并收掉面纱。
///
/// 对照 Compose 版 `LiquidGlassNavigationBar.kt` 的 `drawBackdrop`：
/// - 静止：`onDrawSurface` 画 `black@0.1`（深色 `white@0.1`），`alpha = 1 - press`，
///   所以胶囊在静止时**就有**一块可见的玻璃（此前我们误用了「关闭模糊」回退分支的
///   `accent@0.15` 平涂，叠加在半透明栏上几乎透明，看起来像没有指示器）；
/// - 按压：面纱淡出、叠 `black@0.03 * press`、内阴影 `radius 8dp * press`，
///   边缘高光 alpha 直接取按压进度。
/// - 关闭模糊时才是回退分支：扁平 `accent@0.15`，无高光。
class _PillIndicator extends StatelessWidget {
  const _PillIndicator({
    required this.color,
    required this.radius,
    required this.press,
    required this.blurEnabled,
    required this.glassEnabled,
    required this.isDark,
  });

  /// 回退分支（关闭模糊）的胶囊底色：官方 `accentColor @ 0.15`。
  final Color color;

  final double radius;
  final double press;
  final bool blurEnabled;
  final bool glassEnabled;
  final bool isDark;

  /// 静止面纱不透明度（官方 `Color.Black/White.copy(alpha = 0.1f)`）。
  static const double _veilAlpha = 0.1;

  /// 按压时叠加的压暗（官方 `Color.Black.copy(alpha = 0.03f * progress)`）。
  static const double _pressDimAlpha = 0.03;

  /// 内阴影模糊半径上限（官方 `radius = 8.dp * progress`）。
  static const double _innerShadowBlur = 8;

  /// 内阴影不透明度上限（官方 `Color.Black.copy(alpha = 0.15f)`）。
  static const double _innerShadowAlpha = 0.15;

  @override
  Widget build(BuildContext context) {
    final ShapeBorder shape = MiuixSquircleBorder(cornerRadius: radius);

    final bool pressing = press > 0.01;

    // 关闭模糊且没开玻璃：官方回退分支，扁平 accent 底色，没有高光与面纱。
    if (!blurEnabled && !glassEnabled) {
      return DecoratedBox(
        decoration: ShapeDecoration(color: color, shape: shape),
      );
    }

    // 静止面纱（浅色压 10% 黑 / 深色压 10% 白），随按压淡出。
    final Widget veil = ColoredBox(
      color: (isDark ? Colors.white : Colors.black).withValues(
        alpha: _veilAlpha * (1 - press),
      ),
    );
    final Widget pressDim = pressing
        ? ColoredBox(
            color: Colors.black.withValues(alpha: _pressDimAlpha * press),
          )
        : const SizedBox.shrink();
    final Widget innerShadow = pressing
        ? CustomPaint(
            painter: _PillInnerShadowPainter(
              radius: radius,
              blurRadius: _innerShadowBlur * press,
              alpha: _innerShadowAlpha * press,
            ),
          )
        : const SizedBox.shrink();

    // 液态玻璃：参考库在**按压时**才给胶囊加透镜
    // （`lens(10dp * progress, 14dp * progress, depthEffect = true, chromaticAberration = 0.5)`），
    // 静止时只有面纱，所以这里用按压进度驱动折射参数。
    if (glassEnabled) {
      final Widget glass = LiquidGlassLayer(
        cornerRadius: radius,
        // 参考库的选中胶囊只做 lens，不额外模糊（模糊由底栏那层负责）。
        refractionHeight: 10 * press,
        refractionAmount: 14 * press,
        depthEffect: press,
        dispersion: 0.5 * press,
        // 胶囊嵌在底栏内，可用取样外扩有限，取小一点避免越界。
        padding: 8,
        // 不铺强调色：参考库的选中态是「面纱 + 透镜 + 边缘高光」，
        // 选中信息由图标/文字的主题色承担（见 _MiuixFloatingBarItem）。
        highlightColor: Colors.white.withValues(alpha: 0.5 * press),
        highlightWidth: 0.5,
        highlightAngle: 45,
        // HyperOS 胶囊边缘用 BloomStroke（随按压亮起）。
        fallbackHighlight: pressing
            ? IgnorePointer(
                child: BloomStrokeLayer(
                  radius: radius,
                  isDark: isDark,
                  enabled: true,
                  highlightAlpha: press,
                ),
              )
            : null,
        // 面纱/压暗/内阴影属于"表面"，必须画在高光之下，
        // 否则半透明遮罩会把边缘高光压暗（参考库的层序即如此）。
        surface: Stack(
          fit: StackFit.expand,
          children: [veil, pressDim, innerShadow],
        ),
        child: const SizedBox.shrink(),
      );
      // 参考库 `Shadow(alpha = progress)`：胶囊的投影也由按压驱动
      // （radius 24dp、黑 10%、纵向偏移 radius/6），只在形状外侧绘制，
      // 避免半透明玻璃把阴影的黑色透出来。
      if (press <= 0.01) return glass;
      return MiuixDropShadow(
        shape: shape,
        color: Colors.black.withValues(
          alpha: MiuixFloatingBarDefaults.pillShadowAlpha * press,
        ),
        sigma: MiuixFloatingBarDefaults.pillShadowRadius * 0.45,
        offset: const Offset(0, MiuixFloatingBarDefaults.pillShadowOffsetY),
        child: glass,
      );
    }

    return ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 透镜：官方 drawBackdrop 会在胶囊区域内再模糊一次背景（`blur(4dp)`），
          // 所以胶囊是"更虚"的一块玻璃，而不是单纯压深。
          BackdropFilter(
            filter: _barBlurFilter,
            child: const SizedBox.expand(),
          ),
          veil,
          pressDim,
          innerShadow,
        ],
      ),
    );
  }
}

/// 胶囊内阴影：沿形状内侧描一圈模糊黑影，按压时才有（官方 `innerShadow`）。
class _PillInnerShadowPainter extends CustomPainter {
  const _PillInnerShadowPainter({
    required this.radius,
    required this.blurRadius,
    required this.alpha,
  });

  final double radius;
  final double blurRadius;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    if (alpha <= 0 || blurRadius <= 0 || size.isEmpty) return;
    final Rect rect = Offset.zero & size;
    final Path outer = MiuixSquircleBorder(
      cornerRadius: radius,
    ).getOuterPath(rect);

    // 只保留贴近边缘的一条带：外轮廓减去内缩轮廓，再整体高斯模糊。
    final double band = math.min(blurRadius * 2, rect.shortestSide / 2);
    final Path inner = MiuixSquircleBorder(
      cornerRadius: math.max(0, radius - band),
    ).getOuterPath(rect.deflate(band));

    canvas.save();
    canvas.clipPath(outer, doAntiAlias: true);
    canvas.drawPath(
      Path.combine(PathOperation.difference, outer, inner),
      Paint()
        ..color = Colors.black.withValues(alpha: alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PillInnerShadowPainter oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.blurRadius != blurRadius ||
      oldDelegate.alpha != alpha;
}

/// 玻璃胶囊容器：液态玻璃面（折射 / 模糊 + 填充 + 边缘高光 + 按压高光）。
///
/// 对照参考库 `LiquidBottomTabs` 的那层 `Row`：
/// - 效果 `vibrancy + blur(8dp) + lens(24dp, 24dp)`；
/// - **底栏本身没有投影、也不随按压缩放**（参考库只给选中胶囊加 `Shadow`
///   与放大，那才是「液滴」效果），靠玻璃自身的边缘高光与容器色区分层次。
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
    final MiuixColors mc = MiuixTheme.of(context).colors;
    final ShapeBorder shape = MiuixSquircleBorder(cornerRadius: height / 2);
    // 玻璃模式下底色必须保持半透明，否则会盖住折射出来的背景。
    final Color fill = (blurEnabled || glassEnabled)
        ? mc.surfaceContainer.withValues(
            alpha: MiuixFloatingBarDefaults.fillAlpha,
          )
        : mc.surfaceContainer;

    final Widget content = Padding(
      padding: MiuixFloatingBarDefaults.insidePadding,
      child: SizedBox.expand(child: child),
    );

    // 玻璃关闭：实色（可选纯模糊），不做折射与高光。
    if (!glassEnabled) {
      return SizedBox(
        height: height,
        child: ClipPath(
          clipper: ShapeBorderClipper(shape: shape),
          child: Stack(
            children: [
              if (blurEnabled)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: liquidGlassImageFilter(
                      blurSigma: MiuixFloatingBarDefaults.blurSigma,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              Positioned.fill(child: ColoredBox(color: fill)),
              content,
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: LiquidGlassLayer(
        cornerRadius: height / 2,
        // 参考库：blur(8dp) + lens(24dp, 24dp)。
        blurSigma: blurEnabled ? MiuixFloatingBarDefaults.blurSigma : 0,
        refractionHeight: MiuixFloatingBarDefaults.refractionPad,
        refractionAmount: MiuixFloatingBarDefaults.refractionPad,
        padding: MiuixFloatingBarDefaults.refractionPad,
        fillColor: fill,
        highlightColor: Colors.white.withValues(
          alpha: MiuixFloatingBarDefaults.highlightAlpha,
        ),
        highlightWidth: 0.5,
        highlightAngle: 45,
        fallbackHighlight: IgnorePointer(
          child: BloomStrokeLayer(
            radius: height / 2,
            isDark: isDark,
            enabled: true,
            highlightAlpha: MiuixFloatingBarDefaults.highlightAlpha,
          ),
        ),
        child: content,
      ),
    );
  }
}

/// 胶囊透镜层的局部模糊：官方 `blur(4.dp)`，radius 即 sigma。
final ImageFilter _barBlurFilter = liquidGlassImageFilter(blurSigma: 4);

/// 单个底栏项：图标 + 可选标签，选中态按指示器位置连续着色。
///
/// 纯展示组件，**不挂自己的手势识别器**：点按与拖动统一由外层 Listener 判定，
/// 避免两个识别器在手势竞技场里互相等待（那会让按住拖动完全没反应）。
/// 无障碍点击仍通过 [Semantics.onTap] 提供。
class _MiuixFloatingBarItem extends StatelessWidget {
  const _MiuixFloatingBarItem({
    required this.data,
    required this.selected,
    required this.highlight,
    required this.iconSize,
    required this.fontSize,
    required this.showLabel,
    required this.onTap,
  });

  final MiuixFloatingBarItemData data;
  final bool selected;
  final double highlight;
  final double iconSize;
  final double fontSize;
  final bool showLabel;
  final VoidCallback onTap;

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
      onTap: onTap,
      child: ExcludeSemantics(
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
    );
  }
}

/// 交互高光：选中胶囊处的圆弧胶囊形亮斑，随按压进度亮起，
/// 轮廓与展开的胶囊完全吻合，两端为柔和圆弧。
class _InteractiveHighlightPainter extends CustomPainter {
  const _InteractiveHighlightPainter({
    required this.position,
    required this.width,
    required this.height,
    required this.radius,
    required this.progress,
  });

  /// 胶囊中心位置。
  final Offset position;

  /// 胶囊宽度与高度（含按压与拉伸缩放）。
  final double width;
  final double height;

  /// 胶囊端点圆角半径。
  final double radius;

  /// 按压高光进度 (0–1)。
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 ||
        size.height <= 0 ||
        progress <= 0 ||
        width <= 0 ||
        height <= 0) {
      return;
    }

    final Rect pillRect = Rect.fromCenter(
      center: position,
      width: width,
      height: height,
    );
    final RRect rrect = RRect.fromRectAndRadius(
      pillRect,
      Radius.circular(radius.clamp(0.0, height / 2)),
    );

    // 亮斑形状：与选中胶囊轮廓吻合的圆弧胶囊形，
    // 告别之前的正圆形手电筒光斑。
    final double maxAlpha = (0.22 * progress).clamp(0.0, 0.22);

    // 1. 外层柔和胶囊晕染（向外微弱扩散，形成光晕）
    canvas.drawRRect(
      rrect.inflate(4),
      Paint()
        ..color = Colors.white.withValues(alpha: maxAlpha * 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
        ..blendMode = BlendMode.plus,
    );

    // 2. 核心圆弧胶囊亮斑（形状轮廓清晰，两端弧形与胶囊完全契合）
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white.withValues(alpha: maxAlpha * 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
        ..blendMode = BlendMode.plus,
    );
  }

  @override
  bool shouldRepaint(covariant _InteractiveHighlightPainter oldDelegate) =>
      position != oldDelegate.position ||
      width != oldDelegate.width ||
      height != oldDelegate.height ||
      radius != oldDelegate.radius ||
      progress != oldDelegate.progress;
}

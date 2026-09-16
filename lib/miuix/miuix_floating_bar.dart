import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';

import '../theme_manager.dart';
import 'liquid_glass_filter.dart';
import 'miuix_theme.dart';

/// 悬浮胶囊底栏的官方几何与配色常量。
///
/// 数值取自 Compose 版 miuix：
/// - 常规悬浮栏 `MiuixFloatingNavigationBarDefaults`（胶囊 50、图标 28、间距 12）；
/// - 液态玻璃栏示例 `example/.../liquid/LiquidGlassNavigationBar.kt`
///   （高度 64、内边距 4、外边距 24、图标 22、标签 11sp、填充 0.4、
///   胶囊高光 alpha 0.75、阴影 radius 10 黑 10%/20%、选中胶囊 accent@0.15）。
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

  /// 选中胶囊底色不透明度（官方 accentColor @ 0.15）。
  static const double pillAlpha = 0.15;

  /// 玻璃填充不透明度（官方 surfaceContainer @ 0.4）。
  static const double fillAlpha = 0.4;

  /// 边缘高光不透明度（官方 `baseHighlight.copy(alpha = 0.75f)`）。
  static const double highlightAlpha = 0.75;

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
/// 结构与动效对齐 Compose 版液态玻璃底栏：
/// - 容器：高度 64（二级 56）、内边距 4、胶囊圆角、左右外边距 24；
/// - 材质：`surfaceContainer @ 0.4` 填充 + 高斯模糊 + BloomStroke 边缘高光（alpha 0.75）；
/// - 阴影：radius 10，黑色 10%（浅色）/ 20%（深色），零偏移；
/// - 选中：跟随页面位移的 accent@0.15 胶囊指示器，图标与标签同步着色；
/// - 按压：指示器随压力缩放、内容白色高光扫过，无涟漪。
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
    with SingleTickerProviderStateMixin {
  /// 按压弹簧：官方用于指示器缩放与高光扫过。
  late final AnimationController _pressController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  final ValueNotifier<Offset> _highlightPos = ValueNotifier(Offset.zero);
  bool _pressing = false;

  @override
  void dispose() {
    _pressController.dispose();
    _highlightPos.dispose();
    super.dispose();
  }

  bool get _reduceMotion =>
      MediaQuery.disableAnimationsOf(context) ||
      View.of(context).platformDispatcher.accessibilityFeatures.reduceMotion;

  void _onDragStart(DragStartDetails details) {
    if (widget.controller.hasClients) {
      (widget.controller.position as ScrollPositionWithSingleContext).goIdle();
    }
    _setPressing(true, details.localPosition);
  }

  void _onDragUpdate(DragUpdateDetails details, double tabWidth) {
    _highlightPos.value = details.localPosition;
    if (!widget.controller.hasClients) return;
    final position = widget.controller.position;
    final double viewport = position.viewportDimension;
    double target =
        widget.controller.offset + details.delta.dx * (viewport / tabWidth);
    if (target < position.minScrollExtent) {
      final overshoot = target - position.minScrollExtent;
      target =
          position.minScrollExtent +
          (overshoot * viewport * 0.55) / (viewport + 0.55 * overshoot.abs());
    } else if (target > position.maxScrollExtent) {
      final overshoot = target - position.maxScrollExtent;
      target =
          position.maxScrollExtent +
          (overshoot * viewport * 0.55) / (viewport + 0.55 * overshoot.abs());
    }
    widget.controller.jumpTo(target);
  }

  void _onDragEnd(DragEndDetails details, double tabWidth) {
    if (!widget.controller.hasClients) return;
    if (_reduceMotion) {
      widget.controller.jumpToPage(
        (widget.controller.page ?? 0.0).round().clamp(
          0,
          widget.items.length - 1,
        ),
      );
    } else {
      final position =
          widget.controller.position as ScrollPositionWithSingleContext;
      position.goBallistic(
        details.velocity.pixelsPerSecond.dx *
            (position.viewportDimension / tabWidth),
      );
    }
    _setPressing(false);
  }

  void _onDragCancel(double tabWidth) {
    if (!widget.controller.hasClients) {
      _setPressing(false);
      return;
    }
    if (_reduceMotion) {
      widget.controller.jumpToPage(
        (widget.controller.page ?? 0.0).round().clamp(
          0,
          widget.items.length - 1,
        ),
      );
    } else {
      (widget.controller.position as ScrollPositionWithSingleContext)
          .goBallistic(0);
    }
    _setPressing(false);
  }

  void _setPressing(bool value, [Offset? position]) {
    _pressing = value;
    if (value) {
      if (position != null) _highlightPos.value = position;
      if (_reduceMotion) {
        _pressController.value = 1.0;
      } else {
        _pressController.forward();
      }
    } else {
      if (_reduceMotion) {
        _pressController.value = 0.0;
      } else {
        _pressController.reverse();
      }
    }
  }

  void _select(int index, double tabWidth) {
    _setPressing(true);
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
    // 指示器归位由 controller 监听驱动；此处仅收尾按压反馈。
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (mounted) _setPressing(false);
    });
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
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: (d) => _onDragUpdate(d, tabWidth),
            onHorizontalDragEnd: (d) => _onDragEnd(d, tabWidth),
            onHorizontalDragCancel: () => _onDragCancel(tabWidth),
            child: AnimatedBuilder(
              animation: Listenable.merge([
                widget.controller,
                _pressController,
              ]),
              builder: (context, _) {
                final double page = widget.controller.hasClients
                    ? (widget.controller.page ?? 0.0)
                    : 0.0;
                final double press = _pressController.value;
                // 官方 layerBlock：缩放幅度按 16dp / 栏宽换算。
                final double pillScale =
                    1.0 + (contentWidth <= 0 ? 0.0 : 16 / contentWidth) * press;

                return _GlassBarSurface(
                  height: widget.height,
                  blurEnabled: blurEnabled,
                  glassEnabled: glassEnabled,
                  isDark: isDark,
                  child: Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: [
                      // 选中胶囊指示器（坐标基于已内缩 4dp 的内容区）。
                      Positioned(
                        left: page * tabWidth,
                        top: 0,
                        width: tabWidth.clamp(0.0, double.infinity),
                        height: pillHeight,
                        child: Transform.scale(
                          scale: pillScale,
                          child: DecoratedBox(
                            decoration: ShapeDecoration(
                              color: mc.primary.withValues(
                                alpha: MiuixFloatingBarDefaults.pillAlpha,
                              ),
                              shape: MiuixSquircleBorder(
                                cornerRadius: pillHeight / 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 按压高光（官方 InteractiveHighlight 等效实现）。
                      if (_pressing && press > 0.01)
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
                                  // 触点相对于整栏，转换为内容区坐标。
                                  position:
                                      _highlightPos.value -
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
                      Row(
                        children: [
                          for (int i = 0; i < count; i++)
                            Expanded(
                              child: _MiuixFloatingBarItem(
                                data: widget.items[i],
                                selected: page.round() == i,
                                highlight: (1.0 - (page - i).abs()).clamp(
                                  0.0,
                                  1.0,
                                ),
                                iconSize: widget.iconSize,
                                fontSize: widget.fontSize,
                                showLabel: widget.showLabels,
                                onPressed: () => _select(i, tabWidth),
                                onPressChanged: (v) => _setPressing(v),
                              ),
                            ),
                        ],
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
}

/// 玻璃胶囊容器：填充 + 模糊 + 边缘高光 + 官方阴影。
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

    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.1),
            blurRadius: 10,
          ),
        ],
      ),
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

/// 单个底栏项：图标 + 可选标签，选中态按页面位移连续着色。
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

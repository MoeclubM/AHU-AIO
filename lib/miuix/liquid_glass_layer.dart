import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 计算玻璃区域（形状 + 取样外扩）左上角在**屏幕空间**中的位置，设备像素。
///
/// 这是与着色器的坐标契约：作为 backdrop filter 时 `FlutterFragCoord` 是屏幕
/// 空间设备像素，所以 shader 需要区域在屏幕中的绝对位置才能算出局部坐标。
/// 单独提成函数是为了能被测试直接覆盖——只按局部坐标算会在屏幕中央糊出一个
/// 巨大形状（曾经的真实 bug）。
Offset liquidGlassRegionOrigin(
  RenderBox box, {
  required double pad,
  required double dpr,
}) {
  return (box.localToGlobal(Offset.zero) - Offset(pad, pad)) * dpr;
}

/// 液态玻璃渲染层。
///
/// 效果对照 [AndroidLiquidGlass](https://github.com/Kyant0/AndroidLiquidGlass)
/// （Apache-2.0）的 `drawBackdrop`：
///
/// 1. **折射**（`lens`）：靠近边缘的一圈按 SDF 法线方向重采样背景，
///    让边缘像真实玻璃一样弯折背景，而不是单纯模糊；
/// 2. **模糊 + 鲜艳度**：背景先高斯模糊、再提饱和（×1.5）；
/// 3. **填充**：`surfaceContainer@0.4` 一类的半透明底色；
/// 4. **边缘高光**（`Highlight.Default`）：沿轮廓的细亮线，强度随边缘法线与
///    45° 光方向变化，白 50% 加成混合。
///
/// 折射依赖 `ImageFilter.shader`（**仅 Impeller 可用**）。不可用时退化为纯模糊
/// 玻璃：观感是均匀磨砂而非透镜，但不会崩、也不会画错。
class LiquidGlassLayer extends StatefulWidget {
  const LiquidGlassLayer({
    super.key,
    required this.child,
    required this.cornerRadius,
    this.refractionHeight = 0,
    this.refractionAmount = 0,
    this.blurSigma = 0,
    this.dispersion = 0,
    this.depthEffect = 0,
    this.fillColor,
    this.highlightColor = const Color(0x80FFFFFF),
    this.highlightWidth = 0.5,
    this.highlightAngle = 45,
    this.highlightFalloff = 1,
    this.padding = 0,
    this.showHighlight = true,
    this.surface,
    this.fallbackHighlight,
  });

  /// 玻璃面上方的内容（画在最后一层，会盖住高光）。
  final Widget child;

  /// 玻璃表面层：画在填充之上、高光之下。
  ///
  /// 参考库的层序是「背景 → 表面（面纱 / 压暗）→ 边缘高光」；高光必须在表面
  /// 之上，否则会被半透明遮罩压暗。所以这里单独留一个槽位。
  final Widget? surface;

  /// 形状圆角（逻辑像素）；等于高度一半时为胶囊。
  final double cornerRadius;

  /// 折射高度（逻辑像素）：从边缘向内多少距离内发生弯折。
  final double refractionHeight;

  /// 折射强度（逻辑像素）：边缘处最大重采样位移。
  final double refractionAmount;

  /// 背景模糊 sigma；<= 0 表示不模糊（参考库的选中胶囊就不模糊）。
  final double blurSigma;

  /// 色散强度；>0 时 R/B 通道错位（参考库按压态用 0.5）。
  final double dispersion;

  /// >0 时折射位移额外带上指向中心的分量。
  final double depthEffect;

  /// 玻璃填充色；null 表示不铺底色。
  final Color? fillColor;

  /// 高光颜色（含 alpha）。
  final Color highlightColor;

  /// 高光宽度（逻辑像素）——只画在形状内侧。
  final double highlightWidth;

  /// 光方向（度）。
  final double highlightAngle;

  /// 高光衰减指数。
  final double highlightFalloff;

  /// 折射取样额外外扩的距离（逻辑像素）。
  ///
  /// 形状周围必须留出背景纹理，否则边缘折射只能取到被钳制的边界像素，
  /// 表现为一圈糊掉的色带。该区域向组件盒子外溢出绘制，不参与布局。
  final double padding;

  final bool showHighlight;

  /// 自定义边缘高光（如 miuix-blur 的 BloomStroke）。
  ///
  /// 非 null 时优先于内置 SDF 高光——HyperOS 玻璃用的是 BloomStroke
  /// 立体边缘，不是 Kyant 的二维 rim light。为 null 时才回退到 SDF 高光。
  final Widget? fallbackHighlight;

  /// 当前后端是否支持真折射（Impeller）。
  static bool get isRefractionSupported =>
      ui.ImageFilter.isShaderFilterSupported;

  @override
  State<LiquidGlassLayer> createState() => _LiquidGlassLayerState();
}

class _LiquidGlassLayerState extends State<LiquidGlassLayer> {
  ui.FragmentShader? _refractionShader;
  bool _shaderReady = false;
  ModalRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    if (LiquidGlassLayer.isRefractionSupported) _loadShader();
  }

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
    // 上层子页面推入或退出时，强制刷新，保证返回就位时着色器与滤镜立即恢复。
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadShader() async {
    final ui.FragmentProgram program = await loadLiquidGlassRefractionProgram();
    if (!mounted) return;
    setState(() {
      // 每个玻璃面各持一个 FragmentShader：uniform 缓冲区随实例走，
      // 复用同一个实例会让多个玻璃面互相覆盖参数。
      _refractionShader = program.fragmentShader();
      _shaderReady = true;
    });
  }

  @override
  void dispose() {
    _route?.secondaryAnimation?.removeListener(_onRouteAnimation);
    _refractionShader?.dispose();
    super.dispose();
  }

  /// 本次是否真的走折射（需要后端支持且折射量非零）。
  bool get _usesRefraction =>
      _shaderReady &&
      (widget.refractionHeight > 0 || widget.refractionAmount > 0);

  bool get _usesBlur => widget.blurSigma > 0;

  /// 是否需要背景滤镜；两者都没有时完全不挂 [BackdropFilter]。
  bool get _needsBackdrop => _usesRefraction || _usesBlur;

  /// 背景滤镜：模糊在内、折射在外，与参考库 `blur → lens` 的顺序一致
  /// （鲜艳度在折射 shader 内完成）。
  ui.ImageFilter _buildFilter({required bool refract}) {
    final ui.ImageFilter? blur = _usesBlur
        ? ui.ImageFilter.blur(
            sigmaX: widget.blurSigma,
            sigmaY: widget.blurSigma,
            tileMode: TileMode.clamp,
          )
        : null;
    if (!refract) return blur!;
    return blur == null
        ? ui.ImageFilter.shader(_refractionShader!)
        : ui.ImageFilter.compose(
            inner: blur,
            outer: ui.ImageFilter.shader(_refractionShader!),
          );
  }

  /// 本区域（形状 + 取样外扩）左上角在屏幕中的位置，**设备像素**。
  ///
  /// backdrop 滤镜的 `FlutterFragCoord` 是屏幕空间设备像素（见
  /// `shaders/liquid_glass_refraction.frag` 顶部的坐标契约说明），所以必须把
  /// 区域位置显式传给 shader，不能假设 fragCoord 是局部的。
  /// 尚未完成布局时返回 null —— 此时**不做折射**，退化为纯模糊，
  /// 避免用错误几何画出巨大的形状。
  Offset? _regionOriginDevice(double pad, double dpr) {
    final RenderObject? ro = context.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize) return null;
    return liquidGlassRegionOrigin(ro, pad: pad, dpr: dpr);
  }

  /// 写入折射参数。
  ///
  /// 用按名字绑定的 uniform 槽位（`getUniformFloat` 等），避免依赖声明顺序。
  /// `u_size` 由引擎每帧写入背景纹理尺寸，这里不碰。
  void _updateShaderUniforms(
    ui.FragmentShader shader, {
    required Offset originDevice,
    required Size regionDevice,
    required double dpr,
  }) {
    shader.getUniformVec2('u_origin').set(originDevice.dx, originDevice.dy);
    shader
        .getUniformVec2('u_region_size')
        .set(regionDevice.width, regionDevice.height);
    shader.getUniformFloat('u_dpr').set(dpr);
    shader.getUniformFloat('u_radius').set(widget.cornerRadius);
    shader.getUniformFloat('u_refraction_height').set(widget.refractionHeight);
    shader.getUniformFloat('u_refraction_amount').set(widget.refractionAmount);
    shader.getUniformFloat('u_depth_effect').set(widget.depthEffect);
    shader.getUniformFloat('u_dispersion').set(widget.dispersion);
  }

  @override
  Widget build(BuildContext context) {
    // 折射 / 高光 shader 用的是圆角矩形 SDF，裁剪与描边必须同轮廓，
    // 否则边缘弯折会和可见轮廓对不齐（参考库 shape 也是 CornerBasedShape）。
    final ShapeBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(widget.cornerRadius),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final Size box = Size(
          constraints.hasBoundedWidth ? constraints.maxWidth : 0,
          constraints.hasBoundedHeight ? constraints.maxHeight : 0,
        );
        final double dpr = MediaQuery.devicePixelRatioOf(context);
        // 只有真正走折射时才外扩：形状周围需要背景纹理供边缘取样，且必须
        // 先拿到区域在屏幕中的位置（否则几何不可信，宁可退回纯模糊）。
        final Offset? originDevice = _usesRefraction
            ? _regionOriginDevice(widget.padding, dpr)
            : null;
        final bool refract = originDevice != null;
        final double pad = refract ? widget.padding : 0;
        if (refract) {
          _updateShaderUniforms(
            _refractionShader!,
            originDevice: originDevice,
            regionDevice: Size(
              (box.width + pad * 2) * dpr,
              (box.height + pad * 2) * dpr,
            ),
            dpr: dpr,
          );
        }

        final Widget backdrop = !_needsBackdrop
            ? const SizedBox.shrink()
            : _GlassBackdrop(
                filter: _buildFilter(refract: refract),
                shape: shape,
                pad: pad,
                shader: refract ? _refractionShader : null,
                dpr: dpr,
                cornerRadius: widget.cornerRadius,
                refractionHeight: widget.refractionHeight,
                refractionAmount: widget.refractionAmount,
                depthEffect: widget.depthEffect,
                dispersion: widget.dispersion,
              );

        final Widget highlight = widget.showHighlight
            ? CustomPaint(
                painter: _LiquidGlassHighlightPainter(
                  radius: widget.cornerRadius,
                  width: widget.highlightWidth,
                  angleDegrees: widget.highlightAngle,
                  falloff: widget.highlightFalloff,
                  color: widget.highlightColor,
                ),
              )
            : const SizedBox.shrink();

        // 调用方给了自定义高光（如 miuix-blur 的 BloomStroke）就优先用它——
        // 那才是 HyperOS 的玻璃边缘样式；SDF 高光是 Kyant 的简化 rim light，
        // 只在未提供自定义高光时使用。
        final Widget effectiveHighlight = !widget.showHighlight
            ? const SizedBox.shrink()
            : (widget.fallbackHighlight ?? highlight);

        final Widget inner = Stack(
          fit: StackFit.expand,
          children: [
            if (widget.fillColor != null) ColoredBox(color: widget.fillColor!),
            if (widget.surface != null) widget.surface!,
            effectiveHighlight,
          ],
        );

        return SizedBox(
          width: box.width,
          height: box.height,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              if (pad > 0)
                Positioned(
                  left: -pad,
                  top: -pad,
                  right: -pad,
                  bottom: -pad,
                  child: backdrop,
                )
              else
                backdrop,
              ClipPath(
                clipper: ShapeBorderClipper(shape: shape),
                child: inner,
              ),
              widget.child,
            ],
          ),
        );
      },
    );
  }
}

/// 把背景（经 [filter] 处理）画进 [shape] 内。
///
/// **始终裁剪到形状**：这是最后一道保险——取样外扩区域（[pad]）只用来让
/// shader 取到形状外的背景，输出必须严格限制在形状内，否则一旦几何或着色器
/// 出问题，就会在屏幕上糊出一大块形状。
class _GlassBackdrop extends StatelessWidget {
  const _GlassBackdrop({
    required this.filter,
    required this.shape,
    required this.pad,
    this.shader,
    this.dpr = 1.0,
    this.cornerRadius = 0.0,
    this.refractionHeight = 0.0,
    this.refractionAmount = 0.0,
    this.depthEffect = 0.0,
    this.dispersion = 0.0,
  });

  final ui.ImageFilter filter;
  final ShapeBorder shape;
  final double pad;
  final ui.FragmentShader? shader;
  final double dpr;
  final double cornerRadius;
  final double refractionHeight;
  final double refractionAmount;
  final double depthEffect;
  final double dispersion;

  @override
  Widget build(BuildContext context) {
    final Widget filtered = BackdropFilter(
      filter: filter,
      child: const SizedBox.expand(),
    );
    final Widget clipped = ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: filtered,
    );
    final Widget synced = _LiquidGlassShaderSync(
      shader: shader,
      pad: pad,
      dpr: dpr,
      cornerRadius: cornerRadius,
      refractionHeight: refractionHeight,
      refractionAmount: refractionAmount,
      depthEffect: depthEffect,
      dispersion: dispersion,
      child: clipped,
    );
    return pad > 0
        ? Padding(padding: EdgeInsets.all(pad), child: synced)
        : synced;
  }
}

/// 在绘制阶段实时从 Canvas 的全局变换矩阵同步着色器坐标（u_origin / u_region_size）。
///
/// 避免因路由转场（SlideTransition / DualTransition）、滑动或无 rebuild 的位移导致
/// 着色器的屏幕空间原点停留在旧位置，从而在子页面返回时出现覆盖率归零（底栏变灰）的问题。
class _LiquidGlassShaderSync extends SingleChildRenderObjectWidget {
  const _LiquidGlassShaderSync({
    required this.shader,
    required this.pad,
    required this.dpr,
    required this.cornerRadius,
    required this.refractionHeight,
    required this.refractionAmount,
    required this.depthEffect,
    required this.dispersion,
    required super.child,
  });

  final ui.FragmentShader? shader;
  final double pad;
  final double dpr;
  final double cornerRadius;
  final double refractionHeight;
  final double refractionAmount;
  final double depthEffect;
  final double dispersion;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderLiquidGlassShaderSync(
      shader: shader,
      pad: pad,
      dpr: dpr,
      cornerRadius: cornerRadius,
      refractionHeight: refractionHeight,
      refractionAmount: refractionAmount,
      depthEffect: depthEffect,
      dispersion: dispersion,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderLiquidGlassShaderSync renderObject,
  ) {
    renderObject
      ..shader = shader
      ..pad = pad
      ..dpr = dpr
      ..cornerRadius = cornerRadius
      ..refractionHeight = refractionHeight
      ..refractionAmount = refractionAmount
      ..depthEffect = depthEffect
      ..dispersion = dispersion;
  }
}

class _RenderLiquidGlassShaderSync extends RenderProxyBox {
  _RenderLiquidGlassShaderSync({
    required this.shader,
    required this.pad,
    required this.dpr,
    required this.cornerRadius,
    required this.refractionHeight,
    required this.refractionAmount,
    required this.depthEffect,
    required this.dispersion,
  });

  ui.FragmentShader? shader;
  double pad;
  double dpr;
  double cornerRadius;
  double refractionHeight;
  double refractionAmount;
  double depthEffect;
  double dispersion;

  @override
  void paint(PaintingContext context, Offset offset) {
    final ui.FragmentShader? s = shader;
    if (s != null && (refractionHeight > 0 || refractionAmount > 0)) {
      final Float64List matrix = context.canvas.getTransform();
      final double scaleX = matrix[0];
      final double scaleY = matrix[5];
      final double transX = matrix[12] + offset.dx * scaleX;
      final double transY = matrix[13] + offset.dy * scaleY;
      final double originX = (transX - pad) * dpr;
      final double originY = (transY - pad) * dpr;
      final double regionW = (size.width + pad * 2) * dpr;
      final double regionH = (size.height + pad * 2) * dpr;

      s
        ..getUniformVec2('u_origin').set(originX, originY)
        ..getUniformVec2('u_region_size').set(regionW, regionH)
        ..getUniformFloat('u_dpr').set(dpr)
        ..getUniformFloat('u_radius').set(cornerRadius)
        ..getUniformFloat('u_refraction_height').set(refractionHeight)
        ..getUniformFloat('u_refraction_amount').set(refractionAmount)
        ..getUniformFloat('u_depth_effect').set(depthEffect)
        ..getUniformFloat('u_dispersion').set(dispersion);
    }
    super.paint(context, offset);
  }
}

/// 绘制液态玻璃的边缘高光。
///
/// 参考库的做法是「沿轮廓描边（`strokeWidth = width * 2`）再裁到形状内」，但
/// Skia 的描边路径不按 shader 的逐像素 alpha 合成（实测强度被整体吃掉，
/// falloff 完全不起作用），所以这里改成**填充一圈内缩环带**：形状减去内缩
/// [width] 的形状。视觉等价，合成结果正确。
///
/// [falloff] 越大，高光沿法线方向的衰减越快、整体越暗。
void paintLiquidGlassHighlight(
  Canvas canvas,
  Size size, {
  required double radius,
  required double width,
  required double angleDegrees,
  required double falloff,
  required Color color,
}) {
  if (color.a <= 0.01 || width <= 0 || size.isEmpty) return;
  final ui.FragmentProgram? program = liquidGlassHighlightProgram;
  if (program == null) return;

  final ui.FragmentShader shader = program.fragmentShader();
  shader.getUniformVec2('u_size').set(size.width, size.height);
  shader.getUniformFloat('u_pad').set(0);
  shader.getUniformFloat('u_radius').set(radius);
  shader
      .getUniformFloat('u_angle')
      .set(angleDegrees * 3.1415926535897932 / 180);
  shader.getUniformFloat('u_falloff').set(falloff);
  shader.getUniformVec4('u_color').set(color.r, color.g, color.b, color.a);

  final Rect rect = Offset.zero & size;
  // 与折射 shader 的 sdRoundedRect 同轮廓。
  final RRect outer = RRect.fromRectAndRadius(
    rect,
    Radius.circular(radius.clamp(0.0, size.shortestSide / 2)),
  );
  final RRect inner = RRect.fromRectAndRadius(
    rect.deflate(width),
    Radius.circular(
      math.max(0.0, radius - width).clamp(0.0, size.shortestSide / 2),
    ),
  );
  final Path band = Path.combine(
    PathOperation.difference,
    Path()..addRRect(outer),
    Path()..addRRect(inner),
  );

  canvas.drawPath(
    band,
    Paint()
      ..blendMode = BlendMode.plus
      ..shader = shader,
  );
}

/// 边缘高光：用 shader 沿形状描一圈细线，只保留内侧一半。
///
/// 对应参考库 `HighlightModifier` 的做法——`strokeWidth = width * 2`，再把
/// 结果裁剪到形状内，于是可见的只有内侧宽度为 [width] 的一圈，强度随该处
/// 边缘法线与光方向的夹角变化。
class _LiquidGlassHighlightPainter extends CustomPainter {
  const _LiquidGlassHighlightPainter({
    required this.radius,
    required this.width,
    required this.angleDegrees,
    required this.falloff,
    required this.color,
  });

  final double radius;
  final double width;
  final double angleDegrees;
  final double falloff;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    paintLiquidGlassHighlight(
      canvas,
      size,
      radius: radius,
      width: width,
      angleDegrees: angleDegrees,
      falloff: falloff,
      color: color,
    );
  }

  @override
  bool shouldRepaint(_LiquidGlassHighlightPainter oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.width != width ||
      oldDelegate.angleDegrees != angleDegrees ||
      oldDelegate.falloff != falloff ||
      oldDelegate.color != color;
}

// ---------------------------------------------------------------------------
// shader 资源
// ---------------------------------------------------------------------------

ui.FragmentProgram? _gRefractionProgram;
ui.FragmentProgram? _gHighlightProgram;
Future<ui.FragmentProgram>? _gRefractionLoading;
Future<ui.FragmentProgram>? _gHighlightLoading;

/// 加载折射着色器（带缓存，供所有玻璃面共用同一个 Program）。
Future<ui.FragmentProgram> loadLiquidGlassRefractionProgram() {
  if (_gRefractionProgram != null) {
    return Future<ui.FragmentProgram>.value(_gRefractionProgram);
  }
  return _gRefractionLoading ??=
      ui.FragmentProgram.fromAsset('shaders/liquid_glass_refraction.frag').then(
        (program) {
          _gRefractionProgram = program;
          return program;
        },
      );
}

/// 边缘高光着色器；尚未加载完成时为 null（此时不画高光）。
ui.FragmentProgram? get liquidGlassHighlightProgram => _gHighlightProgram;

/// 预热两个着色器：折射在首帧后按需异步加载，高光需要显式预热才会生效。
Future<void> preloadLiquidGlassShaders() async {
  try {
    if (_gRefractionProgram == null) {
      await loadLiquidGlassRefractionProgram();
    }
    _gHighlightProgram ??= await (_gHighlightLoading ??=
        ui.FragmentProgram.fromAsset('shaders/liquid_glass_highlight.frag'));
  } catch (_) {
    // 优雅降级：着色器不可用时退化为纯模糊玻璃。
  }
}

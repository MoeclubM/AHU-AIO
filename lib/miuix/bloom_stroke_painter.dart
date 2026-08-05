import 'dart:ui';
import 'package:flutter/material.dart';

FragmentProgram? _gBloomStrokeProgram;

/// 复用缓存的 [FragmentProgram]，避免重复加载 shader 资源。
Future<FragmentProgram> loadBloomStrokeProgram() async {
  return _gBloomStrokeProgram ??= await FragmentProgram.fromAsset(
    'shaders/bloom_stroke.frag',
  );
}

/// 用 Flutter FragmentShader 精确移植 miuix-blur 的 BloomStroke 高光。
///
/// 参考 SukiSU Ultra / compose-miuix-ui miuix 的 BloomStroke：圆角矩形
/// SDF + 半球法线 + 双定向光源边缘高光。shader 与 SukiSU 一致，效果对等。
///
/// [enabled] 为 false 时不绘制（用于高对比度等场景）。
class BloomStrokePainter extends CustomPainter {
  BloomStrokePainter({
    required this.radius,
    required this.isDark,
    required this.enabled,
    this.highlightAlpha = 1.0,
  });

  final double radius;
  final bool isDark;
  final bool enabled;
  final double highlightAlpha;

  FragmentProgram? _program;
  bool _loading = false;

  @override
  void paint(Canvas canvas, Size size) {
    if (!enabled || size.width <= 0 || size.height <= 0) return;

    if (_program == null && !_loading) {
      _loading = true;
      loadBloomStrokeProgram().then((p) {
        _program = p;
        _loading = false;
      });
      return;
    }
    final program = _program;
    if (program == null) return;

    final shader = program.fragmentShader();
    final r = radius.clamp(0.0, size.shortestSide / 2).toDouble();
    // GlassStrokeMiddle 预设：stroke 0.8dp、innerBlur 2.8dp。
    // Flutter 的 CustomPaint 传入的是逻辑像素，dp 需按 (shortestSide/360) 比例换算，
    // 使不同屏幕尺寸下高光带相对宽度一致（近似 dpr）。
    final density = (size.shortestSide / 360).clamp(0.5, 2.0).toDouble();
    final strokeW = (0.8 * density)
        .clamp(0.0, size.shortestSide / 2)
        .toDouble();
    final innerBlur = (2.8 * density).clamp(0.0, size.shortestSide).toDouble();

    // Flutter 的 setFloat 按 float 展平索引：u_size(vec2) 占 0,1；
    // u_corner_radius=2, u_stroke_width=3, u_inner_blur_radius=4,
    // u_highlight_alpha=5, u_dark=6。
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, r)
      ..setFloat(3, strokeW)
      ..setFloat(4, innerBlur)
      ..setFloat(5, highlightAlpha)
      ..setFloat(6, isDark ? 1.0 : 0.0);

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant BloomStrokePainter oldDelegate) =>
      enabled != oldDelegate.enabled ||
      radius != oldDelegate.radius ||
      isDark != oldDelegate.isDark ||
      highlightAlpha != oldDelegate.highlightAlpha;
}

import 'dart:ui';
import 'package:flutter/material.dart';

FragmentProgram? _gBloomStrokeProgram;

/// 复用缓存的 [FragmentProgram]，避免重复加载 shader 资源。
Future<FragmentProgram> loadBloomStrokeProgram() async {
  return _gBloomStrokeProgram ??= await FragmentProgram.fromAsset(
    'shaders/bloom_stroke.frag',
  );
}

/// 用 Flutter FragmentShader 精确绘制 miuix-blur 的 BloomStroke 高光。
///
/// 这是承载 [CustomPaint] 的 StatefulWidget：加载 [FragmentProgram] 完成后
/// 通过 [setState] 触发重绘，避免异步加载后永远不画的问题。
///
/// [enabled] 为 false 时不绘制（用于高对比度等场景）。
class BloomStrokeLayer extends StatefulWidget {
  const BloomStrokeLayer({
    super.key,
    required this.radius,
    required this.isDark,
    required this.enabled,
    this.highlightAlpha = 1.0,
  });

  final double radius;
  final bool isDark;
  final bool enabled;
  final double highlightAlpha;

  @override
  State<BloomStrokeLayer> createState() => _BloomStrokeLayerState();
}

class _BloomStrokeLayerState extends State<BloomStrokeLayer> {
  FragmentProgram? _program;

  @override
  void initState() {
    super.initState();
    loadBloomStrokeProgram().then((p) {
      if (mounted) setState(() => _program = p);
    });
  }

  @override
  Widget build(BuildContext context) {
    final program = _program;
    if (program == null || !widget.enabled) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: CustomPaint(
        painter: _BloomStrokePainter(
          program: program,
          radius: widget.radius,
          isDark: widget.isDark,
          highlightAlpha: widget.highlightAlpha,
        ),
      ),
    );
  }
}

class _BloomStrokePainter extends CustomPainter {
  _BloomStrokePainter({
    required this.program,
    required this.radius,
    required this.isDark,
    required this.highlightAlpha,
  });

  final FragmentProgram program;
  final double radius;
  final bool isDark;
  final double highlightAlpha;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final shader = program.fragmentShader();
    final r = radius.clamp(0.0, size.shortestSide / 2).toDouble();
    // GlassStrokeMiddle 预设：stroke 0.8dp、innerBlur 2.8dp。
    // CustomPaint 传入逻辑像素，按 (shortestSide/360) 比例换算相对宽度。
    final density = (size.shortestSide / 360).clamp(0.5, 2.0).toDouble();
    final strokeW = (0.8 * density)
        .clamp(0.0, size.shortestSide / 2)
        .toDouble();
    final innerBlur = (2.8 * density).clamp(0.0, size.shortestSide).toDouble();

    // Flutter setFloat 按 float 展平：u_size 占 0,1；u_corner_radius=2,
    // u_stroke_width=3, u_inner_blur_radius=4, u_highlight_alpha=5, u_dark=6。
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
  bool shouldRepaint(covariant _BloomStrokePainter oldDelegate) =>
      program != oldDelegate.program ||
      radius != oldDelegate.radius ||
      isDark != oldDelegate.isDark ||
      highlightAlpha != oldDelegate.highlightAlpha;
}

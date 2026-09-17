import 'package:flutter/material.dart';

/// 只在形状**外侧**绘制的投影，等价 Compose 的 `Modifier.dropShadow`。
///
/// Flutter 的 [BoxShadow] 会把形状内部一并填成阴影色；当上层是半透明填充
/// （毛玻璃 / 液态玻璃）时，这份内部的黑色会直接透出来，让整块区域发暗——
/// 表现为「底下的文字把黑色糊满了整个面板」。本组件把阴影裁到形状之外，
/// 因此可以安全地配合半透明表面使用。
class MiuixDropShadow extends StatelessWidget {
  const MiuixDropShadow({
    super.key,
    required this.shape,
    required this.color,
    required this.sigma,
    required this.child,
    this.offset = Offset.zero,
  });

  /// 投影形状（同时作为挖空区域）。
  final ShapeBorder shape;

  /// 阴影颜色（含透明度）。
  final Color color;

  /// 高斯模糊 sigma，约等于 Compose shadow radius 的一半。
  final double sigma;

  /// 阴影相对形状的偏移（Compose `Shadow` 的 offset）。
  final Offset offset;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _OutsideShadowPainter(
                shape: shape,
                color: color,
                sigma: sigma,
                offset: offset,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _OutsideShadowPainter extends CustomPainter {
  const _OutsideShadowPainter({
    required this.shape,
    required this.color,
    required this.sigma,
    required this.offset,
  });

  final ShapeBorder shape;
  final Color color;
  final double sigma;
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final Rect rect = Offset.zero & size;
    final Path shaped = shape.getOuterPath(rect);
    // 偏移后的阴影不能画进形状内部，否则半透明表面会透出阴影的黑色。
    final Path shifted = shaped.shift(offset);
    final Path outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(rect.inflate(sigma * 4 + offset.distance)),
      shaped,
    );

    canvas.save();
    canvas.clipPath(outside, doAntiAlias: true);
    canvas.drawPath(
      shifted,
      Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OutsideShadowPainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.color != color ||
      oldDelegate.sigma != sigma ||
      oldDelegate.offset != offset;
}

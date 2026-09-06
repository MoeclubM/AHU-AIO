import 'dart:ui';

/// 液态玻璃模糊滤镜。
///
/// 使用高性能高斯模糊 [ImageFilter.blur]，支持边缘 clamp。
ImageFilter liquidGlassImageFilter({double blurSigma = 4.0}) {
  return ImageFilter.blur(
    sigmaX: blurSigma,
    sigmaY: blurSigma,
    tileMode: TileMode.clamp,
  );
}

import 'dart:typed_data';
import 'dart:ui';

/// Vibrancy filter: saturation 1.5x, matching SukiSU colorControls(saturation=1.5).
ImageFilter vibrancyFilter({double saturation = 1.5}) {
  final s = saturation;
  final m = Float64List.fromList([
    0.213 + 0.787 * s, 0.715 - 0.715 * s, 0.072 - 0.072 * s, 0, 0, //
    0.213 - 0.213 * s, 0.715 + 0.285 * s, 0.072 - 0.072 * s, 0, 0, //
    0.213 - 0.213 * s, 0.715 - 0.715 * s, 0.072 + 0.928 * s, 0, 0, //
    0, 0, 0, 1, 0,
  ]);
  return ImageFilter.matrix(m);
}

/// Composed blur(4dp) + vibrancy, matching SukiSU blur(4dp) + vibrancy().
ImageFilter liquidGlassImageFilter({double blurSigma = 4.0}) {
  return ImageFilter.compose(
    inner: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
    outer: vibrancyFilter(),
  );
}

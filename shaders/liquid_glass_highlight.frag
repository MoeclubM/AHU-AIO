// 液态玻璃边缘高光（rim light）：Flutter 移植自 AndroidLiquidGlass (Kyant0,
// Apache-2.0) 的 internal/Shaders.kt 的 DefaultHighlightShaderString。
//
// 原理：沿形状边缘取 SDF 梯度当法线，与光方向点乘，用 pow(abs(dot), falloff)
// 得到沿周向变化的强度 —— 面向光的一侧最亮，背光侧最暗，形成玻璃的镜面反光。
// 与 BloomStroke 的差异：这里不做 3D 半球法线，纯二维 SDF 梯度，因此高光是
// 一条贴着轮廓、随角度渐变的细亮线。
//
// 用法：以 Paint.shader 绘制（不需要 Impeller），画的时候按参考实现用
// 「描边 + 裁到形状内」，这样高光只出现在形状内侧一圈。
#include <flutter/runtime_effect.glsl>

// 画布尺寸（逻辑像素），由 Dart 侧设置。
uniform vec2 u_size;

// 形状相对画布的内缩与圆角半径（逻辑像素）。
uniform float u_pad;
uniform float u_radius;

// 光方向（弧度）与衰减指数。
uniform float u_angle;
uniform float u_falloff;

// 高光颜色（含 alpha）。
uniform vec4 u_color;

out vec4 frag_color;

vec2 gradSdRoundedRect(vec2 coord, vec2 halfSize, float radius) {
  vec2 cornerCoord = abs(coord) - (halfSize - vec2(radius));
  if (cornerCoord.x >= 0.0 || cornerCoord.y >= 0.0) {
    return sign(coord) * normalize(max(cornerCoord, vec2(0.0)) + vec2(1e-5));
  }
  float gradX = step(cornerCoord.y, cornerCoord.x);
  return sign(coord) * vec2(gradX, 1.0 - gradX);
}

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 halfSize = max(u_size * 0.5 - vec2(u_pad), vec2(1.0));
  vec2 centered = fragCoord - u_size * 0.5;
  float radius = clamp(u_radius, 0.0, min(halfSize.x, halfSize.y));

  // 与参考实现一致：梯度半径放大 1.5 倍，让法线在圆角处更平缓。
  float gradRadius = min(radius * 1.5, min(halfSize.x, halfSize.y));
  vec2 grad = gradSdRoundedRect(centered, halfSize, gradRadius);

  vec2 lightNormal = vec2(cos(u_angle), sin(u_angle));
  float d = dot(grad, lightNormal);
  float intensity = pow(abs(d), u_falloff);

  // Flutter 的 fragment shader 输出按**预乘 alpha** 解释，
  // 直接写 vec4(rgb, a) 会让颜色被当成已预乘、整体偏亮到饱和。
  float alpha = u_color.a * intensity;
  frag_color = vec4(u_color.rgb * alpha, alpha);
}

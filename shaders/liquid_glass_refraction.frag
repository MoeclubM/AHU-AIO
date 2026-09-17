// 液态玻璃折射（lens）：Flutter 移植自 AndroidLiquidGlass (Kyant0, Apache-2.0)
// 的 backdrop/effects/Lens.kt + internal/Shaders.kt 的 RoundedRectRefractionShaderString。
//
// 原理：按圆角矩形的 SDF 求梯度方向，在靠近边缘的一圈内沿法线方向重采样背景，
// 位移量由 circleMap（1 - sqrt(1 - x²)）给出，于是边缘像真实玻璃一样把背景
// 压缩/放大，而不是单纯模糊。可选 depthEffect 让位移在中心方向也有分量，
// 可选色散让 R/B 通道错开采样。
//
// 用法：作为 ImageFilter.shader 的输入（需 Impeller）。引擎会把背景纹理尺寸
// 写进第一个 vec2 uniform，因此 u_size 不由 Dart 侧设置。
#include <flutter/runtime_effect.glsl>

// 首个 uniform 必须是 vec2 —— ImageFilter.shader 在此写入背景纹理尺寸
// （物理像素）。引擎每帧覆盖，Dart 侧无需也无法设置。
uniform vec2 u_size;
uniform sampler2D u_texture;

// 逻辑尺寸：片上单位与逻辑像素的比值由 u_size / u_logical_size 推出，
// 这样折射量不依赖具体 DPR。
uniform vec2 u_logical_size;

// 形状相对纹理的内缩（逻辑像素）——形状周围要留出背景纹理供边缘取样。
uniform float u_pad;

// 圆角半径（逻辑像素）。
uniform float u_radius;

// 折射高度与强度（逻辑像素），对应 Kotlin 的 refractionHeight / refractionAmount。
uniform float u_refraction_height;
uniform float u_refraction_amount;

// 0 = 关闭；>0 时位移同时具备指向中心的分量。
uniform float u_depth_effect;

// 0 = 关闭；>0 时开启通道色散。
uniform float u_dispersion;

out vec4 frag_color;

float sdRoundedRect(vec2 coord, vec2 halfSize, float radius) {
  vec2 cornerCoord = abs(coord) - (halfSize - vec2(radius));
  float outside = length(max(cornerCoord, vec2(0.0))) - radius;
  float inside = min(max(cornerCoord.x, cornerCoord.y), 0.0);
  return outside + inside;
}

vec2 gradSdRoundedRect(vec2 coord, vec2 halfSize, float radius) {
  vec2 cornerCoord = abs(coord) - (halfSize - vec2(radius));
  if (cornerCoord.x >= 0.0 || cornerCoord.y >= 0.0) {
    return sign(coord) * normalize(max(cornerCoord, vec2(0.0)) + vec2(1e-5));
  }
  float gradX = step(cornerCoord.y, cornerCoord.x);
  return sign(coord) * vec2(gradX, 1.0 - gradX);
}

float circleMap(float x) {
  return 1.0 - sqrt(max(1.0 - x * x, 0.0));
}

vec4 sampleContent(vec2 coord) {
  vec2 uv = coord / u_size;
#ifdef IMPELLER_TARGET_OPENGLES
  // OpenGL ES 的纹理原点在左下，与 FlutterFragCoord 相反。
  uv.y = 1.0 - uv.y;
#endif
  return texture(u_texture, uv);
}

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;

  // 逻辑像素 → 片上单位。
  float unit = 0.5 *
      (u_size.x / max(u_logical_size.x, 1.0) +
       u_size.y / max(u_logical_size.y, 1.0));

  vec2 halfSize = max(u_size * 0.5 - vec2(u_pad * unit), vec2(1.0));
  vec2 centered = fragCoord - u_size * 0.5;
  float radius = clamp(u_radius * unit, 0.0, min(halfSize.x, halfSize.y));

  float sd = sdRoundedRect(centered, halfSize, radius);

  // 形状外输出透明：由 SDF 自己裁出边缘并顺带抗锯齿，
  // 这样过滤器区域可以比形状大，边缘取样才有背景可用。
  float coverage = 1.0 - smoothstep(-1.0, 1.0, sd);
  if (coverage <= 0.0) {
    frag_color = vec4(0.0);
    return;
  }

  float refrHeight = u_refraction_height * unit;
  // 与 Kotlin 端一致：位移量取负，边缘表现为向内收拢的透镜。
  float refrAmount = -u_refraction_amount * unit;

  vec2 coord = fragCoord;
  vec2 dispersionVec = vec2(0.0);

  if (refrHeight > 0.0 && -sd < refrHeight) {
    float inner = min(sd, 0.0);
    float d = circleMap(1.0 - -inner / refrHeight) * refrAmount;
    float gradRadius = min(radius * 1.5, min(halfSize.x, halfSize.y));
    vec2 grad = normalize(
        gradSdRoundedRect(centered, halfSize, gradRadius) +
        u_depth_effect * normalize(centered + vec2(1e-5)));
    coord += d * grad;

    float dispersionIntensity =
        u_dispersion * (centered.x * centered.y) /
        max(halfSize.x * halfSize.y, 1.0);
    dispersionVec = d * grad * dispersionIntensity;
  }

  vec3 rgb;
  if (u_dispersion > 0.0) {
    // 简化色散：只有 R/B 沿色散方向错开（参考实现用 7 抽样，这里取等效观感）。
    rgb.r = sampleContent(coord + dispersionVec).r;
    rgb.g = sampleContent(coord).g;
    rgb.b = sampleContent(coord - dispersionVec).b;
  } else {
    rgb = sampleContent(coord).rgb;
  }

  // vibrancy：模糊后的背景提饱和，系数与参考库 VibrantColorFilter 一致。
  float lum = dot(rgb, vec3(0.213, 0.715, 0.072));
  rgb = mix(vec3(lum), rgb, 1.5);

  // 输出按预乘 alpha 解释：形状外用 coverage 同时把颜色与 alpha 归零。
  rgb = clamp(rgb, vec3(0.0), vec3(1.0)) * coverage;
  frag_color = vec4(rgb, coverage);
}

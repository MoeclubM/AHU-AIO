// 液态玻璃折射（lens）：Flutter 移植自 AndroidLiquidGlass (Kyant0, Apache-2.0)
// 的 backdrop/effects/Lens.kt + internal/Shaders.kt 的 RoundedRectRefractionShaderString。
//
// 原理：按圆角矩形的 SDF 求梯度方向，在靠近边缘的一圈内沿法线方向重采样背景，
// 位移量由 circleMap（1 - sqrt(1 - x²)）给出，于是边缘像真实玻璃一样把背景
// 压缩/放大，而不是单纯模糊。可选 depthEffect 让位移在中心方向也有分量，
// 可选色散让 R/B 通道错开采样。
//
// 坐标契约（关键）：作为 **backdrop filter** 使用时，`FlutterFragCoord` 是
// **屏幕空间**设备像素，`u_size` 是整个背景纹理（≈全屏）的尺寸——Flutter 引擎
// 自己的 `ClippedBackdropFilterWithShader` 测试就是这么用的（拿 fragCoord 直接
// 和 u_size 表示的屏幕边界比较）。所以形状必须用外层传入的 u_origin
// （本区域左上角在屏幕中的位置）换算到局部坐标，不能把 fragCoord 当局部坐标。
#include <flutter/runtime_effect.glsl>

// 首个 uniform 必须是 vec2 —— ImageFilter.shader 在此写入背景纹理尺寸
// （设备像素）。引擎每帧覆盖，Dart 侧无需也无法设置；这里只用于取样钳制。
uniform vec2 u_size;
uniform sampler2D u_texture;

// 本区域（形状 + 取样外扩）左上角在屏幕中的位置，设备像素。
uniform vec2 u_origin;

// 本区域尺寸，设备像素。
uniform vec2 u_region_size;

// 设备像素比：把逻辑像素参数换算成片上单位。
uniform float u_dpr;

// 圆角半径（逻辑像素）。支持四角独立：x=TL, y=TR, z=BR, w=BL。
uniform vec4 u_radius;

// 折射高度与强度（逻辑像素），对应 Kotlin 的 refractionHeight / refractionAmount。
uniform float u_refraction_height;
uniform float u_refraction_amount;

// 0 = 关闭；>0 时位移同时具备指向中心的分量。
uniform float u_depth_effect;

// 0 = 关闭；>0 时开启 7 抽样通道色散（对应 chromaticAberration）。
uniform float u_dispersion;

out vec4 frag_color;

float radiusAt(vec2 coord, vec4 radii) {
  if (coord.x >= 0.0) {
    if (coord.y <= 0.0) return radii.y;
    return radii.z;
  }
  if (coord.y <= 0.0) return radii.x;
  return radii.w;
}

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

vec4 sampleContent(vec2 screenCoord) {
  // 钳制到纹理内，避免边缘出现钳制像素拉出的色带。
  vec2 clamped = clamp(screenCoord, vec2(0.0), max(u_size - vec2(1.0), vec2(0.0)));
  vec2 uv = clamped / u_size;
#ifdef IMPELLER_TARGET_OPENGLES
  // OpenGL ES 的纹理原点在左下，与 FlutterFragCoord 相反。
  uv.y = 1.0 - uv.y;
#endif
  return texture(u_texture, uv);
}

void main() {
  // 屏幕空间设备像素 → 本区域局部设备像素。
  vec2 local = FlutterFragCoord().xy - u_origin;

  vec2 halfSize = max(u_region_size * 0.5, vec2(1.0));
  vec2 centered = local - halfSize;
  float radius = clamp(
    radiusAt(centered, u_radius) * u_dpr,
    0.0,
    min(halfSize.x, halfSize.y)
  );

  float sd = sdRoundedRect(centered, halfSize, radius);

  // 形状外输出透明：由 SDF 自己裁出边缘并顺带抗锯齿，
  // 这样过滤器区域可以比形状大，边缘取样才有背景可用。
  float coverage = 1.0 - smoothstep(-1.0, 1.0, sd);
  if (coverage <= 0.0) {
    frag_color = vec4(0.0);
    return;
  }

  float refrHeight = u_refraction_height * u_dpr;
  // 与 Kotlin 端一致：位移量取负，边缘表现为向内收拢的透镜。
  float refrAmount = -u_refraction_amount * u_dpr;

  vec2 coord = local;
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

  // 取样坐标换算回屏幕空间（背景纹理坐标即屏幕设备像素）。
  vec2 screenCoord = coord + u_origin;

  vec4 rgba;
  if (u_dispersion > 0.0) {
    // 与参考库 RoundedRectRefractionWithDispersionShaderString 一致的 7 抽样色散：
    // 红→紫沿色散向量分布，各通道按光谱权重累加。
    vec4 color = vec4(0.0);

    vec4 red = sampleContent(screenCoord + dispersionVec);
    color.r += red.r / 3.5;
    color.a += red.a / 7.0;

    vec4 orange = sampleContent(screenCoord + dispersionVec * (2.0 / 3.0));
    color.r += orange.r / 3.5;
    color.g += orange.g / 7.0;
    color.a += orange.a / 7.0;

    vec4 yellow = sampleContent(screenCoord + dispersionVec * (1.0 / 3.0));
    color.r += yellow.r / 3.5;
    color.g += yellow.g / 3.5;
    color.a += yellow.a / 7.0;

    vec4 green = sampleContent(screenCoord);
    color.g += green.g / 3.5;
    color.a += green.a / 7.0;

    vec4 cyan = sampleContent(screenCoord - dispersionVec * (1.0 / 3.0));
    color.g += cyan.g / 3.5;
    color.b += cyan.b / 3.0;
    color.a += cyan.a / 7.0;

    vec4 blue = sampleContent(screenCoord - dispersionVec * (2.0 / 3.0));
    color.b += blue.b / 3.0;
    color.a += blue.a / 7.0;

    vec4 purple = sampleContent(screenCoord - dispersionVec);
    color.r += purple.r / 7.0;
    color.b += purple.b / 3.0;
    color.a += purple.a / 7.0;

    rgba = color;
  } else {
    rgba = sampleContent(screenCoord);
  }

  vec3 rgb = rgba.rgb;

  // vibrancy：模糊后的背景提饱和，系数与参考库 VibrantColorFilter 一致。
  float lum = dot(rgb, vec3(0.213, 0.715, 0.072));
  rgb = mix(vec3(lum), rgb, 1.5);

  // 输出按预乘 alpha 解释：形状外用 coverage 同时把颜色与 alpha 归零。
  rgb = clamp(rgb, vec3(0.0), vec3(1.0)) * coverage;
  frag_color = vec4(rgb, coverage);
}

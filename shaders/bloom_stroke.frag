// Flutter runtime effect port of miuix-blur BloomStroke AGSL shader.
// Rounded-rect SDF + 3D hemispheric rim normal lit by two directional lights.
// See compose-miuix-ui/miuix miuix-blur internal/Shaders.kt (Apache-2.0).
// Preset lights (GlassStrokeMiddle) hardcoded for a minimal uniform set.
#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;          // fragment coordinate space size
uniform float u_corner_radius;
uniform float u_stroke_width;
uniform float u_inner_blur_radius;
uniform float u_highlight_alpha;
uniform float u_dark;         // 1.0 = dark preset, 0.0 = light preset

// Light reference origin (miuix LIGHT_REF).
const float LIGHT_REF_X = 0.5;
const float LIGHT_REF_Y = 0.7;

out vec4 fragColor;

float roundedBoxSDF(vec2 pos, vec2 halfSize, float radius) {
    radius = min(radius, min(halfSize.x, halfSize.y));
    vec2 d = pos - halfSize + radius;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - radius;
}

vec3 getNormal(vec2 fragCoord, float sdf, float R, vec2 halfView) {
    vec2 xy = fragCoord - floor(halfView);
    vec2 xy_a = abs(xy);
    float t = smoothstep(-u_inner_blur_radius, 0.0, sdf);
    float z = sqrt(max(u_inner_blur_radius * u_inner_blur_radius - t * t, 0.0));
    vec3 coord = vec3(xy_a, -z);

    vec2 corner = halfView - R;
    corner.x = min(corner.x, xy_a.x);
    corner.y = min(corner.y, xy_a.y);

    vec2 dirn = normalize(coord.xy - corner.xy);
    corner += dirn * (R - u_inner_blur_radius);

    if (any(lessThan(xy_a, corner))) {
        return vec3(0.0, 0.0, -1.0);
    }

    vec2 signal = sign(xy);
    vec3 n = normalize(coord - vec3(corner, 0.0));
    n.xy *= signal;
    return n;
}

void main() {
    vec2 fragCoord = FlutterFragCoord();
    vec2 halfView = u_size * 0.5;
    vec2 xy = abs(fragCoord - halfView);

    float R = max(u_corner_radius, u_inner_blur_radius);

    if (all(lessThan(xy, halfView - R))) {
        fragColor = vec4(0.0);
        return;
    }

    float sdf = roundedBoxSDF(xy, halfView, u_corner_radius);
    float outMask = smoothstep(0.0, -1.0, sdf);
    float strokeAlpha = smoothstep(-u_stroke_width, -u_stroke_width + 1.0, sdf);

    // GlassStrokeMiddle preset: stroke color white, alpha 0.05/0.06.
    float strokeAlphaMul = mix(0.05, 0.06, u_dark);
    vec3 rgb = vec3(strokeAlphaMul * strokeAlpha * strokeAlpha);

    vec3 n = getNormal(fragCoord, sdf, R, halfView);

    // Primary light (0.5, 0.5, -0.5), intensity 0.4 / 0.5.
    vec3 primaryLightDir = normalize(vec3(0.5 - LIGHT_REF_X, 0.5 - LIGHT_REF_Y, -0.5));
    vec2 primaryAxis = normalize(vec2(primaryLightDir.x, primaryLightDir.y));
    float pIntensity = mix(0.4, 0.5, u_dark);
    float falloff1 = max(dot(vec3(primaryAxis, 0.0), n), 0.0);
    float light1 = clamp(dot(n, primaryLightDir) * falloff1, 0.0, 1.0);
    rgb += vec3(light1 * light1 * pIntensity);

    // Secondary light (0.5, 0.8, -0.5), intensity 0.25.
    vec3 secondaryLightDir = normalize(vec3(0.5 - LIGHT_REF_X, 0.8 - LIGHT_REF_Y, -0.5));
    vec2 secondaryAxis = normalize(vec2(secondaryLightDir.x, secondaryLightDir.y));
    float falloff2 = max(dot(vec3(secondaryAxis, 0.0), n), 0.0);
    float light2 = clamp(dot(n, secondaryLightDir) * falloff2, 0.0, 1.0);
    rgb += vec3(light2 * light2 * 0.25);

    // 仅边缘带可见：矩形内部深处与外部均透明，
    // 避免整块覆盖内容导致黑屏并遮挡点击。
    float innerEdge = smoothstep(-u_inner_blur_radius, 0.0, sdf);
    float outerEdge = 1.0 - smoothstep(0.0, u_stroke_width, sdf);
    float edgeMask = min(innerEdge, outerEdge);

    fragColor = vec4(rgb * u_highlight_alpha, outMask * edgeMask * u_highlight_alpha);
}
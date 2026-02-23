#include <flutter/runtime_effect.glsl>

precision highp float;

// Core uniforms
uniform vec2 uSize;
uniform float uClickCount;
uniform vec2 uTouchPoints[10];
uniform float uTimes[10];

// Noise & edge
uniform float uNoiseScale;
uniform float uEdgeWidth;
uniform float uGlowIntensity;
uniform vec3 uSmokeColor;     // RGB smoke color
uniform float uBurnRadius;    // radius of each burn tap

// Child texture
uniform sampler2D uTexture;

out vec4 fragColor;

// ============ HASH FUNCTIONS ============

vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy) * 2.0 - 1.0;
}

// ============ PERLIN NOISE ============

float perlinNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

    float a = dot(hash22(i), f);
    float b = dot(hash22(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0));
    float c = dot(hash22(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0));
    float d = dot(hash22(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y) * 0.5 + 0.5;
}

// ============ TURBULENCE ============

float turbulenceNoise(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    float maxValue = 0.0;

    mat2 rot = mat2(0.8, 0.6, -0.6, 0.8);

    for (int i = 0; i < 5; i++) {
        value += amplitude * abs(perlinNoise(p * frequency) * 2.0 - 1.0);
        maxValue += amplitude;
        amplitude *= 0.5;
        frequency *= 2.0;
        p = rot * p;
    }

    return value / maxValue;
}

// ============ MAIN ============

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    float aspect = uSize.x / uSize.y;
    int clickCount = int(uClickCount);

    // Evaluate turbulence noise once (position-dependent, not tap-dependent)
    float noiseVal = turbulenceNoise(uv * uNoiseScale);

    // Margin so each tap's burn starts and ends fully invisible
    float edgeThickness = 0.06;
    float glowWidth = 0.12;
    float margin = edgeThickness + glowWidth;
    float offset = margin + uEdgeWidth;
    float sweepRange = 1.0 + 2.0 * uEdgeWidth + 2.0 * margin;

    // Find minimum burn distance across all active taps
    float minD = 999.0;

    for (int i = 0; i < 10; i++) {
        if (i >= clickCount) break;

        // Per-tap progress is now 0-1, computed in Dart
        float tapProgress = uTimes[i];

        // Radial distance from this tap point (in UV space, aspect-corrected)
        vec2 origin = uTouchPoints[i] / uSize;
        vec2 delta = uv - origin;
        delta.x *= aspect;
        float dist = length(delta);
        float normalizedDist = dist / (uBurnRadius * 0.5);

        // Per-tap burn distance
        float d_i = normalizedDist + uEdgeWidth * (noiseVal - 0.5) * 2.0
                    + offset - tapProgress * sweepRange;
        minD = min(minD, d_i);
    }

    // Sample child texture
    vec4 tex = texture(uTexture, uv);

    // If no taps, just show the texture
    if (clickCount == 0) {
        fragColor = tex;
        return;
    }

    float burnMask = smoothstep(-edgeThickness, edgeThickness, minD);
    float glow = smoothstep(-glowWidth - edgeThickness, -edgeThickness, minD)
               * (1.0 - burnMask);

    // Modulate glow with noise for organic flicker
    float glowNoise = turbulenceNoise(uv * uNoiseScale * 2.0 + 42.0);
    glow *= 0.5 + 0.5 * glowNoise;

    // Smoke color
    vec3 smokeColor = uSmokeColor * uGlowIntensity;

    // Compose: child texture with burn mask + smoke glow
    // Use premultiplied alpha compositing
    vec3 color = tex.rgb * burnMask + smokeColor * glow;
    float alpha = tex.a * burnMask + glow;
    alpha = clamp(alpha, 0.0, 1.0);

    fragColor = vec4(color, alpha);
}

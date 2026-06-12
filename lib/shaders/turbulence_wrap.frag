#include <flutter/runtime_effect.glsl>

precision highp float;

// Standard header
uniform vec2 uSize;
uniform float uTime;

// Turbulence params
uniform float uOctaves;
uniform float uBaseFrequency;
uniform float uNoiseScale;
uniform float uAnimSpeed;
uniform float uDisplacementStrength;

// Child texture (sampler index 0, auto-bound by ShaderWrap)
uniform sampler2D uTexture;

out vec4 fragColor;

// ============ HASH FUNCTION ============

vec3 hash33(vec3 p) {
    p = fract(p * vec3(0.1031, 0.1030, 0.0973));
    p += dot(p, p.yxz + 33.33);
    return fract((p.xxy + p.yxx) * p.zyx) * 2.0 - 1.0;
}

// ============ 3D PERLIN NOISE ============

float perlinNoise3D(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);

    // Quintic interpolation
    vec3 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

    float n000 = dot(hash33(i + vec3(0.0, 0.0, 0.0)), f - vec3(0.0, 0.0, 0.0));
    float n100 = dot(hash33(i + vec3(1.0, 0.0, 0.0)), f - vec3(1.0, 0.0, 0.0));
    float n010 = dot(hash33(i + vec3(0.0, 1.0, 0.0)), f - vec3(0.0, 1.0, 0.0));
    float n110 = dot(hash33(i + vec3(1.0, 1.0, 0.0)), f - vec3(1.0, 1.0, 0.0));
    float n001 = dot(hash33(i + vec3(0.0, 0.0, 1.0)), f - vec3(0.0, 0.0, 1.0));
    float n101 = dot(hash33(i + vec3(1.0, 0.0, 1.0)), f - vec3(1.0, 0.0, 1.0));
    float n011 = dot(hash33(i + vec3(0.0, 1.0, 1.0)), f - vec3(0.0, 1.0, 1.0));
    float n111 = dot(hash33(i + vec3(1.0, 1.0, 1.0)), f - vec3(1.0, 1.0, 1.0));

    float n00 = mix(n000, n100, u.x);
    float n01 = mix(n001, n101, u.x);
    float n10 = mix(n010, n110, u.x);
    float n11 = mix(n011, n111, u.x);

    float n0 = mix(n00, n10, u.y);
    float n1 = mix(n01, n11, u.y);

    return mix(n0, n1, u.z);
}

// ============ FBM (zero-centered) ============

float fbmNoise3D(vec3 p, int octaves, float baseFreq) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = baseFreq;
    float maxValue = 0.0;

    mat3 rot = mat3(
        0.8, 0.6, 0.0,
        -0.6, 0.8, 0.0,
        0.0, 0.0, 1.0
    );

    for (int i = 0; i < 8; i++) {
        if (i >= octaves) break;

        value += amplitude * perlinNoise3D(p * frequency);
        maxValue += amplitude;
        amplitude *= 0.5;
        frequency *= 2.0;
        p = rot * p;
    }

    return value / maxValue;
}

float animatedFbm(vec2 p, float time, int octaves, float baseFreq) {
    return fbmNoise3D(vec3(p, time * 0.3), octaves, baseFreq);
}

// ============ MAIN ============

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uSize;

    // Compute turbulence for 2D displacement
    float time = uTime * uAnimSpeed;
    float aspect = uSize.x / uSize.y;
    vec2 noiseCoord = vec2(uv.x * aspect, uv.y) * uNoiseScale;
    int octaves = int(uOctaves);

    float noiseX = animatedFbm(noiseCoord, time, octaves, uBaseFrequency);
    // Offset by large constant to decorrelate X and Y channels
    float noiseY = animatedFbm(noiseCoord + vec2(43.0, 17.0), time, octaves, uBaseFrequency);

    // FBM is already zero-centered [-1,1], so no bias offset needed
    vec2 displacement = vec2(noiseX, noiseY);

    // Scale by user-controlled strength
    displacement *= uDisplacementStrength;

    // Re-sample child at displaced UV, clamped to bounds
    vec2 displacedUV = clamp(uv + displacement, vec2(0.0), vec2(1.0));
    fragColor = texture(uTexture, displacedUV);
}

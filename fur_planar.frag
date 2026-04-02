#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float time;
uniform vec3 uBgColor;  // sRGB space input

// Plane shape uniforms
uniform float uPlaneOffset;
uniform float uFurThickness;

// Fur pattern uniforms
uniform float uFurNoiseStrength;
uniform float uFurNoiseScale;    // Controls hair fineness (higher = thinner hairs)
uniform float uFurWaveAmplitude;
uniform float uFurWaveFreqX;
uniform float uFurWaveFreqY;
uniform float uFurAnimationSpeed;

// Key light uniforms
uniform vec3 uKeyLightDir;
uniform vec3 uKeyLightColor;
uniform float uKeyLightIntensity;

// Fill light uniforms
uniform vec3 uFillLightDir;
uniform vec3 uFillLightColor;
uniform float uFillLightIntensity;

// Rim/back light uniforms
uniform vec3 uRimLightDir;
uniform vec3 uRimLightColor;
uniform float uRimLightIntensity;

// Fur color uniform
uniform vec3 uFurColor;

// Gradient epsilon uniform
uniform float uGradientEps;

// Wavelet parameter uniforms
uniform float uWaveletSpeed;
uniform float uWaveletFreq;
uniform float uWaveletAmplitude;
uniform float uWaveletDecay;
uniform float uWaveletWidth;

// Click/wavelet uniforms
uniform float uClickCount;
uniform vec2 uClickPos0;
uniform vec2 uClickPos1;
uniform vec2 uClickPos2;
uniform vec2 uClickPos3;
uniform vec2 uClickPos4;
uniform float uClickTime0;
uniform float uClickTime1;
uniform float uClickTime2;
uniform float uClickTime3;
uniform float uClickTime4;

out vec4 fragColor;

#define V vec3

// ============ sRGB CONVERSION ============

// sRGB to linear (for lighting calculations)
V srgbToLinear(V srgb) {
    return pow(srgb, V(2.2));
}

// Linear to sRGB (for output)
V linearToSrgb(V linear) {
    return pow(max(linear, V(0.0)), V(1.0 / 2.2));
}

// ============ CONFIGURATION ============

// Lighting - fixed parameters
const float LIGHT_INITIAL = 5.0;
const float LIGHT_ABSORPTION = 3.0;
const float ALPHA_MULTIPLIER = 2.0;

// Front light: from camera position
const float FRONT_INTENSITY = 0.35;
const V FRONT_COLOR = V(1.0, 0.98, 0.95);

// Ambient (relative to background color)
const float AMBIENT_STRENGTH = 0.6;

// Raymarching
const float RAY_STEP = 0.025;
const int RAY_STEPS = 64;
const float CAMERA_DISTANCE = 3.0;

// ============ PROCEDURAL NOISE ============

float hash21(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float proceduralNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);

    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// ============ SHADER CODE ============

// Signed distance function for the plane half-space.
// The solid region is z > planeZ (behind the plane).
// Fur grows toward the camera (in -z direction) from the plane surface.
// Returns: positive in front of plane (toward camera), negative behind.
float sdPlane(float pz) {
    return -uPlaneOffset - pz;
}

// Calculate wavelet displacement from a single click (3D version)
float wavelet(V pos, vec2 clickPos, float clickTime) {
    if (clickTime <= 0.0) return 0.0;
    float decay = exp(-clickTime * uWaveletDecay);
    if (decay < 0.001) return 0.0;

    vec2 dxy = pos.xy - clickPos;
    float dist = sqrt(dxy.x * dxy.x + dxy.y * dxy.y + pos.z * pos.z);
    float waveRadius = clickTime * uWaveletSpeed;

    float ringDist = abs(dist - waveRadius);
    if (ringDist > uWaveletWidth) return 0.0;
    float ring = 1.0 - ringDist / uWaveletWidth;

    float wave = sin(dist * uWaveletFreq - waveRadius * uWaveletFreq);

    return wave * ring * decay * uWaveletAmplitude;
}

// Calculate total wavelet displacement from all clicks
float totalWavelet(V pos) {
    int clicks = int(uClickCount);
    if (clicks == 0) return 0.0;

    float total = wavelet(pos, uClickPos0, uClickTime0);
    if (clicks == 1) return total;
    total += wavelet(pos, uClickPos1, uClickTime1);
    if (clicks == 2) return total;
    total += wavelet(pos, uClickPos2, uClickTime2);
    if (clicks == 3) return total;
    total += wavelet(pos, uClickPos3, uClickTime3);
    if (clicks == 4) return total;
    total += wavelet(pos, uClickPos4, uClickTime4);

    return total;
}

// Base shape + noise (for gradient - gives fur strand detail)
float fForGradient(V p) {
    float baseShape = uFurThickness - sdPlane(p.z);
    float furNoise = uFurNoiseStrength * proceduralNoise(p.xy * uFurNoiseScale);
    float furWave = uFurWaveAmplitude * sin(
        sin(uFurWaveFreqX * p.x) +
        uFurWaveFreqY * p.y +
        uFurAnimationSpeed * time
    );
    return baseShape - furNoise - furWave;
}

// Full density function for the furry plane
float f(V p, float waveletDisp) {
    return max(0.0, fForGradient(p) + waveletDisp);
}

// Gradient using forward differences (3 samples instead of 6)
V fastGradient(V p) {
    float center = fForGradient(p);
    return V(
        center - fForGradient(p + V(uGradientEps, 0.0, 0.0)),
        center - fForGradient(p + V(0.0, uGradientEps, 0.0)),
        center - fForGradient(p + V(0.0, 0.0, uGradientEps))
    );
}

// Compute wavelet gradient contribution (for visible ripple effect)
V waveletGradient(V p) {
    float center = totalWavelet(p);
    return V(
        center - totalWavelet(p + V(uGradientEps, 0.0, 0.0)),
        center - totalWavelet(p + V(0.0, uGradientEps, 0.0)),
        center - totalWavelet(p + V(0.0, 0.0, uGradientEps))
    );
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;

    // Convert background color from sRGB to linear for lighting calculations
    V bgLinear = srgbToLinear(uBgColor);

    float minDim = min(uSize.x, uSize.y);
    float invMinDim = 1.0 / minDim;

    // Normalize light directions (hoisted outside loop)
    V keyDir = normalize(uKeyLightDir);
    V fillDir = normalize(uFillLightDir);
    V rimDir = normalize(uRimLightDir);

    // Pre-compute rim color blend with background
    V rimColorLinear = mix(uRimLightColor, bgLinear, 0.5);

    // Pre-compute ambient
    V ambient = bgLinear * AMBIENT_STRENGTH;

    // Ray setup
    vec2 uv = (fragCoord - 0.5 * uSize) * invMinDim;
    V rayDir = V(uv, 1.0);
    V rayPos = rayDir * 2.3 - V(0.0, 0.0, CAMERA_DISTANCE);
    V rayStep = rayDir * RAY_STEP;

    // Light accumulator (for self-shadowing within fur)
    V lightAccum = V(LIGHT_INITIAL);

    // Volumetric compositing
    V accumulatedColor = V(0.0);
    float transmittance = 1.0;

    // Raymarching loop
    for (int i = 0; i < RAY_STEPS; i++) {
        // March forward
        rayPos += rayStep;

        // Calculate wavelet once per step, reuse for density
        float waveletDisp = totalWavelet(rayPos);
        float density = f(rayPos, waveletDisp);

        // Attenuate light through fur (for self-shadowing)
        lightAccum *= uFurColor - density / LIGHT_ABSORPTION;

        // Compute gradient: base shape + wavelet contribution for visible ripples
        V gradient = fastGradient(rayPos);

        // Only compute wavelet gradient when there are active clicks
        if (uClickCount > 0.0) {
            gradient += waveletGradient(rayPos);
        }

        // Surface brightness from gradient magnitude
        float gradMag = length(gradient);
        V normal = normalize(gradient + 0.001);

        // Cache normalized ray position and view direction
        V rayPosNorm = normalize(rayPos);
        V viewDir = -rayPosNorm;

        // Four-point lighting calculation
        // Key light (with shadow occlusion)
        float keyDiffuse = max(0.0, dot(normal, keyDir));
        float keyShadow = smoothstep(-0.3, 0.5, dot(rayPosNorm, keyDir));
        V keyContrib = uKeyLightColor * (uKeyLightIntensity * keyDiffuse * keyShadow);

        // Front light (from camera position)
        float NdotV = max(0.0, dot(normal, viewDir));
        V frontContrib = FRONT_COLOR * (FRONT_INTENSITY * NdotV);

        // Fill light (softer, less shadow)
        float fillDiffuse = max(0.0, dot(normal, fillDir));
        float fillShadow = 0.5 + 0.5 * smoothstep(-0.5, 0.3, dot(rayPosNorm, fillDir));
        V fillContrib = uFillLightColor * (uFillLightIntensity * fillDiffuse * fillShadow);

        // Back/rim light
        float oneMinusNdotV = 1.0 - NdotV;
        float rim = oneMinusNdotV * oneMinusNdotV;
        float backDiffuse = max(0.0, dot(normal, rimDir));
        float rimShadow = smoothstep(-0.3, 0.5, dot(rayPosNorm, rimDir));
        V backContrib = rimColorLinear * (uRimLightIntensity * rim * (0.5 + 0.5 * backDiffuse) * rimShadow);

        // Combine all lights with ambient
        V totalLight = ambient + keyContrib + frontContrib + fillContrib + backContrib;

        // Opacity for this sample
        float densityOpacity = density * ALPHA_MULTIPLIER * 0.5;
        float strandOpacity = gradMag * ALPHA_MULTIPLIER * 0.15 * step(0.001, density);
        float sampleOpacity = clamp(max(densityOpacity, strandOpacity), 0.0, 1.0);

        // Color contribution from this sample
        V sampleColor = lightAccum * totalLight;

        // Front-to-back compositing
        accumulatedColor += transmittance * sampleOpacity * sampleColor;

        // Reduce transmittance
        transmittance *= (1.0 - sampleOpacity);

        // Early termination when nearly opaque
        if (transmittance < 0.01) break;
    }

    // Tone map the accumulated fur color
    V furToneMapped = accumulatedColor / (1.0 + accumulatedColor);

    // Composite with background
    V finalLinear = furToneMapped + bgLinear * transmittance;

    // Convert from linear to sRGB for output
    fragColor = vec4(linearToSrgb(finalLinear), 1.0);
}

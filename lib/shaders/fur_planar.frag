#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float time;

// Scalar uniforms are packed into vec4 slots: Impeller's Metal backend binds
// every uniform declaration to its own [[buffer(N)]] and iOS rejects N > 30,
// so the declaration count must stay ≤ 31 (see registry_audit_test.dart).
// The flat float order is unchanged — the Dart writers are untouched; the
// #define aliases keep the body readable.

// Background + plane shape
uniform vec4 uBgPlane;
#define uBgColor           uBgPlane.rgb  // sRGB space input
#define uPlaneOffset       uBgPlane.w

// Fur shape + pattern
uniform vec4 uFur0;
#define uFurThickness      uFur0.x
#define uFurNoiseStrength  uFur0.y
#define uFurNoiseScale     uFur0.z  // Controls hair fineness (higher = thinner hairs)
#define uFurWaveAmplitude  uFur0.w
uniform vec3 uFur1;
#define uFurWaveFreqX      uFur1.x
#define uFurWaveFreqY      uFur1.y
#define uFurAnimationSpeed uFur1.z

// Key/fill/rim lights, packed as mat4 columns + vec4 + float to fit the iOS
// Simulator's 14-buffer cap. Flat float order is keyDir(3), keyColor(3),
// keyIntensity, fillDir(3), fillColor(3), fillIntensity, rimDir(3),
// rimColor(3), rimIntensity — the vec3s straddle column boundaries, hence
// the constructor #defines.
uniform mat4 uLightsA;
uniform vec4 uLightsB;
uniform float uRimLightIntensity;
#define uKeyLightDir        uLightsA[0].xyz
#define uKeyLightColor      vec3(uLightsA[0].w, uLightsA[1].xy)
#define uKeyLightIntensity  uLightsA[1].z
#define uFillLightDir       vec3(uLightsA[1].w, uLightsA[2].xy)
#define uFillLightColor     vec3(uLightsA[2].zw, uLightsA[3].x)
#define uFillLightIntensity uLightsA[3].y
#define uRimLightDir        vec3(uLightsA[3].zw, uLightsB.x)
#define uRimLightColor      uLightsB.yzw

// Fur color + gradient epsilon
uniform vec4 uFurColorEps;
#define uFurColor          uFurColorEps.rgb
#define uGradientEps       uFurColorEps.w

// Wavelet params + click count + click positions, packed as mat4 columns:
// [speed, freq, amplitude, decay][width, count, pos0.xy][pos1.xy, pos2.xy]
// [pos3.xy, pos4.xy] — then click start times as vec4 + float.
uniform mat4 uTailA;
#define uWaveletSpeed      uTailA[0].x
#define uWaveletFreq       uTailA[0].y
#define uWaveletAmplitude  uTailA[0].z
#define uWaveletDecay      uTailA[0].w
#define uWaveletWidth      uTailA[1].x
#define uClickCount        uTailA[1].y
#define uClickPos0         uTailA[1].zw
#define uClickPos1         uTailA[2].xy
#define uClickPos2         uTailA[2].zw
#define uClickPos3         uTailA[3].xy
#define uClickPos4         uTailA[3].zw
uniform vec4 uClickTimeA;
#define uClickTime0        uClickTimeA.x
#define uClickTime1        uClickTimeA.y
#define uClickTime2        uClickTimeA.z
#define uClickTime3        uClickTimeA.w
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

    // clickPos arrives in screen-UV space; project to world XY at the fur plane
    // (pz = -uPlaneOffset) so distances match pos.xy.
    vec2 worldClick = clickPos * (CAMERA_DISTANCE - uPlaneOffset);
    vec2 dxy = pos.xy - worldClick;
    float dz = pos.z + uPlaneOffset;
    float dist = sqrt(dxy.x * dxy.x + dxy.y * dxy.y + dz * dz);
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

        // Skip lighting for empty-space regions
        if (density < 0.001) continue;

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

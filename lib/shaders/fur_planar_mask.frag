#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float time;
uniform vec3 uBgColor;  // sRGB space input
uniform float uBgOpacity;  // 0 = transparent outside fur (for stacking), 1 = fill bgColor

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

// Mask uniforms
uniform vec3 uMaskColor;
uniform float uMaskThreshold;
uniform float uEdgeLeanStrength;

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

// Mask texture sampler (child widget capture)
uniform sampler2D uMaskTexture;

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

// Wavelet decay cutoffs. Displacement is kept for the whole ripple
// lifetime; the gradient (specular shimmer) only matters while the ripple
// is young and high-amplitude, so it stops at ~half the lifetime
// (sqrt(0.001) = decay at lifetime/2).
const float WAVELET_DISP_CUTOFF = 0.001;
const float WAVELET_GRAD_CUTOFF = 0.0316;

// Calculate wavelet displacement from a single click (3D version)
float wavelet(V pos, vec2 clickPos, float clickTime, float decayCutoff) {
    if (clickTime <= 0.0) return 0.0;
    float decay = exp(-clickTime * uWaveletDecay);
    if (decay < decayCutoff) return 0.0;

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
float totalWavelet(V pos, float decayCutoff) {
    int clicks = int(uClickCount);
    if (clicks == 0) return 0.0;

    float total = wavelet(pos, uClickPos0, uClickTime0, decayCutoff);
    if (clicks == 1) return total;
    total += wavelet(pos, uClickPos1, uClickTime1, decayCutoff);
    if (clicks == 2) return total;
    total += wavelet(pos, uClickPos2, uClickTime2, decayCutoff);
    if (clicks == 3) return total;
    total += wavelet(pos, uClickPos3, uClickTime3, decayCutoff);
    if (clicks == 4) return total;
    total += wavelet(pos, uClickPos4, uClickTime4, decayCutoff);

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

// Gradient using forward differences (3 samples instead of 6)
V fastGradient(V p) {
    float center = fForGradient(p);
    return V(
        center - fForGradient(p + V(uGradientEps, 0.0, 0.0)),
        center - fForGradient(p + V(0.0, uGradientEps, 0.0)),
        center - fForGradient(p + V(0.0, 0.0, uGradientEps))
    );
}

// Compute wavelet gradient contribution (for visible ripple effect).
// Sums young clicks only (WAVELET_GRAD_CUTOFF) — old ripples keep their
// displacement but their lighting shimmer has decayed below notice.
V waveletGradient(V p) {
    float center = totalWavelet(p, WAVELET_GRAD_CUTOFF);
    return V(
        center - totalWavelet(p + V(uGradientEps, 0.0, 0.0), WAVELET_GRAD_CUTOFF),
        center - totalWavelet(p + V(0.0, uGradientEps, 0.0), WAVELET_GRAD_CUTOFF),
        center - totalWavelet(p + V(0.0, 0.0, uGradientEps), WAVELET_GRAD_CUTOFF)
    );
}

// Sample mask texture and return match value (0 = no fur, 1 = fur)
float getMaskValue(vec2 tc) {
    float bounds = step(0.0, tc.x) * step(tc.x, 1.0)
                 * step(0.0, tc.y) * step(tc.y, 1.0);
    vec3 s = texture(uMaskTexture, tc).rgb;
    return (1.0 - smoothstep(0.0, uMaskThreshold, distance(s, uMaskColor))) * bounds;
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

    // Pre-compute projection scale for mask sampling (outside loop)
    float projScale = -uPlaneOffset + CAMERA_DISTANCE;

    // Ray setup
    vec2 uv = (fragCoord - 0.5 * uSize) * invMinDim;
    V rayDir = V(uv, 1.0);
    V rayPos = rayDir * 2.3 - V(0.0, 0.0, CAMERA_DISTANCE);
    V rayStep = rayDir * RAY_STEP;

    // === Hoisted mask field (once per pixel, not per step) ===
    // The fur surface is exactly planar, so the mask gradient and the
    // strand-root sample barely change across the shell's depth. Intersect
    // the ray with the mid-shell plane analytically (rayDir.z == 1.0) and
    // fetch all 5 mask taps there; the loop keeps only the height-dependent
    // lean math as ALU on these values. Mid-shell halves the xy drift error
    // at grazing angles vs sampling at the shell top.
    float zMid = -uPlaneOffset - 0.5 * uFurThickness;
    vec2 midXY = rayPos.xy + uv * (zMid - rayPos.z);
    vec2 toMaskTC = (minDim / uSize) / projScale;
    vec2 maskTC = midXY * toMaskTC + vec2(0.5);

    // Mask gradient (edge lean direction/strength)
    vec2 gStep = 8.0 / uSize;
    float maskR = getMaskValue(maskTC + vec2(gStep.x, 0.0));
    float maskL = getMaskValue(maskTC - vec2(gStep.x, 0.0));
    float maskU = getMaskValue(maskTC + vec2(0.0, gStep.y));
    float maskD = getMaskValue(maskTC - vec2(0.0, gStep.y));

    vec2 maskGradTC = vec2(maskR - maskL, maskU - maskD);
    float edgeStrength = length(maskGradTC);

    // Lean direction in world space:
    // outward = -maskGrad direction, aspect-corrected back to world
    vec2 edgeDir = edgeStrength > 0.001 ? -maskGradTC / edgeStrength : vec2(0.0);
    vec2 edgeDirWorld = normalize(edgeDir * uSize / minDim + vec2(0.0001));

    // Strand-root sample at the unleaned plane projection — the height
    // taper for pixels away from mask edges, where the base-trace is
    // constant along the strand.
    float rootMask = getMaskValue(maskTC);
    float heightReductionFlat =
        uFurThickness * (1.0 - smoothstep(0.0, 0.4, rootMask));

    // Within the edge band the base-trace must stay per-step: the inward
    // lean grows with height, so hair rooted inside the mask overhangs the
    // boundary at the tip (spill-over). A single fixed-lean sample would
    // turn that overhang into a hard cut at the region edge. The band is
    // bounded by the gradient stencil (edgeStrength is 0 beyond ~8 px of
    // the boundary, which also bounded the spill reach before the hoist),
    // so only a thin ring of pixels pays the per-step tap.
    bool edgeBand = edgeStrength > 0.001;

    // === Hoisted wavelet field (once per pixel, not per step) ===
    // The click ripple expands on the plane; across the thin shell its
    // value barely changes, so displacement is constant along each strand.
    float waveletDisp = 0.0;
    V waveletGrad = V(0.0);
    if (uClickCount > 0.0) {
        V wavePos = V(midXY, zMid);
        waveletDisp = totalWavelet(wavePos, WAVELET_DISP_CUTOFF);
        waveletGrad = waveletGradient(wavePos);
    }

    // Light accumulator (for self-shadowing within fur)
    V lightAccum = V(LIGHT_INITIAL);

    // Volumetric compositing
    V accumulatedColor = V(0.0);
    float transmittance = 1.0;

    // Raymarching loop
    for (int i = 0; i < RAY_STEPS; i++) {
        // March forward
        rayPos += rayStep;

        // === STEP A: Height computation ===
        float h = sdPlane(rayPos.z);           // 0 at surface, uFurThickness at tip
        float h01 = clamp(h / uFurThickness, 0.0, 1.0);

        // === STEP B: Edge lean on the hoisted mask field ===
        // Quadratic growth with height, scaled by edge proximity
        float leanAmount = h01 * h01 * edgeStrength * uEdgeLeanStrength;

        // Tip is at rayPos.xy (displaced outward). Base is inward:
        vec2 baseWorldXY = rayPos.xy - edgeDirWorld * leanAmount;

        // === STEP C: Density at strand-following position ===
        // Noise sampled at base XY (strand continuity), height at actual z
        V strandPos = V(baseWorldXY, rayPos.z);

        // Height falloff (moss taper): per-step base-trace inside the edge
        // band (this is what lets hair tips spill over the mask boundary),
        // hoisted constant everywhere else.
        float heightReduction = heightReductionFlat;
        if (edgeBand) {
            float baseMask = getMaskValue(baseWorldXY * toMaskTC + vec2(0.5));
            heightReduction =
                uFurThickness * (1.0 - smoothstep(0.0, 0.4, baseMask));
        }
        float density = max(0.0, fForGradient(strandPos) + waveletDisp - heightReduction);

        // Skip lighting for masked-out regions
        if (density < 0.001) continue;

        // Attenuate light through fur (for self-shadowing)
        lightAccum *= uFurColor - density / LIGHT_ABSORPTION;

        // === STEP D: Normals with edge lean bias ===
        V gradient = fastGradient(strandPos) + waveletGrad;

        // Surface brightness from gradient magnitude
        float gradMag = length(gradient);
        V normal = normalize(gradient + 0.001);

        // Explicit outward tilt at edges so lighting reveals the lean
        float normalBias = edgeStrength * h01 * uEdgeLeanStrength * 2.0;
        normal = normalize(normal + V(edgeDirWorld * normalBias, 0.0));

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

    // Composite with background, scaled by uBgOpacity.
    // furToneMapped is already premultiplied-style (front-to-back accumulation),
    // so output alpha is the union of fur coverage and bg fill.
    V finalLinear = furToneMapped + bgLinear * transmittance * uBgOpacity;
    float outAlpha = 1.0 - transmittance * (1.0 - uBgOpacity);

    // Convert from linear to sRGB for output
    fragColor = vec4(linearToSrgb(finalLinear), outAlpha);
}

// BENCH VARIANT — DO NOT SHIP. Derived from lib/shaders/iridescent_liquid_wrap.frag.
// Edit: NUM_DIRS 32->16
#include <flutter/runtime_effect.glsl>
precision highp float;

// Iridescent liquid wrap — stripes + fbm domain warp masked onto a child.
//   uStripeRippleStrength  0 = pure fbm warp, 1 = pure stripes
//   uBumpWarpWeight        0 = stripes ignore fbm, 1 = stripes track the fbm

// Standard header
uniform vec2  uSize;
uniform float uTime;

// Pattern tuning
uniform float uRepetition;            // stripe density (1..10)
uniform float uSoftness;              // stripe-edge blur
uniform float uDistortion;            // noise warp into stripe phase
uniform float uContour;               // stripe bending at the shape edge
uniform float uAngleDeg;              // pattern rotation (degrees)

// Diagonal asymmetries — set both to 0 for a symmetric look.
uniform float uStripeDiagaBias;       // linear diagA → direction
uniform float uStripeTwist;           // per-pixel rotation perturbation

// Stripe pattern (parametric)
uniform float uStripeCount;           // bright stripes per cycle (0..5)
uniform float uStripeThickness;       // stripe width as fraction of slot
uniform float uStripeOffset;          // phase offset (0..1 cycles)
uniform float uStripeFalloff;         // gradient zone width (intermediate-color thickness)
uniform float uStripeSpeed;           // animation speed multiplier (1 = default)

// Chromatic aberration
uniform float uShiftRed;
uniform float uShiftBlue;

// Composition
uniform vec4  uColorBack;             // backdrop beneath the masked shape
uniform vec4  uColorTint;             // colour-burn tint (alpha = strength)

// Mask pass colour. alpha == 0 → alpha-driven mask, anything else → exact match.
uniform vec4  uPassColor;

// Width (px) of the synthetic distance-to-edge band that drives uContour.
// Larger values bend stripes deeper into the shape at higher tap cost.
uniform float uEdgeBandPx;

// Smoothing factor (fraction of uEdgeBandPx) for the ray-fan blend. Higher
// values dissolve radial "wrinkles" from fixed ray angles, at the cost of
// a slightly softer-reading field.
uniform float uEdgeSmoothness;

// Domain warp tuning
uniform float uWarpTimeScale;
uniform float uWarpFreqInner;
uniform float uWarpFreqMiddle;
uniform float uWarpFreqHigh;
uniform float uFbmScaleFactor;
uniform float uStripeRippleStrength;
uniform float uBumpWarpWeight;

// Palette (10 RGBA stops, first uPaletteStops active)
uniform float uPaletteStops;
uniform vec4  uColor0;
uniform vec4  uColor1;
uniform vec4  uColor2;
uniform vec4  uColor3;
uniform vec4  uColor4;
uniform vec4  uColor5;
uniform vec4  uColor6;
uniform vec4  uColor7;
uniform vec4  uColor8;
uniform vec4  uColor9;

// Child texture (sampler index 0, auto-bound by ShaderWrap)
uniform sampler2D uTexture;

out vec4 fragColor;

#define PI 3.141592653589793

// 45° rotation between fbm octaves, decorrelates layers.
const mat2 FBM_ROT = mat2(0.70710678, 0.70710678, -0.70710678, 0.70710678);

// 2D simplex noise (Ashima/Gustavson).
vec3 permute(vec3 x) { return mod(((x * 34.0) + 1.0) * x, 289.0); }

float snoise(vec2 p) {
    const float F2 = 0.366025403784439;
    const float G2 = 0.211324865405187;

    vec2 i  = floor(p + (p.x + p.y) * F2);
    vec2 v0 = p - i + (i.x + i.y) * G2;
    vec2 i1 = (v0.x > v0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec2 v1 = v0 - i1 + G2;
    vec2 v2 = v0 - 1.0 + 2.0 * G2;

    i = mod(i, 289.0);
    vec3 hash = permute(permute(i.y + vec3(0.0, i1.y, 1.0))
                              + i.x + vec3(0.0, i1.x, 1.0));

    vec3 r2 = vec3(dot(v0, v0), dot(v1, v1), dot(v2, v2));
    vec3 m = max(0.5 - r2, 0.0);
    m = m * m; m = m * m;

    vec3 gx = 2.0 * fract(hash * (1.0 / 41.0)) - 1.0;
    vec3 gy = abs(gx) - 0.5;
    gx    -= floor(gx + 0.5);
    m     *= 1.79284291400159 - 0.85373472095314 * (gx * gx + gy * gy);

    vec3 dots;
    dots.x = gx.x * v0.x + gy.x * v0.y;
    dots.y = gx.y * v1.x + gy.y * v1.y;
    dots.z = gx.z * v2.x + gy.z * v2.y;
    return 130.0 * dot(m, dots);
}

vec2 rotate2(vec2 v, float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c) * v;
}

float dispersionRed(float bump, float noise, float diagA) {
    float d = clamp(1.0 - bump, 0.0, 1.0);
    d += 0.03 * bump * noise;
    d -= diagA;
    return d * (uShiftRed / 20.0);
}

float dispersionBlue(float bump, float edge) {
    float d = clamp(1.0 - bump, 0.0, 1.0) * 1.3;
    d -= 0.2 * edge;
    return d * (uShiftBlue / 20.0);
}

// N evenly-spaced bright stripes per cycle, parameterised by uStripeCount,
// uStripeThickness (fraction of slot width), and uStripeOffset (phase shift).
float sampleStripe(float bright, float dark, float phase, float blur) {
    if (uStripeCount < 0.5) return dark;

    phase = fract(phase + uStripeOffset);
    float local      = fract(phase * uStripeCount);
    float dist       = abs(local - 0.5);
    float halfWidth  = 0.5 * uStripeThickness;
    float edgeBlur   = max((blur + 0.5 * uStripeFalloff) * uStripeCount, 1e-4);
    float t          = smoothstep(halfWidth - edgeBlur,
                                  halfWidth + edgeBlur, dist);
    return mix(bright, dark, t);
}

// SkSL rejects array initializers for vec4[N], so palette is an if-chain.
vec4 paletteAt(int i) {
    if (i <= 0) return uColor0;
    if (i == 1) return uColor1;
    if (i == 2) return uColor2;
    if (i == 3) return uColor3;
    if (i == 4) return uColor4;
    if (i == 5) return uColor5;
    if (i == 6) return uColor6;
    if (i == 7) return uColor7;
    if (i == 8) return uColor8;
    return uColor9;
}

// 4-octave fBm on simplex noise.
float fbm(vec2 p) {
    float f  = 0.5000 * snoise(p); p = FBM_ROT * p * 2.03;
          f += 0.2500 * snoise(p); p = FBM_ROT * p * 2.01;
          f += 0.1250 * snoise(p); p = FBM_ROT * p * 1.99;
          f += 0.0625 * snoise(p);
    return f / 0.9375;
}

vec2 fbm2(vec2 p) {
    return vec2(fbm(p), fbm(p.yx + vec2(3.2, 13.7)));
}

// Mask value at `uv`. Alpha is the primary signal — it's smooth across AA
// edges, unlike chromaticity which wobbles enough to wreck the distance
// field. When uPassColor.a > 0, chromaticity acts as a gate on top.
// Out-of-bounds returns 0; Flutter's default tile mode is implementation-
// defined and large-σ rays would otherwise sample the opposite edge.
float maskAt(vec2 uv) {
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        return 0.0;
    }

    vec4 pixel = texture(uTexture, uv);

    if (uPassColor.a <= 0.0) {
        return pixel.a;
    }

    // Floor alpha so 0/0 in transparent regions stays finite (the trailing
    // * pixel.a zeroes any garbage chroma).
    float a      = max(pixel.a, 1e-4);
    vec3  unp    = pixel.rgb / a;
    float chroma = length(unp - uPassColor.rgb);

    // Wide tolerance — reject only clearly different colours.
    float gate   = 1.0 - smoothstep(0.15, 0.55, chroma);
    return gate * pixel.a;
}

// Distance along a single ray. Coarse walk brackets the inside→outside
// crossing, then bisection refines to ~0.5 px. Stopping at 4 iterations
// (not 6) is deliberate: finer precision picks up sub-pixel rasterisation
// noise that propagates as visible jaggies.
float rayDistancePx(vec2 uv, float ang,
                    float maxDistPx, float coarseStepPx) {
    const int NUM_COARSE = 8;
    const int NUM_BISECT = 4;

    vec2 dir = vec2(cos(ang), sin(ang));

    for (int s = 1; s <= NUM_COARSE; s++) {
        float rPx = float(s) * coarseStepPx;
        if (maskAt(uv + dir * (rPx / uSize)) < 0.5) {
            float lo = rPx - coarseStepPx;
            float hi = rPx;
            for (int b = 0; b < NUM_BISECT; b++) {
                float mid = 0.5 * (lo + hi);
                if (maskAt(uv + dir * (mid / uSize)) < 0.5) {
                    hi = mid;
                } else {
                    lo = mid;
                }
            }
            return hi;
        }
    }
    return maxDistPx;
}

// Single-pass approximation of a Poisson distance-to-boundary field.
// Casts NUM_DIRS rays and combines them via exp-weighted average:
//   d̂ = Σ (dᵢ · exp(−dᵢ / softness)) / Σ exp(−dᵢ / softness)
// C∞-smooth (no min() switch) so inside corners don't blow up. 32 fixed
// angles minimise the residual radial wrinkles; uEdgeSmoothness blends
// across rays to dissolve what's left. mask < 0.5 short-circuits to 0.
float distanceToEdgePx(vec2 uv, float maxDistPx) {
    const int NUM_DIRS = 16;

    if (maskAt(uv) < 0.5) {
        return 0.0;
    }

    float coarseStepPx = maxDistPx / 8.0;
    // Softness floor avoids hard-min facets at small σ; cap at 8 px stops
    // unfound-boundary rays (returning maxDistPx) from biasing the mean so
    // high the field saturates to 0.
    float softness     = clamp(uEdgeBandPx * uEdgeSmoothness, 0.5, 8.0);

    float weightedSum = 0.0;
    float weightTotal = 0.0;
    for (int d = 0; d < NUM_DIRS; d++) {
        float ang  = float(d) / float(NUM_DIRS) * 2.0 * PI;
        float dRay = rayDistancePx(uv, ang, maxDistPx, coarseStepPx);
        float w    = exp(-dRay / softness);
        weightedSum += dRay * w;
        weightTotal += w;
    }

    return weightedSum / max(weightTotal, 1e-30);
}

// Triple-nested warp collapsed to a palette-index scalar in [0, 1].
float warpShape(vec2 p, float tw) {
    vec2 w1 = fbm2(uFbmScaleFactor * uWarpFreqInner * p);
    vec2 w2 = fbm2(-tw + uWarpFreqMiddle * (p + w1));
    vec2 w3 = fbm2( tw + uWarpFreqHigh   * (p + w2));
    float f = dot(w3, vec2(1.0, -1.0));
    return clamp(0.5 + 0.5 * f, 0.0, 1.0);
}

// Domain warp → palette lookup. `stripe` is blended into the fbm shape via
// uStripeRippleStrength before indexing the palette.
vec4 warpMap(vec2 p, float tw, float stripe) {
    float shape = mix(warpShape(p, tw), stripe, uStripeRippleStrength);

    // SkSL has no integer clamp/min overloads — clamp in floats then cast.
    float nF  = clamp(uPaletteStops + 0.5, 2.0, 10.0);
    float nm1 = nF - 1.0;
    float tp  = shape * nm1;
    float i0F = floor(tp);
    float i1F = min(i0F + 1.0, nm1);
    float fp  = smoothstep(0.0, 1.0, tp - i0F);
    return mix(paletteAt(int(i0F)), paletteAt(int(i1F)), fp);
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;

    // Pre-aspect-squish UV so the texture lookup stays inside [0, 1].
    vec2  sampleUV = fragCoord / uSize;

    // Aspect-correct UV — pattern runs in a unit square on the short axis,
    // y-flipped so pattern-space "up" is screen-top.
    float aspect = uSize.x / uSize.y;
    vec2  uv     = vec2(fragCoord.x / uSize.x,
                        1.0 - fragCoord.y / uSize.y);
    if (aspect > 1.0) uv.x = (uv.x - 0.5) * aspect + 0.5;
    else              uv.y = (uv.y - 0.5) / aspect + 0.5;

    float t = 0.3 * (uTime + 2.8);

    // ---- 1. Mask & edge field ---------------------------------------------
    float mask = maskAt(sampleUV);

    // Distance field: 1 at boundary, decays to 0 inside. Naive `1 - mask`
    // doesn't penetrate the interior, so we run a real distance probe —
    // skipped when contour is off to save ~320 taps per pixel.
    float distanceField;
    if (uContour < 0.001) {
        distanceField = 1.0 - mask;
    } else {
        // 2σ search radius — smoothstep saturates beyond that.
        float maxDistPx = uEdgeBandPx * 2.0;
        float distPx    = distanceToEdgePx(sampleUV, maxDistPx);
        distanceField   = 1.0 - smoothstep(0.0, uEdgeBandPx, distPx);
    }

    float edge    = pow(distanceField, 1.6)
                   * smoothstep(0.0, 0.4, uContour);
    float opacity = mask;

    // ---- 2. Rotated coords (+70° bias for default angle = 0) --------------
    float angle = (70.0 - uAngleDeg) * PI / 180.0;
    vec2  rUV   = rotate2(uv - 0.5, angle) + 0.5;
    float diagA = rUV.x - rUV.y;

    // ---- 3. Warp tap: drives `noise` and `bump` ---------------------------
    vec2  p          = uv - 0.5;
    float tw         = uWarpTimeScale * uTime;
    float warpShapeV = warpShape(2.0 * p, tw);
    float noise      = mix(snoise(uv - t),
                           2.0 * warpShapeV - 1.0,
                           uBumpWarpWeight);
    float bump       = uBumpWarpWeight * warpShapeV;

    float edgeN    = edge + (1.0 - edge) * uDistortion * noise;
    float edgeS    = smoothstep(0.0, 1.0, edgeN);
    float edgePeak = edgeS * (1.0 - edgeS);
    float contourB = smoothstep(0.5, 1.0, uContour);

    // ---- 4. Warp sampling coord (edge-driven contour distortion) ----------
    vec2 warpUV = 2.0 * p;
    warpUV += rotate2(p, 0.5 * PI) * edgePeak * contourB * 2.0;
    warpUV += 0.3 * pow(uContour, 4.0) * (1.0 - edgeS);

    // ---- 5. Stripe accumulator -------------------------------------------
    float direction = rotate2(p, (0.25 - uStripeTwist * diagA) * PI).x;
    direction += uStripeDiagaBias * diagA;
    direction -= 2.0 * noise * diagA * edgePeak;
    direction *= mix(1.0, 1.0 - edgeN, contourB);
    direction -= 1.7 * edgeN * contourB;
    direction += 0.2 * pow(uContour, 4.0) * (1.0 - edgeS);
    direction *= 0.1 + (1.1 - edgeN) * bump;
    direction *= 0.4 + 0.6 * (1.0 - smoothstep(0.5, 1.0, edgeN));
    direction *= uRepetition;
    direction -= t * uStripeSpeed;

    // ---- 6. Per-channel stripe scalars (chromatic aberration) -------------
    float phaseR = fract(direction + dispersionRed (bump, noise, diagA));
    float phaseG = fract(direction);
    float phaseB = fract(direction - dispersionBlue(bump, edgeN));

    // SkSL has no derivative ops; fwidth(phase) is approximated as
    // uRepetition * (1 / uSize.y) — the scale at which `phase` advances per
    // pixel along the screen's short axis.
    float pxY     = 1.0 / max(uSize.y, 1.0);
    float phaseFw = uRepetition * pxY;

    float softness = 0.05 * uSoftness;
    float blur     = softness
                   + 0.5 * smoothstep(1.0, 10.0, uRepetition) * edgeS;
    float stripeR = sampleStripe(1.0, 0.0, phaseR, blur + phaseFw);
    float stripeG = sampleStripe(1.0, 0.0, phaseG, blur + phaseFw);
    float stripeB = sampleStripe(1.0, 0.0, phaseB, blur + phaseFw);

    // ---- 7. Per-channel warpMap taps (fbm + palette) ---------------------
    vec2 offUvR = vec2(uShiftRed  / 50.0, 0.0);
    vec2 offUvB = vec2(uShiftBlue / 50.0, 0.0);

    vec3 col = vec3(
        warpMap(warpUV + offUvR, tw, stripeR).r,
        warpMap(warpUV,          tw, stripeG).g,
        warpMap(warpUV - offUvB, tw, stripeB).b
    );

    // Color-burn tint (alpha = strength).
    col = mix(col,
              1.0 - min(vec3(1.0),
                        (1.0 - col) / max(uColorTint.rgb, vec3(0.0001))),
              uColorTint.a);
    col *= opacity;

    // ---- 8. Composite over uColorBack + dither ---------------------------
    col        += uColorBack.rgb * uColorBack.a * (1.0 - opacity);
    float alpha = opacity + uColorBack.a * (1.0 - opacity);

    col += (1.0 / 256.0) *
           (fract(sin(dot(fragCoord, vec2(12.9898, 78.233))) * 43758.5453)
            - 0.5);

    // Output is already premultiplied (col *= opacity, premultiplied backdrop).
    fragColor = vec4(col, alpha);
}

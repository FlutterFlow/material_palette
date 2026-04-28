#include <flutter/runtime_effect.glsl>
precision highp float;

// =============================================================================
//  Iridescent liquid wrap — animated chrome-over-fbm material.
//
//  A rotated stripe pattern blended with an iq-style triple-nested fbm domain
//  warp, painted onto the wrapped child via a passColor mask. All former const
//  knobs are uniforms so the entire look is tunable from Dart.
//
//  Two key blend knobs:
//    uStripeRippleStrength  0 = pure fbm warp,  1 = pure palette-coloured stripes
//    uBumpWarpWeight        0 = clean radial,    1 = stripe shape tracks the fbm
// =============================================================================

// Standard header
uniform vec2  uSize;
uniform float uTime;

// Bump-surface shape selector. 0 = radial dome, 1 = horizontal cylinder,
// 2 = vertical cylinder, 3 = diagonal ridge, 4 = flat plane.
uniform float uBumpShape;

// Pattern tuning
uniform float uRepetition;            // stripe density (1..10)
uniform float uSoftness;              // stripe-edge blur
uniform float uDistortion;            // noise warp into stripe phase
uniform float uContour;               // stripe bending at the shape edge
uniform float uAngleDeg;              // pattern rotation (degrees)

// Diagonal asymmetries — set both (and uBumpShear) to 0 for a symmetric look.
uniform float uStripeDiagaBias;       // linear diagA → direction
uniform float uStripeTwist;           // per-pixel rotation perturbation

// Bump tuning
uniform float uBumpRadius;            // inverse radius (larger = tighter peak)
uniform float uBumpExponent;          // falloff: 1 = cone, 2 = parabolic
uniform vec2  uBumpShear;             // radial dome shear along diagA

// Top-down lighting on the bump shape: stripes get progressively dimmer as
// uv.y → 0 (bottom of the shape).
//
//   uBumpTopBias = 0  →  gradient disabled (uniform brightness top-to-bottom)
//   uBumpTopBias > 0  →  brighter at the top, falling off toward the bottom.
//                         Larger values fall off faster (sharper top-lit feel).
//
// `uBumpFloor` then clamps the bottom of that gradient so the lower edge of
// the shape never goes fully unlit — without it, the contour stripes at
// the bottom would vanish at large uBumpTopBias values. 0 = let it go
// fully dark; 1 = uniform (floor wins everywhere).
uniform float uBumpTopBias;
uniform float uBumpFloor;

// Chromatic aberration
uniform float uShiftRed;
uniform float uShiftBlue;

// Composition
uniform vec4  uColorBack;             // backdrop beneath the masked shape
uniform vec4  uColorTint;             // colour-burn tint (alpha = strength)

// Mask pass colour. alpha == 0 → alpha-driven mask, anything else → exact match.
uniform vec4  uPassColor;

// Inward thickness (in pixels) of the synthetic distance-to-edge band that
// drives `uContour`. The reference Shadertoy expects a Poisson-preprocessed
// distance field as input; without that, we approximate by sampling the mask
// at a ring of offsets up to this radius. Larger values let the contour bend
// stripes deeper inside the shape (at the cost of more texture taps).
uniform float uEdgeBandPx;

// Smoothness of the GPU distance approximation, as a fraction of
// uEdgeBandPx. Controls the exponential weighting across the ray fan when
// combining individual ray distances into the final field:
//
//   softness (px) = max(uEdgeBandPx · uEdgeSmoothness, 0.5)
//
// Higher values smooth out residual angular sampling artifacts (the faint
// radial "wrinkles" that emanate from sharp interior corners of the mask
// because all pixels share the same fixed ray angles). The trade-off is
// a small constant bias: the field reads slightly higher than the true
// distance, which makes the contour effect appear slightly softer.
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

// =============================================================================
// 2D simplex noise — Ashima / Gustavson texture-free GLSL variant.
// =============================================================================
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

// Soft top-hat window: 0 below a, 1 across b..c, 0 above d.
float window(float x, float a, float b, float c, float d) {
    return smoothstep(a, b, x) * (1.0 - smoothstep(c, d, x));
}

float dispersionRed(vec2 uv, float bump, float noise, float diagA) {
    float d = clamp(1.0 - bump, 0.0, 1.0);
    d += 0.03 * bump * noise;
    d += 5.0 * window(uv.y, -0.1, 0.2, 0.1, 0.5)
            * window(bump,   0.4, 0.6, 0.4, 1.0);
    d -= diagA;
    return d * (uShiftRed / 20.0);
}

float dispersionBlue(vec2 uv, float bump, float edge) {
    float d = clamp(1.0 - bump, 0.0, 1.0) * 1.3;
    d += window(uv.y, 0.0, 0.4, 0.1, 0.8)
       * window(bump, 0.4, 0.6, 0.4, 0.8);
    d -= 0.2 * edge;
    return d * (uShiftBlue / 20.0);
}

// One cycle of the stripe pattern at `phase` ∈ [0, 1).
// Layout:  bright → dark → bright → dark → wide gradient → bright.
float sampleStripe(float bright, float dark, float phase,
                   vec3 w, float blur, float bump) {
    float ch = mix(dark, bright, smoothstep(0.0, 2.0 * blur, phase));

    float b = w.x;
    ch = mix(ch, dark,   smoothstep(b, b + 2.0 * blur, phase));
    b = w.x + 0.4 * (1.0 - bump) * w.y;
    ch = mix(ch, bright, smoothstep(b, b + 2.0 * blur, phase));
    b = w.x + 0.5 * (1.0 - bump) * w.y;
    ch = mix(ch, dark,   smoothstep(b, b + 2.0 * blur, phase));
    b = w.x + w.y;
    ch = mix(ch, bright, smoothstep(b, b + 2.0 * blur, phase));

    float gt = (phase - w.x - w.y) / w.z;
    ch = mix(ch, mix(bright, dark, smoothstep(0.0, 1.0, gt)),
                 smoothstep(b, b + 0.5 * blur, phase));
    return ch;
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

// Mask value at `uv`. The child texture is premultiplied. Always uses the
// alpha channel as the primary "inside the shape" signal — that's the only
// quantity that's perfectly smooth across anti-aliased edges and unaffected
// by sub-pixel rendering wobble. When `uPassColor.a > 0` chromaticity acts
// as a *gate* on top: pixels whose un-premultiplied colour is far from the
// pass colour (e.g. a coloured background that happens to be opaque) get
// rejected, but pixels that match — including AA edges, where chromaticity
// is invariant — pass through with their alpha intact.
//
// Earlier revisions used chromaticity as the primary signal with a tight
// threshold, which dropped any interior pixel whose rendering wobbled even
// 0.05 in chroma. With a Gaussian distance field on top, those scattered
// rejected pixels then dragged the field haywire over a wide neighbourhood,
// producing region-scale "shards" aligned with stroke skeletons.
//
// Out-of-bounds UVs explicitly return 0. The default sampler tile mode
// outside [0, 1] is implementation-defined in Flutter (clamp, decal, or
// repeat depending on the backend), and at large σ the spiral samples can
// stray outside the texture — repeating would silently feed the field with
// content from the opposite edge, which is exactly the "sampling from the
// wrong section" failure mode.
float maskAt(vec2 uv) {
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        return 0.0;
    }

    vec4 pixel = texture(uTexture, uv);

    if (uPassColor.a <= 0.0) {
        return pixel.a;
    }

    // Floor the alpha before dividing so fully-transparent regions don't
    // produce NaN/Inf from 0/0 — the multiplication by pixel.a at the end
    // zeroes out any garbage chromaticity in those regions anyway.
    float a      = max(pixel.a, 1e-4);
    vec3  unp    = pixel.rgb / a;
    float chroma = length(unp - uPassColor.rgb);

    // Wide tolerance: keep pixels whose colour is broadly the same hue as
    // uPassColor, only rejecting cleanly different colours (chroma > ~0.5
    // means a clearly distinct colour in unit-cube RGB).
    float gate   = 1.0 - smoothstep(0.15, 0.55, chroma);
    return gate * pixel.a;
}

// Distance along a single ray from `uv` at angle `ang`. Coarse linear walk
// (NUM_COARSE steps) brackets the first inside→outside crossing; bisection
// (NUM_BISECT iterations) refines the bracket. 4 iterations narrows the
// bracket by 16×, so an 8-px coarse step ends at ~0.5 px precision —
// deliberately less than the 6-iteration ~0.125 px version, because at
// that finer precision the bisection starts tracking sub-pixel mask
// rasterisation noise and the rays propagate it as visible jaggies.
// Coarser per-ray distances let the exp-weighted average across rays
// blend out the noise instead.
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

// Single-pass approximation of a Poisson-style distance-to-boundary field
// for an arbitrary mask. Replaces what the reference Shadertoy gets from a
// CPU-side Poisson solve packed into the texture's R channel — a continuous
// "hill" that's 0 deep inside the shape, rising smoothly toward 1 at the
// boundary.
//
// Algorithm: cast NUM_DIRS rays from the current pixel; each ray returns a
// boundary distance via coarse-walk + bisection (sub-pixel radial
// resolution). Combine via an exponentially-weighted average:
//
//     d̂ = Σ (d_i · exp(−d_i / softness)) / Σ exp(−d_i / softness)
//
// This is C∞ smooth in every input d_i — there is no `min()` switch, no
// "winning ray" boundary, no parabolic-fit blow-up at inside corners
// where neighbouring rays point at different boundary segments. Closer
// rays dominate (their weight is exponentially larger), and farther rays
// taper smoothly toward zero contribution. The result is the continuous
// "hill" shape the Poisson solve produces, at the cost of a small
// constant bias (~3–5% high) that's tunable via `uEdgeSmoothness`.
//
// 32 rays at fixed angles is the dominant lever for reducing the residual
// radial pattern that emanates from sharp interior corners — those
// wrinkles are a direct consequence of all pixels sharing the same fixed
// ray angles, so halving the angular gap (22.5° → 11.25°) both densifies
// and dims them. `uEdgeSmoothness` then lets the user blend across rays
// to dissolve whatever's left.
//
// Worst-case cost is NUM_DIRS × (NUM_COARSE + NUM_BISECT) texture taps.
// A pixel whose own mask is < 0.5 short-circuits to 0.
float distanceToEdgePx(vec2 uv, float maxDistPx) {
    const int NUM_DIRS = 32;

    if (maskAt(uv) < 0.5) {
        return 0.0;
    }

    float coarseStepPx = maxDistPx / 8.0;
    // Smoothing scale (px). Scales with σ so the blend stays consistent
    // across band widths; floored so very small σ values don't drive
    // softness toward zero (re-introducing hard-min facets), and *capped*
    // at 8 px so very large σ + high smoothness doesn't push softness so
    // far that exp-weighting becomes a plain mean of all rays — at that
    // point unfound-boundary rays (returning maxDistPx) bias the result
    // so high that distanceField saturates to 0 and the contour effect
    // collapses entirely. The cap keeps the field useful at all settings.
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

    // Sample the child at the unmodified UV (before the aspect squish) so the
    // texture lookup stays inside [0, 1].
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

    // The contour effect needs a distance-to-edge field that's 1 at the
    // boundary and decays smoothly to 0 deep inside. With a plain binary
    // mask the naive `1 - mask` is 0 everywhere inside and 1 outside — it
    // never penetrates the visible interior, so contour bending becomes
    // invisible. Replace with a true single-pass distance probe; skip when
    // contour is effectively off so deeply-interior pixels don't pay the
    // ~320 worst-case texture-tap budget for a value that gets multiplied
    // out anyway.
    float distanceField;
    if (uContour < 0.001) {
        distanceField = 1.0 - mask;
    } else {
        // Search up to 2σ — beyond that the smoothstep below saturates at
        // 0 anyway, so further taps are wasted.
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

    // ---- 3. Bump (fake 3D surface curvature) ------------------------------
    vec2 p = uv - 0.5;
    int  shapeIdx = int(uBumpShape + 0.5);

    // Each `pow` base is floored at 1e-5 so `pow(0, 0)` (implementation-
    // defined in GLSL — NaN on some Skia backends) can't appear when the
    // user dials radius/exponent or top-bias to zero.
    float bump;
    if (shapeIdx == 0) {
        // RADIAL: dome peaking at center.
        float dist = length(p + diagA * uBumpShear);
        bump = 1.0 - pow(max(uBumpRadius * dist, 1e-5), uBumpExponent);
    } else if (shapeIdx == 1) {
        // CYLINDER_H: horizontal ridge (peak on y = 0).
        bump = 1.0 - pow(max(uBumpRadius * abs(p.y), 1e-5), uBumpExponent);
    } else if (shapeIdx == 2) {
        // CYLINDER_V: vertical ridge (peak on x = 0).
        bump = 1.0 - pow(max(uBumpRadius * abs(p.x), 1e-5), uBumpExponent);
    } else if (shapeIdx == 3) {
        // DIAGONAL: ridge along diagA.
        float ridgeDist = abs(p.x + p.y) * 0.70710678;
        bump = 1.0 - pow(max(uBumpRadius * ridgeDist, 1e-5), uBumpExponent);
    } else {
        // PLANE (or any unrecognised value).
        bump = 1.0;
    }
    bump = clamp(bump, 0.0, 1.0);

    // Top-down lighting: gradient by uv.y, then *actually* floored so the
    // bottom can't go below uBumpFloor. The previous design multiplied two
    // gradients and tried to floor the second — but with the multiplicative
    // structure the first gradient already drove the product to zero at
    // uv.y = 0, so the "floor" never floored anything. One curve + one
    // honest floor does the job in one less control.
    float vertical = pow(max(uv.y, 1e-5), uBumpTopBias);
    vertical = max(vertical, uBumpFloor);
    bump *= vertical;

    // ---- 4. Warp tap: drives `noise` and blends into `bump` ---------------
    float tw         = uWarpTimeScale * uTime;
    float warpShapeV = warpShape(2.0 * p, tw);
    float noise      = mix(snoise(uv - t),
                           2.0 * warpShapeV - 1.0,
                           uBumpWarpWeight);
    bump             = mix(bump, warpShapeV, uBumpWarpWeight);

    // mask-mode: contrast-boost the bump that drives the stripes.
    float bumpStripe = smoothstep(0.2, 0.8, bump);

    float edgeN    = edge + (1.0 - edge) * uDistortion * noise;
    float edgeS    = smoothstep(0.0, 1.0, edgeN);
    float edgePeak = edgeS * (1.0 - edgeS);
    float contourB = smoothstep(0.5, 1.0, uContour);

    // ---- 5. Warp sampling coord (edge-driven contour distortion) ----------
    vec2 warpUV = 2.0 * p;
    warpUV += rotate2(p, 0.5 * PI) * edgePeak * contourB * 2.0;
    warpUV += 0.3 * pow(uContour, 4.0) * (1.0 - edgeS);

    // ---- 6. Stripe accumulator -------------------------------------------
    float direction = rotate2(p, (0.25 - uStripeTwist * diagA) * PI).x;
    direction += uStripeDiagaBias * diagA;
    direction -= 2.0 * noise * diagA * edgePeak;
    direction *= mix(1.0, 1.0 - edgeN, contourB);
    direction -= 1.7 * edgeN * contourB;
    direction += 0.2 * pow(uContour, 4.0) * (1.0 - edgeS);
    direction *= 0.1 + (1.1 - edgeN) * bump;
    direction *= 0.4 + 0.6 * (1.0 - smoothstep(0.5, 1.0, edgeN));
    direction += 0.18 * window(uv.y,       0.1, 0.2, 0.2, 0.4);
    direction += 0.03 * window(1.0 - uv.y, 0.1, 0.2, 0.2, 0.4);
    direction *= 0.5 + 0.5 * pow(uv.y, 2.0);
    direction *= uRepetition;
    direction -= t;

    // Stripe widths: one cycle = thin1 + thin2 + wide gradient.
    float thin1 = 0.12 * (1.0 - 0.4 * bump);
    float thin2 = 0.07 * (1.0 + 0.4 * bump);
    vec3  w     = vec3(thin1, thin2,
                       1.0 - (thin1 + thin2) / max(uRepetition, 0.001));
    w.y -= 0.02 * smoothstep(0.0, 1.0, edgeN + bump);

    // ---- 7. Per-channel stripe scalars (chromatic aberration) -------------
    float phaseR = fract(direction + dispersionRed (uv, bump, noise, diagA));
    float phaseG = fract(direction);
    float phaseB = fract(direction - dispersionBlue(uv, bump, edgeN));

    // SkSL has no derivative ops; fwidth(phase) is approximated as
    // uRepetition * (1 / uSize.y) — the scale at which `phase` advances per
    // pixel along the screen's short axis.
    float pxY     = 1.0 / max(uSize.y, 1.0);
    float phaseFw = uRepetition * pxY;

    float softness = 0.05 * uSoftness;
    float blur     = softness
                   + 0.5 * smoothstep(1.0, 10.0, uRepetition) * edgeS;
    float extraR   = softness * (0.05 + 0.1 * (uShiftRed / 20.0) * bump);
    float extraG   = softness * 0.05 / max(0.001, abs(1.0 - diagA));

    float stripeR = sampleStripe(1.0, 0.0, phaseR, w,
                                 blur + phaseFw + extraR, bumpStripe);
    float stripeG = sampleStripe(1.0, 0.0, phaseG, w,
                                 blur + phaseFw + extraG, bumpStripe);
    float stripeB = sampleStripe(1.0, 0.0, phaseB, w,
                                 blur + phaseFw,          bumpStripe);

    // ---- 8. Per-channel warpMap taps (fbm + palette) ---------------------
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

    // ---- 9. Composite over uColorBack + dither ---------------------------
    col        += uColorBack.rgb * uColorBack.a * (1.0 - opacity);
    float alpha = opacity + uColorBack.a * (1.0 - opacity);

    col += (1.0 / 256.0) *
           (fract(sin(dot(fragCoord, vec2(12.9898, 78.233))) * 43758.5453)
            - 0.5);

    // Output is already premultiplied (col *= opacity, premultiplied backdrop).
    fragColor = vec4(col, alpha);
}

#include <flutter/runtime_effect.glsl>

precision highp float;

// ============================================================
//  Layered metal — procedural fill combining a noise-rotated
//  pre-warp with an iterative swirl chain and a checkerboard
//  base shape. Coloured through a 10-stop RGBA palette and
//  shaded as a heightfield with a warm edge glow. Every former
//  top-level const is exposed as a tunable uniform.
// ============================================================

// Standard header
uniform vec2  uSize;
uniform float uTime;

// Pattern / animation
uniform float uPatternScale;      // global zoom
uniform float uSwirlTimeScale;    // clock rate of the swirl pipeline
uniform float uSwirlDistortion;   // strength of the noise-rotated pre-warp
uniform float uSwirlStrength;     // per-iteration amplitude of the swirl offsets
uniform float uSwirlFreq;         // base spatial frequency for swirl iterations
uniform float uSwirlIterations;   // runtime swirl iteration count (1..20)
uniform float uSeed;              // noise seed — cycles to unrelated variants
uniform float uShapeScale;        // frequency multiplier for the base shape
uniform float uShapeProportion;   // 0..1: biases the black/white split

// Lighting
uniform float uSampleEps;         // gradient tap offset (smaller = bumpier)
uniform float uAmbientGain;       // quadratic ambient lift
uniform float uRimGain;           // cubic rim highlight

// Edge glow
uniform float uEdgeGain;          // intensity of the ridge/crack highlight
uniform vec3  uEdgeTint;          // colour of the ridge highlight

// Palette (10 RGBA stops, first `uPaletteStops` active)
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

out vec4 fragColor;

// Rec. 709 perceptual luminance weights — hardcoded (not a tuning knob).
const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);

// Upper bound for the swirl loop. `uSwirlIterations` is clamped against this
// at runtime via an early `break`. SkSL has no integer clamp/min, so the
// comparison uses floats.
#define MAX_SWIRL_ITERATIONS 20

// SkSL rejects `vec4 arr[10] = vec4[10](...)` array initializers, so the
// palette is exposed through a lookup function that returns the uniform
// directly via an if-chain.
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

float hash(vec2 p) {
    float h = dot(p, vec2(127.1, 311.7));
    // Adding uSeed inside sin() shifts the hash's phase non-linearly — tiny
    // seed changes produce uncorrelated noise patterns (not just a pan).
    return -1.0 + 2.0 * fract(sin(h + uSeed) * 43758.5453123);
}

// 2D value noise with smoothstep (cubic) interpolation between lattice hashes.
float noise(in vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i + vec2(0.0, 0.0)),
                   hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)),
                   hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

// Swirl-distorted checkerboard shape.
//
// 1. Pre-warp: nudge uv by a vector whose angle comes from one noise sample
//    and magnitude from another — gives a soft turbulent flow.
// 2. Iterative swirl: chain of cos() offsets with 1/i amplitude creates
//    recursive churn reminiscent of plasma/cloud effects.
// 3. Base shape: sin(x)*cos(y) checkerboard-like field on the distorted
//    coords → [0, 1].
// 4. Palette: N-stop lookup driven by shape, carrying alpha through.
vec4 map(vec2 p) {
    vec2 uv = 0.5 * uPatternScale * p;
    float t = uSwirlTimeScale * uTime;

    // Pre-distortion. noise() returns [-1,1]; remap to [0,1] so n1 spans a
    // full angle and n2 stays non-negative as a magnitude.
    float n1 = 0.5 + 0.5 * noise(uv + t);
    float n2 = 0.5 + 0.5 * noise(2.0 * uv - t);
    float angle = n1 * 6.28318530718;
    uv += 4.0 * uSwirlDistortion * n2 * vec2(cos(angle), sin(angle));

    // Approximate pixel footprint in uv-space. SkSL doesn't expose
    // `fwidth`/`dFdx`/`dFdy`, so we derive it from uSize: a 1-pixel step in
    // fragCoord maps to `2/uSize.y` in p-space; `uv = 0.5*uPatternScale*p`
    // scales that by `uPatternScale/2`, and the length across both axes
    // picks up a √2. The pre-warp's contribution to the actual derivative
    // is dropped — the fade just needs a reasonable baseline.
    float px = uPatternScale * 1.41421356 / uSize.y;

    // Iterative swirl. The loop bound is a compile-time constant; runtime
    // iteration count is enforced by the early break below.
    float iterations = clamp(uSwirlIterations, 1.0, float(MAX_SWIRL_ITERATIONS));
    for (int i = 1; i <= MAX_SWIRL_ITERATIONS; i++) {
        if (float(i) > iterations) break;
        float fi = float(i);
        float w  = smoothstep(1.0, 0.5, px * fi * uSwirlFreq);
        uv.x += w * uSwirlStrength / fi * cos(t + fi * uSwirlFreq * uv.y);
        uv.y += w * uSwirlStrength / fi * cos(t + fi * uSwirlFreq * uv.x);
    }

    // Checkerboard-like base shape → scalar in [0, 1]. `bias` shifts the
    // mid-value so the black/white proportion can be tuned.
    float prop = clamp(uShapeProportion, 0.0, 1.0);
    float bias = 0.48 * sign(prop - 0.5) * pow(abs(prop - 0.5), 0.5);
    vec2 s = uv * (0.5 + 3.5 * uShapeScale);
    float shape = 0.5 + 0.5 * sin(s.x) * cos(s.y) + bias;
    shape = clamp(shape, 0.0, 1.0);

    // N-stop palette lookup. All math stays in floats — SkSL has no integer
    // clamp/min overloads — with int() casts only at the indexing step.
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

    // Aspect-correct coords centred on screen: y in [-1, 1], x scaled to match.
    vec2 p = (-uSize.xy + 2.0 * fragCoord.xy) / uSize.y;

    // Approximate 1-pixel footprint in p-space. SkSL doesn't have
    // `fwidth`, so we derive it from uSize: the aspect-correction divides by
    // uSize.y and multiplies by 2, so a 1-pixel step is 2/uSize.y; √2 picks
    // up both axes. Clamping uSampleEps to this floor prevents sub-pixel
    // variation from amplifying AND handles a preset setting eps to 0 (which
    // would collapse the three taps and produce a NaN normal).
    float pxFootprint = 2.0 * 1.41421356 / uSize.y;
    float eps = max(uSampleEps, pxFootprint);

    // Three taps for a forward-difference gradient of the pattern's luminance.
    vec4 colc = map(p);
    vec4 cola = map(p + vec2(eps, 0.0));
    vec4 colb = map(p + vec2(0.0, eps));

    float gc = dot(colc.rgb, LUMA);
    float ga = dot(cola.rgb, LUMA);
    float gb = dot(colb.rgb, LUMA);

    // Treat luminance as a heightfield: xz = forward partials, y = "up" axis.
    vec3 nor = normalize(vec3(ga - gc, eps, gb - gc));

    vec3 col = colc.rgb;

    // Edge / ridge highlight: 2*gc - ga - gb is a cheap 3-sample edge detector.
    col += uEdgeTint * uEdgeGain * abs(2.0 * gc - ga - gb);

    // Fake lighting off the heightfield normal. Ambient lifts flat,
    // upward-facing areas (nor.y near 1); rim lights slopes / edges
    // (nor.y near 0) where the surface tilts away from "up".
    col *= 1.0 + uAmbientGain * nor.y * nor.y;
    float rim = 1.0 - nor.y;
    col +=       uRimGain     * rim * rim * rim;

    // Dither to hide 8-bit quantisation banding.
    col += (1.0 / 256.0) * (fract(sin(dot(0.021 * fragCoord.xy,
                                          vec2(23.1407, 59.721)))
                                  * 57283.1841932) - 0.5);

    // Premultiplied-alpha output — required by Flutter's compositor so that
    // transparent palette stops actually composite transparently.
    col = clamp(col, 0.0, 1.0);
    float a = clamp(colc.a, 0.0, 1.0);
    fragColor = vec4(col * a, a);
}

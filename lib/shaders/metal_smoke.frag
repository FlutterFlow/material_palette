#include <flutter/runtime_effect.glsl>

precision highp float;

// Metal smoke — noise-rotated pre-warp + iterative swirl + checkerboard,
// coloured through a 10-stop palette and shaded as a heightfield with an
// edge glow.

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

// Rec. 709 perceptual luminance weights.
const vec3  LUMA  = vec3(0.2126, 0.7152, 0.0722);
const float SQRT2 = 1.41421356;

// Compile-time loop bound; runtime count enforced via early break (SkSL has
// no integer clamp).
#define MAX_SWIRL_ITERATIONS 20

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

float hash(vec2 p) {
    float h = dot(p, vec2(127.1, 311.7));
    // uSeed inside sin() shifts phase non-linearly — small seed deltas
    // give uncorrelated patterns, not just a pan.
    return -1.0 + 2.0 * fract(sin(h + uSeed) * 43758.5453123);
}

// 2D value noise, cubic interpolation between lattice hashes.
float noise(in vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i + vec2(0.0, 0.0)),
                   hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)),
                   hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

// Pre-warp + iterative swirl + checkerboard → palette lookup.
vec4 map(vec2 p) {
    vec2 uv = 0.5 * uPatternScale * p;
    float t = uSwirlTimeScale * uTime;

    // Remap noise from [-1,1] → [0,1] so angle spans a full turn and
    // magnitude stays non-negative.
    float n1 = 0.5 + 0.5 * noise(uv + t);
    float n2 = 0.5 + 0.5 * noise(2.0 * uv - t);
    float angle = n1;
    uv += 4.0 * uSwirlDistortion * n2 * vec2(cos(angle), sin(angle));

    // fwidth-free pixel footprint in uv-space, derived from uSize. Used to
    // fade out swirl iterations as they hit the Nyquist limit.
    float px = uPatternScale * SQRT2 / uSize.y;

    float iterations = clamp(uSwirlIterations, 1.0, float(MAX_SWIRL_ITERATIONS));
    for (int i = 1; i <= MAX_SWIRL_ITERATIONS; i++) {
        if (float(i) > iterations) break;
        float fi = float(i);
        float w  = smoothstep(1.0, 0.5, px * fi * uSwirlFreq);
        uv.x += w * uSwirlStrength / fi * cos(t + fi * uSwirlFreq * uv.y);
        uv.y += w * uSwirlStrength / fi * cos(t + fi * uSwirlFreq * uv.x);
    }

    // `bias` shifts the mid-value to tune the black/white proportion.
    float prop = clamp(uShapeProportion, 0.0, 1.0);
    float bias = 0.48 * sign(prop - 0.5) * pow(abs(prop - 0.5), 0.5);
    vec2 s = uv * (0.5 + 3.5 * uShapeScale);
    float shape = 0.5 + 0.5 * sin(s.x) * cos(s.y) + bias;
    shape = clamp(shape, 0.0, 1.0);

    // SkSL has no integer clamp/min — clamp in floats, cast at indexing.
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

    // Aspect-correct coords: y in [-1, 1], x scaled to match.
    vec2 p = (-uSize.xy + 2.0 * fragCoord.xy) / uSize.y;

    // Floor eps at the 1-pixel footprint: prevents sub-pixel amplification,
    // and stops eps=0 from collapsing the three taps into a NaN normal.
    float pxFootprint = 2.0 * SQRT2 / uSize.y;
    float eps = max(uSampleEps, pxFootprint);

    // Forward-difference gradient of the pattern's luminance.
    vec4 colc = map(p);
    vec4 cola = map(p + vec2(eps, 0.0));
    vec4 colb = map(p + vec2(0.0, eps));

    float gc = dot(colc.rgb, LUMA);
    float ga = dot(cola.rgb, LUMA);
    float gb = dot(colb.rgb, LUMA);

    // Luminance as a heightfield: xz = partials, y = "up" axis.
    vec3 nor = normalize(vec3(ga - gc, eps, gb - gc));

    vec3 col = colc.rgb;

    // Cheap 3-sample edge detector.
    col += uEdgeTint * uEdgeGain * abs(2.0 * gc - ga - gb);

    // Ambient on upward-facing areas (nor.y → 1), rim on tilted slopes.
    col *= 1.0 + uAmbientGain * nor.y * nor.y;
    float rim = 1.0 - nor.y;
    col +=       uRimGain     * rim * rim * rim;

    // 8-bit quantisation dither.
    col += (1.0 / 256.0) * (fract(sin(dot(0.021 * fragCoord.xy,
                                          vec2(23.1407, 59.721)))
                                  * 57283.1841932) - 0.5);

    // Premultiplied alpha — required by Flutter's compositor.
    col = clamp(col, 0.0, 1.0);
    float a = clamp(colc.a, 0.0, 1.0);
    fragColor = vec4(col * a, a);
}

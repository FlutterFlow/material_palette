#include <flutter/runtime_effect.glsl>
precision highp float;

// Iridescent liquid (fill) — stripes + fbm domain warp filling the quad.
// No mask, no edge-driven contour bending.
//   uStripeRippleStrength  0 = pure fbm warp, 1 = pure stripes
//   uBumpWarpWeight        0 = stripes ignore fbm, 1 = stripes track the fbm

// Standard header
uniform vec2  uSize;
uniform float uTime;

// Scalar uniforms are packed into vec4 slots: Impeller's Metal backend binds
// every uniform declaration to its own [[buffer(N)]] and iOS rejects N > 30,
// so the declaration count must stay ≤ 31 (see registry_audit_test.dart).
// The flat float order is unchanged — the Dart writers are untouched; the
// #define aliases keep the body readable.

// Pattern tuning
uniform vec4 uPat0;
#define uRepetition      uPat0.x  // stripe density (1..10)
#define uSoftness        uPat0.y  // stripe-edge blur
#define uDistortion      uPat0.z  // noise warp into stripe phase
#define uAngleDeg        uPat0.w  // pattern rotation (degrees)

// Diagonal asymmetries (set both to 0 for a symmetric look) + stripe pattern
uniform vec4 uPat1;
#define uStripeDiagaBias uPat1.x  // linear diagA → direction
#define uStripeTwist     uPat1.y  // per-pixel rotation perturbation
#define uStripeCount     uPat1.z  // bright stripes per cycle (0..5)
#define uStripeThickness uPat1.w  // stripe width as fraction of slot

uniform vec4 uPat2;
#define uStripeOffset    uPat2.x  // phase offset (0..1 cycles)
#define uStripeFalloff   uPat2.y  // gradient zone width (intermediate-color thickness)
#define uStripeSpeed     uPat2.z  // animation speed multiplier (1 = default)
#define uShiftRed        uPat2.w  // chromatic aberration

// Chromatic aberration
uniform float uShiftBlue;

// Composition
uniform vec4  uColorTint;             // colour-burn tint (alpha = strength)

// Domain warp tuning
uniform vec4 uWarp0;
#define uWarpTimeScale        uWarp0.x
#define uWarpFreqInner        uWarp0.y
#define uWarpFreqMiddle       uWarp0.z
#define uWarpFreqHigh         uWarp0.w

uniform vec4 uWarp1;
#define uFbmScaleFactor       uWarp1.x
#define uStripeRippleStrength uWarp1.y
#define uBumpWarpWeight       uWarp1.z
#define uPaletteStops         uWarp1.w  // active stop count for the palette below

// Palette (10 RGBA stops, first uPaletteStops active). Stops 0-7 are packed
// as mat4 columns — one RGBA stop per column, same flat float order.
uniform mat4 uPalette0;
#define uColor0 uPalette0[0]
#define uColor1 uPalette0[1]
#define uColor2 uPalette0[2]
#define uColor3 uPalette0[3]
uniform mat4 uPalette1;
#define uColor4 uPalette1[0]
#define uColor5 uPalette1[1]
#define uColor6 uPalette1[2]
#define uColor7 uPalette1[3]
uniform vec4  uColor8;
uniform vec4  uColor9;

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

// Triple-nested warp collapsed to a palette-index scalar in [0, 1].
float warpShape(vec2 p, float tw) {
    vec2 w1 = fbm2(uFbmScaleFactor * uWarpFreqInner * p);
    vec2 w2 = fbm2(-tw + uWarpFreqMiddle * (p + w1));
    vec2 w3 = fbm2( tw + uWarpFreqHigh   * (p + w2));
    float f = dot(w3, vec2(1.0, -1.0));
    return clamp(0.5 + 0.5 * f, 0.0, 1.0);
}

// Palette lookup for a warp-shape scalar — the cheap per-channel tail of
// the domain warp. The expensive warpShape eval is computed once in main
// and shared across RGB; `stripe` is blended in via uStripeRippleStrength
// before indexing the palette.
vec4 warpPalette(float shape, float stripe) {
    float v = mix(shape, stripe, uStripeRippleStrength);

    // SkSL has no integer clamp/min overloads — clamp in floats then cast.
    float nF  = clamp(uPaletteStops + 0.5, 2.0, 10.0);
    float nm1 = nF - 1.0;
    float tp  = v * nm1;
    float i0F = floor(tp);
    float i1F = min(i0F + 1.0, nm1);
    float fp  = smoothstep(0.0, 1.0, tp - i0F);
    return mix(paletteAt(int(i0F)), paletteAt(int(i1F)), fp);
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;

    // Aspect-correct UV — pattern runs in a unit square on the short axis,
    // y-flipped so pattern-space "up" is screen-top.
    float aspect = uSize.x / uSize.y;
    vec2  uv     = vec2(fragCoord.x / uSize.x,
                        1.0 - fragCoord.y / uSize.y);
    if (aspect > 1.0) uv.x = (uv.x - 0.5) * aspect + 0.5;
    else              uv.y = (uv.y - 0.5) / aspect + 0.5;

    float t = 0.3 * (uTime + 2.8);

    // ---- 1. Rotated coords (+70° bias for default angle = 0) --------------
    float angle = (70.0 - uAngleDeg) * PI / 180.0;
    vec2  rUV   = rotate2(uv - 0.5, angle) + 0.5;
    float diagA = rUV.x - rUV.y;

    // ---- 2. Warp tap: drives `noise` and `bump` ---------------------------
    vec2  p          = uv - 0.5;
    float tw         = uWarpTimeScale * uTime;
    float warpShapeV = warpShape(2.0 * p, tw);
    float noise      = mix(snoise(uv - t),
                           2.0 * warpShapeV - 1.0,
                           uBumpWarpWeight);
    float bump       = uBumpWarpWeight * warpShapeV;

    float edgeN    = uDistortion * noise;
    float edgeS    = smoothstep(0.0, 1.0, edgeN);
    float edgePeak = edgeS * (1.0 - edgeS);

    // ---- 3. Stripe accumulator -------------------------------------------
    float direction = rotate2(p, (0.25 - uStripeTwist * diagA) * PI).x;
    direction += uStripeDiagaBias * diagA;
    direction -= 2.0 * noise * diagA * edgePeak;
    direction *= 0.1 + (1.1 - edgeN) * bump;
    direction *= 0.4 + 0.6 * (1.0 - smoothstep(0.5, 1.0, edgeN));
    direction *= uRepetition;
    direction -= t * uStripeSpeed;

    // ---- 4. Per-channel stripe scalars (chromatic aberration) -------------
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

    // ---- 5. Shared warp + per-channel palette taps -------------------------
    // The color path samples the warp at 2.0 * p — the identical arguments
    // already evaluated for the bump term in section 2, so that eval is
    // reused (exact dedupe). One shape serves all three channels: the
    // visible chromatic dispersion lives in the per-channel stripe phases
    // above, which the warp shape barely noticed at its old ±uShift/50
    // coordinate offsets.
    vec3 col = vec3(
        warpPalette(warpShapeV, stripeR).r,
        warpPalette(warpShapeV, stripeG).g,
        warpPalette(warpShapeV, stripeB).b
    );

    // Color-burn tint (alpha = strength).
    col = mix(col,
              1.0 - min(vec3(1.0),
                        (1.0 - col) / max(uColorTint.rgb, vec3(0.0001))),
              uColorTint.a);

    // ---- 6. Dither --------------------------------------------------------
    col += (1.0 / 256.0) *
           (fract(sin(dot(fragCoord, vec2(12.9898, 78.233))) * 43758.5453)
            - 0.5);

    fragColor = vec4(col, 1.0);
}

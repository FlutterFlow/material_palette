#include <flutter/runtime_effect.glsl>

precision highp float;

// ============================================================
//  Liquid metal — procedural fill with a triple-nested domain
//  warp over 4-octave value noise, shaded as a heightfield with
//  a warm edge glow. All former file-scope constants are
//  exposed as uniforms so the entire look is tunable.
// ============================================================

// Standard header
uniform vec2  uSize;
uniform float uTime;

// Pattern / animation
uniform float uRotAngle;        // rad — FBM lattice rotation
uniform float uPatternScale;    // global zoom (smaller = coarser features)
uniform float uTimeScale;       // warp flow speed
uniform float uWarpFreqInner;   // innermost warp frequency multiplier
uniform float uWarpFreqMiddle;  // middle warp frequency multiplier
uniform float uWarpFreqHigh;    // outermost warp frequency multiplier

// Lighting
uniform float uSampleEps;       // gradient tap offset (smaller = bumpier)
uniform float uAmbientGain;     // quadratic ambient lift
uniform float uRimGain;         // cubic rim highlight

// Edge glow
uniform float uEdgeGain;        // intensity of ridge/crack highlight
uniform vec3  uEdgeTint;        // colour of the ridge highlight
uniform vec3  uLumaWeights;     // perceptual-luminance weights (Rec. 709 default)

// Palette (10 RGBA stops, first `uPaletteStops` active)
uniform float uPaletteStops;    // active stop count, clamped to [2, 10]
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

float hash(vec2 p) {
    float h = dot(p, vec2(129.2, 331.3));
    return -1.0 + 2.0 * fract(sin(h) * 294279.242);
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

// 4-octave fractional Brownian motion. `m` was a file-scope const in the
// original; it's now rebuilt from uRotAngle per fbm() call (two sin + two
// cos — negligible next to the 16 noise lookups).
float fbm(vec2 p) {
    float c = cos(uRotAngle);
    float s = sin(uRotAngle);
    mat2 m  = mat2(c, s, -s, c);
    float f  = 0.5000 * noise(p); p = m * p * 2.03;
          f += 0.2500 * noise(p); p = m * p * 2.01;
          f += 0.1250 * noise(p); p = m * p * 1.99;
          f += 0.0625 * noise(p);
    return f / 0.9375;
}

vec2 fbm2(in vec2 p) {
    return vec2(fbm(p), fbm(p.yx + vec2(3.2, 13.7)));
}

// Palette lookup by index. Written as an if-chain because SkSL (used by
// Flutter's Skia backend) does not accept `vec4[10] = vec4[](...)` array
// initializers, so we can't build a local array from uniforms.
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

// Triple-nested domain warp. Two layers counter-drift at ±uTimeScale*uTime.
vec4 map(vec2 p) {
    p *= uPatternScale;

    vec2 w1 = fbm2(uWarpFreqInner  * p);
    vec2 w2 = fbm2(-uTimeScale * uTime + uWarpFreqMiddle * (p + w1));
    vec2 w3 = fbm2( uTimeScale * uTime + uWarpFreqHigh   * (p + w2));

    float f     = dot(w3, vec2(1.0, -1.0));
    float shape = clamp(0.5 + 0.5 * f, 0.0, 1.0);

    // N-stop palette lookup. Split [0,1] into N-1 equal segments, smoothstep
    // the local fraction within the segment, then mix between the bracketing
    // stops (alpha interpolates linearly with rgb). All math stays in floats
    // — SkSL has no integer clamp/min overloads.
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
    vec2 p = (-uSize + 2.0 * fragCoord.xy) / uSize.y;

    // Three taps for a forward-difference gradient of pattern luminance.
    vec4 colc = map(p);
    vec4 cola = map(p + vec2(uSampleEps, 0.0));
    vec4 colb = map(p + vec2(0.0, uSampleEps));

    float gc = dot(colc.rgb, uLumaWeights);
    float ga = dot(cola.rgb, uLumaWeights);
    float gb = dot(colb.rgb, uLumaWeights);

    // Fake normal from luminance heightfield. Using uSampleEps as the y
    // component scales the tilt with the tap distance — smaller eps → bumpier.
    vec3 nor = normalize(vec3(ga - gc, uSampleEps, gb - gc));

    vec3 col = colc.rgb;

    // Edge / ridge highlight: 2*gc - ga - gb is a cheap 3-sample edge detector.
    col += uEdgeTint * uEdgeGain * abs(2.0 * gc - ga - gb);

    // Fake lighting off the heightfield normal.
    col *= 1.0 + uAmbientGain * nor.y * nor.y;
    col +=       uRimGain     * nor.y * nor.y * nor.y;

    // Dither to hide 8-bit quantisation banding (±0.5/256, deterministic per pixel).
    col += (1.0 / 256.0) * (fract(sin(dot(0.019 * fragCoord.xy,
                                          vec2(37.3, 71.9)))
                                  * 42893.2817) - 0.5);

    fragColor = vec4(col, colc.a);
}

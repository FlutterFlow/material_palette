#include <flutter/runtime_effect.glsl>

precision highp float;

// Core uniforms
uniform vec2 uSize;
uniform float uTime;

// Gradient settings
uniform vec2 uGradientCenter;     // Center point (0.5, 0.5 = center)
uniform float uGradientScale;     // Scale factor (1.0 = covers viewport)
uniform float uGradientOffset;    // Shift gradient position (-1 to 1)

// Noise settings
uniform float uNoiseDensity;      // Stipple density (higher = finer grain)
uniform float uNoiseIntensity;    // How much noise affects the color (0-1)
uniform float uStippleStrength;   // How much stipple noise is added (0=none, 1=full)
uniform float uDitherStrength;    // Dithering at color boundaries (0-1)
uniform float uDitherScale;       // Dither sampling scale (lower = more pixelated)

// Animation
uniform float uAnimSpeed;         // Noise animation speed

// Color palette (sRGB, RGBA) - up to 10 gradient stops
uniform vec4 uColor0;
uniform vec4 uColor1;
uniform vec4 uColor2;
uniform vec4 uColor3;
uniform vec4 uColor4;
uniform vec4 uColor5;
uniform vec4 uColor6;
uniform vec4 uColor7;
uniform vec4 uColor8;
uniform vec4 uColor9;
uniform float uColorCount;         // Number of active color stops (2-10)
uniform float uSoftness;           // Transition sharpness (0=sharp, 1=smooth)

// Post-processing
uniform float uExposure;
uniform float uContrast;

out vec4 fragColor;

// ============ COLOR SPACE CONVERSION ============

float srgbToLinear(float c) {
    return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4);
}

vec3 srgbToLinear(vec3 c) {
    return vec3(srgbToLinear(c.r), srgbToLinear(c.g), srgbToLinear(c.b));
}

float linearToSrgb(float c) {
    return c <= 0.0031308 ? c * 12.92 : 1.055 * pow(c, 1.0 / 2.4) - 0.055;
}

vec3 linearToSrgb(vec3 c) {
    return vec3(linearToSrgb(c.r), linearToSrgb(c.g), linearToSrgb(c.b));
}

// ============ NOISE FUNCTIONS ============

// High-quality random for stipple effect
float random(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// Stipple noise - creates the grainy/risograph effect
float stippleNoise(vec2 p, float time) {
    // Pixel-level random stipple
    vec2 pixelCoord = floor(p);

    // Add subtle time-based variation if animated
    float timeOffset = time * 100.0;

    // Multiple layers of stipple at different scales
    float stipple1 = random(pixelCoord + timeOffset);
    float stipple2 = random(pixelCoord * 0.5 + timeOffset * 0.7);
    float stipple3 = random(pixelCoord * 2.0 + timeOffset * 1.3);

    // Combine with weighted average favoring fine detail
    return stipple1 * 0.6 + stipple2 * 0.25 + stipple3 * 0.15;
}

// Proper 4x4 Bayer ordered dither (16 distinct thresholds)
float orderedDither(vec2 p) {
    vec2 cell = mod(floor(p), 4.0);
    // Decompose into two 2x2 levels of the recursive Bayer pattern
    float bx0 = mod(cell.x, 2.0);
    float by0 = mod(cell.y, 2.0);
    float bx1 = floor(cell.x / 2.0);
    float by1 = floor(cell.y / 2.0);
    float fine   = mod(bx0 * 2.0 + by0 * 3.0, 4.0);
    float coarse = mod(bx1 * 2.0 + by1 * 3.0, 4.0);
    float bayer = (fine * 4.0 + coarse + 0.5) / 16.0;
    return (bayer - 0.5) * 2.0;
}

// Combined gritty texture — all lookups use the quantized cell coordinate
// so every screen pixel in the same dither cell gets identical values.
float grittyTexture(vec2 cellCoord, float time) {
    float stipple = stippleNoise(cellCoord * uNoiseDensity / 100.0, time);
    float dither = orderedDither(cellCoord) * uDitherStrength * 0.1;

    // Mix between neutral (0.5) and stipple; at strength 0 only dither contributes
    return mix(0.5, stipple, uStippleStrength) + dither;
}

// ============ RADIAL GRADIENT FUNCTION ============

float calculateRadialGradient(vec2 uv) {
    // Account for aspect ratio to make gradient circular
    float aspect = uSize.x / uSize.y;
    vec2 adjustedUV = uv;
    adjustedUV.x = (adjustedUV.x - 0.5) * aspect + 0.5;

    // Calculate distance from center
    vec2 centered = adjustedUV - uGradientCenter;
    float dist = length(centered);

    // Apply scale and offset
    float t = dist / (0.5 * uGradientScale) + uGradientOffset;

    // Clamp to 0-1 range
    return clamp(t, 0.0, 1.0);
}

// ============ MULTI-STOP COLOR INTERPOLATION ============

// Get color stop by index
vec4 getColorStop(int i) {
    if (i == 0) return uColor0;
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

// Multi-stop gradient with softness control and premultiplied alpha
vec4 gradientColor(float t) {
    int count = int(uColorCount);
    if (count < 2) count = 2;
    if (count > 10) count = 10;

    // Map t to color stop space
    float stopT = t * float(count - 1);
    int idx = int(floor(stopT));
    if (idx >= count - 1) idx = count - 2;
    float frac = stopT - float(idx);

    // Get the two adjacent stops
    vec4 stopA = getColorStop(idx);
    vec4 stopB = getColorStop(idx + 1);

    // Convert sRGB to linear, premultiply alpha
    vec3 linA = srgbToLinear(stopA.rgb);
    vec3 linB = srgbToLinear(stopB.rgb);
    float alphaA = stopA.a;
    float alphaB = stopB.a;

    // Premultiply
    vec4 pmA = vec4(linA * alphaA, alphaA);
    vec4 pmB = vec4(linB * alphaB, alphaB);

    // Apply softness to transition
    float blend;
    if (uSoftness >= 0.999) {
        blend = frac;
    } else if (uSoftness <= 0.001) {
        blend = step(0.5, frac);
    } else {
        float edge = 0.5 * uSoftness;
        blend = smoothstep(0.5 - edge, 0.5 + edge, frac);
    }

    // Interpolate in premultiplied space
    return mix(pmA, pmB, blend);
}

// Apply stipple noise to create gritty color transition
vec4 grittyGradientColor(float gradientT, float noise) {
    float noiseMod = (noise - 0.5) * 2.0 * uNoiseIntensity;
    float noisyT = gradientT + noiseMod;
    noisyT = clamp(noisyT, 0.0, 1.0);
    return gradientColor(noisyT);
}

// ============ MAIN ============

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    float time = uTime * uAnimSpeed;

    // Snap to dither pixel grid so each cell outputs one discrete color
    float cellSize = 1.0 / max(uDitherScale, 0.001);
    vec2 cellCoord = floor(fragCoord / cellSize);
    vec2 quantized = (cellCoord + 0.5) * cellSize;

    // All sampling uses the quantized coordinate
    vec2 uv = quantized / uSize;

    // Calculate radial gradient position (0 at center, 1 at edge)
    float gradientT = calculateRadialGradient(uv);

    // Generate stipple noise
    float grit = grittyTexture(cellCoord, time);

    // Get color with gritty/stippled transition (premultiplied alpha)
    vec4 pmColor = grittyGradientColor(gradientT, grit);

    // Un-premultiply for post-processing
    float alpha = pmColor.a;
    vec3 color = alpha > 0.001 ? pmColor.rgb / alpha : vec3(0.0);

    // Apply contrast
    color = mix(vec3(0.5), color, uContrast);

    // Apply exposure
    color *= uExposure;

    // Clamp to [0,1] before sRGB conversion
    color = clamp(color, 0.0, 1.0);

    // Convert back to sRGB
    color = linearToSrgb(color);
    color = clamp(color, 0.0, 1.0);

    // Re-premultiply for output
    fragColor = vec4(color * alpha, alpha);
}

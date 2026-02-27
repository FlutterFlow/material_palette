// Marble Smear Shader
// Creates organic, flowing marble patterns using double domain warping

#include <flutter/runtime_effect.glsl>

precision highp float;

// Core uniforms
uniform vec2 uSize;
uniform float time;
uniform vec3 uBgColor;

// Domain warping uniforms
uniform float uWarp1Scale;
uniform float uWarp2Scale;
uniform float uFinalScale;
uniform float uWarpStrength;

// Contrast uniforms
uniform float uContrastPower;
uniform float uFinalContrast;

// Animation uniforms
uniform float uAnimSpeedInputX;
uniform float uAnimSpeedInputY;
uniform float uAnimSpeedWarpX;
uniform float uAnimSpeedWarpY;
uniform float uAnimAmpInput;
uniform float uAnimAmpWarp;

// Color palette uniforms (sRGB)
uniform vec3 uColor0; // cream / lightest vein
uniform vec3 uColor1; // tan / mid-tone base
uniform vec3 uColor2; // brown / dark base
uniform vec3 uColor3; // teal / accent edge
uniform vec3 uColor4; // dark / valley shadow

// Lighting uniforms
uniform float uLightIntensity;

const vec3 LIGHT_DIR = vec3(0.89553, 0.19901, -0.39801);
const float LIGHT_AMBIENT = 0.3;
const float LIGHT_DIFFUSE = 0.7;
const vec3 LIGHT_SKY_LIN = vec3(1.0, 1.0, 1.0);
const vec3 LIGHT_SUN_LIN = vec3(0.01, 0.01, 0.01);

// Smudge settings
uniform float uSmudgeRadius;
uniform float uSmudgeStrength;
uniform float uSmudgeFalloff;

// Smudge data
uniform float uSmudgeCount;
// Each smudge: startX, startY, endX, endY, time (5 floats per smudge, 10 smudges)
uniform float uSmudge0StartX;
uniform float uSmudge0StartY;
uniform float uSmudge0EndX;
uniform float uSmudge0EndY;
uniform float uSmudge0Time;
uniform float uSmudge1StartX;
uniform float uSmudge1StartY;
uniform float uSmudge1EndX;
uniform float uSmudge1EndY;
uniform float uSmudge1Time;
uniform float uSmudge2StartX;
uniform float uSmudge2StartY;
uniform float uSmudge2EndX;
uniform float uSmudge2EndY;
uniform float uSmudge2Time;
uniform float uSmudge3StartX;
uniform float uSmudge3StartY;
uniform float uSmudge3EndX;
uniform float uSmudge3EndY;
uniform float uSmudge3Time;
uniform float uSmudge4StartX;
uniform float uSmudge4StartY;
uniform float uSmudge4EndX;
uniform float uSmudge4EndY;
uniform float uSmudge4Time;
uniform float uSmudge5StartX;
uniform float uSmudge5StartY;
uniform float uSmudge5EndX;
uniform float uSmudge5EndY;
uniform float uSmudge5Time;
uniform float uSmudge6StartX;
uniform float uSmudge6StartY;
uniform float uSmudge6EndX;
uniform float uSmudge6EndY;
uniform float uSmudge6Time;
uniform float uSmudge7StartX;
uniform float uSmudge7StartY;
uniform float uSmudge7EndX;
uniform float uSmudge7EndY;
uniform float uSmudge7Time;
uniform float uSmudge8StartX;
uniform float uSmudge8StartY;
uniform float uSmudge8EndX;
uniform float uSmudge8EndY;
uniform float uSmudge8Time;
uniform float uSmudge9StartX;
uniform float uSmudge9StartY;
uniform float uSmudge9EndX;
uniform float uSmudge9EndY;
uniform float uSmudge9Time;

out vec4 fragColor;

// Smudge lifetime for fade calculation
const float SMUDGE_LIFETIME = 8.0;

// Animation frequency for input (kept as constant)
const vec2 ANIM_FREQ_INPUT = vec2(4.1, 4.3);

// FBM settings
const mat2 ROT = mat2(0.966, 0.259, -0.259, 0.966);

// ============ COLOR SPACE CONVERSION ============

// sRGB to linear conversion (single channel)
float srgbToLinear(float c) {
    return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4);
}

// sRGB to linear conversion (vec3)
vec3 srgbToLinear(vec3 c) {
    return vec3(srgbToLinear(c.r), srgbToLinear(c.g), srgbToLinear(c.b));
}

// Linear to sRGB conversion (single channel)
float linearToSrgb(float c) {
    return c <= 0.0031308 ? c * 12.92 : 1.055 * pow(c, 1.0 / 2.4) - 0.055;
}

// Linear to sRGB conversion (vec3)
vec3 linearToSrgb(vec3 c) {
    return vec3(linearToSrgb(c.r), linearToSrgb(c.g), linearToSrgb(c.b));
}

// RGB to HSL conversion
vec3 rgbToHsl(vec3 c) {
    float maxC = max(c.r, max(c.g, c.b));
    float minC = min(c.r, min(c.g, c.b));
    float l = (maxC + minC) * 0.5;
    
    if (maxC == minC) return vec3(0.0, 0.0, l);
    
    float d = maxC - minC;
    float s = l > 0.5 ? d / (2.0 - maxC - minC) : d / (maxC + minC);
    
    float h;
    if (maxC == c.r) h = (c.g - c.b) / d + (c.g < c.b ? 6.0 : 0.0);
    else if (maxC == c.g) h = (c.b - c.r) / d + 2.0;
    else h = (c.r - c.g) / d + 4.0;
    
    return vec3(h / 6.0, s, l);
}

// HSL to RGB helper
float hue2rgb(float p, float q, float t) {
    if (t < 0.0) t += 1.0;
    if (t > 1.0) t -= 1.0;
    if (t < 1.0/6.0) return p + (q - p) * 6.0 * t;
    if (t < 0.5) return q;
    if (t < 2.0/3.0) return p + (q - p) * (2.0/3.0 - t) * 6.0;
    return p;
}

// HSL to RGB conversion
vec3 hslToRgb(vec3 hsl) {
    if (hsl.y == 0.0) return vec3(hsl.z);
    
    float q = hsl.z < 0.5 ? hsl.z * (1.0 + hsl.y) : hsl.z + hsl.y - hsl.z * hsl.y;
    float p = 2.0 * hsl.z - q;
    
    return vec3(
        hue2rgb(p, q, hsl.x + 1.0/3.0),
        hue2rgb(p, q, hsl.x),
        hue2rgb(p, q, hsl.x - 1.0/3.0)
    );
}

// ============ NOISE FUNCTIONS ============

// Turbulent sine - higher frequency detail
float turbulentNoise(vec2 p) {
    return sin(p.x + 0.5 * sin(2.0 * p.y)) * sin(p.y + 0.5 * sin(2.0 * p.x));
}

float noise(vec2 p) {
    return turbulentNoise(p);
}

// ============ FBM FUNCTIONS ============

// FBM with 4 octaves - balanced detail/performance
float fbm4(vec2 p) {
    float f = 0.0;
    f += 0.5000 * (0.5 + 0.5 * noise(p)); p = ROT * p * 2.01;
    f += 0.2500 * (0.5 + 0.5 * noise(p)); p = ROT * p * 1.99;
    f += 0.1250 * (0.5 + 0.5 * noise(p)); p = ROT * p * 2.03;
    f += 0.0625 * (0.5 + 0.5 * noise(p));
    return f / 0.9375;
}

// ============ 2D FBM WRAPPERS ============

vec2 fbm4_2(vec2 p) {
    return vec2(fbm4(p + vec2(17.8)), fbm4(p + vec2(73.7)));
}

// ============ SMUDGE SYSTEM ============

// Calculate displacement from a single smudge
vec2 calcSmudgeDisplacement(vec2 pos, vec2 smudgeStart, vec2 smudgeEnd, float smudgeTime) {
    if (smudgeTime <= 0.0) return vec2(0.0);
    
    // Drag vector
    vec2 dragVector = smudgeEnd - smudgeStart;
    float dragLength = length(dragVector);
    
    if (dragLength < 0.001) return vec2(0.0);
    
    // Distance from current position to smudge center (end point)
    vec2 toCenter = smudgeEnd - pos;
    float dist = length(toCenter);
    
    // Smooth falloff from smudge center
    float influence = exp(-dist * dist * uSmudgeFalloff / (uSmudgeRadius * uSmudgeRadius));
    
    // Scale influence by drag magnitude
    float dragInfluence = min(dragLength * 2.0, 1.0);
    
    // Fade out over lifetime
    float fadeOut = 1.0 - smoothstep(0.0, SMUDGE_LIFETIME, smudgeTime);
    
    // Displacement pushes the pattern opposite to drag direction
    return -dragVector * influence * dragInfluence * uSmudgeStrength * fadeOut;
}

// Get total displacement from all active smudges
vec2 getTotalSmudgeDisplacement(vec2 pos) {
    vec2 total = vec2(0.0);
    
    if (uSmudgeCount > 0.0) {
        total += calcSmudgeDisplacement(pos, vec2(uSmudge0StartX, uSmudge0StartY), vec2(uSmudge0EndX, uSmudge0EndY), uSmudge0Time);
    }
    if (uSmudgeCount > 1.0) {
        total += calcSmudgeDisplacement(pos, vec2(uSmudge1StartX, uSmudge1StartY), vec2(uSmudge1EndX, uSmudge1EndY), uSmudge1Time);
    }
    if (uSmudgeCount > 2.0) {
        total += calcSmudgeDisplacement(pos, vec2(uSmudge2StartX, uSmudge2StartY), vec2(uSmudge2EndX, uSmudge2EndY), uSmudge2Time);
    }
    if (uSmudgeCount > 3.0) {
        total += calcSmudgeDisplacement(pos, vec2(uSmudge3StartX, uSmudge3StartY), vec2(uSmudge3EndX, uSmudge3EndY), uSmudge3Time);
    }
    if (uSmudgeCount > 4.0) {
        total += calcSmudgeDisplacement(pos, vec2(uSmudge4StartX, uSmudge4StartY), vec2(uSmudge4EndX, uSmudge4EndY), uSmudge4Time);
    }
    if (uSmudgeCount > 5.0) {
        total += calcSmudgeDisplacement(pos, vec2(uSmudge5StartX, uSmudge5StartY), vec2(uSmudge5EndX, uSmudge5EndY), uSmudge5Time);
    }
    if (uSmudgeCount > 6.0) {
        total += calcSmudgeDisplacement(pos, vec2(uSmudge6StartX, uSmudge6StartY), vec2(uSmudge6EndX, uSmudge6EndY), uSmudge6Time);
    }
    if (uSmudgeCount > 7.0) {
        total += calcSmudgeDisplacement(pos, vec2(uSmudge7StartX, uSmudge7StartY), vec2(uSmudge7EndX, uSmudge7EndY), uSmudge7Time);
    }
    if (uSmudgeCount > 8.0) {
        total += calcSmudgeDisplacement(pos, vec2(uSmudge8StartX, uSmudge8StartY), vec2(uSmudge8EndX, uSmudge8EndY), uSmudge8Time);
    }
    if (uSmudgeCount > 9.0) {
        total += calcSmudgeDisplacement(pos, vec2(uSmudge9StartX, uSmudge9StartY), vec2(uSmudge9EndX, uSmudge9EndY), uSmudge9Time);
    }
    
    return total;
}

// ============ DOMAIN WARPING ============

// Double domain warping function
float warpedPattern(vec2 q, out vec4 warpInfo) {
    // Apply smudge displacement
    q += getTotalSmudgeDisplacement(q);
    
    // Animate input coordinates with radial swirl
    vec2 animSpeed = vec2(uAnimSpeedInputX, uAnimSpeedInputY);
    q += uAnimAmpInput * sin(animSpeed * time + length(q) * ANIM_FREQ_INPUT);

    // First warp layer (4 octaves)
    vec2 warp1 = 2.0 * fbm4_2(uWarp1Scale * q) - 1.0;

    // Animate first warp
    vec2 warpAnimSpeed = vec2(uAnimSpeedWarpX, uAnimSpeedWarpY);
    warp1 += uAnimAmpWarp * sin(warpAnimSpeed * time + length(warp1));

    // Second warp layer (4 octaves, avoids hf aliasing at small screen sizes)
    vec2 warp2 = fbm4_2(uWarp2Scale * warp1);

    // Output warp values for coloring
    warpInfo = vec4(warp1, warp2);

    // Final pattern using both warp layers
    float f = fbm4(uFinalScale * q + uWarpStrength * warp2);

    // Non-linear contrast based on warp amount
    return mix(f, f * f * f * uContrastPower, f * abs(warp2.x));
}

// ============ MAIN SHADER ============

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    
    // Convert palette to linear space
    vec3 COLOR_VEIN = srgbToLinear(uColor0);
    vec3 COLOR_BASE_LIGHT = srgbToLinear(uColor1);
    vec3 COLOR_BASE_DARK = srgbToLinear(uColor2);
    vec3 COLOR_EDGE = srgbToLinear(uColor3);
    vec3 COLOR_VALLEY = srgbToLinear(uColor4);

    // Normalized coordinates
    vec2 p = (2.0 * fragCoord - uSize) / uSize.y;
    float epsilon = 2.0 / uSize.y;

    // Compute warped pattern
    vec4 warpInfo = vec4(0.0);
    float f = warpedPattern(p, warpInfo);

    // ---- COLORING (in linear space) ----
    vec3 col = vec3(0.0);

    col = mix(COLOR_BASE_DARK, COLOR_BASE_LIGHT, f);

    float warp2Strength = dot(warpInfo.zw, warpInfo.zw);
    col = mix(col, COLOR_VEIN, warp2Strength);

    col = mix(col, COLOR_VALLEY, 0.2 + 0.5 * warpInfo.y * warpInfo.y);

    float edgeFactor = abs(warpInfo.z) + abs(warpInfo.w);
    col = mix(col, COLOR_EDGE, 0.5 * smoothstep(1.2, 1.3, edgeFactor));

    // Modulate by pattern value
    col = clamp(col * f * 2.0, 0.0, 1.0);

    // ---- LIGHTING (in linear space) ----
    vec4 unused;
    vec3 normal = normalize(vec3(
        warpedPattern(p + vec2(epsilon, 0.0), unused) - f,
        2.0 * epsilon,
        warpedPattern(p + vec2(0.0, epsilon), unused) - f
    ));

    // Directional lighting
    float diffuse = clamp(LIGHT_AMBIENT + LIGHT_DIFFUSE * dot(normal, LIGHT_DIR), 0.0, 1.0);

    // Combine sky (hemisphere) and sun (directional) lighting
    vec3 lighting = LIGHT_SKY_LIN * (normal.y * 0.5 + 0.5) + LIGHT_SUN_LIN * diffuse;
    col *= uLightIntensity * lighting;

    // ---- POST-PROCESSING (still in linear space) ----
    col = clamp(col, 0.0, 1.0);
    vec3 hsl = rgbToHsl(col);
    hsl.z = 1.0 - hsl.z;
    col = hslToRgb(hsl);

    // Contrast boost (in linear space)
    col = uFinalContrast * col * col;

    // ---- GAMMA CORRECTION ----
    col = clamp(col, 0.0, 1.0);
    col = linearToSrgb(col);

    fragColor = vec4(col, 1.0);
}

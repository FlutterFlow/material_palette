#include <flutter/runtime_effect.glsl>

precision highp float;

// Core uniforms
uniform vec2 uSize;
uniform float uClickCount;
uniform vec2 uTouchPoints[10];
uniform float uTimes[10];

// Slurp params
uniform float uRadius;        // influence radius of slurp
uniform float uGravity;       // drape exponent (higher = steeper tent)
uniform float uWrinkles;      // number of radial fold lines
uniform float uWrinkleDepth;  // how pronounced folds are
uniform float uFoldShading;   // brightness variation from folds

// Child texture
uniform sampler2D uTexture;

out vec4 fragColor;

// ============ MAIN ============

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uSize;
    float aspect = uSize.x / uSize.y;
    int clickCount = int(uClickCount);

    // If no taps, just show the texture
    if (clickCount == 0) {
        fragColor = texture(uTexture, uv);
        return;
    }

    // Start from screen position, apply each tap's inverse warp sequentially
    vec2 sampleUV = uv;
    float totalShading = 1.0;
    float totalFade = 0.0;

    for (int i = 0; i < 10; i++) {
        if (i >= clickCount) break;

        float progress = uTimes[i];
        if (progress <= 0.0) continue;

        vec2 tapUV = uTouchPoints[i] / uSize;

        // Aspect-corrected distance from tap
        vec2 delta = uv - tapUV;
        vec2 deltaCorr = delta;
        deltaCorr.x *= aspect;
        float dist = length(deltaCorr);

        // Pull factor: smooth exponential falloff — always non-zero,
        // so even distant edges get pulled in.
        // radius controls width, gravity controls steepness.
        float k = progress * exp(-pow(dist / max(uRadius, 0.001), uGravity));
        k = clamp(k, 0.0, 1.0);

        // Inverse mapping: find where this pixel's content came from
        // Forward: dst = tap + (src - tap) * (1 - k)
        // Inverse: src = tap + (dst - tap) / (1 - k)
        float denom = max(1.0 - k, 0.01);
        sampleUV = tapUV + (sampleUV - tapUV) / denom;

        // Wrinkle displacement (tangential)
        if (uWrinkles > 0.0 && dist > 0.001) {
            float angle = atan(deltaCorr.y, deltaCorr.x);
            float wrinklePhase = sin(angle * uWrinkles);

            // Tangential direction (perpendicular to radial, undo aspect)
            vec2 radialDir = normalize(deltaCorr);
            vec2 tangentDir = vec2(-radialDir.y, radialDir.x);
            tangentDir.x /= aspect;

            float wrinkleStrength = wrinklePhase * uWrinkleDepth * k;
            sampleUV += tangentDir * wrinkleStrength * uRadius * 0.05;

            // Fold shading: brightness modulation for 3D appearance
            float shade = 1.0 - uFoldShading * abs(wrinklePhase) * k * 0.5;
            totalShading *= shade;
        }

        // Fade center to transparent as cloth is sucked up
        float fade = smoothstep(0.85, 0.95, k);
        totalFade = max(totalFade, fade);
    }

    // Out-of-bounds sample = cloth pulled away, reveal transparency
    if (sampleUV.x < 0.0 || sampleUV.x > 1.0 ||
        sampleUV.y < 0.0 || sampleUV.y > 1.0) {
        fragColor = vec4(0.0);
        return;
    }

    vec4 tex = texture(uTexture, sampleUV);
    float alpha = 1.0 - totalFade;
    fragColor = vec4(tex.rgb * totalShading * alpha, tex.a * alpha);
}

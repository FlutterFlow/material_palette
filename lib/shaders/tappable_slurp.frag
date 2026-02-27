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

// ============ HASH FUNCTION ============

float hash21(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

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

    // Accumulate displacement and shading across all taps
    vec2 totalDisplacement = vec2(0.0);
    float totalFade = 0.0;
    float totalShading = 1.0;

    for (int i = 0; i < 10; i++) {
        if (i >= clickCount) break;

        float progress = uTimes[i];
        if (progress <= 0.0) continue;

        // Tap position in UV space
        vec2 tapUV = uTouchPoints[i] / uSize;

        // Distance from tap (aspect-corrected)
        vec2 delta = uv - tapUV;
        delta.x *= aspect;
        float dist = length(delta);

        // Normalized distance within radius
        float normDist = dist / max(uRadius, 0.001);

        // Pull factor: strong near tap, zero at edge
        float falloff = max(1.0 - normDist, 0.0);
        float k = progress * pow(falloff, uGravity);

        // Per-pixel noise to break circular symmetry
        float noise = hash21(floor(fragCoord * 0.5)) * 0.15;
        k = clamp(k + noise * k, 0.0, 1.0);

        // Inverse displacement: gather texture toward tap
        float denom = max(1.0 - k * 0.95, 0.05);
        vec2 displacement = (uv - tapUV) / denom - (uv - tapUV);
        // Correct for the fact delta.x was aspect-scaled but displacement shouldn't be
        totalDisplacement += displacement;

        // Wrinkle displacement (tangential)
        if (uWrinkles > 0.0 && dist > 0.001) {
            float angle = atan(delta.y, delta.x);
            float wrinklePhase = sin(angle * uWrinkles);

            // Tangential direction (perpendicular to radial)
            vec2 radialDir = normalize(delta);
            vec2 tangentDir = vec2(-radialDir.y, radialDir.x);
            // Undo aspect correction for tangent direction
            tangentDir.x /= aspect;

            float wrinkleStrength = wrinklePhase * uWrinkleDepth * k * falloff;
            totalDisplacement += tangentDir * wrinkleStrength * uRadius * 0.1;

            // Fold shading: brightness modulation
            float shade = 1.0 - uFoldShading * abs(wrinklePhase) * k * 0.5;
            totalShading *= shade;
        }

        // Fade to transparent as cloth is sucked up
        float fade = smoothstep(0.85, 0.95, k);
        totalFade = max(totalFade, fade);
    }

    // Sample texture from displaced position
    vec2 sampleUV = uv + totalDisplacement;
    sampleUV = clamp(sampleUV, vec2(0.0), vec2(1.0));

    vec4 tex = texture(uTexture, sampleUV);

    // Apply fold shading and fade
    float alpha = 1.0 - totalFade;
    fragColor = vec4(tex.rgb * totalShading * alpha, tex.a * alpha);
}

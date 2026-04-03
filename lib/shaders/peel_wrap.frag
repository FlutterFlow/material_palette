#include <flutter/runtime_effect.glsl>

precision highp float;

// Standard header
uniform vec2 uSize;
uniform float uTime;       // Peel progress: 0 = flat, 1 = fully peeled

// Peel params
uniform float uCurlRadius;     // Radius of the curl cylinder in pixels
uniform float uShadowStrength; // Shadow darkness behind the curl (0 = none)

// Child texture (sampler index 0, auto-bound by ShaderWrap)
uniform sampler2D uTexture;

out vec4 fragColor;

#define PI 3.14159265359

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uSize;

    // Fold line moves from right edge (time=0) to left edge (time=1)
    float foldX = uSize.x * (1.0 - uTime);
    float r = max(uCurlRadius, 1.0);

    // Distance from the fold line (positive = right of fold)
    float d = fragCoord.x - foldX;

    // ── Zone 1: Flat region (left of fold) ──────────────────────────
    if (d < 0.0) {
        fragColor = texture(uTexture, uv);
        return;
    }

    // ── Zone 2: Curl zone (within radius of fold) ───────────────────
    if (d <= r) {
        float theta = asin(d / r);

        // Front face: the part curling up toward the viewer
        // Arc length along cylinder = theta * r
        float frontSrcX = foldX + theta * r;
        vec2 frontUV = vec2(frontSrcX / uSize.x, uv.y);

        // Back face: the underside curling over
        // Arc length = (PI - theta) * r
        float backSrcX = foldX + (PI - theta) * r;
        vec2 backUV = vec2(backSrcX / uSize.x, uv.y);

        // Back face is closer to viewer (draws on top)
        if (backUV.x >= 0.0 && backUV.x <= 1.0) {
            vec4 backColor = texture(uTexture, backUV);
            // Shade based on angle — darker toward the fold
            float shade = 0.6 + 0.4 * cos(theta);
            backColor.rgb *= shade;
            fragColor = backColor;
        } else if (frontUV.x >= 0.0 && frontUV.x <= 1.0) {
            vec4 frontColor = texture(uTexture, frontUV);
            // Darken front face as it curls away
            float shade = pow(clamp((r - d) / r, 0.0, 1.0), 0.2);
            frontColor.rgb *= shade;
            fragColor = frontColor;
        } else {
            // Shadow on the surface beneath
            float shadowFade = 1.0 - d / r;
            fragColor = vec4(0.0, 0.0, 0.0, uShadowStrength * shadowFade);
        }
        return;
    }

    // ── Zone 3: Past the curl (peeled away) ─────────────────────────
    // Transparent with fading shadow
    float shadowFade = clamp(1.0 - (d - r) / r, 0.0, 1.0);
    fragColor = vec4(0.0, 0.0, 0.0, uShadowStrength * shadowFade * 0.5);
}

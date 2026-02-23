#include <flutter/runtime_effect.glsl>

precision highp float;

// Core uniforms
uniform vec2 uSize;
uniform float uTime;          // elapsed time in seconds

// Radial center & scale
uniform float uCenterX;      // 0.0–1.0, default 0.5
uniform float uCenterY;      // 0.0–1.0, default 0.5
uniform float uScale;        // controls dissolve reach, default 1.0

// Pixel dissolve params
uniform float uPixelSize;     // size of each pixel block in screen pixels
uniform float uEdgeWidth;     // dissolve transition zone width
uniform float uScatter;       // scatter intensity (0 = no movement)
uniform float uNoiseAmount;   // per-cell randomness in dissolve timing

// Child texture
uniform sampler2D uTexture;

out vec4 fragColor;

// ============ HASH FUNCTION ============

float hash21(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

// ============ MAIN ============

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uSize;

    // Aspect ratio correction for circular dissolve
    float aspect = uSize.x / uSize.y;
    vec2 center = vec2(uCenterX, uCenterY);

    // Progress is now 0-1, computed in Dart
    float progress = uTime;

    // Cell size in UV space
    vec2 cellSizeUV = vec2(uPixelSize) / uSize;

    // Compute max radial distance so dissolve starts and ends fully off-screen
    float scatterMargin = uScatter * max(cellSizeUV.x, cellSizeUV.y) * 5.0;
    float margin = scatterMargin + uEdgeWidth;

    float maxDeltaX = max(uCenterX, 1.0 - uCenterX) * aspect;
    float maxDeltaY = max(uCenterY, 1.0 - uCenterY);
    float maxBase = sqrt(maxDeltaX * maxDeltaX + maxDeltaY * maxDeltaY)
                    / (0.5 * uScale);
    float offset = margin + uEdgeWidth;
    float sweepRange = maxBase + 2.0 * uEdgeWidth + 2.0 * margin;

    // Check 5x5 neighborhood of cells for scattered pixels that land here
    vec2 currentCell = floor(fragCoord / uPixelSize);

    vec4 result = vec4(0.0);
    float bestDepth = -1.0;

    for (int dy = -2; dy <= 2; dy++) {
        for (int dx = -2; dx <= 2; dx++) {
            vec2 neighborCell = currentCell + vec2(float(dx), float(dy));

            // Cell center in UV space
            vec2 cellCenterUV = (neighborCell + 0.5) * cellSizeUV;

            // Radial distance from center (aspect-corrected)
            vec2 delta = cellCenterUV - center;
            delta.x *= aspect;
            float dist = length(delta);
            float normalizedDist = dist / (0.5 * uScale);

            // Per-cell random values
            float cellRand = hash21(neighborCell);
            vec2 cellRand2 = hash22(neighborCell + 127.0);

            // Per-cell dissolve threshold
            float noiseOffset = (cellRand - 0.5) * uEdgeWidth * uNoiseAmount;
            float cellThreshold = normalizedDist + noiseOffset + offset;

            // How far this cell is into its dissolve (0 = solid, 1 = fully gone)
            float cellDissolve = clamp((progress * sweepRange - cellThreshold) / max(uEdgeWidth * 0.5, 0.001), 0.0, 1.0);

            // Skip fully solid cells from non-origin positions
            if (cellDissolve <= 0.0 && (dx != 0 || dy != 0)) continue;
            // Skip fully dissolved cells
            if (cellDissolve >= 1.0) continue;

            // Scatter direction: outward from center with per-cell random variation
            vec2 outDir = normalize(delta + vec2(0.001));
            vec2 scatterDir = outDir + (cellRand2 - 0.5) * 0.8;
            vec2 scatterOffset = scatterDir * cellDissolve * uScatter * cellSizeUV * 5.0;

            // Where does this cell's pixel block land after scatter?
            vec2 scatteredCellOrigin = neighborCell * uPixelSize + scatterOffset * uSize;

            // Does the current fragment fall inside this scattered block?
            vec2 localPos = fragCoord - scatteredCellOrigin;
            if (localPos.x < 0.0 || localPos.x >= uPixelSize ||
                localPos.y < 0.0 || localPos.y >= uPixelSize) continue;

            // Depth priority: cells closer to dissolve front render on top
            float depth = cellDissolve;
            if (depth > bestDepth) {
                bestDepth = depth;

                // Sample texture from the original position within this cell
                vec2 sampleUV = (neighborCell * uPixelSize + localPos) / uSize;
                sampleUV = clamp(sampleUV, vec2(0.0), vec2(1.0));
                vec4 tex = texture(uTexture, sampleUV);

                // Fade out as cell dissolves
                float alpha = 1.0 - cellDissolve;
                result = vec4(tex.rgb * alpha, tex.a * alpha);
            }
        }
    }

    // If no scattered cell covers this fragment, check if original cell is still solid
    if (bestDepth < 0.0) {
        vec2 cellCenterUV = (currentCell + 0.5) * cellSizeUV;
        vec2 delta = cellCenterUV - center;
        delta.x *= aspect;
        float dist = length(delta);
        float normalizedDist = dist / (0.5 * uScale);

        float cellRand = hash21(currentCell);
        float noiseOffset = (cellRand - 0.5) * uEdgeWidth * uNoiseAmount;
        float cellThreshold = normalizedDist + noiseOffset + offset;
        float cellDissolve = clamp((progress * sweepRange - cellThreshold) / max(uEdgeWidth * 0.5, 0.001), 0.0, 1.0);

        if (cellDissolve <= 0.0) {
            // Cell is fully solid - pass through original texture at full resolution
            result = texture(uTexture, uv);
        }
    }

    fragColor = result;
}

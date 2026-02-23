#include <flutter/runtime_effect.glsl>

precision highp float;

// Core uniforms
uniform vec2 uSize;
uniform float uClickCount;
uniform vec2 uTouchPoints[10];
uniform float uTimes[10];

// Pixel dissolve params
uniform float uPixelSize;     // size of each pixel block in screen pixels
uniform float uEdgeWidth;     // dissolve transition zone width
uniform float uScatter;       // scatter intensity (0 = no movement)
uniform float uNoiseAmount;   // per-cell randomness in dissolve timing
uniform float uRadius;        // radius of each tap dissolve

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
    float aspect = uSize.x / uSize.y;
    int clickCount = int(uClickCount);

    // If no taps, just show the texture
    if (clickCount == 0) {
        fragColor = texture(uTexture, uv);
        return;
    }

    // Cell size in UV space
    vec2 cellSizeUV = vec2(uPixelSize) / uSize;

    // Margin so each tap's dissolve starts and ends fully invisible
    float scatterMargin = uScatter * max(cellSizeUV.x, cellSizeUV.y) * 5.0;
    float margin = scatterMargin + uEdgeWidth;
    float offset = margin + uEdgeWidth;
    float sweepRange = 1.0 + 2.0 * uEdgeWidth + 2.0 * margin;

    // Check 5x5 neighborhood of cells for scattered pixels that land here
    vec2 currentCell = floor(fragCoord / uPixelSize);

    vec4 result = vec4(0.0);
    float bestDepth = -1.0;

    for (int dy = -2; dy <= 2; dy++) {
        for (int dx = -2; dx <= 2; dx++) {
            vec2 neighborCell = currentCell + vec2(float(dx), float(dy));

            // Cell center in UV space
            vec2 cellCenterUV = (neighborCell + 0.5) * cellSizeUV;

            // Per-cell random values
            float cellRand = hash21(neighborCell);
            vec2 cellRand2 = hash22(neighborCell + 127.0);

            // Find the maximum dissolve across all active taps for this cell
            float maxCellDissolve = 0.0;
            vec2 bestScatterDir = vec2(0.0);

            for (int i = 0; i < 10; i++) {
                if (i >= clickCount) break;

                // Per-tap progress is now 0-1, computed in Dart
                float tapProgress = uTimes[i];

                // Radial distance from this tap point (aspect-corrected)
                vec2 origin = uTouchPoints[i] / uSize;
                vec2 delta = cellCenterUV - origin;
                delta.x *= aspect;
                float dist = length(delta);
                float normalizedDist = dist / (uRadius * 0.5);

                // Per-cell dissolve threshold
                float noiseOffset = (cellRand - 0.5) * uEdgeWidth * uNoiseAmount;
                float cellThreshold = normalizedDist + noiseOffset + offset;

                float cellDissolve = clamp((tapProgress * sweepRange - cellThreshold) / max(uEdgeWidth * 0.5, 0.001), 0.0, 1.0);

                if (cellDissolve > maxCellDissolve) {
                    maxCellDissolve = cellDissolve;
                    bestScatterDir = normalize(delta + vec2(0.001));
                }
            }

            // Skip fully solid cells from non-origin positions
            if (maxCellDissolve <= 0.0 && (dx != 0 || dy != 0)) continue;
            // Skip fully dissolved cells
            if (maxCellDissolve >= 1.0) continue;

            // Scatter direction: outward from tap center with per-cell random variation
            vec2 scatterDir = bestScatterDir + (cellRand2 - 0.5) * 0.8;
            vec2 scatterOffset = scatterDir * maxCellDissolve * uScatter * cellSizeUV * 5.0;

            // Where does this cell's pixel block land after scatter?
            vec2 scatteredCellOrigin = neighborCell * uPixelSize + scatterOffset * uSize;

            // Does the current fragment fall inside this scattered block?
            vec2 localPos = fragCoord - scatteredCellOrigin;
            if (localPos.x < 0.0 || localPos.x >= uPixelSize ||
                localPos.y < 0.0 || localPos.y >= uPixelSize) continue;

            // Depth priority: cells closer to dissolve front render on top
            float depth = maxCellDissolve;
            if (depth > bestDepth) {
                bestDepth = depth;

                // Sample texture from the original position within this cell
                vec2 sampleUV = (neighborCell * uPixelSize + localPos) / uSize;
                sampleUV = clamp(sampleUV, vec2(0.0), vec2(1.0));
                vec4 tex = texture(uTexture, sampleUV);

                // Fade out as cell dissolves
                float alpha = 1.0 - maxCellDissolve;
                result = vec4(tex.rgb * alpha, tex.a * alpha);
            }
        }
    }

    // If no scattered cell covers this fragment, check if original cell is still solid
    if (bestDepth < 0.0) {
        vec2 cellCenterUV = (currentCell + 0.5) * cellSizeUV;
        float cellRand = hash21(currentCell);

        float maxCellDissolve = 0.0;
        for (int i = 0; i < 10; i++) {
            if (i >= clickCount) break;

            // Per-tap progress is now 0-1, computed in Dart
            float tapProgress = uTimes[i];

            vec2 origin = uTouchPoints[i] / uSize;
            vec2 delta = cellCenterUV - origin;
            delta.x *= aspect;
            float dist = length(delta);
            float normalizedDist = dist / (uRadius * 0.5);

            float noiseOffset = (cellRand - 0.5) * uEdgeWidth * uNoiseAmount;
            float cellThreshold = normalizedDist + noiseOffset + offset;
            float cellDissolve = clamp((tapProgress * sweepRange - cellThreshold) / max(uEdgeWidth * 0.5, 0.001), 0.0, 1.0);

            maxCellDissolve = max(maxCellDissolve, cellDissolve);
        }

        if (maxCellDissolve <= 0.0) {
            // Cell is fully solid - pass through original texture at full resolution
            result = texture(uTexture, uv);
        }
    }

    fragColor = result;
}

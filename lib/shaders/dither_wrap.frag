#include <flutter/runtime_effect.glsl>

precision highp float;

// Standard header
uniform vec2 uSize;
uniform float uTime;

// Dither params
uniform float uDitherScale;
uniform float uColorSteps;

// Child texture (sampler index 0, auto-bound by ShaderWrap)
uniform sampler2D uTexture;

out vec4 fragColor;

// Proper 4x4 Bayer ordered dither (16 distinct thresholds)
float orderedDither(vec2 p) {
    vec2 cell = mod(floor(p), 4.0);
    float bx0 = mod(cell.x, 2.0);
    float by0 = mod(cell.y, 2.0);
    float bx1 = floor(cell.x / 2.0);
    float by1 = floor(cell.y / 2.0);
    float fine   = mod(bx0 * 2.0 + by0 * 3.0, 4.0);
    float coarse = mod(bx1 * 2.0 + by1 * 3.0, 4.0);
    float bayer = (fine * 4.0 + coarse + 0.5) / 16.0;
    return (bayer - 0.5) * 2.0;
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;

    // Snap to dither pixel grid
    float cellSize = 1.0 / max(uDitherScale, 0.001);
    vec2 cellCoord = floor(fragCoord / cellSize);
    vec2 quantized = (cellCoord + 0.5) * cellSize;

    // Sample child at quantized coordinate
    vec2 uv = quantized / uSize;
    vec4 image = texture(uTexture, uv);

    // Bayer dither bias
    float dither = orderedDither(cellCoord);
    float steps = max(floor(uColorSteps), 1.0);

    // Compute luminance
    float lum = dot(vec3(0.2126, 0.7152, 0.0722), image.rgb);

    // Quantize luminance with dither bias
    float brightness = clamp(lum + dither / steps, 0.0, 1.0);
    float quantLum = floor(brightness * steps + 0.5) / steps;

    // Reconstruct original colors at quantized brightness.
    // For very dark pixels, fall back to grayscale to avoid
    // amplifying noise through the division.
    vec3 color;
    if (lum > 0.02) {
        color = image.rgb * (quantLum / lum);
    } else {
        color = vec3(quantLum);
    }

    fragColor = vec4(clamp(color, 0.0, 1.0) * image.a, image.a);
}

#include <flutter/runtime_effect.glsl>

precision highp float;

// ============================================================
//  Anisotropic Kuwahara filter — painterly / edge-preserving
//  smoothing filter ported from a Shadertoy single-pass impl.
//
//  Per output pixel:
//   1. Structure tensor via 4 bilinear taps (each tap is a free
//      2×2 box average), folded into a 2×2 symmetric tensor J
//      in colour space.
//   2. Eigendecomposition → principal direction + anisotropy
//      A = (λ1-λ2)/(λ1+λ2).
//   3. Build an anisotropic ellipse, rotated by the principal
//      direction and elongated by A (alpha controls how much).
//   4. Split the ellipse into SECTOR_COUNT angular slices; take
//      weighted mean / luma variance of each.
//   5. Output the mean colour of the lowest-variance sector.
//      Sectors that straddle an edge get rejected → edges are
//      preserved while flat regions look like brush strokes.
// ============================================================

// Standard header
uniform vec2  uSize;
uniform float uTime;

// Kuwahara params
uniform float uKernelRadius; // Sampling radius in pixels (1..6)
uniform float uSharpness;    // Anisotropic elongation bias (higher = rounder)

// Child texture (sampler index 0, auto-bound by ShaderWrap)
uniform sampler2D uTexture;

out vec4 fragColor;

#define SECTOR_COUNT    8   // angular sectors around the kernel
#define SECTOR_SAMPLES  5   // angular samples within each sector
#define MAX_RADIUS      16  // upper bound for the dynamic radius loop

const float PI          = 3.14159265;
const float HALF_SECTOR = PI / float(SECTOR_COUNT);

// ------------------------------------------------------------
//  Colour space. Averaging is only physically correct in linear
//  RGB, so linearise on read and re-encode on write.
// ------------------------------------------------------------
vec3 toLinear(vec3 srgb)     { return pow(srgb, vec3(2.2)); }
vec3 fromLinear(vec3 linRGB) { return pow(linRGB, vec3(1.0 / 2.2)); }

// Returns linear-RGB with alpha preserved, so callers can weight by
// alpha to exclude off-canvas / transparent samples. At large kernel
// radii the ellipse routinely reaches outside the wrapped layer; the
// default sampler returns (0,0,0,0) there, which would otherwise pull
// the sector mean toward black.
vec4 sampleColorA(vec2 pixelCoord) {
    vec4 c = texture(uTexture, pixelCoord / uSize.xy);
    return vec4(toLinear(c.rgb), c.a);
}

vec3 sampleColor(vec2 pixelCoord) {
    return sampleColorA(pixelCoord).rgb;
}

// ------------------------------------------------------------
//  Structure tensor via 4 bilinear taps on pixel corners.
//  Linear filtering hands back the 2×2 box-averaged colour for
//  each tap "for free"; the four quadrants then fold into
//  standard 3×3 Sobel gradients in RGB.
// ------------------------------------------------------------
vec3 structureTensor(vec2 pixelCoord) {
    vec3 ul = sampleColor(pixelCoord + vec2(-0.5, -0.5));
    vec3 ur = sampleColor(pixelCoord + vec2( 0.5, -0.5));
    vec3 ll = sampleColor(pixelCoord + vec2(-0.5,  0.5));
    vec3 lr = sampleColor(pixelCoord + vec2( 0.5,  0.5));

    vec3 gx = (ur + lr) - (ul + ll);
    vec3 gy = (ll + lr) - (ul + ur);

    return vec3(dot(gx, gx), dot(gy, gy), dot(gx, gy));
}

// ------------------------------------------------------------
//  Eigendecomposition of the 2×2 symmetric tensor.
//  Returns principal direction (xy) and anisotropy (z).
// ------------------------------------------------------------
vec3 orient(vec3 J) {
    float Jxx = J.x, Jyy = J.y, Jxy = J.z;
    float trace        = Jxx + Jyy;
    float determinant  = Jxx * Jyy - Jxy * Jxy;
    float discriminant = sqrt(max(0.0, 0.25 * trace * trace - determinant));

    float lambda1 = 0.5 * trace + discriminant;
    float lambda2 = 0.5 * trace - discriminant;

    // Principal eigenvector: solve (J - λ1·I)·v = 0 using the
    // heavier row — avoids the degenerate axis-aligned edge case.
    vec2 row1 = vec2(Jxx - lambda1, Jxy);
    vec2 row2 = vec2(Jxy, Jyy - lambda1);
    vec2 dir  = dot(row1, row1) > dot(row2, row2)
        ? vec2(Jxy, lambda1 - Jxx)
        : vec2(lambda1 - Jyy, Jxy);
    dir = dot(dir, dir) > 1e-12 ? normalize(dir) : vec2(1.0, 0.0);

    float anisotropy = (lambda1 - lambda2) / (lambda1 + lambda2 + 1e-6);
    return vec3(dir, anisotropy);
}

// Per-sample weighting from the paper: favours samples near the
// sector's +x axis and penalises y-offsets.
float polyWeight(vec2 samplePos) {
    const float eta = 0.1, lambda = 0.5;
    float poly = (samplePos.x + eta) - lambda * samplePos.y * samplePos.y;
    return max(0.0, poly * poly);
}

// ------------------------------------------------------------
//  Mean colour + luma variance of one sector.
//  Sampled on an arc swept from r=1..kernelRadius and bent into
//  an ellipse by `kernelMat`. Returns (mean.rgb, variance).
// ------------------------------------------------------------
vec4 sectorStats(
    mat2 kernelMat,
    float sectorAngle,
    vec2 pixelCoord,
    int kernelRadius
) {
    vec3  weightedColorSum   = vec3(0.0);
    vec3  weightedColorSqSum = vec3(0.0);
    float totalWeight        = 0.0;

    for (int radiusStep = 0; radiusStep < MAX_RADIUS; radiusStep++) {
        if (radiusStep >= kernelRadius) break;
        float sampleRadius = float(radiusStep) + 1.0;
        for (int angleStep = 0; angleStep < SECTOR_SAMPLES; angleStep++) {
            float t = float(angleStep) / float(SECTOR_SAMPLES - 1);
            float sampleAngle = sectorAngle + mix(-HALF_SECTOR, HALF_SECTOR, t);

            vec2 offset = sampleRadius * vec2(cos(sampleAngle), sin(sampleAngle));
            offset *= kernelMat;  // bend into the anisotropic ellipse

            vec4  tap    = sampleColorA(pixelCoord + offset);
            // Weight by polyWeight × alpha. Samples that land outside
            // the canvas (or on transparent child pixels) have alpha ≈ 0
            // and drop out of the mean — preventing black smudges in
            // the corners at large kernel radii.
            float weight = polyWeight(offset) * tap.a;

            weightedColorSum   += weight * tap.rgb;
            weightedColorSqSum += weight * tap.rgb * tap.rgb;
            totalWeight        += weight;
        }
    }

    // If the whole sector landed off-canvas, return a sentinel high
    // variance so a neighbouring in-canvas sector wins the min.
    if (totalWeight < 1e-3) {
        return vec4(0.0, 0.0, 0.0, 1e6);
    }

    vec3 mean     = weightedColorSum / totalWeight;
    vec3 variance = weightedColorSqSum / totalWeight - mean * mean;
    return vec4(mean, dot(variance, vec3(0.299, 0.587, 0.114)));
}

// ------------------------------------------------------------
//  Entry point.
// ------------------------------------------------------------
void main() {
    vec2 fragCoord = FlutterFragCoord().xy;

    // Preserve transparent pixels so the wrapped child's alpha
    // shape (e.g. rounded corners, masked regions) is respected.
    vec4 center = texture(uTexture, fragCoord / uSize.xy);
    if (center.a < 0.001) {
        fragColor = vec4(0.0);
        return;
    }

    vec3 ori = orient(structureTensor(fragCoord));
    vec2 dir = ori.xy;
    float anisotropy = ori.z;

    // Ellipse elongation. `alpha` controls the max stretch/squeeze.
    float alpha   = max(uSharpness, 1.0);
    float squeeze = alpha / (anisotropy + alpha);     // ≤ 1
    float stretch = (anisotropy + alpha) / alpha;     // ≥ 1

    // Rotate + scale into the anisotropic kernel frame.
    mat2 rotation  = mat2( dir.x, -dir.y,
                           dir.y,  dir.x);
    mat2 scaling   = mat2(squeeze, 0.0, 0.0, stretch);
    mat2 kernelMat = rotation * scaling;

    // Clamp the radius into [1, MAX_RADIUS] integer range.
    int kernelRadius = int(clamp(uKernelRadius, 1.0, float(MAX_RADIUS)) + 0.5);

    // Scan sectors, keep the one with the lowest variance.
    vec4 best = sectorStats(kernelMat, 0.0, fragCoord, kernelRadius);
    for (int i = 1; i < SECTOR_COUNT; i++) {
        float sectorAngle = float(i) * 2.0 * PI / float(SECTOR_COUNT);
        vec4 sector = sectorStats(kernelMat, sectorAngle, fragCoord, kernelRadius);
        if (sector.w < best.w) best = sector;
    }

    // Every sector landed off-canvas (1×1-ish images, or a corner with a
    // hugely elongated kernel). Fall back to the raw centre pixel.
    if (best.w > 1e5) {
        fragColor = center;
        return;
    }

    fragColor = vec4(fromLinear(best.rgb) * center.a, center.a);
}

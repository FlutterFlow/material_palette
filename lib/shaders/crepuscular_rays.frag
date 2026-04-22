// =============================================================================
//  Crepuscular Rays (God Rays) — Flutter wrap shader
//  Algorithm: GPU Gems 3, Ch. 13 "Volumetric Light Scattering as a Post-Process"
//
//  The child widget texture supplies BOTH the base scene color AND the
//  occlusion mask. Any opaque pixel (alpha > 0) is treated as an occluder;
//  transparent pixels are treated as sky/sun (light passes through).
// =============================================================================
#include <flutter/runtime_effect.glsl>

precision highp float;

// Standard header
uniform vec2  uSize;        // viewport size in pixels
uniform float uTime;        // seconds since start

// Ray params
uniform vec2  uSunPos;      // sun anchor in 0..1 UV space (orbit center)
uniform float uSunRadius;   // soft sun disc radius in screen units, e.g. 0.11
uniform float uExposure;    // overall brightness of the rays, e.g. 0.17
uniform float uDecay;       // per-step falloff; closer to 1.0 = longer rays, e.g. 0.965
uniform float uDensity;     // step length; larger = rays spread further, e.g. 0.85
uniform float uWeight;      // per-sample contribution to the sum, e.g. 0.25
uniform float uOrbitRadius; // orbit amplitude around uSunPos, 0.0 pins the sun
uniform float uOrbitSpeed;  // orbit angular speed (radians/sec at orbit radius 1)
uniform float uShowSun;     // 0..1 opacity of the explicit sun disc overlay
uniform vec3  uSunColor;    // warm sunlight tint, e.g. vec3(1.00, 0.85, 0.55)
uniform vec3  uSunDiscColor; // tint of the sun disc overlay (separate from rays)
uniform vec4  uPassColor;   // color that counts as "light passes" in the mask
                            // (straight alpha; default vec4(0) = transparency)

// Child texture (sampler index 0, auto-bound by ShaderWrap)
uniform sampler2D uTexture;

out vec4 fragColor;

#define NUM_SAMPLES 96

// Cheap per-pixel hash for jittering the ray-march start. Breaks the coherent
// banding you get when the stride between samples grows large (i.e. when the
// pixel is far from the sun) by decorrelating neighboring pixels' sample
// positions, turning stripes into high-frequency noise.
float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// Slow orbit around uSunPos so the effect is visibly alive.
// For a pinned sun, pass uOrbitRadius = 0.
//
// The orbit is measured in y-normalized units and divided by aspect on x,
// so non-square viewports trace a circle in pixel space rather than an
// ellipse. This matches how uSunRadius is measured in sunDisc().
vec2 getSunUV() {
    float t = uTime * uOrbitSpeed;
    float aspect = uSize.x / uSize.y;
    return uSunPos + uOrbitRadius * vec2(cos(t) / aspect, sin(t));
}

// Aspect-corrected soft sun disc — provides a bright core behind the mask so
// rays have a source even when the user's mask doesn't explicitly draw the sun.
float sunDisc(vec2 uv, vec2 sunUV) {
    vec2 d = uv - sunUV;
    d.x *= uSize.x / uSize.y;
    return smoothstep(uSunRadius, 0.0, length(d));
}

// How much the given pixel counts as "light passes" under the current mask
// rules. Two modes, keyed off uPassColor.a:
//   • Transparent pass color (alpha == 0) — classic alpha-driven mask:
//     mask = 1.0 - pixel.a, so transparent pixels fully pass, opaque pixels
//     block, semi-transparent pixels give a proportional partial pass.
//   • Non-transparent pass color — strict exact match, all-or-nothing.
//     A pixel either lands exactly on uPassColor (full pass) or it doesn't
//     (full block); bilinear-filtered anti-aliased edges fall outside the
//     tiny epsilon so boundaries read as crisp ray edges.
float passMatch(vec4 pixel) {
    // The child texture is premultiplied, so premultiply uPassColor to match.
    vec4  passPm  = vec4(uPassColor.rgb * uPassColor.a, uPassColor.a);
    float partial = 1.0 - pixel.a;
    float exact   = step(length(pixel - passPm), 1.0 / 255.0);
    return uPassColor.a > 0.0 ? exact : partial;
}

// Combined occlusion sample for the ray-march: either the pixel passes light
// (via passMatch) OR the synthetic sun disc contributes. The sun light source
// is gated on uShowSun so "Draw sun disc = off" also prevents the ray-march
// from converging on a virtual disc at the sun's position.
float sampleMask(vec2 uv, vec2 sunUV) {
    float inside = step(0.0, uv.x) * step(uv.x, 1.0)
                 * step(0.0, uv.y) * step(uv.y, 1.0);
    float match = passMatch(texture(uTexture, uv));
    float sun   = sunDisc(uv, sunUV) * uShowSun;
    return max(match, sun) * inside;
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv    = fragCoord / uSize;
    vec2 sunUV = getSunUV();

    // Radial march from the current pixel toward the sun in screen space.
    // Each step samples the occlusion mask and accumulates with exponential
    // decay — this is Eq. 3 from the GPU Gems chapter.
    vec2  deltaUV = (uv - sunUV) * (uDensity / float(NUM_SAMPLES));
    // Offset the start by up to one step so neighboring pixels don't all
    // land on the same occluder edges — kills the aliased banding.
    float jitter  = hash12(fragCoord);
    vec2  coord   = uv - deltaUV * jitter;
    float illum   = 1.0;
    float rays    = 0.0;
    for (int i = 0; i < NUM_SAMPLES; i++) {
        coord -= deltaUV;
        float s = sampleMask(coord, sunUV) * illum * uWeight;
        rays  += s;
        illum *= uDecay;
    }
    rays *= uExposure;

    // Composite preserving transparency. Everything is done in premultiplied
    // space — no un-premult divide — so the output varies smoothly across the
    // alpha == 0 boundary. Amplifying stray color bleed from texture filtering
    // at low-alpha edges was what produced the hard contrast seam at the FBM
    // cloud boundaries.
    vec4 base = texture(uTexture, uv); // premultiplied

    // Ray light: clamp to [0,1] so the screen-blend math stays well-behaved
    // even when exposure accumulates above 1.0.
    vec3  rayColor = clamp(uSunColor * rays, 0.0, 1.0);
    float rayAlpha = clamp(rays, 0.0, 1.0);

    // Sun disc: a layer behind the child, visible through pixels that count
    // as "pass" under the current mask (passMatch). With the default
    // transparent pass color, passMatch == 1 - base.a so this reduces to
    // standard SrcOver; with a color pass, the disc shines through the
    // exact-match regions and is hidden everywhere else — including
    // transparent child pixels, which do *not* match a non-zero pass color.
    float discAlpha = sunDisc(uv, sunUV) * uShowSun;
    vec3  discRgbPm = clamp(uSunDiscColor * discAlpha, 0.0, 1.0);
    float baseMatch = passMatch(base);

    vec3  sceneRgb = clamp(base.rgb + discRgbPm * baseMatch, 0.0, 1.0);
    float sceneA   = clamp(base.a   + discAlpha  * baseMatch, 0.0, 1.0);

    // Screen-blend the ray light onto the scene using the premultiplied-space
    // identity  screen_un(scene, ray) * sceneA
    //       ==  sceneRgb + sceneA*ray - sceneRgb*ray
    // which avoids the /sceneA divide that caused the hard seam at sceneA==0.
    vec3 litRgb = sceneRgb + sceneA * rayColor - sceneRgb * rayColor;

    // Rays visible in the still-uncovered portion of the frame (open sky).
    litRgb += rayColor * rayAlpha * (1.0 - sceneA);

    // Light "over" scene for final alpha: opaque scene stays opaque, open
    // sky picks up rayAlpha, dead zones remain fully transparent.
    float outA = sceneA + rayAlpha * (1.0 - sceneA);

    fragColor = vec4(litRgb, outA);
}

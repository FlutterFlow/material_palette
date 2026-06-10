// BENCH VARIANT — DO NOT SHIP.
// Edit: minimal 1:1 child passthrough — isolates the AnimatedSampler
// child-capture (toImageSync) cost from any shader math.
#include <flutter/runtime_effect.glsl>
precision highp float;

uniform vec2 uSize;
uniform float uTime;
uniform sampler2D uTexture;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    // Keep uTime live so the uniform isn't compiled out (the harness always
    // writes size + time); visually a no-op.
    float keep = 1.0 + uTime * 1e-9;
    fragColor = texture(uTexture, uv) * keep;
}

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float uClickCount;
uniform vec2 uTouchPoints[10];
uniform float uTimes[10];       // Per-tap progress (0-1)
// Controllable ripple parameters
uniform float uAmplitude;      // Wave amplitude (default 0.07)
uniform float uFrequency;      // Wave frequency (default 15.0)
uniform float uDecay;          // How fast ripples fade (default 4.0)
uniform float uSpeed;          // How fast ripples propagate (default 2.0)
uniform float uRippleDuration; // Duration in seconds for each ripple
uniform vec4 uBgColor;         // Background color (RGBA, default transparent)
uniform sampler2D uTexture;

out vec4 fragColor;

void main()
{
    vec2 uv = FlutterFragCoord().xy / uSize;
    float aspect = uSize.x / uSize.y;
    int clickCount = int(uClickCount);

    // Sum displacements from all active ripples
    vec2 totalDisplacement = vec2(0.0);
    for (int i = 0; i < 10; i++) {
        if (i >= clickCount) break;

        vec2 origin = uTouchPoints[i] / uSize;
        
        // Calculate distance with aspect ratio correction for circular ripples
        vec2 delta = uv - origin;
        delta.x *= aspect;
        float dist = length(delta);

        // Convert 0-1 progress back to real time for wave propagation
        float realTime = uTimes[i] * uRippleDuration;

        // Delay ripple based on distance from click point
        float t = max(0.0, realTime - dist / uSpeed);

        // Damped sinusoidal wave
        float rippleAmount = uAmplitude * sin(uFrequency * t) * exp(-uDecay * t);
        
        // Direction for displacement (aspect-corrected, then normalized back to UV space)
        vec2 direction = uv - origin;
        direction.x *= aspect;
        direction = normalize(direction);
        direction.x /= aspect;
        totalDisplacement += rippleAmount * direction;
    }

    // Fade out ripple effect near edges to prevent discontinuities
    float edgeFade = 0.1;
    float fadeX = smoothstep(0.0, edgeFade, uv.x) * smoothstep(1.0, 1.0 - edgeFade, uv.x);
    float fadeY = smoothstep(0.0, edgeFade, uv.y) * smoothstep(1.0, 1.0 - edgeFade, uv.y);
    float fade = fadeX * fadeY;

    vec2 sampleUV = clamp(uv + totalDisplacement * fade, 0.001, 0.999);
    vec4 tex = texture(uTexture, sampleUV);
    // Composite texture over background using premultiplied-alpha "source over"
    vec4 bg = vec4(uBgColor.rgb * uBgColor.a, uBgColor.a);
    fragColor = tex + bg * (1.0 - tex.a);
}

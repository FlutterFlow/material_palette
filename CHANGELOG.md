## 1.0.0

- Fix dithering for gritty gradient and radial gritty gradient shaders.
- Add dither controls across all gradient shaders.
- Rename slider parameter for clarity.

## 0.8.0

- Add tappable slurp shader with gravity, wrinkle, and fold shading controls.
- Replace dirX/dirY with angle-based direction controls for burn, smoke, and pixel dissolve shaders.
- Simplify marble smear shader by internalizing lighting constants and cleaning up color roles.
- Fix aspect ratio handling in burn, smoke, and wrap shaders.
- Add shader presets and easing controls to the example app.

## 0.7.0

- Support for implicit animations of shader params.
- Update marble smear shader color handling.

## 0.6.0

- Add smoke and pixel dissolve shaders (with radial and tappable variants).
- Refactor animation system and fix error accumulation in continuous mode.
- Add handling for range and inverse parameters.
- Fix ripple and tap interactions.

## 0.5.0

- Add burn, radial burn, and tappable burn shaders.
- Improve gradient shaders with better controls and transparency support.
- Fix timescale for voronoi shaders.
- Update shader presets.

## 0.4.0

- Reinclude example app in pubdev

## 0.3.0

- Fixes for layer transparency, shader aspect ratio, unnecessary rebuilts, animatedsampler leak, color gamut in perlin noise.
- Add demo app in test/ for debugging wrap shaders.

## 0.2.0

- Testing publishing

## 0.1.0

- Initial release with procedural shader widgets

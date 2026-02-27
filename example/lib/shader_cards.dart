import 'package:flutter/material.dart';
import 'package:material_palette/material_palette.dart';

import 'shader_card_components.dart';

// ============ CONSTANTS ============

/// Background color used throughout the app
const Color backgroundColor = Color(0xFF202329);


/// Shader name constants, ShaderCardData, and allShaders are in shader_registry.dart.

/// Asset paths for shader card images (CC0 / no attribution required)
abstract class ShaderImageAssets {
  static const String ripples = 'assets/images/sunset.jpg';
  static const String taplets = 'assets/images/mountain.jpg';
  static const String burn = 'assets/images/sunset.jpg';
  static const String radialBurn = 'assets/images/sunset.jpg';
  static const String tapBurn = 'assets/images/mountain.jpg';
  static const String smoke = 'assets/images/sunset.jpg';
  static const String radialSmoke = 'assets/images/sunset.jpg';
  static const String tapSmoke = 'assets/images/mountain.jpg';
  static const String pixelDissolve = 'assets/images/sunset.jpg';
  static const String radialPixelDissolve = 'assets/images/sunset.jpg';
  static const String tapPixelDissolve = 'assets/images/mountain.jpg';
}

// ============ HELPERS ============

/// Responsive card dimensions helper
class CardDimensions {
  final double width;
  final double height;
  final double controlsWidth;

  const CardDimensions({
    required this.width,
    required this.height,
    required this.controlsWidth,
  });

  static CardDimensions of(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final availableHeight = size.height - 200; // Account for app bar, indicators, margins
    final availableWidth = size.width;
    
    // Calculate dimensions based on available space
    // Target aspect ratio of 3:5 (width:height)
    double height = (availableHeight * 0.75).clamp(200.0, 500.0);
    double width = (height * 0.6).clamp(150.0, 300.0);
    
    // Also constrain by available width
    final maxWidthFromScreen = availableWidth * 0.7;
    if (width > maxWidthFromScreen) {
      width = maxWidthFromScreen;
      height = width / 0.6;
    }
    
    // Controls width should fit the card width with some margin
    final controlsWidth = (availableWidth * 0.9).clamp(250.0, 400.0);
    
    return CardDimensions(
      width: width,
      height: height,
      controlsWidth: controlsWidth,
    );
  }
}

/// Helper class for generating preset code strings
class PresetGenerator {
  /// Format a Color as Dart code
  static String color(Color c) {
    return 'Color.fromRGBO(${(c.r * 255.0).round().clamp(0, 255)}, ${(c.g * 255.0).round().clamp(0, 255)}, ${(c.b * 255.0).round().clamp(0, 255)}, 1)';
  }
  
  /// Format a double with reasonable precision
  static String num(double v) {
    // Use fewer decimals for cleaner output
    if (v == v.roundToDouble()) {
      return v.toStringAsFixed(1);
    }
    return v.toStringAsFixed(2);
  }

  /// Format a ShaderParams as Dart code
  static String shaderParams(ShaderParams p) {
    final sb = StringBuffer('ShaderParams(\n  values: {\n');
    for (final e in p.values.entries) {
      sb.writeln("    '${e.key}': ${num(e.value)},");
    }
    sb.write('  },\n  colors: {\n');
    for (final e in p.colors.entries) {
      sb.writeln("    '${e.key}': ${color(e.value)},");
    }
    sb.write('  },\n)');
    return sb.toString();
  }
}

// ============ ANIMATION CURVE ENTRIES ============

class _CurveEntry {
  final String name;
  final Curve curve;
  const _CurveEntry(this.name, this.curve);
}

const _kCurveEntries = <_CurveEntry>[
  _CurveEntry('linear', Curves.linear),
  _CurveEntry('easeIn', Curves.easeIn),
  _CurveEntry('easeInOut', Curves.easeInOut),
  _CurveEntry('easeOut', Curves.easeOut),
  _CurveEntry('bounce', Curves.bounceOut),
  _CurveEntry('elastic', Curves.elasticInOut),
];

Widget _buildCurveChips({
  required int selectedIndex,
  required ValueChanged<int> onChanged,
}) {
  return Wrap(
    spacing: 4,
    runSpacing: 4,
    children: List.generate(_kCurveEntries.length, (i) {
      return ChoiceChip(
        label: Text(_kCurveEntries[i].name, style: const TextStyle(fontSize: 10)),
        selected: i == selectedIndex,
        onSelected: (_) => onChanged(i),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }),
  );
}

ShaderAnimationConfig _buildAnimConfig({
  required int curveIndex,
  required double durationSec,
  required double delaySec,
  required bool loop,
  required bool reverse,
  required bool invert,
  required double rangeStart,
  required double rangeEnd,
}) {
  return ShaderAnimationConfig(
    curve: _kCurveEntries[curveIndex].curve,
    duration: Duration(milliseconds: (durationSec * 1000).round()),
    delay: Duration(milliseconds: (delaySec * 1000).round()),
    loop: loop,
    reverse: reverse,
    invert: invert,
    rangeStart: rangeStart,
    rangeEnd: rangeEnd,
  );
}

// ============ SHADER CARD WIDGET ============

/// Main shader card widget that displays shader preview with title and description
class ShaderCard extends StatelessWidget {
  final ShaderCardData data;

  const ShaderCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final dimensions = CardDimensions.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      // Use ScrollConfiguration to hide outer scrollbar - only controls should show scrollbar
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Shader preview - each shader handles its own clipping
              _buildShaderPreview(dimensions),
              const SizedBox(height: 16),
              // Title and description
              Text(
                data.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShaderPreview(CardDimensions dimensions) {
    switch (data.title) {
      case ShaderNames.ripples:
        return RippleShaderCard(dimensions: dimensions);
      case ShaderNames.taplets:
        return ClickRippleShaderCard(dimensions: dimensions);
      case ShaderNames.smarble:
        return MarbleSmearShaderCard(dimensions: dimensions);
      case ShaderNames.gritient:
        return GrittyGradientShaderCard(dimensions: dimensions);
      case ShaderNames.radient:
        return RadialGrittyGradientShaderCard(dimensions: dimensions);
      case ShaderNames.perlin:
        return PerlinGradientShaderCard(dimensions: dimensions);
      case ShaderNames.radialPerlin:
        return RadialPerlinGradientShaderCard(dimensions: dimensions);
      case ShaderNames.simplex:
        return SimplexGradientShaderCard(dimensions: dimensions);
      case ShaderNames.radialSimplex:
        return RadialSimplexGradientShaderCard(dimensions: dimensions);
      case ShaderNames.fbm:
        return FbmGradientShaderCard(dimensions: dimensions);
      case ShaderNames.radialFbm:
        return RadialFbmGradientShaderCard(dimensions: dimensions);
      case ShaderNames.turbulence:
        return TurbulenceGradientShaderCard(dimensions: dimensions);
      case ShaderNames.radialTurbulence:
        return RadialTurbulenceGradientShaderCard(dimensions: dimensions);
      case ShaderNames.voronoi:
        return VoronoiGradientShaderCard(dimensions: dimensions);
      case ShaderNames.radialVoronoi:
        return RadialVoronoiGradientShaderCard(dimensions: dimensions);
      case ShaderNames.voronoise:
        return VoronoiseGradientShaderCard(dimensions: dimensions);
      case ShaderNames.radialVoronoise:
        return RadialVoronoiseGradientShaderCard(dimensions: dimensions);
      case ShaderNames.burn:
        return BurnShaderCard(dimensions: dimensions);
      case ShaderNames.radialBurn:
        return RadialBurnShaderCard(dimensions: dimensions);
      case ShaderNames.tapBurn:
        return TappableBurnShaderCard(dimensions: dimensions);
      case ShaderNames.smoke:
        return SmokeShaderCard(dimensions: dimensions);
      case ShaderNames.radialSmoke:
        return RadialSmokeShaderCard(dimensions: dimensions);
      case ShaderNames.tapSmoke:
        return TappableSmokeShaderCard(dimensions: dimensions);
      case ShaderNames.pixelDissolve:
        return PixelDissolveShaderCard(dimensions: dimensions);
      case ShaderNames.radialPixelDissolve:
        return RadialPixelDissolveShaderCard(dimensions: dimensions);
      case ShaderNames.tapPixelDissolve:
        return TappablePixelDissolveShaderCard(dimensions: dimensions);
      default:
        return ShaderCardContent(
          width: dimensions.width,
          height: dimensions.height,
          child: Container(color: Colors.grey.shade800),
        );
    }
  }
}
// ============ INDIVIDUAL SHADER CARDS ============

class RippleShaderCard extends StatefulWidget {
  final CardDimensions dimensions;

  const RippleShaderCard({super.key, required this.dimensions});

  @override
  State<RippleShaderCard> createState() => _RippleShaderCardState();
}

class _RippleShaderCardState extends State<RippleShaderCard> {
  ShaderParams _params = rippleShaderDef.defaults;
  bool _showControls = false;

  ShaderUIDefaults get _ui => rippleShaderDef.uiDefaults;

  @override
  Widget build(BuildContext context) {
    final dimensions = widget.dimensions;
    final controlsHeight = calculateControlsHeight(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderCardContent(
          width: dimensions.width,
          height: dimensions.height,
          child: RippleShaderWrap(
            backgroundColor: backgroundColor,
            params: _params,
            child: Image.asset(
              ShaderImageAssets.ripples,
              fit: BoxFit.cover,
              width: dimensions.width,
              height: dimensions.height,
            ),
          ),
        ),
        ShaderControlsPanel(
          showControls: _showControls,
          onToggle: () => setState(() => _showControls = !_showControls),
          controlsWidth: dimensions.controlsWidth,
          controlsHeight: controlsHeight,
          onReset: () => setState(() => _params = rippleShaderDef.defaults),
          shaderName: 'Ripples',
          onCopyPreset: () => _generatePreset(),
          children: [
            const ControlSectionTitle('Wave Properties'),
            ControlSlider.fromRange(range: _ui['frequency']!, value: _params.get('frequency'), onChanged: (v) => setState(() => _params = _params.withValue('frequency', v))),
            ControlSlider.fromRange(range: _ui['numWaves']!, value: _params.get('numWaves'), onChanged: (v) => setState(() => _params = _params.withValue('numWaves', v))),
            ControlSlider.fromRange(range: _ui['amplitude']!, value: _params.get('amplitude'), onChanged: (v) => setState(() => _params = _params.withValue('amplitude', v))),
            ControlSlider.fromRange(range: _ui['speed']!, value: _params.get('speed'), onChanged: (v) => setState(() => _params = _params.withValue('speed', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Origin 1'),
            ControlSlider.fromRange(range: _ui['origin1X']!, value: _params.get('origin1X'), onChanged: (v) => setState(() => _params = _params.withValue('origin1X', v))),
            ControlSlider.fromRange(range: _ui['origin1Y']!, value: _params.get('origin1Y'), onChanged: (v) => setState(() => _params = _params.withValue('origin1Y', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Origin 2'),
            ControlSlider.fromRange(range: _ui['origin2X']!, value: _params.get('origin2X'), onChanged: (v) => setState(() => _params = _params.withValue('origin2X', v))),
            ControlSlider.fromRange(range: _ui['origin2Y']!, value: _params.get('origin2Y'), onChanged: (v) => setState(() => _params = _params.withValue('origin2Y', v))),
            const SizedBox(height: 12),
            ControlSlider.fromRange(range: _ui['originScale']!, value: _params.get('originScale'), onChanged: (v) => setState(() => _params = _params.withValue('originScale', v))),
          ],
        ),
      ],
    );
  }

  String _generatePreset() => PresetGenerator.shaderParams(_params);
}

class ClickRippleShaderCard extends StatefulWidget {
  final CardDimensions dimensions;

  const ClickRippleShaderCard({super.key, required this.dimensions});

  @override
  State<ClickRippleShaderCard> createState() => _ClickRippleShaderCardState();
}

class _ClickRippleShaderCardState extends State<ClickRippleShaderCard> {
  ShaderParams _params = clickRippleShaderDef.defaults;
  bool _showControls = false;
  int _curveIndex = 0;
  double _durationSec = 3.0;
  double _delaySec = 0.0;
  bool _reverse = false;
  bool _invert = false;
  bool _persistTaps = false;
  double _rangeStart = 0.0;
  double _rangeEnd = 1.0;
  int _tapKey = 0;

  ShaderUIDefaults get _ui => clickRippleShaderDef.uiDefaults;

  void _rebuild() => setState(() => _tapKey++);

  ShaderAnimationConfig _buildTapConfig() => _buildAnimConfig(
    curveIndex: _curveIndex, durationSec: _durationSec, delaySec: _delaySec,
    loop: false, reverse: _reverse, invert: _invert,
    rangeStart: _rangeStart, rangeEnd: _rangeEnd,
  );

  @override
  Widget build(BuildContext context) {
    final dimensions = widget.dimensions;
    final controlsHeight = calculateControlsHeight(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderCardContent(
          width: dimensions.width,
          height: dimensions.height,
          child: ClickableRippleShaderWrap(
            key: ValueKey('tapRipple_$_tapKey'),
            backgroundColor: backgroundColor,
            params: _params,
            tapConfig: _buildTapConfig(),
            persistTaps: _persistTaps,
            child: Image.asset(
              ShaderImageAssets.taplets,
              fit: BoxFit.cover,
              width: dimensions.width,
              height: dimensions.height,
            ),
          ),
        ),
        ShaderControlsPanel(
          showControls: _showControls,
          onToggle: () => setState(() => _showControls = !_showControls),
          controlsWidth: dimensions.controlsWidth,
          controlsHeight: controlsHeight,
          onReset: () => setState(() => _params = clickRippleShaderDef.defaults),
          shaderName: 'Taplets',
          onCopyPreset: () => _generatePreset(),
          children: [
            const ControlSectionTitle('Ripple Properties'),
            ControlSlider.fromRange(range: _ui['amplitude']!, value: _params.get('amplitude'), onChanged: (v) => setState(() => _params = _params.withValue('amplitude', v))),
            ControlSlider.fromRange(range: _ui['frequency']!, value: _params.get('frequency'), onChanged: (v) => setState(() => _params = _params.withValue('frequency', v))),
            ControlSlider.fromRange(range: _ui['decay']!, value: _params.get('decay'), onChanged: (v) => setState(() => _params = _params.withValue('decay', v))),
            ControlSlider.fromRange(range: _ui['speed']!, value: _params.get('speed'), onChanged: (v) => setState(() => _params = _params.withValue('speed', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Tap Animation'),
            _buildCurveChips(selectedIndex: _curveIndex, onChanged: (i) { _curveIndex = i; _rebuild(); }),
            const SizedBox(height: 8),
            ControlSlider(label: 'Duration (s)', value: _durationSec, min: 0.5, max: 8.0, onChanged: (v) { _durationSec = v; _rebuild(); }),
            ControlSlider(label: 'Delay (s)', value: _delaySec, min: 0.0, max: 2.0, onChanged: (v) { _delaySec = v; _rebuild(); }),
            SwitchListTile(title: const Text('Reverse', style: TextStyle(fontSize: 12)), value: _reverse, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) { _reverse = v; _rebuild(); }),
            SwitchListTile(title: const Text('Invert', style: TextStyle(fontSize: 12)), value: _invert, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) { _invert = v; _rebuild(); }),
            SwitchListTile(title: const Text('Persist taps', style: TextStyle(fontSize: 12)), value: _persistTaps, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) { _persistTaps = v; _rebuild(); }),
            ControlSlider(label: 'Range Start', value: _rangeStart, min: 0.0, max: 1.0, onChanged: (v) { _rangeStart = v; _rebuild(); }),
            ControlSlider(label: 'Range End', value: _rangeEnd, min: 0.0, max: 1.0, onChanged: (v) { _rangeEnd = v; _rebuild(); }),
          ],
        ),
      ],
    );
  }

  String _generatePreset() => PresetGenerator.shaderParams(_params);
}

class MarbleSmearShaderCard extends StatefulWidget {
  final CardDimensions dimensions;

  const MarbleSmearShaderCard({super.key, required this.dimensions});

  @override
  State<MarbleSmearShaderCard> createState() => _MarbleSmearShaderCardState();
}

class _MarbleSmearShaderCardState extends State<MarbleSmearShaderCard> {
  ShaderParams _params = marbleSmearShaderDef.defaults;
  bool _showControls = false;

  ShaderUIDefaults get _ui => marbleSmearShaderDef.uiDefaults;

  @override
  Widget build(BuildContext context) {
    final dimensions = widget.dimensions;
    final controlsHeight = calculateControlsHeight(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderCardContent(
          width: dimensions.width,
          height: dimensions.height,
          child: MarbleSmearShaderFill(
            width: dimensions.width,
            height: dimensions.height,
            backgroundColor: backgroundColor,
            params: _params,
          ),
        ),
        ShaderControlsPanel(
          showControls: _showControls,
          onToggle: () => setState(() => _showControls = !_showControls),
          controlsWidth: dimensions.controlsWidth,
          controlsHeight: controlsHeight,
          onReset: () => setState(() => _params = marbleSmearShaderDef.defaults),
          shaderName: 'Smarble',
          onCopyPreset: () => _generatePreset(),
          children: [
            const ControlSectionTitle('Domain Warping'),
            ControlSlider.fromRange(range: _ui['warp1Scale']!, value: _params.get('warp1Scale'), onChanged: (v) => setState(() => _params = _params.withValue('warp1Scale', v))),
            ControlSlider.fromRange(range: _ui['warp2Scale']!, value: _params.get('warp2Scale'), onChanged: (v) => setState(() => _params = _params.withValue('warp2Scale', v))),
            ControlSlider.fromRange(range: _ui['finalScale']!, value: _params.get('finalScale'), onChanged: (v) => setState(() => _params = _params.withValue('finalScale', v))),
            ControlSlider.fromRange(range: _ui['warpStrength']!, value: _params.get('warpStrength'), onChanged: (v) => setState(() => _params = _params.withValue('warpStrength', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Contrast'),
            ControlSlider.fromRange(range: _ui['contrastPower']!, value: _params.get('contrastPower'), onChanged: (v) => setState(() => _params = _params.withValue('contrastPower', v))),
            ControlSlider.fromRange(range: _ui['finalContrast']!, value: _params.get('finalContrast'), onChanged: (v) => setState(() => _params = _params.withValue('finalContrast', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Animation'),
            ControlSlider.fromRange(range: _ui['animSpeedInputX']!, value: _params.get('animSpeedInputX'), onChanged: (v) => setState(() => _params = _params.withValue('animSpeedInputX', v))),
            ControlSlider.fromRange(range: _ui['animSpeedInputY']!, value: _params.get('animSpeedInputY'), onChanged: (v) => setState(() => _params = _params.withValue('animSpeedInputY', v))),
            ControlSlider.fromRange(range: _ui['animAmpInput']!, value: _params.get('animAmpInput'), onChanged: (v) => setState(() => _params = _params.withValue('animAmpInput', v))),
            ControlSlider.fromRange(range: _ui['animAmpWarp']!, value: _params.get('animAmpWarp'), onChanged: (v) => setState(() => _params = _params.withValue('animAmpWarp', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Color Palette'),
            ColorSchemeGeneratorWidget(
              colorCount: 5,
              initialColors: [
                for (int i = 0; i < 5; i++) _params.getColor('color$i'),
              ],
              onColorsChanged: (colors) => setState(() {
                for (int i = 0; i < colors.length; i++) {
                  _params = _params.withColor('color$i', colors[i]);
                }
              }),
            ),
            const SizedBox(height: 12),
            const ControlSectionTitle('Lighting'),
            ControlSlider.fromRange(range: _ui['lightIntensity']!, value: _params.get('lightIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('lightIntensity', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Smudge Effect'),
            ControlSlider.fromRange(range: _ui['smudgeRadius']!, value: _params.get('smudgeRadius'), onChanged: (v) => setState(() => _params = _params.withValue('smudgeRadius', v))),
            ControlSlider.fromRange(range: _ui['smudgeStrength']!, value: _params.get('smudgeStrength'), onChanged: (v) => setState(() => _params = _params.withValue('smudgeStrength', v))),
            ControlSlider.fromRange(range: _ui['smudgeFalloff']!, value: _params.get('smudgeFalloff'), onChanged: (v) => setState(() => _params = _params.withValue('smudgeFalloff', v))),
          ],
        ),
      ],
    );
  }

  String _generatePreset() => PresetGenerator.shaderParams(_params);
}
class GrittyGradientShaderCard extends StatefulWidget {
  final CardDimensions dimensions;

  const GrittyGradientShaderCard({super.key, required this.dimensions});

  @override
  State<GrittyGradientShaderCard> createState() => _GrittyGradientShaderCardState();
}

class _GrittyGradientShaderCardState extends State<GrittyGradientShaderCard> {
  ShaderParams _params = grittyGradientDef.defaults;
  bool _showControls = false;

  ShaderUIDefaults get _ui => grittyGradientDef.uiDefaults;

  @override
  Widget build(BuildContext context) {
    final dimensions = widget.dimensions;
    final controlsHeight = calculateControlsHeight(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderCardContent(
          width: dimensions.width,
          height: dimensions.height,
          child: GrittyGradientShaderFill(
            width: dimensions.width,
            height: dimensions.height,
            params: _params,
          ),
        ),
        ShaderControlsPanel(
          showControls: _showControls,
          onToggle: () => setState(() => _showControls = !_showControls),
          controlsWidth: dimensions.controlsWidth,
          controlsHeight: controlsHeight,
          onReset: () => setState(() => _params = grittyGradientDef.defaults),
          shaderName: 'Grit',
          onCopyPreset: () => _generatePreset(),
          children: [
            const ControlSectionTitle('Gradient'),
            ControlSlider.fromRange(range: _ui['gradientAngle']!, value: _params.get('gradientAngle'), onChanged: (v) => setState(() => _params = _params.withValue('gradientAngle', v))),
            ControlSlider.fromRange(range: _ui['gradientScale']!, value: _params.get('gradientScale'), onChanged: (v) => setState(() => _params = _params.withValue('gradientScale', v))),
            ControlSlider.fromRange(range: _ui['gradientOffset']!, value: _params.get('gradientOffset'), onChanged: (v) => setState(() => _params = _params.withValue('gradientOffset', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Noise'),
            ControlSlider.fromRange(range: _ui['noiseDensity']!, value: _params.get('noiseDensity'), onChanged: (v) => setState(() => _params = _params.withValue('noiseDensity', v))),
            ControlSlider.fromRange(range: _ui['noiseIntensity']!, value: _params.get('noiseIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('noiseIntensity', v))),
            ControlSlider.fromRange(range: _ui['ditherStrength']!, value: _params.get('ditherStrength'), onChanged: (v) => setState(() => _params = _params.withValue('ditherStrength', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Animation'),
            ControlSlider.fromRange(range: _ui['animSpeed']!, value: _params.get('animSpeed'), onChanged: (v) => setState(() => _params = _params.withValue('animSpeed', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Colors'),
            ColorSchemeGeneratorWidget(
              colorCount: _params.get('colorCount').toInt(),
              initialColors: [
                for (int i = 0; i < _params.get('colorCount').toInt(); i++)
                  _params.getColor('color$i'),
              ],
              onColorsChanged: (colors) => setState(() {
                for (int i = 0; i < colors.length; i++) {
                  _params = _params.withColor('color$i', colors[i]);
                }
              }),
            ),
            ControlSlider.fromRange(range: _ui['colorCount']!, value: _params.get('colorCount'), onChanged: (v) => setState(() => _params = _params.withValue('colorCount', v))),
            ControlSlider.fromRange(range: _ui['softness']!, value: _params.get('softness'), onChanged: (v) => setState(() => _params = _params.withValue('softness', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Post-Processing'),
            ControlSlider.fromRange(range: _ui['exposure']!, value: _params.get('exposure'), onChanged: (v) => setState(() => _params = _params.withValue('exposure', v))),
            ControlSlider.fromRange(range: _ui['contrast']!, value: _params.get('contrast'), onChanged: (v) => setState(() => _params = _params.withValue('contrast', v))),
          ],
        ),
      ],
    );
  }

  String _generatePreset() => PresetGenerator.shaderParams(_params);
}

class RadialGrittyGradientShaderCard extends StatefulWidget {
  final CardDimensions dimensions;

  const RadialGrittyGradientShaderCard({super.key, required this.dimensions});

  @override
  State<RadialGrittyGradientShaderCard> createState() =>
      _RadialGrittyGradientShaderCardState();
}

class _RadialGrittyGradientShaderCardState
    extends State<RadialGrittyGradientShaderCard> {
  ShaderParams _params = radialGrittyGradientDef.defaults;
  bool _showControls = false;

  ShaderUIDefaults get _ui => radialGrittyGradientDef.uiDefaults;

  @override
  Widget build(BuildContext context) {
    final dimensions = widget.dimensions;
    final controlsHeight = calculateControlsHeight(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderCardContent(
          width: dimensions.width,
          height: dimensions.height,
          child: RadialGrittyGradientShaderFill(
            width: dimensions.width,
            height: dimensions.height,
            params: _params,
          ),
        ),
        ShaderControlsPanel(
          showControls: _showControls,
          onToggle: () => setState(() => _showControls = !_showControls),
          controlsWidth: dimensions.controlsWidth,
          controlsHeight: controlsHeight,
          onReset: () => setState(
              () => _params = radialGrittyGradientDef.defaults),
          shaderName: 'Grit Radial',
          onCopyPreset: () => _generatePreset(),
          children: [
            const ControlSectionTitle('Gradient'),
            ControlSlider.fromRange(
              range: _ui['gradientCenterX']!,
              value: _params.get('gradientCenterX'),
              onChanged: (v) => setState(() => _params = _params.withValue('gradientCenterX', v)),
            ),
            ControlSlider.fromRange(
              range: _ui['gradientCenterY']!,
              value: _params.get('gradientCenterY'),
              onChanged: (v) => setState(() => _params = _params.withValue('gradientCenterY', v)),
            ),
            ControlSlider.fromRange(
              range: _ui['gradientScale']!,
              value: _params.get('gradientScale'),
              onChanged: (v) => setState(() => _params = _params.withValue('gradientScale', v)),
            ),
            ControlSlider.fromRange(
              range: _ui['gradientOffset']!,
              value: _params.get('gradientOffset'),
              onChanged: (v) => setState(() => _params = _params.withValue('gradientOffset', v)),
            ),
            const SizedBox(height: 12),
            const ControlSectionTitle('Noise'),
            ControlSlider.fromRange(
              range: _ui['noiseDensity']!,
              value: _params.get('noiseDensity'),
              onChanged: (v) => setState(() => _params = _params.withValue('noiseDensity', v)),
            ),
            ControlSlider.fromRange(
              range: _ui['noiseIntensity']!,
              value: _params.get('noiseIntensity'),
              onChanged: (v) => setState(() => _params = _params.withValue('noiseIntensity', v)),
            ),
            ControlSlider.fromRange(
              range: _ui['ditherStrength']!,
              value: _params.get('ditherStrength'),
              onChanged: (v) => setState(() => _params = _params.withValue('ditherStrength', v)),
            ),
            const SizedBox(height: 12),
            const ControlSectionTitle('Animation'),
            ControlSlider.fromRange(
              range: _ui['animSpeed']!,
              value: _params.get('animSpeed'),
              onChanged: (v) => setState(() => _params = _params.withValue('animSpeed', v)),
            ),
            const SizedBox(height: 12),
            const ControlSectionTitle('Colors'),
            ColorSchemeGeneratorWidget(
              colorCount: _params.get('colorCount').toInt(),
              initialColors: [
                for (int i = 0; i < _params.get('colorCount').toInt(); i++)
                  _params.getColor('color$i'),
              ],
              onColorsChanged: (colors) => setState(() {
                for (int i = 0; i < colors.length; i++) {
                  _params = _params.withColor('color$i', colors[i]);
                }
              }),
            ),
            ControlSlider.fromRange(range: _ui['colorCount']!, value: _params.get('colorCount'), onChanged: (v) => setState(() => _params = _params.withValue('colorCount', v))),
            ControlSlider.fromRange(range: _ui['softness']!, value: _params.get('softness'), onChanged: (v) => setState(() => _params = _params.withValue('softness', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Post-Processing'),
            ControlSlider.fromRange(
              range: _ui['exposure']!,
              value: _params.get('exposure'),
              onChanged: (v) => setState(() => _params = _params.withValue('exposure', v)),
            ),
            ControlSlider.fromRange(
              range: _ui['contrast']!,
              value: _params.get('contrast'),
              onChanged: (v) => setState(() => _params = _params.withValue('contrast', v)),
            ),
          ],
        ),
      ],
    );
  }

  String _generatePreset() => PresetGenerator.shaderParams(_params);
}

// ============ PERLIN GRADIENT SHADER CARDS ============

class PerlinGradientShaderCard extends StatefulWidget {
  final CardDimensions dimensions;

  const PerlinGradientShaderCard({super.key, required this.dimensions});

  @override
  State<PerlinGradientShaderCard> createState() => _PerlinGradientShaderCardState();
}

class _PerlinGradientShaderCardState extends State<PerlinGradientShaderCard> {
  ShaderParams _params = perlinGradientDef.defaults;
  bool _showControls = false;

  ShaderUIDefaults get _ui => perlinGradientDef.uiDefaults;

  @override
  Widget build(BuildContext context) {
    final dimensions = widget.dimensions;
    final controlsHeight = calculateControlsHeight(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderCardContent(
          width: dimensions.width,
          height: dimensions.height,
          child: PerlinGradientShaderFill(
            width: dimensions.width,
            height: dimensions.height,
            params: _params,
          ),
        ),
        ShaderControlsPanel(
          showControls: _showControls,
          onToggle: () => setState(() => _showControls = !_showControls),
          controlsWidth: dimensions.controlsWidth,
          controlsHeight: controlsHeight,
          onReset: () => setState(() => _params = perlinGradientDef.defaults),
          shaderName: 'Perlin',
          onCopyPreset: () => _generatePreset(),
          children: [
            const ControlSectionTitle('Gradient'),
            ControlSlider.fromRange(range: _ui['gradientAngle']!, value: _params.get('gradientAngle'), onChanged: (v) => setState(() => _params = _params.withValue('gradientAngle', v))),
            ControlSlider.fromRange(range: _ui['gradientScale']!, value: _params.get('gradientScale'), onChanged: (v) => setState(() => _params = _params.withValue('gradientScale', v))),
            ControlSlider.fromRange(range: _ui['gradientOffset']!, value: _params.get('gradientOffset'), onChanged: (v) => setState(() => _params = _params.withValue('gradientOffset', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Perlin Noise'),
            ControlSlider.fromRange(range: _ui['noiseScale']!, value: _params.get('noiseScale'), onChanged: (v) => setState(() => _params = _params.withValue('noiseScale', v))),
            ControlSlider.fromRange(range: _ui['noiseContrast']!, value: _params.get('noiseContrast'), onChanged: (v) => setState(() => _params = _params.withValue('noiseContrast', v))),
            ControlSlider.fromRange(range: _ui['noiseIntensity']!, value: _params.get('noiseIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('noiseIntensity', v))),
            ControlSlider.fromRange(range: _ui['edgeFade']!, value: _params.get('edgeFade'), onChanged: (v) => setState(() => _params = _params.withValue('edgeFade', v))),
            ControlSegmentedButton<double>(
              label: 'Fade Mode',
              value: _params.get('edgeFadeMode'),
              options: const [
                (0.0, 'Both'),
                (1.0, 'Start'),
                (2.0, 'End'),
              ],
              onChanged: (v) => setState(() => _params = _params.withValue('edgeFadeMode', v)),
            ),
            ControlSlider.fromRange(range: _ui['ditherStrength']!, value: _params.get('ditherStrength'), onChanged: (v) => setState(() => _params = _params.withValue('ditherStrength', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Animation'),
            ControlSlider.fromRange(range: _ui['animSpeed']!, value: _params.get('animSpeed'), onChanged: (v) => setState(() => _params = _params.withValue('animSpeed', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Colors'),
            ColorSchemeGeneratorWidget(
              colorCount: _params.get('colorCount').toInt(),
              initialColors: [
                for (int i = 0; i < _params.get('colorCount').toInt(); i++)
                  _params.getColor('color$i'),
              ],
              onColorsChanged: (colors) => setState(() {
                for (int i = 0; i < colors.length; i++) {
                  _params = _params.withColor('color$i', colors[i]);
                }
              }),
            ),
            ControlSlider.fromRange(range: _ui['colorCount']!, value: _params.get('colorCount'), onChanged: (v) => setState(() => _params = _params.withValue('colorCount', v))),
            ControlSlider.fromRange(range: _ui['softness']!, value: _params.get('softness'), onChanged: (v) => setState(() => _params = _params.withValue('softness', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Post-Processing'),
            ControlSlider.fromRange(range: _ui['exposure']!, value: _params.get('exposure'), onChanged: (v) => setState(() => _params = _params.withValue('exposure', v))),
            ControlSlider.fromRange(range: _ui['contrast']!, value: _params.get('contrast'), onChanged: (v) => setState(() => _params = _params.withValue('contrast', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Lighting'),
            ControlSlider.fromRange(range: _ui['bumpStrength']!, value: _params.get('bumpStrength'), onChanged: (v) => setState(() => _params = _params.withValue('bumpStrength', v))),
            ControlSlider.fromRange(range: _ui['lightDirX']!, value: _params.get('lightDirX'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirX', v))),
            ControlSlider.fromRange(range: _ui['lightDirY']!, value: _params.get('lightDirY'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirY', v))),
            ControlSlider.fromRange(range: _ui['lightDirZ']!, value: _params.get('lightDirZ'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirZ', v))),
            ControlSlider.fromRange(range: _ui['lightIntensity']!, value: _params.get('lightIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('lightIntensity', v))),
            ControlSlider.fromRange(range: _ui['ambient']!, value: _params.get('ambient'), onChanged: (v) => setState(() => _params = _params.withValue('ambient', v))),
            ControlSlider.fromRange(range: _ui['specular']!, value: _params.get('specular'), onChanged: (v) => setState(() => _params = _params.withValue('specular', v))),
            ControlSlider.fromRange(range: _ui['shininess']!, value: _params.get('shininess'), onChanged: (v) => setState(() => _params = _params.withValue('shininess', v))),
            ControlSlider.fromRange(range: _ui['metallic']!, value: _params.get('metallic'), onChanged: (v) => setState(() => _params = _params.withValue('metallic', v))),
            ControlSlider.fromRange(range: _ui['roughness']!, value: _params.get('roughness'), onChanged: (v) => setState(() => _params = _params.withValue('roughness', v))),
          ],
        ),
      ],
    );
  }

  String _generatePreset() => PresetGenerator.shaderParams(_params);
}

class RadialPerlinGradientShaderCard extends StatefulWidget {
  final CardDimensions dimensions;

  const RadialPerlinGradientShaderCard({super.key, required this.dimensions});

  @override
  State<RadialPerlinGradientShaderCard> createState() => _RadialPerlinGradientShaderCardState();
}

class _RadialPerlinGradientShaderCardState extends State<RadialPerlinGradientShaderCard> {
  ShaderParams _params = radialPerlinGradientDef.defaults;
  bool _showControls = false;

  ShaderUIDefaults get _ui => radialPerlinGradientDef.uiDefaults;

  @override
  Widget build(BuildContext context) {
    final dimensions = widget.dimensions;
    final controlsHeight = calculateControlsHeight(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderCardContent(
          width: dimensions.width,
          height: dimensions.height,
          child: RadialPerlinGradientShaderFill(
            width: dimensions.width,
            height: dimensions.height,
            params: _params,
          ),
        ),
        ShaderControlsPanel(
          showControls: _showControls,
          onToggle: () => setState(() => _showControls = !_showControls),
          controlsWidth: dimensions.controlsWidth,
          controlsHeight: controlsHeight,
          onReset: () => setState(() => _params = radialPerlinGradientDef.defaults),
          shaderName: 'Perlin Radial',
          onCopyPreset: () => _generatePreset(),
          children: [
            const ControlSectionTitle('Gradient'),
            ControlSlider.fromRange(range: _ui['gradientCenterX']!, value: _params.get('gradientCenterX'), onChanged: (v) => setState(() => _params = _params.withValue('gradientCenterX', v))),
            ControlSlider.fromRange(range: _ui['gradientCenterY']!, value: _params.get('gradientCenterY'), onChanged: (v) => setState(() => _params = _params.withValue('gradientCenterY', v))),
            ControlSlider.fromRange(range: _ui['gradientScale']!, value: _params.get('gradientScale'), onChanged: (v) => setState(() => _params = _params.withValue('gradientScale', v))),
            ControlSlider.fromRange(range: _ui['gradientOffset']!, value: _params.get('gradientOffset'), onChanged: (v) => setState(() => _params = _params.withValue('gradientOffset', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Perlin Noise'),
            ControlSlider.fromRange(range: _ui['noiseScale']!, value: _params.get('noiseScale'), onChanged: (v) => setState(() => _params = _params.withValue('noiseScale', v))),
            ControlSlider.fromRange(range: _ui['noiseContrast']!, value: _params.get('noiseContrast'), onChanged: (v) => setState(() => _params = _params.withValue('noiseContrast', v))),
            ControlSlider.fromRange(range: _ui['noiseIntensity']!, value: _params.get('noiseIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('noiseIntensity', v))),
            ControlSlider.fromRange(range: _ui['ditherStrength']!, value: _params.get('ditherStrength'), onChanged: (v) => setState(() => _params = _params.withValue('ditherStrength', v))),
            ControlSlider.fromRange(range: _ui['edgeFade']!, value: _params.get('edgeFade'), onChanged: (v) => setState(() => _params = _params.withValue('edgeFade', v))),
            ControlSegmentedButton<double>(
              label: 'Fade Mode',
              value: _params.get('edgeFadeMode'),
              options: const [
                (0.0, 'Both'),
                (1.0, 'Start'),
                (2.0, 'End'),
              ],
              onChanged: (v) => setState(() => _params = _params.withValue('edgeFadeMode', v)),
            ),
            const SizedBox(height: 12),
            const ControlSectionTitle('Animation'),
            ControlSlider.fromRange(range: _ui['animSpeed']!, value: _params.get('animSpeed'), onChanged: (v) => setState(() => _params = _params.withValue('animSpeed', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Colors'),
            ColorSchemeGeneratorWidget(
              colorCount: _params.get('colorCount').toInt(),
              initialColors: [
                for (int i = 0; i < _params.get('colorCount').toInt(); i++)
                  _params.getColor('color$i'),
              ],
              onColorsChanged: (colors) => setState(() {
                for (int i = 0; i < colors.length; i++) {
                  _params = _params.withColor('color$i', colors[i]);
                }
              }),
            ),
            ControlSlider.fromRange(range: _ui['colorCount']!, value: _params.get('colorCount'), onChanged: (v) => setState(() => _params = _params.withValue('colorCount', v))),
            ControlSlider.fromRange(range: _ui['softness']!, value: _params.get('softness'), onChanged: (v) => setState(() => _params = _params.withValue('softness', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Post-Processing'),
            ControlSlider.fromRange(range: _ui['exposure']!, value: _params.get('exposure'), onChanged: (v) => setState(() => _params = _params.withValue('exposure', v))),
            ControlSlider.fromRange(range: _ui['contrast']!, value: _params.get('contrast'), onChanged: (v) => setState(() => _params = _params.withValue('contrast', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Lighting'),
            ControlSlider.fromRange(range: _ui['bumpStrength']!, value: _params.get('bumpStrength'), onChanged: (v) => setState(() => _params = _params.withValue('bumpStrength', v))),
            ControlSlider.fromRange(range: _ui['lightDirX']!, value: _params.get('lightDirX'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirX', v))),
            ControlSlider.fromRange(range: _ui['lightDirY']!, value: _params.get('lightDirY'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirY', v))),
            ControlSlider.fromRange(range: _ui['lightDirZ']!, value: _params.get('lightDirZ'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirZ', v))),
            ControlSlider.fromRange(range: _ui['lightIntensity']!, value: _params.get('lightIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('lightIntensity', v))),
            ControlSlider.fromRange(range: _ui['ambient']!, value: _params.get('ambient'), onChanged: (v) => setState(() => _params = _params.withValue('ambient', v))),
            ControlSlider.fromRange(range: _ui['specular']!, value: _params.get('specular'), onChanged: (v) => setState(() => _params = _params.withValue('specular', v))),
            ControlSlider.fromRange(range: _ui['shininess']!, value: _params.get('shininess'), onChanged: (v) => setState(() => _params = _params.withValue('shininess', v))),
            ControlSlider.fromRange(range: _ui['metallic']!, value: _params.get('metallic'), onChanged: (v) => setState(() => _params = _params.withValue('metallic', v))),
            ControlSlider.fromRange(range: _ui['roughness']!, value: _params.get('roughness'), onChanged: (v) => setState(() => _params = _params.withValue('roughness', v))),
          ],
        ),
      ],
    );
  }

  String _generatePreset() => PresetGenerator.shaderParams(_params);
}

// ============ SIMPLEX GRADIENT SHADER CARDS ============

class SimplexGradientShaderCard extends StatefulWidget {
  final CardDimensions dimensions;

  const SimplexGradientShaderCard({super.key, required this.dimensions});

  @override
  State<SimplexGradientShaderCard> createState() => _SimplexGradientShaderCardState();
}

class _SimplexGradientShaderCardState extends State<SimplexGradientShaderCard> {
  ShaderParams _params = simplexGradientDef.defaults;
  bool _showControls = false;

  ShaderUIDefaults get _ui => simplexGradientDef.uiDefaults;

  @override
  Widget build(BuildContext context) {
    final dimensions = widget.dimensions;
    final controlsHeight = calculateControlsHeight(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderCardContent(
          width: dimensions.width,
          height: dimensions.height,
          child: SimplexGradientShaderFill(
            width: dimensions.width,
            height: dimensions.height,
            params: _params,
          ),
        ),
        ShaderControlsPanel(
          showControls: _showControls,
          onToggle: () => setState(() => _showControls = !_showControls),
          controlsWidth: dimensions.controlsWidth,
          controlsHeight: controlsHeight,
          onReset: () => setState(() => _params = simplexGradientDef.defaults),
          shaderName: 'Simplex',
          onCopyPreset: () => _generatePreset(),
          children: [
            const ControlSectionTitle('Gradient'),
            ControlSlider.fromRange(range: _ui['gradientAngle']!, value: _params.get('gradientAngle'), onChanged: (v) => setState(() => _params = _params.withValue('gradientAngle', v))),
            ControlSlider.fromRange(range: _ui['gradientScale']!, value: _params.get('gradientScale'), onChanged: (v) => setState(() => _params = _params.withValue('gradientScale', v))),
            ControlSlider.fromRange(range: _ui['gradientOffset']!, value: _params.get('gradientOffset'), onChanged: (v) => setState(() => _params = _params.withValue('gradientOffset', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Simplex Noise'),
            ControlSlider.fromRange(range: _ui['noiseScale']!, value: _params.get('noiseScale'), onChanged: (v) => setState(() => _params = _params.withValue('noiseScale', v))),
            ControlSlider.fromRange(range: _ui['sharpness']!, value: _params.get('sharpness'), onChanged: (v) => setState(() => _params = _params.withValue('sharpness', v))),
            ControlSlider.fromRange(range: _ui['noiseIntensity']!, value: _params.get('noiseIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('noiseIntensity', v))),
            ControlSlider.fromRange(range: _ui['ditherStrength']!, value: _params.get('ditherStrength'), onChanged: (v) => setState(() => _params = _params.withValue('ditherStrength', v))),
            ControlSlider.fromRange(range: _ui['edgeFade']!, value: _params.get('edgeFade'), onChanged: (v) => setState(() => _params = _params.withValue('edgeFade', v))),
            ControlSegmentedButton<double>(
              label: 'Fade Mode',
              value: _params.get('edgeFadeMode'),
              options: const [
                (0.0, 'Both'),
                (1.0, 'Start'),
                (2.0, 'End'),
              ],
              onChanged: (v) => setState(() => _params = _params.withValue('edgeFadeMode', v)),
            ),
            const SizedBox(height: 12),
            const ControlSectionTitle('Animation'),
            ControlSlider.fromRange(range: _ui['animSpeed']!, value: _params.get('animSpeed'), onChanged: (v) => setState(() => _params = _params.withValue('animSpeed', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Colors'),
            ColorSchemeGeneratorWidget(
              colorCount: _params.get('colorCount').toInt(),
              initialColors: [
                for (int i = 0; i < _params.get('colorCount').toInt(); i++)
                  _params.getColor('color$i'),
              ],
              onColorsChanged: (colors) => setState(() {
                for (int i = 0; i < colors.length; i++) {
                  _params = _params.withColor('color$i', colors[i]);
                }
              }),
            ),
            ControlSlider.fromRange(range: _ui['colorCount']!, value: _params.get('colorCount'), onChanged: (v) => setState(() => _params = _params.withValue('colorCount', v))),
            ControlSlider.fromRange(range: _ui['softness']!, value: _params.get('softness'), onChanged: (v) => setState(() => _params = _params.withValue('softness', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Post-Processing'),
            ControlSlider.fromRange(range: _ui['exposure']!, value: _params.get('exposure'), onChanged: (v) => setState(() => _params = _params.withValue('exposure', v))),
            ControlSlider.fromRange(range: _ui['contrast']!, value: _params.get('contrast'), onChanged: (v) => setState(() => _params = _params.withValue('contrast', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Lighting'),
            ControlSlider.fromRange(range: _ui['bumpStrength']!, value: _params.get('bumpStrength'), onChanged: (v) => setState(() => _params = _params.withValue('bumpStrength', v))),
            ControlSlider.fromRange(range: _ui['lightDirX']!, value: _params.get('lightDirX'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirX', v))),
            ControlSlider.fromRange(range: _ui['lightDirY']!, value: _params.get('lightDirY'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirY', v))),
            ControlSlider.fromRange(range: _ui['lightDirZ']!, value: _params.get('lightDirZ'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirZ', v))),
            ControlSlider.fromRange(range: _ui['lightIntensity']!, value: _params.get('lightIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('lightIntensity', v))),
            ControlSlider.fromRange(range: _ui['ambient']!, value: _params.get('ambient'), onChanged: (v) => setState(() => _params = _params.withValue('ambient', v))),
            ControlSlider.fromRange(range: _ui['specular']!, value: _params.get('specular'), onChanged: (v) => setState(() => _params = _params.withValue('specular', v))),
            ControlSlider.fromRange(range: _ui['shininess']!, value: _params.get('shininess'), onChanged: (v) => setState(() => _params = _params.withValue('shininess', v))),
            ControlSlider.fromRange(range: _ui['metallic']!, value: _params.get('metallic'), onChanged: (v) => setState(() => _params = _params.withValue('metallic', v))),
            ControlSlider.fromRange(range: _ui['roughness']!, value: _params.get('roughness'), onChanged: (v) => setState(() => _params = _params.withValue('roughness', v))),
          ],
        ),
      ],
    );
  }

  String _generatePreset() => PresetGenerator.shaderParams(_params);
}

class RadialSimplexGradientShaderCard extends StatefulWidget {
  final CardDimensions dimensions;

  const RadialSimplexGradientShaderCard({super.key, required this.dimensions});

  @override
  State<RadialSimplexGradientShaderCard> createState() => _RadialSimplexGradientShaderCardState();
}

class _RadialSimplexGradientShaderCardState extends State<RadialSimplexGradientShaderCard> {
  ShaderParams _params = radialSimplexGradientDef.defaults;
  bool _showControls = false;

  ShaderUIDefaults get _ui => radialSimplexGradientDef.uiDefaults;

  @override
  Widget build(BuildContext context) {
    final dimensions = widget.dimensions;
    final controlsHeight = calculateControlsHeight(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderCardContent(
          width: dimensions.width,
          height: dimensions.height,
          child: RadialSimplexGradientShaderFill(
            width: dimensions.width,
            height: dimensions.height,
            params: _params,
          ),
        ),
        ShaderControlsPanel(
          showControls: _showControls,
          onToggle: () => setState(() => _showControls = !_showControls),
          controlsWidth: dimensions.controlsWidth,
          controlsHeight: controlsHeight,
          onReset: () => setState(() => _params = radialSimplexGradientDef.defaults),
          shaderName: 'Simplex Radial',
          onCopyPreset: () => _generatePreset(),
          children: [
            const ControlSectionTitle('Gradient'),
            ControlSlider.fromRange(range: _ui['gradientCenterX']!, value: _params.get('gradientCenterX'), onChanged: (v) => setState(() => _params = _params.withValue('gradientCenterX', v))),
            ControlSlider.fromRange(range: _ui['gradientCenterY']!, value: _params.get('gradientCenterY'), onChanged: (v) => setState(() => _params = _params.withValue('gradientCenterY', v))),
            ControlSlider.fromRange(range: _ui['gradientScale']!, value: _params.get('gradientScale'), onChanged: (v) => setState(() => _params = _params.withValue('gradientScale', v))),
            ControlSlider.fromRange(range: _ui['gradientOffset']!, value: _params.get('gradientOffset'), onChanged: (v) => setState(() => _params = _params.withValue('gradientOffset', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Simplex Noise'),
            ControlSlider.fromRange(range: _ui['noiseScale']!, value: _params.get('noiseScale'), onChanged: (v) => setState(() => _params = _params.withValue('noiseScale', v))),
            ControlSlider.fromRange(range: _ui['sharpness']!, value: _params.get('sharpness'), onChanged: (v) => setState(() => _params = _params.withValue('sharpness', v))),
            ControlSlider.fromRange(range: _ui['noiseIntensity']!, value: _params.get('noiseIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('noiseIntensity', v))),
            ControlSlider.fromRange(range: _ui['ditherStrength']!, value: _params.get('ditherStrength'), onChanged: (v) => setState(() => _params = _params.withValue('ditherStrength', v))),
            ControlSlider.fromRange(range: _ui['edgeFade']!, value: _params.get('edgeFade'), onChanged: (v) => setState(() => _params = _params.withValue('edgeFade', v))),
            ControlSegmentedButton<double>(
              label: 'Fade Mode',
              value: _params.get('edgeFadeMode'),
              options: const [
                (0.0, 'Both'),
                (1.0, 'Start'),
                (2.0, 'End'),
              ],
              onChanged: (v) => setState(() => _params = _params.withValue('edgeFadeMode', v)),
            ),
            const SizedBox(height: 12),
            const ControlSectionTitle('Animation'),
            ControlSlider.fromRange(range: _ui['animSpeed']!, value: _params.get('animSpeed'), onChanged: (v) => setState(() => _params = _params.withValue('animSpeed', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Colors'),
            ColorSchemeGeneratorWidget(
              colorCount: _params.get('colorCount').toInt(),
              initialColors: [
                for (int i = 0; i < _params.get('colorCount').toInt(); i++)
                  _params.getColor('color$i'),
              ],
              onColorsChanged: (colors) => setState(() {
                for (int i = 0; i < colors.length; i++) {
                  _params = _params.withColor('color$i', colors[i]);
                }
              }),
            ),
            ControlSlider.fromRange(range: _ui['colorCount']!, value: _params.get('colorCount'), onChanged: (v) => setState(() => _params = _params.withValue('colorCount', v))),
            ControlSlider.fromRange(range: _ui['softness']!, value: _params.get('softness'), onChanged: (v) => setState(() => _params = _params.withValue('softness', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Post-Processing'),
            ControlSlider.fromRange(range: _ui['exposure']!, value: _params.get('exposure'), onChanged: (v) => setState(() => _params = _params.withValue('exposure', v))),
            ControlSlider.fromRange(range: _ui['contrast']!, value: _params.get('contrast'), onChanged: (v) => setState(() => _params = _params.withValue('contrast', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Lighting'),
            ControlSlider.fromRange(range: _ui['bumpStrength']!, value: _params.get('bumpStrength'), onChanged: (v) => setState(() => _params = _params.withValue('bumpStrength', v))),
            ControlSlider.fromRange(range: _ui['lightDirX']!, value: _params.get('lightDirX'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirX', v))),
            ControlSlider.fromRange(range: _ui['lightDirY']!, value: _params.get('lightDirY'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirY', v))),
            ControlSlider.fromRange(range: _ui['lightDirZ']!, value: _params.get('lightDirZ'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirZ', v))),
            ControlSlider.fromRange(range: _ui['lightIntensity']!, value: _params.get('lightIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('lightIntensity', v))),
            ControlSlider.fromRange(range: _ui['ambient']!, value: _params.get('ambient'), onChanged: (v) => setState(() => _params = _params.withValue('ambient', v))),
            ControlSlider.fromRange(range: _ui['specular']!, value: _params.get('specular'), onChanged: (v) => setState(() => _params = _params.withValue('specular', v))),
            ControlSlider.fromRange(range: _ui['shininess']!, value: _params.get('shininess'), onChanged: (v) => setState(() => _params = _params.withValue('shininess', v))),
            ControlSlider.fromRange(range: _ui['metallic']!, value: _params.get('metallic'), onChanged: (v) => setState(() => _params = _params.withValue('metallic', v))),
            ControlSlider.fromRange(range: _ui['roughness']!, value: _params.get('roughness'), onChanged: (v) => setState(() => _params = _params.withValue('roughness', v))),
          ],
        ),
      ],
    );
  }

  String _generatePreset() => PresetGenerator.shaderParams(_params);
}

// ============ FBM GRADIENT SHADER CARDS ============

class FbmGradientShaderCard extends StatefulWidget {
  final CardDimensions dimensions;

  const FbmGradientShaderCard({super.key, required this.dimensions});

  @override
  State<FbmGradientShaderCard> createState() => _FbmGradientShaderCardState();
}

class _FbmGradientShaderCardState extends State<FbmGradientShaderCard> {
  ShaderParams _params = fbmGradientDef.defaults;
  bool _showControls = false;

  ShaderUIDefaults get _ui => fbmGradientDef.uiDefaults;

  @override
  Widget build(BuildContext context) {
    final dimensions = widget.dimensions;
    final controlsHeight = calculateControlsHeight(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderCardContent(
          width: dimensions.width,
          height: dimensions.height,
          child: FbmGradientShaderFill(
            width: dimensions.width,
            height: dimensions.height,
            params: _params,
          ),
        ),
        ShaderControlsPanel(
          showControls: _showControls,
          onToggle: () => setState(() => _showControls = !_showControls),
          controlsWidth: dimensions.controlsWidth,
          controlsHeight: controlsHeight,
          onReset: () => setState(() => _params = fbmGradientDef.defaults),
          shaderName: 'FBM',
          onCopyPreset: () => _generatePreset(),
          children: [
            const ControlSectionTitle('Gradient'),
            ControlSlider.fromRange(range: _ui['gradientAngle']!, value: _params.get('gradientAngle'), onChanged: (v) => setState(() => _params = _params.withValue('gradientAngle', v))),
            ControlSlider.fromRange(range: _ui['gradientScale']!, value: _params.get('gradientScale'), onChanged: (v) => setState(() => _params = _params.withValue('gradientScale', v))),
            ControlSlider.fromRange(range: _ui['gradientOffset']!, value: _params.get('gradientOffset'), onChanged: (v) => setState(() => _params = _params.withValue('gradientOffset', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('FBM Noise'),
            ControlSlider.fromRange(range: _ui['octaves']!, value: _params.get('octaves'), onChanged: (v) => setState(() => _params = _params.withValue('octaves', v))),
            ControlSlider.fromRange(range: _ui['lacunarity']!, value: _params.get('lacunarity'), onChanged: (v) => setState(() => _params = _params.withValue('lacunarity', v))),
            ControlSlider.fromRange(range: _ui['persistence']!, value: _params.get('persistence'), onChanged: (v) => setState(() => _params = _params.withValue('persistence', v))),
            ControlSlider.fromRange(range: _ui['noiseScale']!, value: _params.get('noiseScale'), onChanged: (v) => setState(() => _params = _params.withValue('noiseScale', v))),
            ControlSlider.fromRange(range: _ui['noiseIntensity']!, value: _params.get('noiseIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('noiseIntensity', v))),
            ControlSlider.fromRange(range: _ui['ditherStrength']!, value: _params.get('ditherStrength'), onChanged: (v) => setState(() => _params = _params.withValue('ditherStrength', v))),
            ControlSlider.fromRange(range: _ui['edgeFade']!, value: _params.get('edgeFade'), onChanged: (v) => setState(() => _params = _params.withValue('edgeFade', v))),
            ControlSegmentedButton<double>(
              label: 'Fade Mode',
              value: _params.get('edgeFadeMode'),
              options: const [
                (0.0, 'Both'),
                (1.0, 'Start'),
                (2.0, 'End'),
              ],
              onChanged: (v) => setState(() => _params = _params.withValue('edgeFadeMode', v)),
            ),
            const SizedBox(height: 12),
            const ControlSectionTitle('Animation'),
            ControlSlider.fromRange(range: _ui['animSpeed']!, value: _params.get('animSpeed'), onChanged: (v) => setState(() => _params = _params.withValue('animSpeed', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Colors'),
            ColorSchemeGeneratorWidget(
              colorCount: _params.get('colorCount').toInt(),
              initialColors: [
                for (int i = 0; i < _params.get('colorCount').toInt(); i++)
                  _params.getColor('color$i'),
              ],
              onColorsChanged: (colors) => setState(() {
                for (int i = 0; i < colors.length; i++) {
                  _params = _params.withColor('color$i', colors[i]);
                }
              }),
            ),
            ControlSlider.fromRange(range: _ui['colorCount']!, value: _params.get('colorCount'), onChanged: (v) => setState(() => _params = _params.withValue('colorCount', v))),
            ControlSlider.fromRange(range: _ui['softness']!, value: _params.get('softness'), onChanged: (v) => setState(() => _params = _params.withValue('softness', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Post-Processing'),
            ControlSlider.fromRange(range: _ui['exposure']!, value: _params.get('exposure'), onChanged: (v) => setState(() => _params = _params.withValue('exposure', v))),
            ControlSlider.fromRange(range: _ui['contrast']!, value: _params.get('contrast'), onChanged: (v) => setState(() => _params = _params.withValue('contrast', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Lighting'),
            ControlSlider.fromRange(range: _ui['bumpStrength']!, value: _params.get('bumpStrength'), onChanged: (v) => setState(() => _params = _params.withValue('bumpStrength', v))),
            ControlSlider.fromRange(range: _ui['lightDirX']!, value: _params.get('lightDirX'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirX', v))),
            ControlSlider.fromRange(range: _ui['lightDirY']!, value: _params.get('lightDirY'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirY', v))),
            ControlSlider.fromRange(range: _ui['lightDirZ']!, value: _params.get('lightDirZ'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirZ', v))),
            ControlSlider.fromRange(range: _ui['lightIntensity']!, value: _params.get('lightIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('lightIntensity', v))),
            ControlSlider.fromRange(range: _ui['ambient']!, value: _params.get('ambient'), onChanged: (v) => setState(() => _params = _params.withValue('ambient', v))),
            ControlSlider.fromRange(range: _ui['specular']!, value: _params.get('specular'), onChanged: (v) => setState(() => _params = _params.withValue('specular', v))),
            ControlSlider.fromRange(range: _ui['shininess']!, value: _params.get('shininess'), onChanged: (v) => setState(() => _params = _params.withValue('shininess', v))),
            ControlSlider.fromRange(range: _ui['metallic']!, value: _params.get('metallic'), onChanged: (v) => setState(() => _params = _params.withValue('metallic', v))),
            ControlSlider.fromRange(range: _ui['roughness']!, value: _params.get('roughness'), onChanged: (v) => setState(() => _params = _params.withValue('roughness', v))),
          ],
        ),
      ],
    );
  }

  String _generatePreset() => PresetGenerator.shaderParams(_params);
}

class RadialFbmGradientShaderCard extends StatefulWidget {
  final CardDimensions dimensions;

  const RadialFbmGradientShaderCard({super.key, required this.dimensions});

  @override
  State<RadialFbmGradientShaderCard> createState() => _RadialFbmGradientShaderCardState();
}

class _RadialFbmGradientShaderCardState extends State<RadialFbmGradientShaderCard> {
  ShaderParams _params = radialFbmGradientDef.defaults;
  bool _showControls = false;

  ShaderUIDefaults get _ui => radialFbmGradientDef.uiDefaults;

  @override
  Widget build(BuildContext context) {
    final dimensions = widget.dimensions;
    final controlsHeight = calculateControlsHeight(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderCardContent(
          width: dimensions.width,
          height: dimensions.height,
          child: RadialFbmGradientShaderFill(
            width: dimensions.width,
            height: dimensions.height,
            params: _params,
          ),
        ),
        ShaderControlsPanel(
          showControls: _showControls,
          onToggle: () => setState(() => _showControls = !_showControls),
          controlsWidth: dimensions.controlsWidth,
          controlsHeight: controlsHeight,
          onReset: () => setState(() => _params = radialFbmGradientDef.defaults),
          shaderName: 'FBM Radial',
          onCopyPreset: () => _generatePreset(),
          children: [
            const ControlSectionTitle('Gradient'),
            ControlSlider.fromRange(range: _ui['gradientCenterX']!, value: _params.get('gradientCenterX'), onChanged: (v) => setState(() => _params = _params.withValue('gradientCenterX', v))),
            ControlSlider.fromRange(range: _ui['gradientCenterY']!, value: _params.get('gradientCenterY'), onChanged: (v) => setState(() => _params = _params.withValue('gradientCenterY', v))),
            ControlSlider.fromRange(range: _ui['gradientScale']!, value: _params.get('gradientScale'), onChanged: (v) => setState(() => _params = _params.withValue('gradientScale', v))),
            ControlSlider.fromRange(range: _ui['gradientOffset']!, value: _params.get('gradientOffset'), onChanged: (v) => setState(() => _params = _params.withValue('gradientOffset', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('FBM Noise'),
            ControlSlider.fromRange(range: _ui['octaves']!, value: _params.get('octaves'), onChanged: (v) => setState(() => _params = _params.withValue('octaves', v))),
            ControlSlider.fromRange(range: _ui['lacunarity']!, value: _params.get('lacunarity'), onChanged: (v) => setState(() => _params = _params.withValue('lacunarity', v))),
            ControlSlider.fromRange(range: _ui['persistence']!, value: _params.get('persistence'), onChanged: (v) => setState(() => _params = _params.withValue('persistence', v))),
            ControlSlider.fromRange(range: _ui['noiseScale']!, value: _params.get('noiseScale'), onChanged: (v) => setState(() => _params = _params.withValue('noiseScale', v))),
            ControlSlider.fromRange(range: _ui['noiseIntensity']!, value: _params.get('noiseIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('noiseIntensity', v))),
            ControlSlider.fromRange(range: _ui['ditherStrength']!, value: _params.get('ditherStrength'), onChanged: (v) => setState(() => _params = _params.withValue('ditherStrength', v))),
            ControlSlider.fromRange(range: _ui['edgeFade']!, value: _params.get('edgeFade'), onChanged: (v) => setState(() => _params = _params.withValue('edgeFade', v))),
            ControlSegmentedButton<double>(
              label: 'Fade Mode',
              value: _params.get('edgeFadeMode'),
              options: const [
                (0.0, 'Both'),
                (1.0, 'Start'),
                (2.0, 'End'),
              ],
              onChanged: (v) => setState(() => _params = _params.withValue('edgeFadeMode', v)),
            ),
            const SizedBox(height: 12),
            const ControlSectionTitle('Animation'),
            ControlSlider.fromRange(range: _ui['animSpeed']!, value: _params.get('animSpeed'), onChanged: (v) => setState(() => _params = _params.withValue('animSpeed', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Colors'),
            ColorSchemeGeneratorWidget(
              colorCount: _params.get('colorCount').toInt(),
              initialColors: [
                for (int i = 0; i < _params.get('colorCount').toInt(); i++)
                  _params.getColor('color$i'),
              ],
              onColorsChanged: (colors) => setState(() {
                for (int i = 0; i < colors.length; i++) {
                  _params = _params.withColor('color$i', colors[i]);
                }
              }),
            ),
            ControlSlider.fromRange(range: _ui['colorCount']!, value: _params.get('colorCount'), onChanged: (v) => setState(() => _params = _params.withValue('colorCount', v))),
            ControlSlider.fromRange(range: _ui['softness']!, value: _params.get('softness'), onChanged: (v) => setState(() => _params = _params.withValue('softness', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Post-Processing'),
            ControlSlider.fromRange(range: _ui['exposure']!, value: _params.get('exposure'), onChanged: (v) => setState(() => _params = _params.withValue('exposure', v))),
            ControlSlider.fromRange(range: _ui['contrast']!, value: _params.get('contrast'), onChanged: (v) => setState(() => _params = _params.withValue('contrast', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Lighting'),
            ControlSlider.fromRange(range: _ui['bumpStrength']!, value: _params.get('bumpStrength'), onChanged: (v) => setState(() => _params = _params.withValue('bumpStrength', v))),
            ControlSlider.fromRange(range: _ui['lightDirX']!, value: _params.get('lightDirX'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirX', v))),
            ControlSlider.fromRange(range: _ui['lightDirY']!, value: _params.get('lightDirY'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirY', v))),
            ControlSlider.fromRange(range: _ui['lightDirZ']!, value: _params.get('lightDirZ'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirZ', v))),
            ControlSlider.fromRange(range: _ui['lightIntensity']!, value: _params.get('lightIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('lightIntensity', v))),
            ControlSlider.fromRange(range: _ui['ambient']!, value: _params.get('ambient'), onChanged: (v) => setState(() => _params = _params.withValue('ambient', v))),
            ControlSlider.fromRange(range: _ui['specular']!, value: _params.get('specular'), onChanged: (v) => setState(() => _params = _params.withValue('specular', v))),
            ControlSlider.fromRange(range: _ui['shininess']!, value: _params.get('shininess'), onChanged: (v) => setState(() => _params = _params.withValue('shininess', v))),
            ControlSlider.fromRange(range: _ui['metallic']!, value: _params.get('metallic'), onChanged: (v) => setState(() => _params = _params.withValue('metallic', v))),
            ControlSlider.fromRange(range: _ui['roughness']!, value: _params.get('roughness'), onChanged: (v) => setState(() => _params = _params.withValue('roughness', v))),
          ],
        ),
      ],
    );
  }

  String _generatePreset() => PresetGenerator.shaderParams(_params);
}

// ============ TURBULENCE GRADIENT SHADER CARDS ============
class TurbulenceGradientShaderCard extends StatefulWidget {
  final CardDimensions dimensions;

  const TurbulenceGradientShaderCard({super.key, required this.dimensions});

  @override
  State<TurbulenceGradientShaderCard> createState() => _TurbulenceGradientShaderCardState();
}

class _TurbulenceGradientShaderCardState extends State<TurbulenceGradientShaderCard> {
  ShaderParams _params = turbulenceGradientDef.defaults;
  bool _showControls = false;

  ShaderUIDefaults get _ui => turbulenceGradientDef.uiDefaults;

  @override
  Widget build(BuildContext context) {
    final dimensions = widget.dimensions;
    final controlsHeight = calculateControlsHeight(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderCardContent(
          width: dimensions.width,
          height: dimensions.height,
          child: TurbulenceGradientShaderFill(
            width: dimensions.width,
            height: dimensions.height,
            params: _params,
          ),
        ),
        ShaderControlsPanel(
          showControls: _showControls,
          onToggle: () => setState(() => _showControls = !_showControls),
          controlsWidth: dimensions.controlsWidth,
          controlsHeight: controlsHeight,
          onReset: () => setState(() => _params = turbulenceGradientDef.defaults),
          shaderName: 'Turbulence',
          onCopyPreset: () => _generatePreset(),
          children: [
            const ControlSectionTitle('Gradient'),
            ControlSlider.fromRange(range: _ui['gradientAngle']!, value: _params.get('gradientAngle'), onChanged: (v) => setState(() => _params = _params.withValue('gradientAngle', v))),
            ControlSlider.fromRange(range: _ui['gradientScale']!, value: _params.get('gradientScale'), onChanged: (v) => setState(() => _params = _params.withValue('gradientScale', v))),
            ControlSlider.fromRange(range: _ui['gradientOffset']!, value: _params.get('gradientOffset'), onChanged: (v) => setState(() => _params = _params.withValue('gradientOffset', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Turbulence Noise'),
            ControlSlider.fromRange(range: _ui['octaves']!, value: _params.get('octaves'), onChanged: (v) => setState(() => _params = _params.withValue('octaves', v))),
            ControlSlider.fromRange(range: _ui['baseFrequency']!, value: _params.get('baseFrequency'), onChanged: (v) => setState(() => _params = _params.withValue('baseFrequency', v))),
            ControlSlider.fromRange(range: _ui['noiseScale']!, value: _params.get('noiseScale'), onChanged: (v) => setState(() => _params = _params.withValue('noiseScale', v))),
            ControlSlider.fromRange(range: _ui['noiseIntensity']!, value: _params.get('noiseIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('noiseIntensity', v))),
            ControlSlider.fromRange(range: _ui['ditherStrength']!, value: _params.get('ditherStrength'), onChanged: (v) => setState(() => _params = _params.withValue('ditherStrength', v))),
            ControlSlider.fromRange(range: _ui['edgeFade']!, value: _params.get('edgeFade'), onChanged: (v) => setState(() => _params = _params.withValue('edgeFade', v))),
            ControlSegmentedButton<double>(
              label: 'Fade Mode',
              value: _params.get('edgeFadeMode'),
              options: const [
                (0.0, 'Both'),
                (1.0, 'Start'),
                (2.0, 'End'),
              ],
              onChanged: (v) => setState(() => _params = _params.withValue('edgeFadeMode', v)),
            ),
            const SizedBox(height: 12),
            const ControlSectionTitle('Animation'),
            ControlSlider.fromRange(range: _ui['animSpeed']!, value: _params.get('animSpeed'), onChanged: (v) => setState(() => _params = _params.withValue('animSpeed', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Colors'),
            ColorSchemeGeneratorWidget(
              colorCount: _params.get('colorCount').toInt(),
              initialColors: [
                for (int i = 0; i < _params.get('colorCount').toInt(); i++)
                  _params.getColor('color$i'),
              ],
              onColorsChanged: (colors) => setState(() {
                for (int i = 0; i < colors.length; i++) {
                  _params = _params.withColor('color$i', colors[i]);
                }
              }),
            ),
            ControlSlider.fromRange(range: _ui['colorCount']!, value: _params.get('colorCount'), onChanged: (v) => setState(() => _params = _params.withValue('colorCount', v))),
            ControlSlider.fromRange(range: _ui['softness']!, value: _params.get('softness'), onChanged: (v) => setState(() => _params = _params.withValue('softness', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Post-Processing'),
            ControlSlider.fromRange(range: _ui['exposure']!, value: _params.get('exposure'), onChanged: (v) => setState(() => _params = _params.withValue('exposure', v))),
            ControlSlider.fromRange(range: _ui['contrast']!, value: _params.get('contrast'), onChanged: (v) => setState(() => _params = _params.withValue('contrast', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Lighting'),
            ControlSlider.fromRange(range: _ui['bumpStrength']!, value: _params.get('bumpStrength'), onChanged: (v) => setState(() => _params = _params.withValue('bumpStrength', v))),
            ControlSlider.fromRange(range: _ui['lightDirX']!, value: _params.get('lightDirX'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirX', v))),
            ControlSlider.fromRange(range: _ui['lightDirY']!, value: _params.get('lightDirY'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirY', v))),
            ControlSlider.fromRange(range: _ui['lightDirZ']!, value: _params.get('lightDirZ'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirZ', v))),
            ControlSlider.fromRange(range: _ui['lightIntensity']!, value: _params.get('lightIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('lightIntensity', v))),
            ControlSlider.fromRange(range: _ui['ambient']!, value: _params.get('ambient'), onChanged: (v) => setState(() => _params = _params.withValue('ambient', v))),
            ControlSlider.fromRange(range: _ui['specular']!, value: _params.get('specular'), onChanged: (v) => setState(() => _params = _params.withValue('specular', v))),
            ControlSlider.fromRange(range: _ui['shininess']!, value: _params.get('shininess'), onChanged: (v) => setState(() => _params = _params.withValue('shininess', v))),
            ControlSlider.fromRange(range: _ui['metallic']!, value: _params.get('metallic'), onChanged: (v) => setState(() => _params = _params.withValue('metallic', v))),
            ControlSlider.fromRange(range: _ui['roughness']!, value: _params.get('roughness'), onChanged: (v) => setState(() => _params = _params.withValue('roughness', v))),
          ],
        ),
      ],
    );
  }

  String _generatePreset() => PresetGenerator.shaderParams(_params);
}

class RadialTurbulenceGradientShaderCard extends StatefulWidget {
  final CardDimensions dimensions;

  const RadialTurbulenceGradientShaderCard({super.key, required this.dimensions});

  @override
  State<RadialTurbulenceGradientShaderCard> createState() => _RadialTurbulenceGradientShaderCardState();
}

class _RadialTurbulenceGradientShaderCardState extends State<RadialTurbulenceGradientShaderCard> {
  ShaderParams _params = radialTurbulenceGradientDef.defaults;
  bool _showControls = false;

  ShaderUIDefaults get _ui => radialTurbulenceGradientDef.uiDefaults;

  @override
  Widget build(BuildContext context) {
    final dimensions = widget.dimensions;
    final controlsHeight = calculateControlsHeight(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderCardContent(
          width: dimensions.width,
          height: dimensions.height,
          child: RadialTurbulenceGradientShaderFill(
            width: dimensions.width,
            height: dimensions.height,
            params: _params,
          ),
        ),
        ShaderControlsPanel(
          showControls: _showControls,
          onToggle: () => setState(() => _showControls = !_showControls),
          controlsWidth: dimensions.controlsWidth,
          controlsHeight: controlsHeight,
          onReset: () => setState(() => _params = radialTurbulenceGradientDef.defaults),
          shaderName: 'Turbulence Radial',
          onCopyPreset: () => _generatePreset(),
          children: [
            const ControlSectionTitle('Gradient'),
            ControlSlider.fromRange(range: _ui['gradientCenterX']!, value: _params.get('gradientCenterX'), onChanged: (v) => setState(() => _params = _params.withValue('gradientCenterX', v))),
            ControlSlider.fromRange(range: _ui['gradientCenterY']!, value: _params.get('gradientCenterY'), onChanged: (v) => setState(() => _params = _params.withValue('gradientCenterY', v))),
            ControlSlider.fromRange(range: _ui['gradientScale']!, value: _params.get('gradientScale'), onChanged: (v) => setState(() => _params = _params.withValue('gradientScale', v))),
            ControlSlider.fromRange(range: _ui['gradientOffset']!, value: _params.get('gradientOffset'), onChanged: (v) => setState(() => _params = _params.withValue('gradientOffset', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Turbulence Noise'),
            ControlSlider.fromRange(range: _ui['octaves']!, value: _params.get('octaves'), onChanged: (v) => setState(() => _params = _params.withValue('octaves', v))),
            ControlSlider.fromRange(range: _ui['baseFrequency']!, value: _params.get('baseFrequency'), onChanged: (v) => setState(() => _params = _params.withValue('baseFrequency', v))),
            ControlSlider.fromRange(range: _ui['noiseScale']!, value: _params.get('noiseScale'), onChanged: (v) => setState(() => _params = _params.withValue('noiseScale', v))),
            ControlSlider.fromRange(range: _ui['noiseIntensity']!, value: _params.get('noiseIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('noiseIntensity', v))),
            ControlSlider.fromRange(range: _ui['ditherStrength']!, value: _params.get('ditherStrength'), onChanged: (v) => setState(() => _params = _params.withValue('ditherStrength', v))),
            ControlSlider.fromRange(range: _ui['edgeFade']!, value: _params.get('edgeFade'), onChanged: (v) => setState(() => _params = _params.withValue('edgeFade', v))),
            ControlSegmentedButton<double>(
              label: 'Fade Mode',
              value: _params.get('edgeFadeMode'),
              options: const [
                (0.0, 'Both'),
                (1.0, 'Start'),
                (2.0, 'End'),
              ],
              onChanged: (v) => setState(() => _params = _params.withValue('edgeFadeMode', v)),
            ),
            const SizedBox(height: 12),
            const ControlSectionTitle('Animation'),
            ControlSlider.fromRange(range: _ui['animSpeed']!, value: _params.get('animSpeed'), onChanged: (v) => setState(() => _params = _params.withValue('animSpeed', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Colors'),
            ColorSchemeGeneratorWidget(
              colorCount: _params.get('colorCount').toInt(),
              initialColors: [
                for (int i = 0; i < _params.get('colorCount').toInt(); i++)
                  _params.getColor('color$i'),
              ],
              onColorsChanged: (colors) => setState(() {
                for (int i = 0; i < colors.length; i++) {
                  _params = _params.withColor('color$i', colors[i]);
                }
              }),
            ),
            ControlSlider.fromRange(range: _ui['colorCount']!, value: _params.get('colorCount'), onChanged: (v) => setState(() => _params = _params.withValue('colorCount', v))),
            ControlSlider.fromRange(range: _ui['softness']!, value: _params.get('softness'), onChanged: (v) => setState(() => _params = _params.withValue('softness', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Post-Processing'),
            ControlSlider.fromRange(range: _ui['exposure']!, value: _params.get('exposure'), onChanged: (v) => setState(() => _params = _params.withValue('exposure', v))),
            ControlSlider.fromRange(range: _ui['contrast']!, value: _params.get('contrast'), onChanged: (v) => setState(() => _params = _params.withValue('contrast', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Lighting'),
            ControlSlider.fromRange(range: _ui['bumpStrength']!, value: _params.get('bumpStrength'), onChanged: (v) => setState(() => _params = _params.withValue('bumpStrength', v))),
            ControlSlider.fromRange(range: _ui['lightDirX']!, value: _params.get('lightDirX'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirX', v))),
            ControlSlider.fromRange(range: _ui['lightDirY']!, value: _params.get('lightDirY'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirY', v))),
            ControlSlider.fromRange(range: _ui['lightDirZ']!, value: _params.get('lightDirZ'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirZ', v))),
            ControlSlider.fromRange(range: _ui['lightIntensity']!, value: _params.get('lightIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('lightIntensity', v))),
            ControlSlider.fromRange(range: _ui['ambient']!, value: _params.get('ambient'), onChanged: (v) => setState(() => _params = _params.withValue('ambient', v))),
            ControlSlider.fromRange(range: _ui['specular']!, value: _params.get('specular'), onChanged: (v) => setState(() => _params = _params.withValue('specular', v))),
            ControlSlider.fromRange(range: _ui['shininess']!, value: _params.get('shininess'), onChanged: (v) => setState(() => _params = _params.withValue('shininess', v))),
            ControlSlider.fromRange(range: _ui['metallic']!, value: _params.get('metallic'), onChanged: (v) => setState(() => _params = _params.withValue('metallic', v))),
            ControlSlider.fromRange(range: _ui['roughness']!, value: _params.get('roughness'), onChanged: (v) => setState(() => _params = _params.withValue('roughness', v))),
          ],
        ),
      ],
    );
  }

  String _generatePreset() => PresetGenerator.shaderParams(_params);
}

// ============ VORONOI GRADIENT SHADER CARDS ============

class VoronoiGradientShaderCard extends StatefulWidget {
  final CardDimensions dimensions;

  const VoronoiGradientShaderCard({super.key, required this.dimensions});

  @override
  State<VoronoiGradientShaderCard> createState() => _VoronoiGradientShaderCardState();
}

class _VoronoiGradientShaderCardState extends State<VoronoiGradientShaderCard> {
  ShaderParams _params = voronoiGradientDef.defaults;
  bool _showControls = false;

  ShaderUIDefaults get _ui => voronoiGradientDef.uiDefaults;

  @override
  Widget build(BuildContext context) {
    final dimensions = widget.dimensions;
    final controlsHeight = calculateControlsHeight(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderCardContent(
          width: dimensions.width,
          height: dimensions.height,
          child: VoronoiGradientShaderFill(
            width: dimensions.width,
            height: dimensions.height,
            params: _params,
          ),
        ),
        ShaderControlsPanel(
          showControls: _showControls,
          onToggle: () => setState(() => _showControls = !_showControls),
          controlsWidth: dimensions.controlsWidth,
          controlsHeight: controlsHeight,
          onReset: () => setState(() => _params = voronoiGradientDef.defaults),
          shaderName: 'Voronoi',
          onCopyPreset: () => _generatePreset(),
          children: [
            const ControlSectionTitle('Gradient'),
            ControlSlider.fromRange(range: _ui['gradientAngle']!, value: _params.get('gradientAngle'), onChanged: (v) => setState(() => _params = _params.withValue('gradientAngle', v))),
            ControlSlider.fromRange(range: _ui['gradientScale']!, value: _params.get('gradientScale'), onChanged: (v) => setState(() => _params = _params.withValue('gradientScale', v))),
            ControlSlider.fromRange(range: _ui['gradientOffset']!, value: _params.get('gradientOffset'), onChanged: (v) => setState(() => _params = _params.withValue('gradientOffset', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Voronoi Noise'),
            ControlSlider.fromRange(range: _ui['cellScale']!, value: _params.get('cellScale'), onChanged: (v) => setState(() => _params = _params.withValue('cellScale', v))),
            ControlSlider.fromRange(range: _ui['cellJitter']!, value: _params.get('cellJitter'), onChanged: (v) => setState(() => _params = _params.withValue('cellJitter', v))),
            ControlSlider.fromRange(range: _ui['distanceType']!, value: _params.get('distanceType'), onChanged: (v) => setState(() => _params = _params.withValue('distanceType', v))),
            ControlSlider.fromRange(range: _ui['outputMode']!, value: _params.get('outputMode'), onChanged: (v) => setState(() => _params = _params.withValue('outputMode', v))),
            ControlSlider.fromRange(range: _ui['cellSmoothness']!, value: _params.get('cellSmoothness'), onChanged: (v) => setState(() => _params = _params.withValue('cellSmoothness', v))),
            ControlSlider.fromRange(range: _ui['noiseIntensity']!, value: _params.get('noiseIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('noiseIntensity', v))),
            ControlSlider.fromRange(range: _ui['ditherStrength']!, value: _params.get('ditherStrength'), onChanged: (v) => setState(() => _params = _params.withValue('ditherStrength', v))),
            ControlSlider.fromRange(range: _ui['edgeFade']!, value: _params.get('edgeFade'), onChanged: (v) => setState(() => _params = _params.withValue('edgeFade', v))),
            ControlSegmentedButton<double>(
              label: 'Fade Mode',
              value: _params.get('edgeFadeMode'),
              options: const [
                (0.0, 'Both'),
                (1.0, 'Start'),
                (2.0, 'End'),
              ],
              onChanged: (v) => setState(() => _params = _params.withValue('edgeFadeMode', v)),
            ),
            const SizedBox(height: 12),
            const ControlSectionTitle('Animation'),
            ControlSlider.fromRange(range: _ui['animSpeed']!, value: _params.get('animSpeed'), onChanged: (v) => setState(() => _params = _params.withValue('animSpeed', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Colors'),
            ColorSchemeGeneratorWidget(
              colorCount: _params.get('colorCount').toInt(),
              initialColors: [
                for (int i = 0; i < _params.get('colorCount').toInt(); i++)
                  _params.getColor('color$i'),
              ],
              onColorsChanged: (colors) => setState(() {
                for (int i = 0; i < colors.length; i++) {
                  _params = _params.withColor('color$i', colors[i]);
                }
              }),
            ),
            ControlSlider.fromRange(range: _ui['colorCount']!, value: _params.get('colorCount'), onChanged: (v) => setState(() => _params = _params.withValue('colorCount', v))),
            ControlSlider.fromRange(range: _ui['softness']!, value: _params.get('softness'), onChanged: (v) => setState(() => _params = _params.withValue('softness', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Post-Processing'),
            ControlSlider.fromRange(range: _ui['exposure']!, value: _params.get('exposure'), onChanged: (v) => setState(() => _params = _params.withValue('exposure', v))),
            ControlSlider.fromRange(range: _ui['contrast']!, value: _params.get('contrast'), onChanged: (v) => setState(() => _params = _params.withValue('contrast', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Lighting'),
            ControlSlider.fromRange(range: _ui['bumpStrength']!, value: _params.get('bumpStrength'), onChanged: (v) => setState(() => _params = _params.withValue('bumpStrength', v))),
            ControlSlider.fromRange(range: _ui['lightDirX']!, value: _params.get('lightDirX'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirX', v))),
            ControlSlider.fromRange(range: _ui['lightDirY']!, value: _params.get('lightDirY'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirY', v))),
            ControlSlider.fromRange(range: _ui['lightDirZ']!, value: _params.get('lightDirZ'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirZ', v))),
            ControlSlider.fromRange(range: _ui['lightIntensity']!, value: _params.get('lightIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('lightIntensity', v))),
            ControlSlider.fromRange(range: _ui['ambient']!, value: _params.get('ambient'), onChanged: (v) => setState(() => _params = _params.withValue('ambient', v))),
            ControlSlider.fromRange(range: _ui['specular']!, value: _params.get('specular'), onChanged: (v) => setState(() => _params = _params.withValue('specular', v))),
            ControlSlider.fromRange(range: _ui['shininess']!, value: _params.get('shininess'), onChanged: (v) => setState(() => _params = _params.withValue('shininess', v))),
            ControlSlider.fromRange(range: _ui['metallic']!, value: _params.get('metallic'), onChanged: (v) => setState(() => _params = _params.withValue('metallic', v))),
            ControlSlider.fromRange(range: _ui['roughness']!, value: _params.get('roughness'), onChanged: (v) => setState(() => _params = _params.withValue('roughness', v))),
          ],
        ),
      ],
    );
  }

  String _generatePreset() => PresetGenerator.shaderParams(_params);
}

class RadialVoronoiGradientShaderCard extends StatefulWidget {
  final CardDimensions dimensions;

  const RadialVoronoiGradientShaderCard({super.key, required this.dimensions});

  @override
  State<RadialVoronoiGradientShaderCard> createState() => _RadialVoronoiGradientShaderCardState();
}

class _RadialVoronoiGradientShaderCardState extends State<RadialVoronoiGradientShaderCard> {
  ShaderParams _params = radialVoronoiGradientDef.defaults;
  bool _showControls = false;

  ShaderUIDefaults get _ui => radialVoronoiGradientDef.uiDefaults;

  @override
  Widget build(BuildContext context) {
    final dimensions = widget.dimensions;
    final controlsHeight = calculateControlsHeight(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderCardContent(
          width: dimensions.width,
          height: dimensions.height,
          child: RadialVoronoiGradientShaderFill(
            width: dimensions.width,
            height: dimensions.height,
            params: _params,
          ),
        ),
        ShaderControlsPanel(
          showControls: _showControls,
          onToggle: () => setState(() => _showControls = !_showControls),
          controlsWidth: dimensions.controlsWidth,
          controlsHeight: controlsHeight,
          onReset: () => setState(() => _params = radialVoronoiGradientDef.defaults),
          shaderName: 'Voronoi Radial',
          onCopyPreset: () => _generatePreset(),
          children: [
            const ControlSectionTitle('Gradient'),
            ControlSlider.fromRange(range: _ui['gradientCenterX']!, value: _params.get('gradientCenterX'), onChanged: (v) => setState(() => _params = _params.withValue('gradientCenterX', v))),
            ControlSlider.fromRange(range: _ui['gradientCenterY']!, value: _params.get('gradientCenterY'), onChanged: (v) => setState(() => _params = _params.withValue('gradientCenterY', v))),
            ControlSlider.fromRange(range: _ui['gradientScale']!, value: _params.get('gradientScale'), onChanged: (v) => setState(() => _params = _params.withValue('gradientScale', v))),
            ControlSlider.fromRange(range: _ui['gradientOffset']!, value: _params.get('gradientOffset'), onChanged: (v) => setState(() => _params = _params.withValue('gradientOffset', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Voronoi Noise'),
            ControlSlider.fromRange(range: _ui['cellScale']!, value: _params.get('cellScale'), onChanged: (v) => setState(() => _params = _params.withValue('cellScale', v))),
            ControlSlider.fromRange(range: _ui['cellJitter']!, value: _params.get('cellJitter'), onChanged: (v) => setState(() => _params = _params.withValue('cellJitter', v))),
            ControlSlider.fromRange(range: _ui['distanceType']!, value: _params.get('distanceType'), onChanged: (v) => setState(() => _params = _params.withValue('distanceType', v))),
            ControlSlider.fromRange(range: _ui['outputMode']!, value: _params.get('outputMode'), onChanged: (v) => setState(() => _params = _params.withValue('outputMode', v))),
            ControlSlider.fromRange(range: _ui['cellSmoothness']!, value: _params.get('cellSmoothness'), onChanged: (v) => setState(() => _params = _params.withValue('cellSmoothness', v))),
            ControlSlider.fromRange(range: _ui['noiseIntensity']!, value: _params.get('noiseIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('noiseIntensity', v))),
            ControlSlider.fromRange(range: _ui['ditherStrength']!, value: _params.get('ditherStrength'), onChanged: (v) => setState(() => _params = _params.withValue('ditherStrength', v))),
            ControlSlider.fromRange(range: _ui['edgeFade']!, value: _params.get('edgeFade'), onChanged: (v) => setState(() => _params = _params.withValue('edgeFade', v))),
            ControlSegmentedButton<double>(
              label: 'Fade Mode',
              value: _params.get('edgeFadeMode'),
              options: const [
                (0.0, 'Both'),
                (1.0, 'Start'),
                (2.0, 'End'),
              ],
              onChanged: (v) => setState(() => _params = _params.withValue('edgeFadeMode', v)),
            ),
            const SizedBox(height: 12),
            const ControlSectionTitle('Animation'),
            ControlSlider.fromRange(range: _ui['animSpeed']!, value: _params.get('animSpeed'), onChanged: (v) => setState(() => _params = _params.withValue('animSpeed', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Colors'),
            ColorSchemeGeneratorWidget(
              colorCount: _params.get('colorCount').toInt(),
              initialColors: [
                for (int i = 0; i < _params.get('colorCount').toInt(); i++)
                  _params.getColor('color$i'),
              ],
              onColorsChanged: (colors) => setState(() {
                for (int i = 0; i < colors.length; i++) {
                  _params = _params.withColor('color$i', colors[i]);
                }
              }),
            ),
            ControlSlider.fromRange(range: _ui['colorCount']!, value: _params.get('colorCount'), onChanged: (v) => setState(() => _params = _params.withValue('colorCount', v))),
            ControlSlider.fromRange(range: _ui['softness']!, value: _params.get('softness'), onChanged: (v) => setState(() => _params = _params.withValue('softness', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Post-Processing'),
            ControlSlider.fromRange(range: _ui['exposure']!, value: _params.get('exposure'), onChanged: (v) => setState(() => _params = _params.withValue('exposure', v))),
            ControlSlider.fromRange(range: _ui['contrast']!, value: _params.get('contrast'), onChanged: (v) => setState(() => _params = _params.withValue('contrast', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Lighting'),
            ControlSlider.fromRange(range: _ui['bumpStrength']!, value: _params.get('bumpStrength'), onChanged: (v) => setState(() => _params = _params.withValue('bumpStrength', v))),
            ControlSlider.fromRange(range: _ui['lightDirX']!, value: _params.get('lightDirX'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirX', v))),
            ControlSlider.fromRange(range: _ui['lightDirY']!, value: _params.get('lightDirY'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirY', v))),
            ControlSlider.fromRange(range: _ui['lightDirZ']!, value: _params.get('lightDirZ'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirZ', v))),
            ControlSlider.fromRange(range: _ui['lightIntensity']!, value: _params.get('lightIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('lightIntensity', v))),
            ControlSlider.fromRange(range: _ui['ambient']!, value: _params.get('ambient'), onChanged: (v) => setState(() => _params = _params.withValue('ambient', v))),
            ControlSlider.fromRange(range: _ui['specular']!, value: _params.get('specular'), onChanged: (v) => setState(() => _params = _params.withValue('specular', v))),
            ControlSlider.fromRange(range: _ui['shininess']!, value: _params.get('shininess'), onChanged: (v) => setState(() => _params = _params.withValue('shininess', v))),
            ControlSlider.fromRange(range: _ui['metallic']!, value: _params.get('metallic'), onChanged: (v) => setState(() => _params = _params.withValue('metallic', v))),
            ControlSlider.fromRange(range: _ui['roughness']!, value: _params.get('roughness'), onChanged: (v) => setState(() => _params = _params.withValue('roughness', v))),
          ],
        ),
      ],
    );
  }

  String _generatePreset() => PresetGenerator.shaderParams(_params);
}

// ============ VORONOISE GRADIENT SHADER CARDS ============

class VoronoiseGradientShaderCard extends StatefulWidget {
  final CardDimensions dimensions;

  const VoronoiseGradientShaderCard({super.key, required this.dimensions});

  @override
  State<VoronoiseGradientShaderCard> createState() => _VoronoiseGradientShaderCardState();
}

class _VoronoiseGradientShaderCardState extends State<VoronoiseGradientShaderCard> {
  ShaderParams _params = voronoiseGradientDef.defaults;
  bool _showControls = false;

  ShaderUIDefaults get _ui => voronoiseGradientDef.uiDefaults;

  @override
  Widget build(BuildContext context) {
    final dimensions = widget.dimensions;
    final controlsHeight = calculateControlsHeight(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderCardContent(
          width: dimensions.width,
          height: dimensions.height,
          child: VoronoiseGradientShaderFill(
            width: dimensions.width,
            height: dimensions.height,
            params: _params,
          ),
        ),
        ShaderControlsPanel(
          showControls: _showControls,
          onToggle: () => setState(() => _showControls = !_showControls),
          controlsWidth: dimensions.controlsWidth,
          controlsHeight: controlsHeight,
          onReset: () => setState(() => _params = voronoiseGradientDef.defaults),
          shaderName: 'Voronoise',
          onCopyPreset: () => _generatePreset(),
          children: [
            const ControlSectionTitle('Gradient'),
            ControlSlider.fromRange(range: _ui['gradientAngle']!, value: _params.get('gradientAngle'), onChanged: (v) => setState(() => _params = _params.withValue('gradientAngle', v))),
            ControlSlider.fromRange(range: _ui['gradientScale']!, value: _params.get('gradientScale'), onChanged: (v) => setState(() => _params = _params.withValue('gradientScale', v))),
            ControlSlider.fromRange(range: _ui['gradientOffset']!, value: _params.get('gradientOffset'), onChanged: (v) => setState(() => _params = _params.withValue('gradientOffset', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Voronoise'),
            ControlSlider.fromRange(range: _ui['cellScale']!, value: _params.get('cellScale'), onChanged: (v) => setState(() => _params = _params.withValue('cellScale', v))),
            ControlSlider.fromRange(range: _ui['noiseBlend']!, value: _params.get('noiseBlend'), onChanged: (v) => setState(() => _params = _params.withValue('noiseBlend', v))),
            ControlSlider.fromRange(range: _ui['edgeSmoothness']!, value: _params.get('edgeSmoothness'), onChanged: (v) => setState(() => _params = _params.withValue('edgeSmoothness', v))),
            ControlSlider.fromRange(range: _ui['noiseIntensity']!, value: _params.get('noiseIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('noiseIntensity', v))),
            ControlSlider.fromRange(range: _ui['ditherStrength']!, value: _params.get('ditherStrength'), onChanged: (v) => setState(() => _params = _params.withValue('ditherStrength', v))),
            ControlSlider.fromRange(range: _ui['edgeFade']!, value: _params.get('edgeFade'), onChanged: (v) => setState(() => _params = _params.withValue('edgeFade', v))),
            ControlSegmentedButton<double>(
              label: 'Fade Mode',
              value: _params.get('edgeFadeMode'),
              options: const [
                (0.0, 'Both'),
                (1.0, 'Start'),
                (2.0, 'End'),
              ],
              onChanged: (v) => setState(() => _params = _params.withValue('edgeFadeMode', v)),
            ),
            const SizedBox(height: 12),
            const ControlSectionTitle('Animation'),
            ControlSlider.fromRange(range: _ui['animSpeed']!, value: _params.get('animSpeed'), onChanged: (v) => setState(() => _params = _params.withValue('animSpeed', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Colors'),
            ColorSchemeGeneratorWidget(
              colorCount: _params.get('colorCount').toInt(),
              initialColors: [
                for (int i = 0; i < _params.get('colorCount').toInt(); i++)
                  _params.getColor('color$i'),
              ],
              onColorsChanged: (colors) => setState(() {
                for (int i = 0; i < colors.length; i++) {
                  _params = _params.withColor('color$i', colors[i]);
                }
              }),
            ),
            ControlSlider.fromRange(range: _ui['colorCount']!, value: _params.get('colorCount'), onChanged: (v) => setState(() => _params = _params.withValue('colorCount', v))),
            ControlSlider.fromRange(range: _ui['softness']!, value: _params.get('softness'), onChanged: (v) => setState(() => _params = _params.withValue('softness', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Post-Processing'),
            ControlSlider.fromRange(range: _ui['exposure']!, value: _params.get('exposure'), onChanged: (v) => setState(() => _params = _params.withValue('exposure', v))),
            ControlSlider.fromRange(range: _ui['contrast']!, value: _params.get('contrast'), onChanged: (v) => setState(() => _params = _params.withValue('contrast', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Lighting'),
            ControlSlider.fromRange(range: _ui['bumpStrength']!, value: _params.get('bumpStrength'), onChanged: (v) => setState(() => _params = _params.withValue('bumpStrength', v))),
            ControlSlider.fromRange(range: _ui['lightDirX']!, value: _params.get('lightDirX'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirX', v))),
            ControlSlider.fromRange(range: _ui['lightDirY']!, value: _params.get('lightDirY'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirY', v))),
            ControlSlider.fromRange(range: _ui['lightDirZ']!, value: _params.get('lightDirZ'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirZ', v))),
            ControlSlider.fromRange(range: _ui['lightIntensity']!, value: _params.get('lightIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('lightIntensity', v))),
            ControlSlider.fromRange(range: _ui['ambient']!, value: _params.get('ambient'), onChanged: (v) => setState(() => _params = _params.withValue('ambient', v))),
            ControlSlider.fromRange(range: _ui['specular']!, value: _params.get('specular'), onChanged: (v) => setState(() => _params = _params.withValue('specular', v))),
            ControlSlider.fromRange(range: _ui['shininess']!, value: _params.get('shininess'), onChanged: (v) => setState(() => _params = _params.withValue('shininess', v))),
            ControlSlider.fromRange(range: _ui['metallic']!, value: _params.get('metallic'), onChanged: (v) => setState(() => _params = _params.withValue('metallic', v))),
            ControlSlider.fromRange(range: _ui['roughness']!, value: _params.get('roughness'), onChanged: (v) => setState(() => _params = _params.withValue('roughness', v))),
          ],
        ),
      ],
    );
  }

  String _generatePreset() => PresetGenerator.shaderParams(_params);
}

class RadialVoronoiseGradientShaderCard extends StatefulWidget {
  final CardDimensions dimensions;

  const RadialVoronoiseGradientShaderCard({super.key, required this.dimensions});

  @override
  State<RadialVoronoiseGradientShaderCard> createState() => _RadialVoronoiseGradientShaderCardState();
}

class _RadialVoronoiseGradientShaderCardState extends State<RadialVoronoiseGradientShaderCard> {
  ShaderParams _params = radialVoronoiseGradientDef.defaults;
  bool _showControls = false;

  ShaderUIDefaults get _ui => radialVoronoiseGradientDef.uiDefaults;

  @override
  Widget build(BuildContext context) {
    final dimensions = widget.dimensions;
    final controlsHeight = calculateControlsHeight(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderCardContent(
          width: dimensions.width,
          height: dimensions.height,
          child: RadialVoronoiseGradientShaderFill(
            width: dimensions.width,
            height: dimensions.height,
            params: _params,
          ),
        ),
        ShaderControlsPanel(
          showControls: _showControls,
          onToggle: () => setState(() => _showControls = !_showControls),
          controlsWidth: dimensions.controlsWidth,
          controlsHeight: controlsHeight,
          onReset: () => setState(() => _params = radialVoronoiseGradientDef.defaults),
          shaderName: 'Voronoise Radial',
          onCopyPreset: () => _generatePreset(),
          children: [
            const ControlSectionTitle('Gradient'),
            ControlSlider.fromRange(range: _ui['gradientCenterX']!, value: _params.get('gradientCenterX'), onChanged: (v) => setState(() => _params = _params.withValue('gradientCenterX', v))),
            ControlSlider.fromRange(range: _ui['gradientCenterY']!, value: _params.get('gradientCenterY'), onChanged: (v) => setState(() => _params = _params.withValue('gradientCenterY', v))),
            ControlSlider.fromRange(range: _ui['gradientScale']!, value: _params.get('gradientScale'), onChanged: (v) => setState(() => _params = _params.withValue('gradientScale', v))),
            ControlSlider.fromRange(range: _ui['gradientOffset']!, value: _params.get('gradientOffset'), onChanged: (v) => setState(() => _params = _params.withValue('gradientOffset', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Voronoise'),
            ControlSlider.fromRange(range: _ui['cellScale']!, value: _params.get('cellScale'), onChanged: (v) => setState(() => _params = _params.withValue('cellScale', v))),
            ControlSlider.fromRange(range: _ui['noiseBlend']!, value: _params.get('noiseBlend'), onChanged: (v) => setState(() => _params = _params.withValue('noiseBlend', v))),
            ControlSlider.fromRange(range: _ui['edgeSmoothness']!, value: _params.get('edgeSmoothness'), onChanged: (v) => setState(() => _params = _params.withValue('edgeSmoothness', v))),
            ControlSlider.fromRange(range: _ui['noiseIntensity']!, value: _params.get('noiseIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('noiseIntensity', v))),
            ControlSlider.fromRange(range: _ui['ditherStrength']!, value: _params.get('ditherStrength'), onChanged: (v) => setState(() => _params = _params.withValue('ditherStrength', v))),
            ControlSlider.fromRange(range: _ui['edgeFade']!, value: _params.get('edgeFade'), onChanged: (v) => setState(() => _params = _params.withValue('edgeFade', v))),
            ControlSegmentedButton<double>(
              label: 'Fade Mode',
              value: _params.get('edgeFadeMode'),
              options: const [
                (0.0, 'Both'),
                (1.0, 'Start'),
                (2.0, 'End'),
              ],
              onChanged: (v) => setState(() => _params = _params.withValue('edgeFadeMode', v)),
            ),
            const SizedBox(height: 12),
            const ControlSectionTitle('Animation'),
            ControlSlider.fromRange(range: _ui['animSpeed']!, value: _params.get('animSpeed'), onChanged: (v) => setState(() => _params = _params.withValue('animSpeed', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Colors'),
            ColorSchemeGeneratorWidget(
              colorCount: _params.get('colorCount').toInt(),
              initialColors: [
                for (int i = 0; i < _params.get('colorCount').toInt(); i++)
                  _params.getColor('color$i'),
              ],
              onColorsChanged: (colors) => setState(() {
                for (int i = 0; i < colors.length; i++) {
                  _params = _params.withColor('color$i', colors[i]);
                }
              }),
            ),
            ControlSlider.fromRange(range: _ui['colorCount']!, value: _params.get('colorCount'), onChanged: (v) => setState(() => _params = _params.withValue('colorCount', v))),
            ControlSlider.fromRange(range: _ui['softness']!, value: _params.get('softness'), onChanged: (v) => setState(() => _params = _params.withValue('softness', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Post-Processing'),
            ControlSlider.fromRange(range: _ui['exposure']!, value: _params.get('exposure'), onChanged: (v) => setState(() => _params = _params.withValue('exposure', v))),
            ControlSlider.fromRange(range: _ui['contrast']!, value: _params.get('contrast'), onChanged: (v) => setState(() => _params = _params.withValue('contrast', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Lighting'),
            ControlSlider.fromRange(range: _ui['bumpStrength']!, value: _params.get('bumpStrength'), onChanged: (v) => setState(() => _params = _params.withValue('bumpStrength', v))),
            ControlSlider.fromRange(range: _ui['lightDirX']!, value: _params.get('lightDirX'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirX', v))),
            ControlSlider.fromRange(range: _ui['lightDirY']!, value: _params.get('lightDirY'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirY', v))),
            ControlSlider.fromRange(range: _ui['lightDirZ']!, value: _params.get('lightDirZ'), onChanged: (v) => setState(() => _params = _params.withValue('lightDirZ', v))),
            ControlSlider.fromRange(range: _ui['lightIntensity']!, value: _params.get('lightIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('lightIntensity', v))),
            ControlSlider.fromRange(range: _ui['ambient']!, value: _params.get('ambient'), onChanged: (v) => setState(() => _params = _params.withValue('ambient', v))),
            ControlSlider.fromRange(range: _ui['specular']!, value: _params.get('specular'), onChanged: (v) => setState(() => _params = _params.withValue('specular', v))),
            ControlSlider.fromRange(range: _ui['shininess']!, value: _params.get('shininess'), onChanged: (v) => setState(() => _params = _params.withValue('shininess', v))),
            ControlSlider.fromRange(range: _ui['metallic']!, value: _params.get('metallic'), onChanged: (v) => setState(() => _params = _params.withValue('metallic', v))),
            ControlSlider.fromRange(range: _ui['roughness']!, value: _params.get('roughness'), onChanged: (v) => setState(() => _params = _params.withValue('roughness', v))),
          ],
        ),
      ],
    );
  }

  String _generatePreset() => PresetGenerator.shaderParams(_params);
}

class BurnShaderCard extends StatefulWidget {
  final CardDimensions dimensions;

  const BurnShaderCard({super.key, required this.dimensions});

  @override
  State<BurnShaderCard> createState() => _BurnShaderCardState();
}

class _BurnShaderCardState extends State<BurnShaderCard> {
  ShaderParams _params = burnShaderDef.defaults;
  bool _showControls = false;
  bool _useExplicit = false;
  int _curveIndex = 2;
  double _durationSec = 3.0;
  double _delaySec = 0.0;
  bool _loop = true;
  bool _reverse = true;
  bool _invert = false;
  double _rangeStart = 0.0;
  double _rangeEnd = 1.0;
  int _animKey = 0;

  ShaderUIDefaults get _ui => burnShaderDef.uiDefaults;

  void _rebuild() => setState(() => _animKey++);

  @override
  Widget build(BuildContext context) {
    final dimensions = widget.dimensions;
    final controlsHeight = calculateControlsHeight(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderCardContent(
          width: dimensions.width,
          height: dimensions.height,
          child: KeyedSubtree(
            key: ValueKey('burn_$_animKey'),
            child: BurnShaderWrap(
              params: _params,
              animationMode: _useExplicit ? ShaderAnimationMode.explicit : ShaderAnimationMode.continuous,
              animationConfig: _useExplicit ? _buildAnimConfig(curveIndex: _curveIndex, durationSec: _durationSec, delaySec: _delaySec, loop: _loop, reverse: _reverse, invert: _invert, rangeStart: _rangeStart, rangeEnd: _rangeEnd) : null,
              child: Image.asset(
                ShaderImageAssets.burn,
                fit: BoxFit.cover,
                width: dimensions.width,
                height: dimensions.height,
              ),
            ),
          ),
        ),
        ShaderControlsPanel(
          showControls: _showControls,
          onToggle: () => setState(() => _showControls = !_showControls),
          controlsWidth: dimensions.controlsWidth,
          controlsHeight: controlsHeight,
          onReset: () => setState(() => _params = burnShaderDef.defaults),
          shaderName: 'Burn',
          onCopyPreset: () => _generatePreset(),
          children: [
            const ControlSectionTitle('Burn Direction'),
            ControlSlider.fromRange(range: _ui['angle']!, value: _params.get('angle'), onChanged: (v) => setState(() => _params = _params.withValue('angle', v))),
            ControlSlider.fromRange(range: _ui['scale']!, value: _params.get('scale'), onChanged: (v) => setState(() => _params = _params.withValue('scale', v))),
            ControlSlider.fromRange(range: _ui['offset']!, value: _params.get('offset'), onChanged: (v) => setState(() => _params = _params.withValue('offset', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Noise & Edge'),
            ControlSlider.fromRange(range: _ui['noiseScale']!, value: _params.get('noiseScale'), onChanged: (v) => setState(() => _params = _params.withValue('noiseScale', v))),
            ControlSlider.fromRange(range: _ui['edgeWidth']!, value: _params.get('edgeWidth'), onChanged: (v) => setState(() => _params = _params.withValue('edgeWidth', v))),
            ControlSlider.fromRange(range: _ui['glowIntensity']!, value: _params.get('glowIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('glowIntensity', v))),
            ControlColorPicker(label: 'Fire Color', color: _params.getColor('fireColor'), onChanged: (c) => setState(() => _params = _params.withColor('fireColor', c))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Animation'),
            ControlSegmentedButton<bool>(label: 'Mode', value: _useExplicit, options: const [(false, 'Continuous'), (true, 'Explicit')], onChanged: (v) { _useExplicit = v; _rebuild(); }),
            if (!_useExplicit)
              ControlSlider.fromRange(range: _ui['speed']!, value: _params.get('speed'), onChanged: (v) => setState(() => _params = _params.withValue('speed', v))),
            if (_useExplicit) ...[
              const SizedBox(height: 8),
              _buildCurveChips(selectedIndex: _curveIndex, onChanged: (i) { _curveIndex = i; _rebuild(); }),
              const SizedBox(height: 8),
              ControlSlider(label: 'Duration (s)', value: _durationSec, min: 0.5, max: 10.0, onChanged: (v) { _durationSec = v; _rebuild(); }),
              ControlSlider(label: 'Delay (s)', value: _delaySec, min: 0.0, max: 3.0, onChanged: (v) { _delaySec = v; _rebuild(); }),
              SwitchListTile(title: const Text('Loop', style: TextStyle(fontSize: 12)), value: _loop, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) { _loop = v; _rebuild(); }),
              SwitchListTile(title: const Text('Reverse', style: TextStyle(fontSize: 12)), value: _reverse, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) { _reverse = v; _rebuild(); }),
              SwitchListTile(title: const Text('Invert', style: TextStyle(fontSize: 12)), value: _invert, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) { _invert = v; _rebuild(); }),
              ControlSlider(label: 'Range Start', value: _rangeStart, min: 0.0, max: 1.0, onChanged: (v) { _rangeStart = v; _rebuild(); }),
              ControlSlider(label: 'Range End', value: _rangeEnd, min: 0.0, max: 1.0, onChanged: (v) { _rangeEnd = v; _rebuild(); }),
            ],
          ],
        ),
      ],
    );
  }

  String _generatePreset() => PresetGenerator.shaderParams(_params);
}

class RadialBurnShaderCard extends StatefulWidget {
  final CardDimensions dimensions;

  const RadialBurnShaderCard({super.key, required this.dimensions});

  @override
  State<RadialBurnShaderCard> createState() => _RadialBurnShaderCardState();
}

class _RadialBurnShaderCardState extends State<RadialBurnShaderCard> {
  ShaderParams _params = radialBurnShaderDef.defaults;
  bool _showControls = false;
  bool _useExplicit = false;
  int _curveIndex = 2;
  double _durationSec = 3.0;
  double _delaySec = 0.0;
  bool _loop = true;
  bool _reverse = true;
  bool _invert = false;
  double _rangeStart = 0.0;
  double _rangeEnd = 1.0;
  int _animKey = 0;

  ShaderUIDefaults get _ui => radialBurnShaderDef.uiDefaults;

  void _rebuild() => setState(() => _animKey++);

  @override
  Widget build(BuildContext context) {
    final dimensions = widget.dimensions;
    final controlsHeight = calculateControlsHeight(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderCardContent(
          width: dimensions.width,
          height: dimensions.height,
          child: KeyedSubtree(
            key: ValueKey('radialBurn_$_animKey'),
            child: RadialBurnShaderWrap(
              params: _params,
              animationMode: _useExplicit ? ShaderAnimationMode.explicit : ShaderAnimationMode.continuous,
              animationConfig: _useExplicit ? _buildAnimConfig(curveIndex: _curveIndex, durationSec: _durationSec, delaySec: _delaySec, loop: _loop, reverse: _reverse, invert: _invert, rangeStart: _rangeStart, rangeEnd: _rangeEnd) : null,
              child: Image.asset(
                ShaderImageAssets.radialBurn,
                fit: BoxFit.cover,
                width: dimensions.width,
                height: dimensions.height,
              ),
            ),
          ),
        ),
        ShaderControlsPanel(
          showControls: _showControls,
          onToggle: () => setState(() => _showControls = !_showControls),
          controlsWidth: dimensions.controlsWidth,
          controlsHeight: controlsHeight,
          onReset: () => setState(() => _params = radialBurnShaderDef.defaults),
          shaderName: 'Burn Radial',
          onCopyPreset: () => _generatePreset(),
          children: [
            const ControlSectionTitle('Burn Center'),
            ControlSlider.fromRange(range: _ui['burnCenterX']!, value: _params.get('burnCenterX'), onChanged: (v) => setState(() => _params = _params.withValue('burnCenterX', v))),
            ControlSlider.fromRange(range: _ui['burnCenterY']!, value: _params.get('burnCenterY'), onChanged: (v) => setState(() => _params = _params.withValue('burnCenterY', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Noise & Edge'),
            ControlSlider.fromRange(range: _ui['burnScale']!, value: _params.get('burnScale'), onChanged: (v) => setState(() => _params = _params.withValue('burnScale', v))),
            ControlSlider.fromRange(range: _ui['noiseScale']!, value: _params.get('noiseScale'), onChanged: (v) => setState(() => _params = _params.withValue('noiseScale', v))),
            ControlSlider.fromRange(range: _ui['edgeWidth']!, value: _params.get('edgeWidth'), onChanged: (v) => setState(() => _params = _params.withValue('edgeWidth', v))),
            ControlSlider.fromRange(range: _ui['glowIntensity']!, value: _params.get('glowIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('glowIntensity', v))),
            ControlColorPicker(label: 'Fire Color', color: _params.getColor('fireColor'), onChanged: (c) => setState(() => _params = _params.withColor('fireColor', c))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Animation'),
            ControlSegmentedButton<bool>(label: 'Mode', value: _useExplicit, options: const [(false, 'Continuous'), (true, 'Explicit')], onChanged: (v) { _useExplicit = v; _rebuild(); }),
            if (!_useExplicit)
              ControlSlider.fromRange(range: _ui['speed']!, value: _params.get('speed'), onChanged: (v) => setState(() => _params = _params.withValue('speed', v))),
            if (_useExplicit) ...[
              const SizedBox(height: 8),
              _buildCurveChips(selectedIndex: _curveIndex, onChanged: (i) { _curveIndex = i; _rebuild(); }),
              const SizedBox(height: 8),
              ControlSlider(label: 'Duration (s)', value: _durationSec, min: 0.5, max: 10.0, onChanged: (v) { _durationSec = v; _rebuild(); }),
              ControlSlider(label: 'Delay (s)', value: _delaySec, min: 0.0, max: 3.0, onChanged: (v) { _delaySec = v; _rebuild(); }),
              SwitchListTile(title: const Text('Loop', style: TextStyle(fontSize: 12)), value: _loop, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) { _loop = v; _rebuild(); }),
              SwitchListTile(title: const Text('Reverse', style: TextStyle(fontSize: 12)), value: _reverse, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) { _reverse = v; _rebuild(); }),
              SwitchListTile(title: const Text('Invert', style: TextStyle(fontSize: 12)), value: _invert, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) { _invert = v; _rebuild(); }),
              ControlSlider(label: 'Range Start', value: _rangeStart, min: 0.0, max: 1.0, onChanged: (v) { _rangeStart = v; _rebuild(); }),
              ControlSlider(label: 'Range End', value: _rangeEnd, min: 0.0, max: 1.0, onChanged: (v) { _rangeEnd = v; _rebuild(); }),
            ],
          ],
        ),
      ],
    );
  }

  String _generatePreset() => PresetGenerator.shaderParams(_params);
}

class TappableBurnShaderCard extends StatefulWidget {
  final CardDimensions dimensions;

  const TappableBurnShaderCard({super.key, required this.dimensions});

  @override
  State<TappableBurnShaderCard> createState() => _TappableBurnShaderCardState();
}

class _TappableBurnShaderCardState extends State<TappableBurnShaderCard> {
  ShaderParams _params = tappableBurnShaderDef.defaults;
  bool _showControls = false;
  int _curveIndex = 0;
  double _durationSec = 1.5;
  double _delaySec = 0.0;
  bool _reverse = true;
  bool _invert = false;
  bool _persistTaps = false;
  double _rangeStart = 0.0;
  double _rangeEnd = 1.0;
  int _tapKey = 0;

  ShaderUIDefaults get _ui => tappableBurnShaderDef.uiDefaults;

  void _rebuild() => setState(() => _tapKey++);

  ShaderAnimationConfig _buildTapConfig() => _buildAnimConfig(
    curveIndex: _curveIndex, durationSec: _durationSec, delaySec: _delaySec,
    loop: false, reverse: _reverse, invert: _invert,
    rangeStart: _rangeStart, rangeEnd: _rangeEnd,
  );

  @override
  Widget build(BuildContext context) {
    final dimensions = widget.dimensions;
    final controlsHeight = calculateControlsHeight(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderCardContent(
          width: dimensions.width,
          height: dimensions.height,
          child: TappableBurnShaderWrap(
            key: ValueKey('tapBurn_$_tapKey'),
            params: _params,
            tapConfig: _buildTapConfig(),
            persistTaps: _persistTaps,
            child: Image.asset(
              ShaderImageAssets.tapBurn,
              fit: BoxFit.cover,
              width: dimensions.width,
              height: dimensions.height,
            ),
          ),
        ),
        ShaderControlsPanel(
          showControls: _showControls,
          onToggle: () => setState(() => _showControls = !_showControls),
          controlsWidth: dimensions.controlsWidth,
          controlsHeight: controlsHeight,
          onReset: () => setState(() => _params = tappableBurnShaderDef.defaults),
          shaderName: 'Burn Tap',
          onCopyPreset: () => _generatePreset(),
          children: [
            const ControlSectionTitle('Burn Properties'),
            ControlSlider.fromRange(range: _ui['noiseScale']!, value: _params.get('noiseScale'), onChanged: (v) => setState(() => _params = _params.withValue('noiseScale', v))),
            ControlSlider.fromRange(range: _ui['edgeWidth']!, value: _params.get('edgeWidth'), onChanged: (v) => setState(() => _params = _params.withValue('edgeWidth', v))),
            ControlSlider.fromRange(range: _ui['glowIntensity']!, value: _params.get('glowIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('glowIntensity', v))),
            ControlColorPicker(label: 'Fire Color', color: _params.getColor('fireColor'), onChanged: (c) => setState(() => _params = _params.withColor('fireColor', c))),
            ControlSlider.fromRange(range: _ui['burnRadius']!, value: _params.get('burnRadius'), onChanged: (v) => setState(() => _params = _params.withValue('burnRadius', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Tap Animation'),
            _buildCurveChips(selectedIndex: _curveIndex, onChanged: (i) { _curveIndex = i; _rebuild(); }),
            const SizedBox(height: 8),
            ControlSlider(label: 'Duration (s)', value: _durationSec, min: 0.2, max: 5.0, onChanged: (v) { _durationSec = v; _rebuild(); }),
            ControlSlider(label: 'Delay (s)', value: _delaySec, min: 0.0, max: 2.0, onChanged: (v) { _delaySec = v; _rebuild(); }),
            SwitchListTile(title: const Text('Reverse', style: TextStyle(fontSize: 12)), value: _reverse, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) { _reverse = v; _rebuild(); }),
            SwitchListTile(title: const Text('Invert', style: TextStyle(fontSize: 12)), value: _invert, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) { _invert = v; _rebuild(); }),
            SwitchListTile(title: const Text('Persist taps', style: TextStyle(fontSize: 12)), value: _persistTaps, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) { _persistTaps = v; _rebuild(); }),
            ControlSlider(label: 'Range Start', value: _rangeStart, min: 0.0, max: 1.0, onChanged: (v) { _rangeStart = v; _rebuild(); }),
            ControlSlider(label: 'Range End', value: _rangeEnd, min: 0.0, max: 1.0, onChanged: (v) { _rangeEnd = v; _rebuild(); }),
          ],
        ),
      ],
    );
  }

  String _generatePreset() => PresetGenerator.shaderParams(_params);
}

class SmokeShaderCard extends StatefulWidget {
  final CardDimensions dimensions;

  const SmokeShaderCard({super.key, required this.dimensions});

  @override
  State<SmokeShaderCard> createState() => _SmokeShaderCardState();
}

class _SmokeShaderCardState extends State<SmokeShaderCard> {
  ShaderParams _params = smokeShaderDef.defaults;
  bool _showControls = false;
  bool _useExplicit = false;
  int _curveIndex = 2;
  double _durationSec = 3.0;
  double _delaySec = 0.0;
  bool _loop = true;
  bool _reverse = true;
  bool _invert = false;
  double _rangeStart = 0.0;
  double _rangeEnd = 1.0;
  int _animKey = 0;

  ShaderUIDefaults get _ui => smokeShaderDef.uiDefaults;

  void _rebuild() => setState(() => _animKey++);

  @override
  Widget build(BuildContext context) {
    final dimensions = widget.dimensions;
    final controlsHeight = calculateControlsHeight(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderCardContent(
          width: dimensions.width,
          height: dimensions.height,
          child: KeyedSubtree(
            key: ValueKey('smoke_$_animKey'),
            child: SmokeShaderWrap(
              params: _params,
              animationMode: _useExplicit ? ShaderAnimationMode.explicit : ShaderAnimationMode.continuous,
              animationConfig: _useExplicit ? _buildAnimConfig(curveIndex: _curveIndex, durationSec: _durationSec, delaySec: _delaySec, loop: _loop, reverse: _reverse, invert: _invert, rangeStart: _rangeStart, rangeEnd: _rangeEnd) : null,
              child: Image.asset(
                ShaderImageAssets.smoke,
                fit: BoxFit.cover,
                width: dimensions.width,
                height: dimensions.height,
              ),
            ),
          ),
        ),
        ShaderControlsPanel(
          showControls: _showControls,
          onToggle: () => setState(() => _showControls = !_showControls),
          controlsWidth: dimensions.controlsWidth,
          controlsHeight: controlsHeight,
          onReset: () => setState(() => _params = smokeShaderDef.defaults),
          shaderName: 'Smoke',
          onCopyPreset: () => _generatePreset(),
          children: [
            const ControlSectionTitle('Smoke Direction'),
            ControlSlider.fromRange(range: _ui['angle']!, value: _params.get('angle'), onChanged: (v) => setState(() => _params = _params.withValue('angle', v))),
            ControlSlider.fromRange(range: _ui['scale']!, value: _params.get('scale'), onChanged: (v) => setState(() => _params = _params.withValue('scale', v))),
            ControlSlider.fromRange(range: _ui['offset']!, value: _params.get('offset'), onChanged: (v) => setState(() => _params = _params.withValue('offset', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Noise & Edge'),
            ControlSlider.fromRange(range: _ui['noiseScale']!, value: _params.get('noiseScale'), onChanged: (v) => setState(() => _params = _params.withValue('noiseScale', v))),
            ControlSlider.fromRange(range: _ui['edgeWidth']!, value: _params.get('edgeWidth'), onChanged: (v) => setState(() => _params = _params.withValue('edgeWidth', v))),
            ControlSlider.fromRange(range: _ui['glowIntensity']!, value: _params.get('glowIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('glowIntensity', v))),
            ControlColorPicker(label: 'Smoke Color', color: _params.getColor('smokeColor'), onChanged: (c) => setState(() => _params = _params.withColor('smokeColor', c))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Animation'),
            ControlSegmentedButton<bool>(label: 'Mode', value: _useExplicit, options: const [(false, 'Continuous'), (true, 'Explicit')], onChanged: (v) { _useExplicit = v; _rebuild(); }),
            if (!_useExplicit)
              ControlSlider.fromRange(range: _ui['speed']!, value: _params.get('speed'), onChanged: (v) => setState(() => _params = _params.withValue('speed', v))),
            if (_useExplicit) ...[
              const SizedBox(height: 8),
              _buildCurveChips(selectedIndex: _curveIndex, onChanged: (i) { _curveIndex = i; _rebuild(); }),
              const SizedBox(height: 8),
              ControlSlider(label: 'Duration (s)', value: _durationSec, min: 0.5, max: 10.0, onChanged: (v) { _durationSec = v; _rebuild(); }),
              ControlSlider(label: 'Delay (s)', value: _delaySec, min: 0.0, max: 3.0, onChanged: (v) { _delaySec = v; _rebuild(); }),
              SwitchListTile(title: const Text('Loop', style: TextStyle(fontSize: 12)), value: _loop, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) { _loop = v; _rebuild(); }),
              SwitchListTile(title: const Text('Reverse', style: TextStyle(fontSize: 12)), value: _reverse, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) { _reverse = v; _rebuild(); }),
              SwitchListTile(title: const Text('Invert', style: TextStyle(fontSize: 12)), value: _invert, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) { _invert = v; _rebuild(); }),
              ControlSlider(label: 'Range Start', value: _rangeStart, min: 0.0, max: 1.0, onChanged: (v) { _rangeStart = v; _rebuild(); }),
              ControlSlider(label: 'Range End', value: _rangeEnd, min: 0.0, max: 1.0, onChanged: (v) { _rangeEnd = v; _rebuild(); }),
            ],
          ],
        ),
      ],
    );
  }

  String _generatePreset() => PresetGenerator.shaderParams(_params);
}

class RadialSmokeShaderCard extends StatefulWidget {
  final CardDimensions dimensions;

  const RadialSmokeShaderCard({super.key, required this.dimensions});

  @override
  State<RadialSmokeShaderCard> createState() => _RadialSmokeShaderCardState();
}

class _RadialSmokeShaderCardState extends State<RadialSmokeShaderCard> {
  ShaderParams _params = radialSmokeShaderDef.defaults;
  bool _showControls = false;
  bool _useExplicit = false;
  int _curveIndex = 2;
  double _durationSec = 3.0;
  double _delaySec = 0.0;
  bool _loop = true;
  bool _reverse = true;
  bool _invert = false;
  double _rangeStart = 0.0;
  double _rangeEnd = 1.0;
  int _animKey = 0;

  ShaderUIDefaults get _ui => radialSmokeShaderDef.uiDefaults;

  void _rebuild() => setState(() => _animKey++);

  @override
  Widget build(BuildContext context) {
    final dimensions = widget.dimensions;
    final controlsHeight = calculateControlsHeight(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderCardContent(
          width: dimensions.width,
          height: dimensions.height,
          child: KeyedSubtree(
            key: ValueKey('radialSmoke_$_animKey'),
            child: RadialSmokeShaderWrap(
              params: _params,
              animationMode: _useExplicit ? ShaderAnimationMode.explicit : ShaderAnimationMode.continuous,
              animationConfig: _useExplicit ? _buildAnimConfig(curveIndex: _curveIndex, durationSec: _durationSec, delaySec: _delaySec, loop: _loop, reverse: _reverse, invert: _invert, rangeStart: _rangeStart, rangeEnd: _rangeEnd) : null,
              child: Image.asset(
                ShaderImageAssets.radialSmoke,
                fit: BoxFit.cover,
                width: dimensions.width,
                height: dimensions.height,
              ),
            ),
          ),
        ),
        ShaderControlsPanel(
          showControls: _showControls,
          onToggle: () => setState(() => _showControls = !_showControls),
          controlsWidth: dimensions.controlsWidth,
          controlsHeight: controlsHeight,
          onReset: () => setState(() => _params = radialSmokeShaderDef.defaults),
          shaderName: 'Smoke Radial',
          onCopyPreset: () => _generatePreset(),
          children: [
            const ControlSectionTitle('Smoke Center'),
            ControlSlider.fromRange(range: _ui['burnCenterX']!, value: _params.get('burnCenterX'), onChanged: (v) => setState(() => _params = _params.withValue('burnCenterX', v))),
            ControlSlider.fromRange(range: _ui['burnCenterY']!, value: _params.get('burnCenterY'), onChanged: (v) => setState(() => _params = _params.withValue('burnCenterY', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Noise & Edge'),
            ControlSlider.fromRange(range: _ui['burnScale']!, value: _params.get('burnScale'), onChanged: (v) => setState(() => _params = _params.withValue('burnScale', v))),
            ControlSlider.fromRange(range: _ui['noiseScale']!, value: _params.get('noiseScale'), onChanged: (v) => setState(() => _params = _params.withValue('noiseScale', v))),
            ControlSlider.fromRange(range: _ui['edgeWidth']!, value: _params.get('edgeWidth'), onChanged: (v) => setState(() => _params = _params.withValue('edgeWidth', v))),
            ControlSlider.fromRange(range: _ui['glowIntensity']!, value: _params.get('glowIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('glowIntensity', v))),
            ControlColorPicker(label: 'Smoke Color', color: _params.getColor('smokeColor'), onChanged: (c) => setState(() => _params = _params.withColor('smokeColor', c))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Animation'),
            ControlSegmentedButton<bool>(label: 'Mode', value: _useExplicit, options: const [(false, 'Continuous'), (true, 'Explicit')], onChanged: (v) { _useExplicit = v; _rebuild(); }),
            if (!_useExplicit)
              ControlSlider.fromRange(range: _ui['speed']!, value: _params.get('speed'), onChanged: (v) => setState(() => _params = _params.withValue('speed', v))),
            if (_useExplicit) ...[
              const SizedBox(height: 8),
              _buildCurveChips(selectedIndex: _curveIndex, onChanged: (i) { _curveIndex = i; _rebuild(); }),
              const SizedBox(height: 8),
              ControlSlider(label: 'Duration (s)', value: _durationSec, min: 0.5, max: 10.0, onChanged: (v) { _durationSec = v; _rebuild(); }),
              ControlSlider(label: 'Delay (s)', value: _delaySec, min: 0.0, max: 3.0, onChanged: (v) { _delaySec = v; _rebuild(); }),
              SwitchListTile(title: const Text('Loop', style: TextStyle(fontSize: 12)), value: _loop, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) { _loop = v; _rebuild(); }),
              SwitchListTile(title: const Text('Reverse', style: TextStyle(fontSize: 12)), value: _reverse, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) { _reverse = v; _rebuild(); }),
              SwitchListTile(title: const Text('Invert', style: TextStyle(fontSize: 12)), value: _invert, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) { _invert = v; _rebuild(); }),
              ControlSlider(label: 'Range Start', value: _rangeStart, min: 0.0, max: 1.0, onChanged: (v) { _rangeStart = v; _rebuild(); }),
              ControlSlider(label: 'Range End', value: _rangeEnd, min: 0.0, max: 1.0, onChanged: (v) { _rangeEnd = v; _rebuild(); }),
            ],
          ],
        ),
      ],
    );
  }

  String _generatePreset() => PresetGenerator.shaderParams(_params);
}

class TappableSmokeShaderCard extends StatefulWidget {
  final CardDimensions dimensions;

  const TappableSmokeShaderCard({super.key, required this.dimensions});

  @override
  State<TappableSmokeShaderCard> createState() => _TappableSmokeShaderCardState();
}

class _TappableSmokeShaderCardState extends State<TappableSmokeShaderCard> {
  ShaderParams _params = tappableSmokeShaderDef.defaults;
  bool _showControls = false;
  int _curveIndex = 0;
  double _durationSec = 1.5;
  double _delaySec = 0.0;
  bool _reverse = true;
  bool _invert = false;
  bool _persistTaps = false;
  double _rangeStart = 0.0;
  double _rangeEnd = 1.0;
  int _tapKey = 0;

  ShaderUIDefaults get _ui => tappableSmokeShaderDef.uiDefaults;

  void _rebuild() => setState(() => _tapKey++);

  ShaderAnimationConfig _buildTapConfig() => _buildAnimConfig(
    curveIndex: _curveIndex, durationSec: _durationSec, delaySec: _delaySec,
    loop: false, reverse: _reverse, invert: _invert,
    rangeStart: _rangeStart, rangeEnd: _rangeEnd,
  );

  @override
  Widget build(BuildContext context) {
    final dimensions = widget.dimensions;
    final controlsHeight = calculateControlsHeight(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderCardContent(
          width: dimensions.width,
          height: dimensions.height,
          child: TappableSmokeShaderWrap(
            key: ValueKey('tapSmoke_$_tapKey'),
            params: _params,
            tapConfig: _buildTapConfig(),
            persistTaps: _persistTaps,
            child: Image.asset(
              ShaderImageAssets.tapSmoke,
              fit: BoxFit.cover,
              width: dimensions.width,
              height: dimensions.height,
            ),
          ),
        ),
        ShaderControlsPanel(
          showControls: _showControls,
          onToggle: () => setState(() => _showControls = !_showControls),
          controlsWidth: dimensions.controlsWidth,
          controlsHeight: controlsHeight,
          onReset: () => setState(() => _params = tappableSmokeShaderDef.defaults),
          shaderName: 'Smoke Tap',
          onCopyPreset: () => _generatePreset(),
          children: [
            const ControlSectionTitle('Smoke Properties'),
            ControlSlider.fromRange(range: _ui['noiseScale']!, value: _params.get('noiseScale'), onChanged: (v) => setState(() => _params = _params.withValue('noiseScale', v))),
            ControlSlider.fromRange(range: _ui['edgeWidth']!, value: _params.get('edgeWidth'), onChanged: (v) => setState(() => _params = _params.withValue('edgeWidth', v))),
            ControlSlider.fromRange(range: _ui['glowIntensity']!, value: _params.get('glowIntensity'), onChanged: (v) => setState(() => _params = _params.withValue('glowIntensity', v))),
            ControlColorPicker(label: 'Smoke Color', color: _params.getColor('smokeColor'), onChanged: (c) => setState(() => _params = _params.withColor('smokeColor', c))),
            ControlSlider.fromRange(range: _ui['burnRadius']!, value: _params.get('burnRadius'), onChanged: (v) => setState(() => _params = _params.withValue('burnRadius', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Tap Animation'),
            _buildCurveChips(selectedIndex: _curveIndex, onChanged: (i) { _curveIndex = i; _rebuild(); }),
            const SizedBox(height: 8),
            ControlSlider(label: 'Duration (s)', value: _durationSec, min: 0.2, max: 5.0, onChanged: (v) { _durationSec = v; _rebuild(); }),
            ControlSlider(label: 'Delay (s)', value: _delaySec, min: 0.0, max: 2.0, onChanged: (v) { _delaySec = v; _rebuild(); }),
            SwitchListTile(title: const Text('Reverse', style: TextStyle(fontSize: 12)), value: _reverse, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) { _reverse = v; _rebuild(); }),
            SwitchListTile(title: const Text('Invert', style: TextStyle(fontSize: 12)), value: _invert, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) { _invert = v; _rebuild(); }),
            SwitchListTile(title: const Text('Persist taps', style: TextStyle(fontSize: 12)), value: _persistTaps, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) { _persistTaps = v; _rebuild(); }),
            ControlSlider(label: 'Range Start', value: _rangeStart, min: 0.0, max: 1.0, onChanged: (v) { _rangeStart = v; _rebuild(); }),
            ControlSlider(label: 'Range End', value: _rangeEnd, min: 0.0, max: 1.0, onChanged: (v) { _rangeEnd = v; _rebuild(); }),
          ],
        ),
      ],
    );
  }

  String _generatePreset() => PresetGenerator.shaderParams(_params);
}

class PixelDissolveShaderCard extends StatefulWidget {
  final CardDimensions dimensions;

  const PixelDissolveShaderCard({super.key, required this.dimensions});

  @override
  State<PixelDissolveShaderCard> createState() => _PixelDissolveShaderCardState();
}

class _PixelDissolveShaderCardState extends State<PixelDissolveShaderCard> {
  ShaderParams _params = pixelDissolveShaderDef.defaults;
  bool _showControls = false;
  bool _useExplicit = false;
  int _curveIndex = 2;
  double _durationSec = 3.0;
  double _delaySec = 0.0;
  bool _loop = true;
  bool _reverse = true;
  bool _invert = false;
  double _rangeStart = 0.0;
  double _rangeEnd = 1.0;
  int _animKey = 0;

  ShaderUIDefaults get _ui => pixelDissolveShaderDef.uiDefaults;

  void _rebuild() => setState(() => _animKey++);

  @override
  Widget build(BuildContext context) {
    final dimensions = widget.dimensions;
    final controlsHeight = calculateControlsHeight(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderCardContent(
          width: dimensions.width,
          height: dimensions.height,
          child: KeyedSubtree(
            key: ValueKey('pixelDissolve_$_animKey'),
            child: PixelDissolveShaderWrap(
              params: _params,
              animationMode: _useExplicit ? ShaderAnimationMode.explicit : ShaderAnimationMode.continuous,
              animationConfig: _useExplicit ? _buildAnimConfig(curveIndex: _curveIndex, durationSec: _durationSec, delaySec: _delaySec, loop: _loop, reverse: _reverse, invert: _invert, rangeStart: _rangeStart, rangeEnd: _rangeEnd) : null,
              child: Image.asset(
                ShaderImageAssets.pixelDissolve,
                fit: BoxFit.cover,
                width: dimensions.width,
                height: dimensions.height,
              ),
            ),
          ),
        ),
        ShaderControlsPanel(
          showControls: _showControls,
          onToggle: () => setState(() => _showControls = !_showControls),
          controlsWidth: dimensions.controlsWidth,
          controlsHeight: controlsHeight,
          onReset: () => setState(() => _params = pixelDissolveShaderDef.defaults),
          shaderName: 'Pixel Dissolve',
          onCopyPreset: () => _generatePreset(),
          children: [
            const ControlSectionTitle('Dissolve Direction'),
            ControlSlider.fromRange(range: _ui['angle']!, value: _params.get('angle'), onChanged: (v) => setState(() => _params = _params.withValue('angle', v))),
            ControlSlider.fromRange(range: _ui['scale']!, value: _params.get('scale'), onChanged: (v) => setState(() => _params = _params.withValue('scale', v))),
            ControlSlider.fromRange(range: _ui['offset']!, value: _params.get('offset'), onChanged: (v) => setState(() => _params = _params.withValue('offset', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Pixel Properties'),
            ControlSlider.fromRange(range: _ui['pixelSize']!, value: _params.get('pixelSize'), onChanged: (v) => setState(() => _params = _params.withValue('pixelSize', v))),
            ControlSlider.fromRange(range: _ui['edgeWidth']!, value: _params.get('edgeWidth'), onChanged: (v) => setState(() => _params = _params.withValue('edgeWidth', v))),
            ControlSlider.fromRange(range: _ui['scatter']!, value: _params.get('scatter'), onChanged: (v) => setState(() => _params = _params.withValue('scatter', v))),
            ControlSlider.fromRange(range: _ui['noiseAmount']!, value: _params.get('noiseAmount'), onChanged: (v) => setState(() => _params = _params.withValue('noiseAmount', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Animation'),
            ControlSegmentedButton<bool>(label: 'Mode', value: _useExplicit, options: const [(false, 'Continuous'), (true, 'Explicit')], onChanged: (v) { _useExplicit = v; _rebuild(); }),
            if (!_useExplicit)
              ControlSlider.fromRange(range: _ui['speed']!, value: _params.get('speed'), onChanged: (v) => setState(() => _params = _params.withValue('speed', v))),
            if (_useExplicit) ...[
              const SizedBox(height: 8),
              _buildCurveChips(selectedIndex: _curveIndex, onChanged: (i) { _curveIndex = i; _rebuild(); }),
              const SizedBox(height: 8),
              ControlSlider(label: 'Duration (s)', value: _durationSec, min: 0.5, max: 10.0, onChanged: (v) { _durationSec = v; _rebuild(); }),
              ControlSlider(label: 'Delay (s)', value: _delaySec, min: 0.0, max: 3.0, onChanged: (v) { _delaySec = v; _rebuild(); }),
              SwitchListTile(title: const Text('Loop', style: TextStyle(fontSize: 12)), value: _loop, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) { _loop = v; _rebuild(); }),
              SwitchListTile(title: const Text('Reverse', style: TextStyle(fontSize: 12)), value: _reverse, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) { _reverse = v; _rebuild(); }),
              SwitchListTile(title: const Text('Invert', style: TextStyle(fontSize: 12)), value: _invert, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) { _invert = v; _rebuild(); }),
              ControlSlider(label: 'Range Start', value: _rangeStart, min: 0.0, max: 1.0, onChanged: (v) { _rangeStart = v; _rebuild(); }),
              ControlSlider(label: 'Range End', value: _rangeEnd, min: 0.0, max: 1.0, onChanged: (v) { _rangeEnd = v; _rebuild(); }),
            ],
          ],
        ),
      ],
    );
  }

  String _generatePreset() => PresetGenerator.shaderParams(_params);
}

class RadialPixelDissolveShaderCard extends StatefulWidget {
  final CardDimensions dimensions;

  const RadialPixelDissolveShaderCard({super.key, required this.dimensions});

  @override
  State<RadialPixelDissolveShaderCard> createState() => _RadialPixelDissolveShaderCardState();
}

class _RadialPixelDissolveShaderCardState extends State<RadialPixelDissolveShaderCard> {
  ShaderParams _params = radialPixelDissolveShaderDef.defaults;
  bool _showControls = false;
  bool _useExplicit = false;
  int _curveIndex = 2;
  double _durationSec = 3.0;
  double _delaySec = 0.0;
  bool _loop = true;
  bool _reverse = true;
  bool _invert = false;
  double _rangeStart = 0.0;
  double _rangeEnd = 1.0;
  int _animKey = 0;

  ShaderUIDefaults get _ui => radialPixelDissolveShaderDef.uiDefaults;

  void _rebuild() => setState(() => _animKey++);

  @override
  Widget build(BuildContext context) {
    final dimensions = widget.dimensions;
    final controlsHeight = calculateControlsHeight(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderCardContent(
          width: dimensions.width,
          height: dimensions.height,
          child: KeyedSubtree(
            key: ValueKey('radialPixelDissolve_$_animKey'),
            child: RadialPixelDissolveShaderWrap(
              params: _params,
              animationMode: _useExplicit ? ShaderAnimationMode.explicit : ShaderAnimationMode.continuous,
              animationConfig: _useExplicit ? _buildAnimConfig(curveIndex: _curveIndex, durationSec: _durationSec, delaySec: _delaySec, loop: _loop, reverse: _reverse, invert: _invert, rangeStart: _rangeStart, rangeEnd: _rangeEnd) : null,
              child: Image.asset(
                ShaderImageAssets.radialPixelDissolve,
                fit: BoxFit.cover,
                width: dimensions.width,
                height: dimensions.height,
              ),
            ),
          ),
        ),
        ShaderControlsPanel(
          showControls: _showControls,
          onToggle: () => setState(() => _showControls = !_showControls),
          controlsWidth: dimensions.controlsWidth,
          controlsHeight: controlsHeight,
          onReset: () => setState(() => _params = radialPixelDissolveShaderDef.defaults),
          shaderName: 'Pixel Dissolve Radial',
          onCopyPreset: () => _generatePreset(),
          children: [
            const ControlSectionTitle('Dissolve Center'),
            ControlSlider.fromRange(range: _ui['centerX']!, value: _params.get('centerX'), onChanged: (v) => setState(() => _params = _params.withValue('centerX', v))),
            ControlSlider.fromRange(range: _ui['centerY']!, value: _params.get('centerY'), onChanged: (v) => setState(() => _params = _params.withValue('centerY', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Pixel Properties'),
            ControlSlider.fromRange(range: _ui['scale']!, value: _params.get('scale'), onChanged: (v) => setState(() => _params = _params.withValue('scale', v))),
            ControlSlider.fromRange(range: _ui['pixelSize']!, value: _params.get('pixelSize'), onChanged: (v) => setState(() => _params = _params.withValue('pixelSize', v))),
            ControlSlider.fromRange(range: _ui['edgeWidth']!, value: _params.get('edgeWidth'), onChanged: (v) => setState(() => _params = _params.withValue('edgeWidth', v))),
            ControlSlider.fromRange(range: _ui['scatter']!, value: _params.get('scatter'), onChanged: (v) => setState(() => _params = _params.withValue('scatter', v))),
            ControlSlider.fromRange(range: _ui['noiseAmount']!, value: _params.get('noiseAmount'), onChanged: (v) => setState(() => _params = _params.withValue('noiseAmount', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Animation'),
            ControlSegmentedButton<bool>(label: 'Mode', value: _useExplicit, options: const [(false, 'Continuous'), (true, 'Explicit')], onChanged: (v) { _useExplicit = v; _rebuild(); }),
            if (!_useExplicit)
              ControlSlider.fromRange(range: _ui['speed']!, value: _params.get('speed'), onChanged: (v) => setState(() => _params = _params.withValue('speed', v))),
            if (_useExplicit) ...[
              const SizedBox(height: 8),
              _buildCurveChips(selectedIndex: _curveIndex, onChanged: (i) { _curveIndex = i; _rebuild(); }),
              const SizedBox(height: 8),
              ControlSlider(label: 'Duration (s)', value: _durationSec, min: 0.5, max: 10.0, onChanged: (v) { _durationSec = v; _rebuild(); }),
              ControlSlider(label: 'Delay (s)', value: _delaySec, min: 0.0, max: 3.0, onChanged: (v) { _delaySec = v; _rebuild(); }),
              SwitchListTile(title: const Text('Loop', style: TextStyle(fontSize: 12)), value: _loop, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) { _loop = v; _rebuild(); }),
              SwitchListTile(title: const Text('Reverse', style: TextStyle(fontSize: 12)), value: _reverse, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) { _reverse = v; _rebuild(); }),
              SwitchListTile(title: const Text('Invert', style: TextStyle(fontSize: 12)), value: _invert, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) { _invert = v; _rebuild(); }),
              ControlSlider(label: 'Range Start', value: _rangeStart, min: 0.0, max: 1.0, onChanged: (v) { _rangeStart = v; _rebuild(); }),
              ControlSlider(label: 'Range End', value: _rangeEnd, min: 0.0, max: 1.0, onChanged: (v) { _rangeEnd = v; _rebuild(); }),
            ],
          ],
        ),
      ],
    );
  }

  String _generatePreset() => PresetGenerator.shaderParams(_params);
}

class TappablePixelDissolveShaderCard extends StatefulWidget {
  final CardDimensions dimensions;

  const TappablePixelDissolveShaderCard({super.key, required this.dimensions});

  @override
  State<TappablePixelDissolveShaderCard> createState() => _TappablePixelDissolveShaderCardState();
}

class _TappablePixelDissolveShaderCardState extends State<TappablePixelDissolveShaderCard> {
  ShaderParams _params = tappablePixelDissolveShaderDef.defaults;
  bool _showControls = false;
  int _curveIndex = 0;
  double _durationSec = 1.5;
  double _delaySec = 0.0;
  bool _reverse = true;
  bool _invert = false;
  bool _persistTaps = false;
  double _rangeStart = 0.0;
  double _rangeEnd = 1.0;
  int _tapKey = 0;

  ShaderUIDefaults get _ui => tappablePixelDissolveShaderDef.uiDefaults;

  void _rebuild() => setState(() => _tapKey++);

  ShaderAnimationConfig _buildTapConfig() => _buildAnimConfig(
    curveIndex: _curveIndex, durationSec: _durationSec, delaySec: _delaySec,
    loop: false, reverse: _reverse, invert: _invert,
    rangeStart: _rangeStart, rangeEnd: _rangeEnd,
  );

  @override
  Widget build(BuildContext context) {
    final dimensions = widget.dimensions;
    final controlsHeight = calculateControlsHeight(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderCardContent(
          width: dimensions.width,
          height: dimensions.height,
          child: TappablePixelDissolveShaderWrap(
            key: ValueKey('tapPixel_$_tapKey'),
            params: _params,
            tapConfig: _buildTapConfig(),
            persistTaps: _persistTaps,
            child: Image.asset(
              ShaderImageAssets.tapPixelDissolve,
              fit: BoxFit.cover,
              width: dimensions.width,
              height: dimensions.height,
            ),
          ),
        ),
        ShaderControlsPanel(
          showControls: _showControls,
          onToggle: () => setState(() => _showControls = !_showControls),
          controlsWidth: dimensions.controlsWidth,
          controlsHeight: controlsHeight,
          onReset: () => setState(() => _params = tappablePixelDissolveShaderDef.defaults),
          shaderName: 'Pixel Dissolve Tap',
          onCopyPreset: () => _generatePreset(),
          children: [
            const ControlSectionTitle('Pixel Properties'),
            ControlSlider.fromRange(range: _ui['pixelSize']!, value: _params.get('pixelSize'), onChanged: (v) => setState(() => _params = _params.withValue('pixelSize', v))),
            ControlSlider.fromRange(range: _ui['edgeWidth']!, value: _params.get('edgeWidth'), onChanged: (v) => setState(() => _params = _params.withValue('edgeWidth', v))),
            ControlSlider.fromRange(range: _ui['scatter']!, value: _params.get('scatter'), onChanged: (v) => setState(() => _params = _params.withValue('scatter', v))),
            ControlSlider.fromRange(range: _ui['noiseAmount']!, value: _params.get('noiseAmount'), onChanged: (v) => setState(() => _params = _params.withValue('noiseAmount', v))),
            ControlSlider.fromRange(range: _ui['radius']!, value: _params.get('radius'), onChanged: (v) => setState(() => _params = _params.withValue('radius', v))),
            const SizedBox(height: 12),
            const ControlSectionTitle('Tap Animation'),
            _buildCurveChips(selectedIndex: _curveIndex, onChanged: (i) { _curveIndex = i; _rebuild(); }),
            const SizedBox(height: 8),
            ControlSlider(label: 'Duration (s)', value: _durationSec, min: 0.2, max: 5.0, onChanged: (v) { _durationSec = v; _rebuild(); }),
            ControlSlider(label: 'Delay (s)', value: _delaySec, min: 0.0, max: 2.0, onChanged: (v) { _delaySec = v; _rebuild(); }),
            SwitchListTile(title: const Text('Reverse', style: TextStyle(fontSize: 12)), value: _reverse, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) { _reverse = v; _rebuild(); }),
            SwitchListTile(title: const Text('Invert', style: TextStyle(fontSize: 12)), value: _invert, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) { _invert = v; _rebuild(); }),
            SwitchListTile(title: const Text('Persist taps', style: TextStyle(fontSize: 12)), value: _persistTaps, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) { _persistTaps = v; _rebuild(); }),
            ControlSlider(label: 'Range Start', value: _rangeStart, min: 0.0, max: 1.0, onChanged: (v) { _rangeStart = v; _rebuild(); }),
            ControlSlider(label: 'Range End', value: _rangeEnd, min: 0.0, max: 1.0, onChanged: (v) { _rangeEnd = v; _rebuild(); }),
          ],
        ),
      ],
    );
  }

  String _generatePreset() => PresetGenerator.shaderParams(_params);
}

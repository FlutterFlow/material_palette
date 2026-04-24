import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_palette/material_palette.dart';

/// Standard border radius used for all shader cards
const double kShaderCardBorderRadius = 14.0;

/// A wrapper that provides consistent sizing and rounded corners for all shader cards.
/// Wraps the shader content with ClipRRect and applies the standard border radius.
class ShaderCardContent extends StatelessWidget {
  const ShaderCardContent({
    super.key,
    required this.width,
    required this.height,
    required this.child,
  });

  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kShaderCardBorderRadius),
        child: child,
      ),
    );
  }
}

/// A collapsible controls panel for shader parameters.
/// Provides a consistent UI for show/hide controls toggle and the controls container.
class ShaderControlsPanel extends StatelessWidget {
  const ShaderControlsPanel({
    super.key,
    required this.showControls,
    required this.onToggle,
    required this.controlsWidth,
    required this.controlsHeight,
    required this.children,
    this.onReset,
    this.onCopyPreset,
    this.shaderName,
  });

  final bool showControls;
  final VoidCallback onToggle;
  final double controlsWidth;
  final double controlsHeight;
  final List<Widget> children;
  final VoidCallback? onReset;
  final String Function()? onCopyPreset;
  final String? shaderName;

  void _showPresetDialog(BuildContext context) {
    if (onCopyPreset == null) return;
    
    final presetCode = onCopyPreset!();
    showDialog(
      context: context,
      builder: (context) => PresetDialog(
        shaderName: shaderName ?? 'Shader',
        presetCode: presetCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onToggle,
          icon: Icon(showControls ? Icons.expand_less : Icons.expand_more, size: 16),
          label: Text(
            showControls ? 'Hide Controls' : 'Show Controls',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        if (showControls)
          Container(
            width: controlsWidth,
            height: controlsHeight,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...children,
                  if (onReset != null || onCopyPreset != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (onReset != null)
                          TextButton(
                            onPressed: onReset,
                            child: const Text('Reset', style: TextStyle(fontSize: 12)),
                          ),
                        if (onCopyPreset != null) ...[
                          if (onReset != null) const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => _showPresetDialog(context),
                            icon: const Icon(Icons.copy, size: 14),
                            label: const Text('Copy Preset', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A section title for grouping related controls.
class ControlSectionTitle extends StatelessWidget {
  const ControlSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// A labeled slider control for numeric parameters.
class ControlSlider extends StatelessWidget {
  const ControlSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.displayScale = 1.0,
  });

  ControlSlider.fromRange({
    super.key,
    required SliderRange range,
    required this.value,
    required this.onChanged,
    this.displayScale = 1.0,
  }) : label = range.label,
       min = range.min,
       max = range.max;

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  /// Multiplier applied to [value] for the numeric text on the right side only.
  /// Useful for parameters whose native range is too small to read at 2dp (e.g.
  /// pass `1000` so 0.0005 displays as `0.50`). The slider itself, clamping,
  /// and [onChanged] all stay on the unscaled, native range.
  final double displayScale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 45,
            child: Text(
              (value * displayScale).toStringAsFixed(2),
              style: const TextStyle(fontSize: 10, color: Colors.white54),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

/// A labeled segmented button control for selecting from discrete options.
class ControlSegmentedButton<T> extends StatelessWidget {
  const ControlSegmentedButton({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ),
          Expanded(
            child: SegmentedButton<T>(
              segments: options.map((opt) => ButtonSegment<T>(
                value: opt.$1,
                label: Text(opt.$2, style: const TextStyle(fontSize: 10)),
              )).toList(),
              selected: {value},
              onSelectionChanged: (selected) {
                if (selected.isNotEmpty) {
                  onChanged(selected.first);
                }
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Generates a palette of colors from a seed color using Material's ColorScheme.
class ShaderColorPalette {
  final String name;
  final Color seedColor;
  late final ColorScheme _scheme;

  ShaderColorPalette(this.name, this.seedColor) {
    _scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
  }

  List<Color> get colors => [
    _scheme.primary,
    _scheme.primaryContainer,
    _scheme.secondary,
    _scheme.secondaryContainer,
    _scheme.tertiary,
    _scheme.tertiaryContainer,
    _scheme.surface,
    _scheme.surfaceContainerHighest,
    _scheme.onPrimary,
    _scheme.onSecondary,
    _scheme.onTertiary,
    _scheme.outline,
  ];

  /// Marble shader palette - slate and stone tones
  static final marble = ShaderColorPalette('Marble', const Color(0xFF607D8B));

  /// Gradient shader palette - vibrant coral/pink
  static final gradient = ShaderColorPalette('Gradient', const Color(0xFFE91E63));

  /// Radial gradient palette - teal/cyan tones
  static final radialGradient = ShaderColorPalette('Radial', const Color(0xFF009688));

  /// Ripple shader palette - ocean blues
  static final ripple = ShaderColorPalette('Ripple', const Color(0xFF2196F3));

  /// Default palette - purple tones
  static final defaultPalette = ShaderColorPalette('Default', const Color(0xFF6750A4));

  /// Perlin shader palette - forest green tones
  static final perlin = ShaderColorPalette('Perlin', const Color(0xFF228B22));

  /// Simplex shader palette - deep purple tones
  static final simplex = ShaderColorPalette('Simplex', const Color(0xFF9C27B0));

  /// FBM shader palette - earth brown tones
  static final fbm = ShaderColorPalette('FBM', const Color(0xFF8D6E63));

  /// Turbulence shader palette - storm gray tones
  static final turbulence = ShaderColorPalette('Turbulence', const Color(0xFF546E7A));

  /// Voronoi shader palette - crystal blue tones
  static final voronoi = ShaderColorPalette('Voronoi', const Color(0xFF00BCD4));

  /// Voronoise shader palette - amber tones
  static final voronoise = ShaderColorPalette('Voronoise', const Color(0xFFFF8F00));

}

/// Paints a checkerboard pattern to visualize transparency.
class _CheckerboardPainter extends CustomPainter {
  const _CheckerboardPainter({this.cellSize = 6.0});
  final double cellSize;

  @override
  void paint(Canvas canvas, Size size) {
    final light = Paint()..color = const Color(0xFFCCCCCC);
    final dark = Paint()..color = const Color(0xFF999999);
    for (double y = 0; y < size.height; y += cellSize) {
      for (double x = 0; x < size.width; x += cellSize) {
        final isLight = ((x ~/ cellSize) + (y ~/ cellSize)) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, cellSize, cellSize),
          isLight ? light : dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A labeled color picker row that shows a color swatch and opens an HSL picker dialog on tap.
class ControlColorPicker extends StatelessWidget {
  const ControlColorPicker({
    super.key,
    required this.label,
    required this.color,
    required this.onChanged,
    this.palette,
  });

  final String label;
  final Color color;
  final ValueChanged<Color> onChanged;
  /// Optional shader-specific color palette. If null, uses default palette.
  final ShaderColorPalette? palette;

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => HSLColorPickerDialog(
        initialColor: color,
        palette: palette ?? ShaderColorPalette.defaultPalette,
        onColorSelected: (selectedColor) {
          onChanged(selectedColor);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showColorPicker(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 32,
                height: 24,
                child: CustomPaint(
                  painter: const _CheckerboardPainter(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(color: Colors.white30),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// HSL color picker dialog with optional preset swatches and HSL sliders.
/// This is a reusable component for both regular color picking and seed color picking.
class HSLColorPickerDialog extends StatefulWidget {
  const HSLColorPickerDialog({
    super.key,
    required this.initialColor,
    required this.onColorSelected,
    this.title = 'Pick Color',
    this.palette,
  });

  final Color initialColor;
  final ValueChanged<Color> onColorSelected;
  final String title;
  /// Optional shader-specific color palette. If null, shows only HSL controls.
  final ShaderColorPalette? palette;

  @override
  State<HSLColorPickerDialog> createState() => _HSLColorPickerDialogState();
}

class _HSLColorPickerDialogState extends State<HSLColorPickerDialog> {
  late double _hue;
  late double _saturation;
  late double _lightness;
  late double _alpha;
  late TextEditingController _hexController;
  bool _hexError = false;

  @override
  void initState() {
    super.initState();
    final hsl = HSLColor.fromColor(widget.initialColor);
    _hue = hsl.hue;
    _saturation = hsl.saturation;
    _lightness = hsl.lightness;
    _alpha = widget.initialColor.a;
    _hexController = TextEditingController(text: _colorToHex(widget.initialColor));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  Color get _currentColor => HSLColor.fromAHSL(_alpha, _hue, _saturation, _lightness).toColor();

  String _colorToHex(Color color) {
    final r = (color.r * 255.0).round().clamp(0, 255);
    final g = (color.g * 255.0).round().clamp(0, 255);
    final b = (color.b * 255.0).round().clamp(0, 255);
    final a = (color.a * 255.0).round().clamp(0, 255);
    final rgb = '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
    if (a < 255) {
      return '${rgb}${a.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
    }
    return rgb.toUpperCase();
  }

  Color? _hexToColor(String hex) {
    hex = hex.trim().toUpperCase();
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.length != 6 && hex.length != 8) return null;
    try {
      final r = int.parse(hex.substring(0, 2), radix: 16);
      final g = int.parse(hex.substring(2, 4), radix: 16);
      final b = int.parse(hex.substring(4, 6), radix: 16);
      final a = hex.length == 8 ? int.parse(hex.substring(6, 8), radix: 16) : 255;
      return Color.fromRGBO(r, g, b, a / 255.0);
    } catch (_) {
      return null;
    }
  }

  void _setColorFromRGB(Color color) {
    final hsl = HSLColor.fromColor(color);
    setState(() {
      _hue = hsl.hue;
      _saturation = hsl.saturation;
      _lightness = hsl.lightness;
      _alpha = color.a;
      _hexController.text = _colorToHex(color);
      _hexError = false;
    });
  }

  void _onHexSubmitted(String value) {
    final color = _hexToColor(value);
    if (color != null) {
      _setColorFromRGB(color);
    } else {
      setState(() => _hexError = true);
    }
  }

  void _updateHexFromCurrentColor() {
    _hexController.text = _colorToHex(_currentColor);
    _hexError = false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title, style: const TextStyle(fontSize: 16)),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: 280,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current color preview with hex
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 40,
                        child: CustomPaint(
                          painter: const _CheckerboardPainter(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _currentColor,
                              border: Border.all(color: Colors.white24),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _hexController,
                      style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        errorText: _hexError ? 'Invalid' : null,
                        errorStyle: const TextStyle(fontSize: 9),
                      ),
                      onSubmitted: _onHexSubmitted,
                      onEditingComplete: () => _onHexSubmitted(_hexController.text),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    tooltip: 'Copy hex',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _colorToHex(_currentColor)));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied ${_colorToHex(_currentColor)}'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Preset swatches (only shown if palette is provided)
              if (widget.palette != null) ...[
                Text(
                  '${widget.palette!.name} Palette',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.palette!.colors.map((color) {
                    final isSelected = _colorsAreClose(color, _currentColor);
                    return GestureDetector(
                      onTap: () => _setColorFromRGB(color),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.white24,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              // HSL sliders
              Text(
                widget.palette != null ? 'Custom Color (HSL)' : 'Color (HSL)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),

              // Hue slider with gradient
              _buildHSLSlider(
                label: 'Hue',
                value: _hue,
                max: 360,
                gradient: LinearGradient(
                  colors: List.generate(7, (i) =>
                    HSLColor.fromAHSL(1.0, i * 60.0, 1.0, 0.5).toColor()
                  ),
                ),
                onChanged: (v) => setState(() { _hue = v; _updateHexFromCurrentColor(); }),
              ),

              // Saturation slider with gradient
              _buildHSLSlider(
                label: 'Saturation',
                value: _saturation,
                max: 1,
                gradient: LinearGradient(
                  colors: [
                    HSLColor.fromAHSL(1.0, _hue, 0.0, _lightness).toColor(),
                    HSLColor.fromAHSL(1.0, _hue, 1.0, _lightness).toColor(),
                  ],
                ),
                onChanged: (v) => setState(() { _saturation = v; _updateHexFromCurrentColor(); }),
              ),

              // Lightness slider with gradient
              _buildHSLSlider(
                label: 'Lightness',
                value: _lightness,
                max: 1,
                gradient: LinearGradient(
                  colors: [
                    HSLColor.fromAHSL(1.0, _hue, _saturation, 0.0).toColor(),
                    HSLColor.fromAHSL(1.0, _hue, _saturation, 0.5).toColor(),
                    HSLColor.fromAHSL(1.0, _hue, _saturation, 1.0).toColor(),
                  ],
                ),
                onChanged: (v) => setState(() { _lightness = v; _updateHexFromCurrentColor(); }),
              ),

              // Alpha slider with checkerboard background
              _buildAlphaSlider(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.onColorSelected(_currentColor);
            Navigator.pop(context);
          },
          child: const Text('Select'),
        ),
      ],
    );
  }

  Widget _buildHSLSlider({
    required String label,
    required double value,
    required double max,
    required LinearGradient gradient,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
              Text(
                max > 1 ? value.toStringAsFixed(0) : value.toStringAsFixed(2),
                style: const TextStyle(fontSize: 10, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            alignment: Alignment.center,
            children: [
              // Gradient track background
              Container(
                height: 12,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white24),
                ),
              ),
              // Transparent slider on top
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 12,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                    elevation: 2,
                  ),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  value: value,
                  min: 0,
                  max: max,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlphaSlider() {
    final opaqueColor = HSLColor.fromAHSL(1.0, _hue, _saturation, _lightness).toColor();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Alpha', style: TextStyle(fontSize: 11, color: Colors.white70)),
              Text(
                _alpha.toStringAsFixed(2),
                style: const TextStyle(fontSize: 10, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            alignment: Alignment.center,
            children: [
              // Checkerboard + gradient track
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 12,
                  child: CustomPaint(
                    painter: const _CheckerboardPainter(cellSize: 4.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            opaqueColor.withValues(alpha: 0.0),
                            opaqueColor,
                          ],
                        ),
                        border: Border.all(color: Colors.white24),
                      ),
                    ),
                  ),
                ),
              ),
              // Transparent slider on top
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 12,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                    elevation: 2,
                  ),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  value: _alpha,
                  min: 0,
                  max: 1,
                  onChanged: (v) => setState(() { _alpha = v; _updateHexFromCurrentColor(); }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Check if two colors are visually close (within tolerance)
  bool _colorsAreClose(Color a, Color b) {
    const tolerance = 5.0 / 255.0;
    return (a.r - b.r).abs() < tolerance &&
           (a.g - b.g).abs() < tolerance &&
           (a.b - b.b).abs() < tolerance;
  }
}

/// Calculates the controls height based on screen height.
double calculateControlsHeight(BuildContext context) {
  final screenHeight = MediaQuery.of(context).size.height;
  return (screenHeight * 0.28).clamp(180.0, 280.0);
}

/// Dialog to display and copy shader preset code.
class PresetDialog extends StatelessWidget {
  const PresetDialog({
    super.key,
    required this.shaderName,
    required this.presetCode,
  });

  final String shaderName;
  final String presetCode;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('$shaderName Preset'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Copy the code below to save your preset:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  presetCode,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: presetCode));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Preset copied to clipboard!'),
                duration: Duration(seconds: 2),
              ),
            );
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copy to Clipboard'),
        ),
      ],
    );
  }
}

/// Generates a color scheme from a single seed color.
/// Uses HSL manipulation for explicit luminance control to create visually distinct colors.
class SeedColorGenerator {
  static final Random _random = Random();

  /// Generate N colors from a seed color, distributed across hue and luminance.
  static List<Color> generateFromSeed(Color seedColor, {int count = 3}) {
    final hsl = HSLColor.fromColor(seedColor);
    final colors = <Color>[];

    for (int i = 0; i < count; i++) {
      final t = count > 1 ? i / (count - 1) : 0.5;
      // Spread hue across ±60 degrees (analogous harmony)
      final hueShift = (t - 0.5) * 120.0;
      final hue = (hsl.hue + hueShift + 360) % 360;
      // Vary lightness from 0.75 (light) to 0.30 (dark)
      final lightness = 0.75 - t * 0.45;
      // Vary saturation slightly
      final saturation = (hsl.saturation * (0.9 - t * 0.2)).clamp(0.25, 0.9);

      colors.add(HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor());
    }

    return colors;
  }

  /// Generate a random seed color.
  static Color randomSeedColor() {
    return HSLColor.fromAHSL(
      1.0,
      _random.nextDouble() * 360.0,
      0.5 + _random.nextDouble() * 0.5, // 0.5-1.0 saturation
      0.4 + _random.nextDouble() * 0.3, // 0.4-0.7 lightness
    ).toColor();
  }
}

/// A widget that allows generating shader color presets from a single seed color.
/// Displays the seed color, generated colors, and controls to regenerate or randomize.
class ColorSchemeGeneratorWidget extends StatefulWidget {
  const ColorSchemeGeneratorWidget({
    super.key,
    required this.colorCount,
    required this.initialColors,
    required this.onColorsChanged,
  });

  final int colorCount;
  final List<Color> initialColors;
  final void Function(List<Color> colors) onColorsChanged;

  @override
  State<ColorSchemeGeneratorWidget> createState() => _ColorSchemeGeneratorWidgetState();
}

class _ColorSchemeGeneratorWidgetState extends State<ColorSchemeGeneratorWidget> {
  late Color _seedColor;

  @override
  void initState() {
    super.initState();
    _seedColor = widget.initialColors.isNotEmpty ? widget.initialColors.first : Colors.blue;
  }

  void _regenerateFromSeed() {
    final colors = SeedColorGenerator.generateFromSeed(_seedColor, count: widget.colorCount);
    widget.onColorsChanged(colors);
  }

  void _randomizeSeed() {
    setState(() {
      _seedColor = SeedColorGenerator.randomSeedColor();
    });
    _regenerateFromSeed();
  }

  void _pickSeedColor() {
    showDialog(
      context: context,
      builder: (context) => HSLColorPickerDialog(
        initialColor: _seedColor,
        title: 'Pick Seed Color',
        onColorSelected: (selectedColor) {
          setState(() => _seedColor = selectedColor);
        },
      ),
    );
  }

  String _colorToHex(Color color) {
    final r = (color.r * 255.0).round().clamp(0, 255);
    final g = (color.g * 255.0).round().clamp(0, 255);
    final b = (color.b * 255.0).round().clamp(0, 255);
    return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seed color section
        Row(
          children: [
            GestureDetector(
              onTap: _pickSeedColor,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _seedColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.edit, size: 14, color: Colors.white54),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _colorToHex(_seedColor),
              style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.shuffle, size: 18),
              tooltip: 'Apply random',
              onPressed: _randomizeSeed,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: const Icon(Icons.check, size: 18),
              tooltip: 'Apply',
              onPressed: _regenerateFromSeed,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Generated colors preview
        Row(
          children: [
            for (int i = 0; i < widget.colorCount && i < widget.initialColors.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              _buildColorPreview('color$i', widget.initialColors[i], i),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildColorPreview(String label, Color color, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => HSLColorPickerDialog(
              initialColor: color,
              title: 'Pick $label',
              onColorSelected: (selectedColor) {
                final colors = List<Color>.from(widget.initialColors);
                if (index < colors.length) {
                  colors[index] = selectedColor;
                  widget.onColorsChanged(colors);
                }
              },
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
            const SizedBox(height: 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 24,
                child: CustomPaint(
                  painter: const _CheckerboardPainter(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(color: Colors.white24),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


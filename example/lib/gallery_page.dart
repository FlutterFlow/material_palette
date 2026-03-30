import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_palette/material_palette.dart';

import 'shader_cards.dart';
import 'shader_card_components.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final swatchSize = (screenWidth - 48) / 3;
    final fillPresetEntries = presets.values.toList();
    final wrapPresetEntries = wrapPresets.values.toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Effect Menagerie'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text('Fill Shaders', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _GallerySwatch(preset: fillPresetEntries[index], size: swatchSize),
                childCount: fillPresetEntries.length,
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text('Wrap Shaders', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _WrapGallerySwatch(preset: wrapPresetEntries[index], size: swatchSize),
                childCount: wrapPresetEntries.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GallerySwatch extends StatefulWidget {
  const _GallerySwatch({
    required this.preset,
    required this.size,
  });

  final ShaderPreset preset;
  final double size;

  @override
  State<_GallerySwatch> createState() => _GallerySwatchState();
}

class _GallerySwatchState extends State<_GallerySwatch> {
  OverlayEntry? _overlayEntry;
  Offset _mousePosition = Offset.zero;

  void _showTooltip(PointerEvent event) {
    _mousePosition = event.position;
    if (_overlayEntry != null) return;
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: _mousePosition.dx + 12,
        top: _mousePosition.dy + 12,
        child: IgnorePointer(
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey[800],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                widget.preset.displayName,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _updateTooltip(PointerEvent event) {
    _mousePosition = event.position;
    _overlayEntry?.markNeedsBuild();
  }

  void _removeTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _removeTooltip();
    super.dispose();
  }

  void _copyToClipboard(BuildContext context) {
    final paramsCode = PresetGenerator.shaderParams(widget.preset.params);
    final clipboardText = '${widget.preset.displayName}\n\n${widget.preset.shaderName}:\n\n$paramsCode';
    Clipboard.setData(ClipboardData(text: clipboardText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied "${widget.preset.displayName}" preset to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildShaderFill() {
    switch (widget.preset.shaderName) {
      case ShaderNames.turbulence:
        return TurbulenceGradientShaderFill(
          width: widget.size, height: widget.size, params: widget.preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case ShaderNames.radialTurbulence:
        return RadialTurbulenceGradientShaderFill(
          width: widget.size, height: widget.size, params: widget.preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case ShaderNames.fbm:
        return FbmGradientShaderFill(
          width: widget.size, height: widget.size, params: widget.preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case ShaderNames.radialFbm:
        return RadialFbmGradientShaderFill(
          width: widget.size, height: widget.size, params: widget.preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case ShaderNames.simplex:
        return SimplexGradientShaderFill(
          width: widget.size, height: widget.size, params: widget.preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case ShaderNames.radialSimplex:
        return RadialSimplexGradientShaderFill(
          width: widget.size, height: widget.size, params: widget.preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case ShaderNames.perlin:
        return PerlinGradientShaderFill(
          width: widget.size, height: widget.size, params: widget.preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case ShaderNames.radialPerlin:
        return RadialPerlinGradientShaderFill(
          width: widget.size, height: widget.size, params: widget.preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case ShaderNames.voronoi:
        return VoronoiGradientShaderFill(
          width: widget.size, height: widget.size, params: widget.preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case ShaderNames.radialVoronoi:
        return RadialVoronoiGradientShaderFill(
          width: widget.size, height: widget.size, params: widget.preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case ShaderNames.voronoise:
        return VoronoiseGradientShaderFill(
          width: widget.size, height: widget.size, params: widget.preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case ShaderNames.radialVoronoise:
        return RadialVoronoiseGradientShaderFill(
          width: widget.size, height: widget.size, params: widget.preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case ShaderNames.gritient:
        return GrittyGradientShaderFill(
          width: widget.size, height: widget.size, params: widget.preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case ShaderNames.radient:
        return RadialGrittyGradientShaderFill(
          width: widget.size, height: widget.size, params: widget.preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case ShaderNames.smarble:
        return MarbleSmearShaderFill(
          width: widget.size, height: widget.size, params: widget.preset.params,
          backgroundColor: const Color(0xFF202329), interactive: false,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      default:
        return Container(color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _showTooltip,
      onHover: _updateTooltip,
      onExit: (_) => _removeTooltip(),
      child: GestureDetector(
        onTap: () => _copyToClipboard(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kShaderCardBorderRadius),
          child: _buildShaderFill(),
        ),
      ),
    );
  }
}

class _WrapGallerySwatch extends StatefulWidget {
  const _WrapGallerySwatch({
    required this.preset,
    required this.size,
  });

  final ShaderPreset preset;
  final double size;

  @override
  State<_WrapGallerySwatch> createState() => _WrapGallerySwatchState();
}

class _WrapGallerySwatchState extends State<_WrapGallerySwatch> {
  OverlayEntry? _overlayEntry;
  Offset _mousePosition = Offset.zero;

  void _showTooltip(PointerEvent event) {
    _mousePosition = event.position;
    if (_overlayEntry != null) return;
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: _mousePosition.dx + 12,
        top: _mousePosition.dy + 12,
        child: IgnorePointer(
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey[800],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                widget.preset.displayName,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _updateTooltip(PointerEvent event) {
    _mousePosition = event.position;
    _overlayEntry?.markNeedsBuild();
  }

  void _removeTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _removeTooltip();
    super.dispose();
  }

  void _copyToClipboard(BuildContext context) {
    final paramsCode = PresetGenerator.shaderParams(widget.preset.params);
    final clipboardText = '${widget.preset.displayName}\n\n${widget.preset.shaderName}:\n\n$paramsCode';
    Clipboard.setData(ClipboardData(text: clipboardText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied "${widget.preset.displayName}" preset to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildShaderWrap() {
    final child = Image.asset(
      ShaderImageAssets.ripples,
      fit: BoxFit.cover,
      width: widget.size,
      height: widget.size,
    );

    switch (widget.preset.shaderName) {
      case ShaderNames.ripples:
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: RippleShaderWrap(
            params: widget.preset.params,
            animationMode: ShaderAnimationMode.continuous,
            cache: true,
            child: child,
          ),
        );
      default:
        return Container(color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _showTooltip,
      onHover: _updateTooltip,
      onExit: (_) => _removeTooltip(),
      child: GestureDetector(
        onTap: () => _copyToClipboard(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kShaderCardBorderRadius),
          child: _buildShaderWrap(),
        ),
      ),
    );
  }
}

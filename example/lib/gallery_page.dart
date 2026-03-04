import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_palette/material_palette.dart';

import 'gallery_presets.dart';
import 'shader_cards.dart';
import 'shader_card_components.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final offset = _scrollController.offset + event.scrollDelta.dy * 3;
      final clamped = offset.clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final swatchSize = (screenWidth - 48) / 3;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Effect Menagerie'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Listener(
        onPointerSignal: _onPointerSignal,
        child: GridView.builder(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: galleryPresets.length,
          itemBuilder: (context, index) {
            return _GallerySwatch(
              preset: galleryPresets[index],
              size: swatchSize,
            );
          },
        ),
      ),
    );
  }
}

class _GallerySwatch extends StatefulWidget {
  const _GallerySwatch({
    required this.preset,
    required this.size,
  });

  final GalleryPreset preset;
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
                widget.preset.name,
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
    final clipboardText = '${widget.preset.name}\n\n${widget.preset.shaderType}:\n\n$paramsCode';
    Clipboard.setData(ClipboardData(text: clipboardText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied "${widget.preset.name}" preset to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildShaderFill() {
    switch (widget.preset.shaderType) {
      case 'Turbulence':
        return TurbulenceGradientShaderFill(
          width: widget.size, height: widget.size, params: widget.preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case 'Turbulence Radial':
        return RadialTurbulenceGradientShaderFill(
          width: widget.size, height: widget.size, params: widget.preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case 'FBM':
        return FbmGradientShaderFill(
          width: widget.size, height: widget.size, params: widget.preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case 'FBM Radial':
        return RadialFbmGradientShaderFill(
          width: widget.size, height: widget.size, params: widget.preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case 'Simplex':
        return SimplexGradientShaderFill(
          width: widget.size, height: widget.size, params: widget.preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case 'Simplex Radial':
        return RadialSimplexGradientShaderFill(
          width: widget.size, height: widget.size, params: widget.preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case 'Perlin':
        return PerlinGradientShaderFill(
          width: widget.size, height: widget.size, params: widget.preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case 'Perlin Radial':
        return RadialPerlinGradientShaderFill(
          width: widget.size, height: widget.size, params: widget.preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case 'Voronoi':
        return VoronoiGradientShaderFill(
          width: widget.size, height: widget.size, params: widget.preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case 'Voronoi Radial':
        return RadialVoronoiGradientShaderFill(
          width: widget.size, height: widget.size, params: widget.preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case 'Voronoise':
        return VoronoiseGradientShaderFill(
          width: widget.size, height: widget.size, params: widget.preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case 'Voronoise Radial':
        return RadialVoronoiseGradientShaderFill(
          width: widget.size, height: widget.size, params: widget.preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case 'Grit':
        return GrittyGradientShaderFill(
          width: widget.size, height: widget.size, params: widget.preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case 'Grit Radial':
        return RadialGrittyGradientShaderFill(
          width: widget.size, height: widget.size, params: widget.preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case 'Smarble':
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

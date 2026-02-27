import 'package:flutter/material.dart';
import 'package:material_palette/material_palette.dart';

import 'shared_components.dart';

/// Sentinel value used in the dropdown to represent the marble smear shader,
/// which is not part of [ShaderMaterialType] because it requires interactive state.
const int _marbleSmearIndex = -1;

enum _WrapShaderType {
  burn,
  smoke,
  pixelDissolve,
  radialBurn,
  radialSmoke,
  radialPixelDissolve,
  ripple,
}

extension on _WrapShaderType {
  String get label => switch (this) {
        _WrapShaderType.burn => 'Burn',
        _WrapShaderType.smoke => 'Smoke',
        _WrapShaderType.pixelDissolve => 'Pixel Dissolve',
        _WrapShaderType.radialBurn => 'Radial Burn',
        _WrapShaderType.radialSmoke => 'Radial Smoke',
        _WrapShaderType.radialPixelDissolve => 'Radial Pixel Dissolve',
        _WrapShaderType.ripple => 'Ripple',
      };
}

ShaderDefinition _getWrapDefinition(_WrapShaderType type) => switch (type) {
      _WrapShaderType.burn => burnShaderDef,
      _WrapShaderType.smoke => smokeShaderDef,
      _WrapShaderType.pixelDissolve => pixelDissolveShaderDef,
      _WrapShaderType.radialBurn => radialBurnShaderDef,
      _WrapShaderType.radialSmoke => radialSmokeShaderDef,
      _WrapShaderType.radialPixelDissolve => radialPixelDissolveShaderDef,
      _WrapShaderType.ripple => rippleShaderDef,
    };

class DynamicShaderPreviewPage extends StatefulWidget {
  const DynamicShaderPreviewPage({super.key});

  @override
  State<DynamicShaderPreviewPage> createState() =>
      _DynamicShaderPreviewPageState();
}

class _DynamicShaderPreviewPageState extends State<DynamicShaderPreviewPage> {
  /// null means marble smear is selected.
  ShaderMaterialType? _selectedType = ShaderMaterialType.grittyGradient;
  double _width = 300;
  double _height = 400;
  ShaderAnimationMode _animationMode = ShaderAnimationMode.implicit;
  late ShaderParams _currentParams;
  late ShaderDefinition _definition;

  // Wrap shader state
  _WrapShaderType _wrapShaderType = _WrapShaderType.burn;
  late ShaderDefinition _wrapDefinition;
  late ShaderParams _wrapParams;

  bool get _isMarbleSmear => _selectedType == null;

  @override
  void initState() {
    super.initState();
    _definition = ShaderMaterialRegistry.definition(_selectedType!);
    _currentParams = _definition.defaults;
    _wrapDefinition = _getWrapDefinition(_wrapShaderType);
    _wrapParams = _wrapDefinition.defaults;
  }

  void _onTypeChanged(int? index) {
    if (index == null) return;
    setState(() {
      if (index == _marbleSmearIndex) {
        _selectedType = null;
        _definition = marbleSmearShaderDef;
        _currentParams = _definition.defaults;
      } else {
        _selectedType = ShaderMaterialType.values[index];
        _definition = ShaderMaterialRegistry.definition(_selectedType!);
        _currentParams = _definition.defaults;
      }
    });
  }

  void _onWrapTypeChanged(_WrapShaderType? type) {
    if (type == null) return;
    setState(() {
      _wrapShaderType = type;
      _wrapDefinition = _getWrapDefinition(type);
      _wrapParams = _wrapDefinition.defaults;
    });
  }

  void _resetParams() {
    setState(() {
      _currentParams = _definition.defaults;
    });
  }

  void _resetWrapParams() {
    setState(() {
      _wrapParams = _wrapDefinition.defaults;
    });
  }

  /// Unique key that changes when the shader type changes, forcing
  /// ShaderBuilder to remount and load the correct shader program.
  Key get _shaderKey => ValueKey(_selectedType?.name ?? 'marble_smear');

  Key get _wrapShaderKey => ValueKey('wrap_${_wrapShaderType.name}');

  int get _dropdownValue =>
      _isMarbleSmear ? _marbleSmearIndex : _selectedType!.index;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Shader Scale Test'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: shader preview
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Fill shader
                  _buildSectionLabel('ShaderFill'),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(kShaderCardBorderRadius),
                    child: _buildFillShader(),
                  ),
                  const SizedBox(height: 24),
                  // Wrap shader
                  _buildSectionLabel('${_wrapShaderType.label}ShaderWrap'),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(kShaderCardBorderRadius),
                    child: _buildWrapShader(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Right: controls panel
          const VerticalDivider(thickness: 1, width: 1),
          SizedBox(
            width: 340,
            child: _buildControlsPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildFillShader() {
    if (_isMarbleSmear) {
      return MarbleSmearShaderFill(
        key: _shaderKey,
        width: _width,
        height: _height,
        params: _currentParams,
        animationMode: _animationMode,
      );
    }
    return ShaderFill(
      key: _shaderKey,
      width: _width,
      height: _height,
      shaderPath: _selectedType!.shaderAssetPath,
      uniformsCallback: (shader, size, time) {
        setShaderUniforms(
            shader, size, time, _currentParams, _definition.layout);
      },
      animationMode: _animationMode,
    );
  }

  Widget _buildWrapChild() {
    return SizedBox(
      width: _width,
      height: _height,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/earth.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Wrapped Content',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                          blurRadius: 8,
                          color: Colors.black.withValues(alpha: 0.8)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_width.toInt()} x ${_height.toInt()}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    shadows: [
                      Shadow(
                          blurRadius: 6,
                          color: Colors.black.withValues(alpha: 0.8)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Explore'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWrapShader() {
    final child = _buildWrapChild();
    return switch (_wrapShaderType) {
      _WrapShaderType.burn => BurnShaderWrap(
          key: _wrapShaderKey,
          params: _wrapParams,
          animationMode: ShaderAnimationMode.continuous,
          child: child,
        ),
      _WrapShaderType.smoke => SmokeShaderWrap(
          key: _wrapShaderKey,
          params: _wrapParams,
          animationMode: ShaderAnimationMode.continuous,
          child: child,
        ),
      _WrapShaderType.pixelDissolve => PixelDissolveShaderWrap(
          key: _wrapShaderKey,
          params: _wrapParams,
          animationMode: ShaderAnimationMode.continuous,
          child: child,
        ),
      _WrapShaderType.radialBurn => RadialBurnShaderWrap(
          key: _wrapShaderKey,
          params: _wrapParams,
          animationMode: ShaderAnimationMode.continuous,
          child: child,
        ),
      _WrapShaderType.radialSmoke => RadialSmokeShaderWrap(
          key: _wrapShaderKey,
          params: _wrapParams,
          animationMode: ShaderAnimationMode.continuous,
          child: child,
        ),
      _WrapShaderType.radialPixelDissolve => RadialPixelDissolveShaderWrap(
          key: _wrapShaderKey,
          params: _wrapParams,
          animationMode: ShaderAnimationMode.continuous,
          child: child,
        ),
      _WrapShaderType.ripple => RippleShaderWrap(
          key: _wrapShaderKey,
          params: _wrapParams,
          animationMode: ShaderAnimationMode.continuous,
          child: child,
        ),
    };
  }

  Widget _buildSectionLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildControlsPanel() {
    final ranges = _definition.uiDefaults.ranges;
    final wrapRanges = _wrapDefinition.uiDefaults.ranges;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fill shader type dropdown
          const ControlSectionTitle('Fill Shader Type'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade700),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _dropdownValue,
                dropdownColor: Colors.grey.shade900,
                isExpanded: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                items: [
                  for (final type in ShaderMaterialType.values)
                    DropdownMenuItem(
                      value: type.index,
                      child: Text(type.displayName),
                    ),
                  const DropdownMenuItem(
                    value: _marbleSmearIndex,
                    child: Text('Marble Smear'),
                  ),
                ],
                onChanged: _onTypeChanged,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Dimensions
          const ControlSectionTitle('Dimensions'),
          ControlSlider(
            label: 'Width',
            value: _width,
            min: 50,
            max: 800,
            onChanged: (v) => setState(() => _width = v),
          ),
          ControlSlider(
            label: 'Height',
            value: _height,
            min: 50,
            max: 800,
            onChanged: (v) => setState(() => _height = v),
          ),
          const SizedBox(height: 16),

          // Animation mode
          const ControlSectionTitle('Animation'),
          ControlSegmentedButton<ShaderAnimationMode>(
            label: 'Mode',
            value: _animationMode,
            options: const [
              (ShaderAnimationMode.implicit, 'Implicit'),
              (ShaderAnimationMode.continuous, 'Continuous'),
            ],
            onChanged: (v) => setState(() => _animationMode = v),
          ),
          const SizedBox(height: 16),

          // Fill shader param sliders
          if (ranges.isNotEmpty) ...[
            const ControlSectionTitle('Fill Parameters'),
            for (final entry in ranges.entries)
              ControlSlider.fromRange(
                range: entry.value,
                value: _currentParams.get(entry.key),
                onChanged: (v) {
                  setState(() {
                    _currentParams = _currentParams.withValue(entry.key, v);
                  });
                },
              ),
            const SizedBox(height: 16),
          ],

          // Fill color pickers
          if (_currentParams.colors.isNotEmpty) ...[
            const ControlSectionTitle('Fill Colors'),
            for (final entry in _currentParams.colors.entries)
              ControlColorPicker(
                label: entry.key,
                color: entry.value,
                onChanged: (c) {
                  setState(() {
                    _currentParams = _currentParams.withColor(entry.key, c);
                  });
                },
              ),
            const SizedBox(height: 16),
          ],

          // Fill reset button
          Center(
            child: TextButton.icon(
              onPressed: _resetParams,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reset Fill Defaults'),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),

          // Wrap shader type dropdown
          const ControlSectionTitle('Wrap Shader'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade700),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<_WrapShaderType>(
                value: _wrapShaderType,
                dropdownColor: Colors.grey.shade900,
                isExpanded: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                items: [
                  for (final type in _WrapShaderType.values)
                    DropdownMenuItem(
                      value: type,
                      child: Text(type.label),
                    ),
                ],
                onChanged: _onWrapTypeChanged,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Wrap shader param sliders
          if (wrapRanges.isNotEmpty) ...[
            const ControlSectionTitle('Wrap Parameters'),
            for (final entry in wrapRanges.entries)
              ControlSlider.fromRange(
                range: entry.value,
                value: _wrapParams.get(entry.key),
                onChanged: (v) {
                  setState(() {
                    _wrapParams = _wrapParams.withValue(entry.key, v);
                  });
                },
              ),
            const SizedBox(height: 16),
          ],

          // Wrap color pickers
          if (_wrapParams.colors.isNotEmpty) ...[
            const ControlSectionTitle('Wrap Colors'),
            for (final entry in _wrapParams.colors.entries)
              ControlColorPicker(
                label: entry.key,
                color: entry.value,
                onChanged: (c) {
                  setState(() {
                    _wrapParams = _wrapParams.withColor(entry.key, c);
                  });
                },
              ),
            const SizedBox(height: 16),
          ],

          // Wrap reset button
          Center(
            child: TextButton.icon(
              onPressed: _resetWrapParams,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reset Wrap Defaults'),
            ),
          ),
        ],
      ),
    );
  }
}

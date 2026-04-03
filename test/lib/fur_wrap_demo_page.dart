import 'package:flutter/material.dart';
import 'package:material_palette/material_palette.dart';

import 'shared_components.dart';

const _buttonColor = Color(0xFF8C8CEF);

class FurWrapDemoPage extends StatefulWidget {
  const FurWrapDemoPage({super.key});

  @override
  State<FurWrapDemoPage> createState() => _FurWrapDemoPageState();
}

class _FurWrapDemoPageState extends State<FurWrapDemoPage> {
  ShaderParams _params = furPlanarMaskedShaderDef.defaults.copyWith(
    colors: {
      ...furPlanarMaskedShaderDef.defaults.colors,
      'maskColor': _buttonColor,
    },
  );

  ShaderUIDefaults get _ui => furPlanarMaskedShaderDef.uiDefaults;

  @override
  Widget build(BuildContext context) {
    final dimensions = CardDimensions.of(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Fur Wrap Demo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Row(
        children: [
          // Preview
          Expanded(
            child: Center(
              child: FurPlanarMaskShaderWrap(
                params: _params,
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _buttonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 64, vertical: 32),
                      textStyle: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Tap Me'),
                  ),
                ),
              ),
            ),
          ),

          // Controls panel
          Container(
            width: dimensions.controlsWidth,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D23),
              border: Border(
                left: BorderSide(color: Colors.grey.shade800, width: 1),
              ),
            ),
            child: ScrollConfiguration(
              behavior:
                  ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ControlSectionTitle('Fur Properties'),
                    ControlSlider.fromRange(
                      range: _ui['planeOffset']!,
                      value: _params.get('planeOffset'),
                      onChanged: (v) => setState(
                          () => _params = _params.withValue('planeOffset', v)),
                    ),
                    ControlSlider.fromRange(
                      range: _ui['furThickness']!,
                      value: _params.get('furThickness'),
                      onChanged: (v) => setState(
                          () => _params = _params.withValue('furThickness', v)),
                    ),
                    ControlSlider.fromRange(
                      range: _ui['furNoiseStrength']!,
                      value: _params.get('furNoiseStrength'),
                      onChanged: (v) => setState(() =>
                          _params = _params.withValue('furNoiseStrength', v)),
                    ),
                    ControlSlider.fromRange(
                      range: _ui['furNoiseScale']!,
                      value: _params.get('furNoiseScale'),
                      onChanged: (v) => setState(
                          () => _params = _params.withValue('furNoiseScale', v)),
                    ),
                    const SizedBox(height: 12),
                    const ControlSectionTitle('Wave Animation'),
                    ControlSlider.fromRange(
                      range: _ui['furWaveAmplitude']!,
                      value: _params.get('furWaveAmplitude'),
                      onChanged: (v) => setState(() =>
                          _params = _params.withValue('furWaveAmplitude', v)),
                    ),
                    ControlSlider.fromRange(
                      range: _ui['furAnimationSpeed']!,
                      value: _params.get('furAnimationSpeed'),
                      onChanged: (v) => setState(() =>
                          _params = _params.withValue('furAnimationSpeed', v)),
                    ),
                    const SizedBox(height: 12),
                    const ControlSectionTitle('Mask'),
                    ControlSlider.fromRange(
                      range: _ui['maskThreshold']!,
                      value: _params.get('maskThreshold'),
                      onChanged: (v) => setState(() =>
                          _params = _params.withValue('maskThreshold', v)),
                    ),
                    ControlSlider.fromRange(
                      range: _ui['edgeLeanStrength']!,
                      value: _params.get('edgeLeanStrength'),
                      onChanged: (v) => setState(() =>
                          _params = _params.withValue('edgeLeanStrength', v)),
                    ),
                    const SizedBox(height: 12),
                    const ControlSectionTitle('Lighting'),
                    ControlSlider.fromRange(
                      range: _ui['keyLightIntensity']!,
                      value: _params.get('keyLightIntensity'),
                      onChanged: (v) => setState(() =>
                          _params = _params.withValue('keyLightIntensity', v)),
                    ),
                    ControlSlider.fromRange(
                      range: _ui['fillLightIntensity']!,
                      value: _params.get('fillLightIntensity'),
                      onChanged: (v) => setState(() =>
                          _params = _params.withValue('fillLightIntensity', v)),
                    ),
                    ControlSlider.fromRange(
                      range: _ui['rimLightIntensity']!,
                      value: _params.get('rimLightIntensity'),
                      onChanged: (v) => setState(() =>
                          _params = _params.withValue('rimLightIntensity', v)),
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        _params = furPlanarMaskedShaderDef.defaults.copyWith(
                          colors: {
                            ...furPlanarMaskedShaderDef.defaults.colors,
                            'maskColor': _buttonColor,
                          },
                        );
                      }),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:material_palette/material_palette.dart';

import 'shared_components.dart';

class TurbulenceWrapDemoPage extends StatefulWidget {
  const TurbulenceWrapDemoPage({super.key});

  @override
  State<TurbulenceWrapDemoPage> createState() =>
      _TurbulenceWrapDemoPageState();
}

class _TurbulenceWrapDemoPageState extends State<TurbulenceWrapDemoPage> {
  ShaderParams _params = turbulenceMaskShaderDef.defaults;

  ShaderUIDefaults get _ui => turbulenceMaskShaderDef.uiDefaults;

  @override
  Widget build(BuildContext context) {
    final dimensions = CardDimensions.of(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Turbulence Wrap Demo'),
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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TurbulenceMaskShaderWrap(
                    params: _params,
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8C8CEF),
                          foregroundColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 64, vertical: 32),
                          textStyle: const TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        child: const Text('Tap Me'),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: Text(
                      'Tap Me',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
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
                    const ControlSectionTitle('Turbulence'),
                    ControlSlider.fromRange(
                      range: _ui['octaves']!,
                      value: _params.get('octaves'),
                      onChanged: (v) => setState(
                          () => _params = _params.withValue('octaves', v)),
                    ),
                    ControlSlider.fromRange(
                      range: _ui['baseFrequency']!,
                      value: _params.get('baseFrequency'),
                      onChanged: (v) => setState(() =>
                          _params = _params.withValue('baseFrequency', v)),
                    ),
                    ControlSlider.fromRange(
                      range: _ui['noiseScale']!,
                      value: _params.get('noiseScale'),
                      onChanged: (v) => setState(
                          () => _params = _params.withValue('noiseScale', v)),
                    ),
                    ControlSlider.fromRange(
                      range: _ui['animSpeed']!,
                      value: _params.get('animSpeed'),
                      onChanged: (v) => setState(
                          () => _params = _params.withValue('animSpeed', v)),
                    ),
                    const SizedBox(height: 12),
                    const ControlSectionTitle('Displacement'),
                    ControlSlider.fromRange(
                      range: _ui['displacementStrength']!,
                      value: _params.get('displacementStrength'),
                      onChanged: (v) => setState(() => _params =
                          _params.withValue('displacementStrength', v)),
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => setState(
                          () => _params = turbulenceMaskShaderDef.defaults),
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

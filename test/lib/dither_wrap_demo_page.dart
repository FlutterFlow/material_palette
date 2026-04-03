import 'package:flutter/material.dart';
import 'package:material_palette/material_palette.dart';

import 'shared_components.dart';

class DitherWrapDemoPage extends StatefulWidget {
  const DitherWrapDemoPage({super.key});

  @override
  State<DitherWrapDemoPage> createState() => _DitherWrapDemoPageState();
}

class _DitherWrapDemoPageState extends State<DitherWrapDemoPage> {
  ShaderParams _params = ditherWrapShaderDef.defaults;

  ShaderUIDefaults get _ui => ditherWrapShaderDef.uiDefaults;

  @override
  Widget build(BuildContext context) {
    final dimensions = CardDimensions.of(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Dither Wrap Demo'),
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
              child: DitherShaderWrap(
                params: _params,
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8C8CEF),
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
                    const ControlSectionTitle('Dither'),
                    ControlSlider.fromRange(
                      range: _ui['ditherScale']!,
                      value: _params.get('ditherScale'),
                      onChanged: (v) => setState(
                          () => _params = _params.withValue('ditherScale', v)),
                    ),
                    ControlSlider.fromRange(
                      range: _ui['colorSteps']!,
                      value: _params.get('colorSteps'),
                      onChanged: (v) => setState(() =>
                          _params = _params.withValue('colorSteps', v)),
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => setState(
                          () => _params = ditherWrapShaderDef.defaults),
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

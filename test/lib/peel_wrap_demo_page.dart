import 'package:flutter/material.dart';
import 'package:material_palette/material_palette.dart';

import 'shared_components.dart';

class PeelWrapDemoPage extends StatefulWidget {
  const PeelWrapDemoPage({super.key});

  @override
  State<PeelWrapDemoPage> createState() => _PeelWrapDemoPageState();
}

class _PeelWrapDemoPageState extends State<PeelWrapDemoPage> {
  ShaderParams _params = peelWrapShaderDef.defaults;
  double _durationSec = 3.0;
  bool _loop = true;
  bool _reverse = true;
  int _animKey = 0;

  ShaderUIDefaults get _ui => peelWrapShaderDef.uiDefaults;

  void _rebuild() => setState(() => _animKey++);

  @override
  Widget build(BuildContext context) {
    final dimensions = CardDimensions.of(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Peel Wrap Demo'),
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
              child: UnconstrainedBox(
                child: KeyedSubtree(
                  key: ValueKey('peel_$_animKey'),
                  child: PeelShaderWrap(
                  params: _params,
                  animationConfig: ShaderAnimationConfig(
                    duration:
                        Duration(milliseconds: (_durationSec * 1000).round()),
                    curve: Curves.easeInOut,
                    loop: _loop,
                    reverse: _reverse,
                  ),
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
                    const ControlSectionTitle('Peel Properties'),
                    ControlSlider.fromRange(
                      range: _ui['curlRadius']!,
                      value: _params.get('curlRadius'),
                      onChanged: (v) => setState(
                          () => _params = _params.withValue('curlRadius', v)),
                    ),
                    ControlSlider.fromRange(
                      range: _ui['shadowStrength']!,
                      value: _params.get('shadowStrength'),
                      onChanged: (v) => setState(() =>
                          _params = _params.withValue('shadowStrength', v)),
                    ),
                    const SizedBox(height: 12),
                    const ControlSectionTitle('Animation'),
                    ControlSlider(
                      label: 'Duration (s)',
                      value: _durationSec,
                      min: 0.5,
                      max: 10.0,
                      onChanged: (v) {
                        _durationSec = v;
                        _rebuild();
                      },
                    ),
                    SwitchListTile(
                      title:
                          const Text('Loop', style: TextStyle(fontSize: 12)),
                      value: _loop,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) {
                        _loop = v;
                        _rebuild();
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Reverse',
                          style: TextStyle(fontSize: 12)),
                      value: _reverse,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) {
                        _reverse = v;
                        _rebuild();
                      },
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(
                            () => _params = peelWrapShaderDef.defaults);
                        _rebuild();
                      },
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

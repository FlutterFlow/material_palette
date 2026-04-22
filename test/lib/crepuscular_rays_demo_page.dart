import 'package:flutter/material.dart';
import 'package:material_palette/material_palette.dart';

import 'shared_components.dart';

/// Demo page that wraps a Stack of real Flutter UI (text, buttons, icons) in
/// the crepuscular rays shader. The UI acts as the occlusion mask, so sun rays
/// fan out between and around every opaque UI element.
class CrepuscularRaysDemoPage extends StatefulWidget {
  const CrepuscularRaysDemoPage({super.key});

  @override
  State<CrepuscularRaysDemoPage> createState() =>
      _CrepuscularRaysDemoPageState();
}

class _CrepuscularRaysDemoPageState extends State<CrepuscularRaysDemoPage> {
  // Initialize with blue as the pass color so the demo starts masking on the
  // blue text in the UI stack instead of on transparency.
  ShaderParams _params = crepuscularRaysShaderDef.defaults
      .withColor('passColor', const Color.fromARGB(255, 0, 0, 255));

  ShaderUIDefaults get _ui => crepuscularRaysShaderDef.uiDefaults;

  @override
  Widget build(BuildContext context) {
    final dimensions = CardDimensions.of(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Crepuscular Rays Demo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Row(
        children: [
          Expanded(
            child: Center(
              child: SizedBox(
                width: 480,
                height: 640,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  // Dark sky sits behind the shader so the rays read clearly.
                  // The shader's output paints opaque rgb across the whole
                  // rectangle, so this container mainly anchors the bounds.
                  child: Container(
                    color: Colors.transparent,
                    child: CrepuscularRaysShaderWrap(
                      params: _params,
                      child: _buildUIStack(),
                    ),
                  ),
                ),
              ),
            ),
          ),
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
                    const ControlSectionTitle('Sun'),
                    ControlSlider.fromRange(
                      range: _ui['sunPosX']!,
                      value: _params.get('sunPosX'),
                      onChanged: (v) => setState(
                          () => _params = _params.withValue('sunPosX', v)),
                    ),
                    ControlSlider.fromRange(
                      range: _ui['sunPosY']!,
                      value: _params.get('sunPosY'),
                      onChanged: (v) => setState(
                          () => _params = _params.withValue('sunPosY', v)),
                    ),
                    ControlSlider.fromRange(
                      range: _ui['sunRadius']!,
                      value: _params.get('sunRadius'),
                      onChanged: (v) => setState(
                          () => _params = _params.withValue('sunRadius', v)),
                    ),
                    ControlColorPicker(
                      label: 'Ray Color',
                      color: _params.getColor('sunColor'),
                      onChanged: (c) => setState(
                          () => _params = _params.withColor('sunColor', c)),
                    ),
                    ControlColorPicker(
                      label: 'Disc Color',
                      color: _params.getColor('sunDiscColor'),
                      onChanged: (c) => setState(() =>
                          _params = _params.withColor('sunDiscColor', c)),
                    ),
                    const SizedBox(height: 12),
                    const ControlSectionTitle('Mask'),
                    ControlColorPicker(
                      label: 'Pass Color',
                      color: _params.getColor('passColor'),
                      onChanged: (c) => setState(() =>
                          _params = _params.withColor('passColor', c)),
                    ),
                    const SizedBox(height: 12),
                    const ControlSectionTitle('Rays'),
                    ControlSlider.fromRange(
                      range: _ui['exposure']!,
                      value: _params.get('exposure'),
                      onChanged: (v) => setState(
                          () => _params = _params.withValue('exposure', v)),
                    ),
                    ControlSlider.fromRange(
                      range: _ui['decay']!,
                      value: _params.get('decay'),
                      onChanged: (v) => setState(
                          () => _params = _params.withValue('decay', v)),
                    ),
                    ControlSlider.fromRange(
                      range: _ui['density']!,
                      value: _params.get('density'),
                      onChanged: (v) => setState(
                          () => _params = _params.withValue('density', v)),
                    ),
                    ControlSlider.fromRange(
                      range: _ui['weight']!,
                      value: _params.get('weight'),
                      onChanged: (v) => setState(
                          () => _params = _params.withValue('weight', v)),
                    ),
                    const SizedBox(height: 12),
                    const ControlSectionTitle('Orbit'),
                    ControlSlider.fromRange(
                      range: _ui['orbitRadius']!,
                      value: _params.get('orbitRadius'),
                      onChanged: (v) => setState(() =>
                          _params = _params.withValue('orbitRadius', v)),
                    ),
                    ControlSlider.fromRange(
                      range: _ui['orbitSpeed']!,
                      value: _params.get('orbitSpeed'),
                      onChanged: (v) => setState(() =>
                          _params = _params.withValue('orbitSpeed', v)),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Draw sun disc',
                          style: TextStyle(fontSize: 12)),
                      value: _params.get('showSun') > 0.5,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setState(() => _params =
                          _params.withValue('showSun', v ? 1.0 : 0.0)),
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => setState(
                          () => _params = crepuscularRaysShaderDef.defaults),
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

  /// A deliberately varied stack of Flutter UI so the shader has plenty of
  /// opaque occluders (text glyphs, icons, button backgrounds) for rays to
  /// fan between.
  Widget _buildUIStack() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Text(
                'CREPUSCULAR',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: const Color.fromARGB(255, 0, 10, 240),
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'RAYS',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: const Color.fromARGB(255, 0, 0, 255),
                  letterSpacing: 8,
                ),
              ),
            ],
          ),
        ),
        const Positioned(
          top: 200,
          left: 0,
          right: 0,
          child: Icon(
            Icons.wb_sunny_outlined,
            size: 96,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 220,
          child: Center(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.play_arrow),
              label: const Text(
                'Let There Be Light',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 45, 188, 17),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 120,
          child: Center(
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color.fromARGB(235, 223, 96, 5),
                side: const BorderSide(color: Color.fromARGB(197, 209, 4, 205), width: 2),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Learn More'),
            ),
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 60,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.white, size: 20),
                SizedBox(width: 4),
                Icon(Icons.star, color: Colors.white, size: 20),
                SizedBox(width: 4),
                Icon(Icons.star, color: Colors.white, size: 20),
                SizedBox(width: 4),
                Icon(Icons.star, color: Colors.white, size: 20),
                SizedBox(width: 4),
                Icon(Icons.star_border, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:material_palette/material_palette.dart';

import 'shared_components.dart';

/// Same UI stack as [CrepuscularRaysDemoPage], but with an animated FBM
/// gradient painted behind the UI. Some of the FBM color stops are
/// transparent, so the rays punch through the cloud gaps and the sun disc
/// peeks through where the FBM is clear.
class CrepuscularRaysFbmDemoPage extends StatefulWidget {
  const CrepuscularRaysFbmDemoPage({super.key});

  @override
  State<CrepuscularRaysFbmDemoPage> createState() =>
      _CrepuscularRaysFbmDemoPageState();
}

class _CrepuscularRaysFbmDemoPageState
    extends State<CrepuscularRaysFbmDemoPage> {
  ShaderParams _params = crepuscularRaysShaderDef.defaults;
  ShaderParams _fbmParams = _buildFbmParams();

  ShaderUIDefaults get _ui => crepuscularRaysShaderDef.uiDefaults;

  /// FBM gradient tuned for fluffy white clouds: bright white bodies with a
  /// hint of shadow gray, separated by fully transparent stops so the
  /// gradient has clear sky gaps for the rays to travel through.
  static ShaderParams _buildFbmParams() {
    final base = fbmGradientDef.defaults;
    return base.copyWith(
      values: {
        'colorCount': 4.0,
        'softness': 1.0,
        'gradientAngle': 90.0,
        'gradientScale': 1.2,
        'noiseScale': 3.0,
        'animSpeed': 0.15,
        'edgeFade': 0.0,
        // Kill the glossy sheen so clouds read as matte cotton, not plastic.
        'bumpStrength': 0.0,
        'specular': 0.0,
      },
      colors: {
        'color0': const Color.fromRGBO(255, 255, 255, 1), // bright cloud top
        'color1': const Color.fromRGBO(255, 255, 255, 0), // clear sky
        'color2': const Color.fromRGBO(225, 228, 235, 1), // soft cloud shadow
        'color3': const Color.fromRGBO(255, 255, 255, 0), // clear sky
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dimensions = CardDimensions.of(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Crepuscular Rays + FBM Demo'),
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
                    const SizedBox(height: 12),
                    const ControlSectionTitle('FBM Clouds'),
                    ControlSlider(
                      label: 'Noise Scale',
                      value: _fbmParams.get('noiseScale'),
                      min: 0.5,
                      max: 20.0,
                      onChanged: (v) => setState(() =>
                          _fbmParams = _fbmParams.withValue('noiseScale', v)),
                    ),
                    ControlSlider(
                      label: 'Anim Speed',
                      value: _fbmParams.get('animSpeed'),
                      min: 0.0,
                      max: 1.0,
                      onChanged: (v) => setState(() =>
                          _fbmParams = _fbmParams.withValue('animSpeed', v)),
                    ),
                    ControlSlider(
                      label: 'Gradient Angle',
                      value: _fbmParams.get('gradientAngle'),
                      min: 0.0,
                      max: 360.0,
                      onChanged: (v) => setState(() => _fbmParams =
                          _fbmParams.withValue('gradientAngle', v)),
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        _params = crepuscularRaysShaderDef.defaults;
                        _fbmParams = _buildFbmParams();
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

  /// Same UI elements as [CrepuscularRaysDemoPage], with an FBM gradient
  /// painted behind them. The FBM becomes part of the occlusion mask — its
  /// opaque color stops block light, its transparent stops let rays pass.
  Widget _buildUIStack() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Animated FBM "clouds" — some color stops are transparent so the
        // cloud gradient has clear rifts for the rays to punch through.
        Positioned.fill(
          child: FbmGradientShaderFill(
            width: 480,
            height: 640,
            params: _fbmParams,
          ),
        ),
        Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: Column(
            children: const [
              Text(
                'CREPUSCULAR',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Color.fromARGB(255, 240, 52, 9),
                  letterSpacing: 4,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'RAYS',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: Color.fromARGB(255, 9, 63, 213),
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
            color: Colors.white,
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
                side: const BorderSide(
                    color: Color.fromARGB(197, 209, 4, 205), width: 2),
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

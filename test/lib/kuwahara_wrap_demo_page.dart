import 'package:flutter/material.dart';
import 'package:material_palette/material_palette.dart';

import 'shared_components.dart';

/// Which Flutter UI sample to feed the Kuwahara filter.
enum _KuwaharaSubject {
  photo('Photo'),
  gradientCard('Gradient Card'),
  buttons('Buttons'),
  listTiles('List Tiles'),
  typography('Typography'),
  chart('Chart');

  final String label;
  const _KuwaharaSubject(this.label);
}

class KuwaharaWrapDemoPage extends StatefulWidget {
  const KuwaharaWrapDemoPage({super.key});

  @override
  State<KuwaharaWrapDemoPage> createState() => _KuwaharaWrapDemoPageState();
}

class _KuwaharaWrapDemoPageState extends State<KuwaharaWrapDemoPage> {
  ShaderParams _params = kuwaharaShaderDef.defaults;
  _KuwaharaSubject _subject = _KuwaharaSubject.photo;
  bool _sideBySide = true;

  ShaderUIDefaults get _ui => kuwaharaShaderDef.uiDefaults;

  @override
  Widget build(BuildContext context) {
    final dimensions = CardDimensions.of(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Kuwahara Wrap Demo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Row(
        children: [
          Expanded(
            child: Center(
              child: _sideBySide
                  ? _buildSideBySide()
                  : _buildFiltered(),
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
                    const ControlSectionTitle('Kuwahara'),
                    ControlSlider.fromRange(
                      range: _ui['kernelRadius']!,
                      value: _params.get('kernelRadius'),
                      onChanged: (v) => setState(() =>
                          _params = _params.withValue('kernelRadius', v)),
                    ),
                    ControlSlider.fromRange(
                      range: _ui['sharpness']!,
                      value: _params.get('sharpness'),
                      onChanged: (v) => setState(() =>
                          _params = _params.withValue('sharpness', v)),
                    ),
                    const SizedBox(height: 16),
                    const ControlSectionTitle('Subject'),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _KuwaharaSubject.values.map((s) {
                        return ChoiceChip(
                          label: Text(
                            s.label,
                            style: const TextStyle(fontSize: 11),
                          ),
                          selected: _subject == s,
                          onSelected: (_) => setState(() => _subject = s),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text(
                        'Side-by-side compare',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _sideBySide,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setState(() => _sideBySide = v),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => setState(
                          () => _params = kuwaharaShaderDef.defaults),
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

  Widget _buildFiltered() {
    return KuwaharaShaderWrap(
      params: _params,
      cache: true,
      child: _buildSubject(),
    );
  }

  Widget _buildSideBySide() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _labeled('Original', _buildSubject()),
          _labeled('Kuwahara', _buildFiltered()),
        ],
      ),
    );
  }

  Widget _labeled(String label, Widget child) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white54,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSubject() {
    switch (_subject) {
      case _KuwaharaSubject.photo:
        return _buildPhoto();
      case _KuwaharaSubject.gradientCard:
        return _buildGradientCard();
      case _KuwaharaSubject.buttons:
        return _buildButtons();
      case _KuwaharaSubject.listTiles:
        return _buildListTiles();
      case _KuwaharaSubject.typography:
        return _buildTypography();
      case _KuwaharaSubject.chart:
        return _buildChart();
    }
  }

  Widget _buildPhoto() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(kShaderCardBorderRadius),
      child: Image.asset(
        'assets/images/mountain.jpg',
        width: 320,
        height: 420,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildGradientCard() {
    return Container(
      width: 320,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kShaderCardBorderRadius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6EC7),
            Color(0xFF7F7FFF),
            Color(0xFF1EC8E8),
          ],
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Painterly',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Oriented brushstrokes follow colour boundaries while '
              'flat regions smear into soft fields of paint.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF282C34),
        borderRadius: BorderRadius.circular(kShaderCardBorderRadius),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8C8CEF),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('Primary'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD19A66),
              minimumSize: const Size(double.infinity, 48),
              side: const BorderSide(color: Color(0xFFD19A66), width: 2),
              textStyle: const TextStyle(fontSize: 16),
            ),
            child: const Text('Secondary'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E5435),
              foregroundColor: const Color(0xFF81B88B),
              minimumSize: const Size(double.infinity, 48),
              textStyle: const TextStyle(fontSize: 16),
            ),
            child: const Text('Tonal'),
          ),
          const SizedBox(height: 12),
          IconButton.filled(
            onPressed: () {},
            icon: const Icon(Icons.favorite),
            iconSize: 28,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFE06C75),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTiles() {
    final entries = [
      (Icons.brush, 'Kernel radius', 'Brush size', const Color(0xFF8C8CEF)),
      (Icons.tune, 'Sharpness', 'Edge elongation', const Color(0xFFD19A66)),
      (Icons.palette, 'Linear RGB', 'Physically correct', const Color(0xFF81B88B)),
      (Icons.blur_on, 'Anisotropy', 'Oriented sectors', const Color(0xFFE06C75)),
    ];
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: const Color(0xFF282C34),
        borderRadius: BorderRadius.circular(kShaderCardBorderRadius),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < entries.length; i++) ...[
            ListTile(
              leading: CircleAvatar(
                backgroundColor: entries[i].$4,
                child: Icon(entries[i].$1, color: Colors.white),
              ),
              title: Text(
                entries[i].$2,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              subtitle: Text(
                entries[i].$3,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white30),
            ),
            if (i < entries.length - 1)
              const Divider(color: Colors.white10, height: 1),
          ],
        ],
      ),
    );
  }

  Widget _buildTypography() {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E9D4),
        borderRadius: BorderRadius.circular(kShaderCardBorderRadius),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ag',
            style: TextStyle(
              fontSize: 96,
              fontWeight: FontWeight.w900,
              color: Color(0xFF202329),
              height: 1,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Anisotropic Kuwahara filter',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3A3D45),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Edges stay crisp while flat fields turn into brush strokes.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF5A5E66),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return Container(
      width: 320,
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF202329),
        borderRadius: BorderRadius.circular(kShaderCardBorderRadius),
        border: Border.all(color: Colors.white10),
      ),
      child: CustomPaint(
        painter: _BarChartPainter(),
        child: Container(),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  static const List<double> _bars = [0.4, 0.75, 0.3, 0.9, 0.55, 0.7, 0.45];
  static const List<Color> _colors = [
    Color(0xFF8C8CEF),
    Color(0xFFD19A66),
    Color(0xFF81B88B),
    Color(0xFFE06C75),
    Color(0xFF4C52D1),
    Color(0xFF009688),
    Color(0xFFFF8F00),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / (_bars.length * 1.5);
    final gap = (size.width - barWidth * _bars.length) / (_bars.length + 1);
    for (int i = 0; i < _bars.length; i++) {
      final h = _bars[i] * size.height;
      final x = gap + i * (barWidth + gap);
      final y = size.height - h;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barWidth, h),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );
      canvas.drawRRect(rect, Paint()..color = _colors[i % _colors.length]);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) => false;
}

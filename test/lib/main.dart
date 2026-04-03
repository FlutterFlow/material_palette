import 'package:flutter/material.dart';

import 'animation_demo_page.dart';
import 'dynamic_shader_preview_page.dart';
import 'implicit_animation_demo_page.dart';
import 'shared_components.dart';
import 'shader_wrap_demo_page.dart';
import 'tappable_demo_page.dart';
import 'dither_wrap_demo_page.dart';
import 'fur_wrap_demo_page.dart';
import 'peel_wrap_demo_page.dart';
import 'turbulence_wrap_demo_page.dart';

void main() {
  runApp(const TestDemosApp());
}

class TestDemosApp extends StatelessWidget {
  const TestDemosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Demos',
      theme: ThemeData(
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFF8C8CEF),
          onPrimary: Color(0xFF09090B),
          primaryContainer: Color(0xFF4C52D1),
          onPrimaryContainer: Color(0xFFF0F0F0),
          secondary: Color(0xFFD19A66),
          onSecondary: Color(0xFF09090B),
          secondaryContainer: Color(0xFF5A3E1F),
          onSecondaryContainer: Color(0xFFF0F0F0),
          tertiary: Color(0xFF81B88B),
          onTertiary: Color(0xFF09090B),
          tertiaryContainer: Color(0xFF2E5435),
          onTertiaryContainer: Color(0xFFF0F0F0),
          error: Color(0xFFE06C75),
          onError: Color(0xFF09090B),
          errorContainer: Color(0xFF5A222A),
          onErrorContainer: Color(0xFFF0F0F0),
          surface: Color(0xFF202329),
          onSurface: Color(0xFFF0F0F0),
          onSurfaceVariant: Color(0xFFABB2BF),
          outline: Color(0xFF373A44),
          outlineVariant: Color(0xFF2C2F38),
          shadow: Color(0xFF000000),
          scrim: Color(0xFF000000),
          inverseSurface: Color(0xFFF0F0F0),
          onInverseSurface: Color(0xFF202329),
          inversePrimary: Color(0xFF4C52D1),
          surfaceContainerHighest: Color(0xFF282C34),
        ),
      ),
      home: const TestDemosHome(),
    );
  }
}

class TestDemosHome extends StatefulWidget {
  const TestDemosHome({super.key});

  @override
  State<TestDemosHome> createState() => _TestDemosHomeState();
}

class _TestDemosHomeState extends State<TestDemosHome> {
  int _selectedIndex = 0;

  static const _pages = <Widget>[
    ShaderWrapDemoPage(),
    DynamicShaderPreviewPage(),
    AnimationDemoPage(),
    TappableDemoPage(),
    ImplicitAnimationDemoPage(),
    TurbulenceWrapDemoPage(),
    FurWrapDemoPage(),
    DitherWrapDemoPage(),
    PeelWrapDemoPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: const Color(0xFF1A1D23),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.layers),
                label: Text('Shader Wrap'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.tune),
                label: Text('Scale Test'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.animation),
                label: Text('Animations'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.touch_app),
                label: Text('Tappable'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.auto_awesome),
                label: Text('Implicit Anim'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.waves),
                label: Text('Turbulence'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.grass),
                label: Text('Fur Wrap'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.grid_on),
                label: Text('Dither'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.auto_stories),
                label: Text('Peel'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}

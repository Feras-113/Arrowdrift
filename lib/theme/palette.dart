import 'package:flutter/material.dart';

/// A complete colour theme for the game. Players can unlock more with coins.
class AppPalette {
  const AppPalette({
    required this.id,
    required this.name,
    required this.price,
    required this.brightness,
    required this.bgTop,
    required this.bgBottom,
    required this.surface,
    required this.text,
    required this.textDim,
    required this.accent,
    required this.accent2,
    required this.dot,
    required this.arrows,
  });

  final String id;
  final String name;
  final int price;
  final Brightness brightness;
  final Color bgTop;
  final Color bgBottom;
  final Color surface;
  final Color text;
  final Color textDim;
  final Color accent;
  final Color accent2;
  final Color dot;
  final List<Color> arrows;

  Color get danger => const Color(0xFFFF4D6D);
  Color get gold => const Color(0xFFFFC857);
  bool get isDark => brightness == Brightness.dark;

  Color arrowColor(int id) => arrows[id % arrows.length];

  ThemeData toTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    ).copyWith(surface: bgTop, primary: accent, secondary: accent2);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bgTop,
      splashFactory: InkSparkle.splashFactory,
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
            bodyColor: text,
            displayColor: text,
          ),
    );
  }
}

const AppPalette kNeon = AppPalette(
  id: 'neon',
  name: 'Neon Night',
  price: 0,
  brightness: Brightness.dark,
  bgTop: Color(0xFF0B1030),
  bgBottom: Color(0xFF1B2A6B),
  surface: Color(0xFF1E2A63),
  text: Color(0xFFF4F7FF),
  textDim: Color(0xFF9AA7D9),
  accent: Color(0xFF2EF2C9),
  accent2: Color(0xFFFF6B8A),
  dot: Color(0xFF3A4A94),
  arrows: [
    Color(0xFF2EF2C9),
    Color(0xFFFF6B8A),
    Color(0xFFFFC857),
    Color(0xFF7AA2FF),
    Color(0xFFC28BFF),
    Color(0xFF5BE37D),
  ],
);

const AppPalette kSunset = AppPalette(
  id: 'sunset',
  name: 'Sunset',
  price: 300,
  brightness: Brightness.dark,
  bgTop: Color(0xFF2B0F3A),
  bgBottom: Color(0xFF8A2F52),
  surface: Color(0xFF4A1B55),
  text: Color(0xFFFFF4EC),
  textDim: Color(0xFFD9A6B8),
  accent: Color(0xFFFFB45E),
  accent2: Color(0xFFFF6F61),
  dot: Color(0xFF6B2D62),
  arrows: [
    Color(0xFFFFB45E),
    Color(0xFFFF6F61),
    Color(0xFFFFD97D),
    Color(0xFFE86AB5),
    Color(0xFF9B6BFF),
    Color(0xFF6BD6C6),
  ],
);

const AppPalette kForest = AppPalette(
  id: 'forest',
  name: 'Forest',
  price: 500,
  brightness: Brightness.dark,
  bgTop: Color(0xFF06241F),
  bgBottom: Color(0xFF0F5A4A),
  surface: Color(0xFF0E3F36),
  text: Color(0xFFEFFFF8),
  textDim: Color(0xFF8CC7B5),
  accent: Color(0xFF9CF06B),
  accent2: Color(0xFFFF9E7A),
  dot: Color(0xFF1C6B58),
  arrows: [
    Color(0xFF9CF06B),
    Color(0xFF5CE1C9),
    Color(0xFFF6E36B),
    Color(0xFF63B3FF),
    Color(0xFFFF9E7A),
    Color(0xFFD5A6FF),
  ],
);

const AppPalette kPaper = AppPalette(
  id: 'paper',
  name: 'Paper',
  price: 800,
  brightness: Brightness.light,
  bgTop: Color(0xFFF6F1E7),
  bgBottom: Color(0xFFE3D6BC),
  surface: Color(0xFFFFFBF2),
  text: Color(0xFF2B2B3A),
  textDim: Color(0xFF7A7461),
  accent: Color(0xFF17A398),
  accent2: Color(0xFFE4572E),
  dot: Color(0xFFCDBF9F),
  arrows: [
    Color(0xFFE4572E),
    Color(0xFF17A398),
    Color(0xFFF2A541),
    Color(0xFF3D5A98),
    Color(0xFF8C5BC8),
    Color(0xFF2E7D32),
  ],
);

const List<AppPalette> kPalettes = <AppPalette>[kNeon, kSunset, kForest, kPaper];

AppPalette paletteById(String id) =>
    kPalettes.firstWhere((p) => p.id == id, orElse: () => kNeon);

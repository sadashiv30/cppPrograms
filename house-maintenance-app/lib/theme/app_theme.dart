import 'package:flutter/material.dart';

class AppTheme {
  static const _seed = Color(0xFF00897B); // teal-700

  // Semantic colours used across the app
  static const overdueColor   = Color(0xFFE53935);
  static const upcomingColor  = Color(0xFFF57C00);
  static const safeColor      = Color(0xFF43A047);
  static const highPriColor   = Color(0xFFE53935);
  static const medPriColor    = Color(0xFFF57C00);
  static const lowPriColor    = Color(0xFF43A047);

  static ThemeData light() => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: _seed,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F7F5),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      margin: EdgeInsets.zero,
    ),
    appBarTheme: const AppBarTheme(
      scrolledUnderElevation: 0,
      backgroundColor: Color(0xFFF5F7F5),
      centerTitle: false,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      shape: StadiumBorder(),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 4,
      shadowColor: Colors.black12,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ),
    textTheme: _textTheme(Brightness.light),
  );

  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: _seed,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF101412),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF1E2420),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: const AppBarTheme(
      scrolledUnderElevation: 0,
      backgroundColor: Color(0xFF101412),
      centerTitle: false,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: const Color(0xFF1E2420),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      shape: StadiumBorder(),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF1A1F1C),
      elevation: 4,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ),
    textTheme: _textTheme(Brightness.dark),
  );

  static TextTheme _textTheme(Brightness b) {
    final base = b == Brightness.light ? Colors.black87 : Colors.white;
    final muted = b == Brightness.light ? Colors.black54 : Colors.white60;
    return TextTheme(
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: base, height: 1.2),
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: base, height: 1.3),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: base),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: base),
      bodyLarge: TextStyle(fontSize: 15, color: base),
      bodyMedium: TextStyle(fontSize: 13, color: muted),
      labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: base),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: muted, letterSpacing: 0.5),
    );
  }

  static Color priorityColor(int p) => switch (p) {
    1 => highPriColor,
    3 => lowPriColor,
    _ => medPriColor,
  };

  static String priorityLabel(int p) => switch (p) {
    1 => 'High',
    3 => 'Low',
    _ => 'Med',
  };
}

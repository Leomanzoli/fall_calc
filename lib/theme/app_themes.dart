// lib/theme/app_themes.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppThemes {
  // This is the base color that will define your app's visual identity
  static final Color _seedColor = Colors.blueGrey;

  // Theme for Light Mode
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    ),
    // Edge-to-edge: apenas brilho dos ícones (sem cores para evitar APIs descontinuadas)
    appBarTheme: const AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    ),
  );

  // Theme for Dark Mode
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
    // Edge-to-edge: apenas brilho dos ícones (sem cores para evitar APIs descontinuadas)
    appBarTheme: const AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    ),
  );
}

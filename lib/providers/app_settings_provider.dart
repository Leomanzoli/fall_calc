// lib/providers/app_settings_provider.dart

// CORREÇÃO: Usar ":" em vez de "." na importação
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// CORREÇÃO: Usar "extends" para herdar de ChangeNotifier
class AppSettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  bool _soundEnabled = true;
  double _textScale = 1.0;

  ThemeMode get themeMode => _themeMode;
  bool get soundEnabled => _soundEnabled;
  double get textScale => _textScale;

  AppSettingsProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    _soundEnabled = prefs.getBool('som_ativado') ?? true;
    _textScale = prefs.getDouble('text_scale') ?? 1.0;

    final themeIndex = prefs.getInt('theme_mode') ?? ThemeMode.light.index;
    _themeMode = ThemeMode.values[themeIndex];

    notifyListeners();
  }

  void toggleTheme(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;

    await prefs.setInt('theme_mode', _themeMode.index);

    notifyListeners();
  }

  void toggleSound(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = isEnabled;
    await prefs.setBool('som_ativado', isEnabled);
    notifyListeners();
  }

  void setTextScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    _textScale = scale.clamp(0.8, 1.5);
    await prefs.setDouble('text_scale', _textScale);
    notifyListeners();
  }
}

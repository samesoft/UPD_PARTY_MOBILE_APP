import 'package:flutter/material.dart';

ThemeManager currentTheme = ThemeManager();

class ThemeManager with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  get themeMode => _themeMode;

  toggleTheme(bool isDark) {
    if (isDark) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }
}

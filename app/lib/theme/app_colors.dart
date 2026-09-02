import 'package:flutter/material.dart';

/// Pastel palette used across the app. Keep it soft — this is a kids' app,
/// not a dashboard.
class AppColors {
  AppColors._();

  static const background = Color(0xFFFFFBF5);
  static const surface = Colors.white;

  static const mint = Color(0xFFB8EDD4);
  static const mintDark = Color(0xFF3FAE7C);
  static const sky = Color(0xFFB9E3F9);
  static const skyDark = Color(0xFF3E9AD1);
  static const star = Color(0xFFFFD866);
  static const starDark = Color(0xFFE0A400);
  static const violet = Color(0xFFDCCFFA);
  static const violetDark = Color(0xFF8B6FDA);
  static const pink = Color(0xFFFAD1E2);
  static const pinkDark = Color(0xFFE0679C);

  static const softRed = Color(0xFFFFB3AE);
  static const softRedDark = Color(0xFFD9615A);

  static const textPrimary = Color(0xFF3A3A3A);
  static const textSecondary = Color(0xFF7A7A7A);

  static const Map<String, Color> childThemes = {
    'mint': mint,
    'sky': sky,
    'yellow': star,
    'violet': violet,
    'pink': pink,
  };

  static const Map<String, Color> childThemesDark = {
    'mint': mintDark,
    'sky': skyDark,
    'yellow': starDark,
    'violet': violetDark,
    'pink': pinkDark,
  };

  static Color themeColor(String key) => childThemes[key] ?? mint;
  static Color themeColorDark(String key) => childThemesDark[key] ?? mintDark;
}

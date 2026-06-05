import 'package:flutter/material.dart';

/// 10 themes sourced directly from colorhunt.co BEST palettes
/// (top-liked, 5000+ likes each).
enum AppThemeId {
  latteNeutral,    // F9F8F6 EFE9E3 D9CFC7 C9B59C
  mintBlush,       // FCF9EA BADFDB FFA4A4 FFBDBD
  cherryBlossom,   // FCF8F8 FBEFEF F9DFDF F5AFAF
  deepSea,         // 0F2854 1C4D8D 4988C4 BDE8F5
  peachSorbet,     // FEEAC9 FFCDC9 FDACAC FD7979
  sageMeadow,      // F1F3E0 D2DCB6 A1BC98 778873
  winePetal,       // FCF5EE FFC4C4 EE6983 850E35
  skyInk,          // EFECE3 8FABD4 4A70A9 000000
  twilight,        // 213448 547792 94B4C1 EAE0CF
  terracotta,      // B77466 FFE1AF E2B59A 957C62
}

extension AppThemeIdX on AppThemeId {
  String get label {
    switch (this) {
      case AppThemeId.latteNeutral:  return 'Latte Neutral';
      case AppThemeId.mintBlush:     return 'Mint Blush';
      case AppThemeId.cherryBlossom: return 'Cherry Blossom';
      case AppThemeId.deepSea:       return 'Deep Sea';
      case AppThemeId.peachSorbet:   return 'Peach Sorbet';
      case AppThemeId.sageMeadow:    return 'Sage Meadow';
      case AppThemeId.winePetal:     return 'Wine Petal';
      case AppThemeId.skyInk:        return 'Sky Ink';
      case AppThemeId.twilight:      return 'Twilight';
      case AppThemeId.terracotta:    return 'Terracotta';
    }
  }

  String get persistKey => name;

  static AppThemeId fromKey(String? key) {
    for (final id in AppThemeId.values) {
      if (id.name == key) return id;
    }
    return AppThemeId.mintBlush;
  }
}

class ThemePalette {
  final Color background;
  final Color card;
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color accent;
  final Color accentDeep;
  final Color magic;
  final Color magicDeep;
  final Color success;
  final Color danger;
  final Color text;
  final Color textOnDark;
  final Color subtle;
  final bool darkScaffold;

  const ThemePalette({
    required this.background,
    required this.card,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.accent,
    required this.accentDeep,
    required this.magic,
    required this.magicDeep,
    required this.success,
    required this.danger,
    required this.text,
    required this.textOnDark,
    required this.subtle,
    this.darkScaffold = false,
  });
}

const Map<AppThemeId, ThemePalette> kPalettes = {
  // 1. Latte Neutral — warm sandy minimal
  AppThemeId.latteNeutral: ThemePalette(
    background: Color(0xFFF9F8F6),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFFC9B59C),
    primaryDark: Color(0xFF7A6951),
    primaryLight: Color(0xFFEFE9E3),
    accent: Color(0xFFD9CFC7),
    accentDeep: Color(0xFFC9B59C),
    magic: Color(0xFFD9CFC7),
    magicDeep: Color(0xFFC9B59C),
    success: Color(0xFF8DA887),
    danger: Color(0xFFC97560),
    text: Color(0xFF3A2E22),
    textOnDark: Color(0xFFF9F8F6),
    subtle: Color(0xFF8E7C66),
  ),

  // 2. Mint Blush — mint + coral pastel
  AppThemeId.mintBlush: ThemePalette(
    background: Color(0xFFFCF9EA),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFFFFA4A4),
    primaryDark: Color(0xFFC25E5E),
    primaryLight: Color(0xFFFFBDBD),
    accent: Color(0xFFBADFDB),
    accentDeep: Color(0xFF6CA9A3),
    magic: Color(0xFFBADFDB),
    magicDeep: Color(0xFF6CA9A3),
    success: Color(0xFF6CA9A3),
    danger: Color(0xFFFFA4A4),
    text: Color(0xFF3A2A2A),
    textOnDark: Color(0xFFFCF9EA),
    subtle: Color(0xFF8A7A7A),
  ),

  // 3. Cherry Blossom — soft pink monochrome
  AppThemeId.cherryBlossom: ThemePalette(
    background: Color(0xFFFCF8F8),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFFF5AFAF),
    primaryDark: Color(0xFFB85F5F),
    primaryLight: Color(0xFFF9DFDF),
    accent: Color(0xFFFBEFEF),
    accentDeep: Color(0xFFF5AFAF),
    magic: Color(0xFFF5AFAF),
    magicDeep: Color(0xFFB85F5F),
    success: Color(0xFF9ABE9E),
    danger: Color(0xFFD86161),
    text: Color(0xFF4A2E2E),
    textOnDark: Color(0xFFFCF8F8),
    subtle: Color(0xFF8E7373),
  ),

  // 4. Deep Sea — bold dark navy + bright cyan
  AppThemeId.deepSea: ThemePalette(
    background: Color(0xFF0F2854),
    card: Color(0xFFBDE8F5),
    primary: Color(0xFF4988C4),
    primaryDark: Color(0xFF0F2854),
    primaryLight: Color(0xFFBDE8F5),
    accent: Color(0xFFBDE8F5),
    accentDeep: Color(0xFF1C4D8D),
    magic: Color(0xFF4988C4),
    magicDeep: Color(0xFF1C4D8D),
    success: Color(0xFF7AB5A3),
    danger: Color(0xFFE07A7A),
    text: Color(0xFF0F2854),
    textOnDark: Color(0xFFBDE8F5),
    subtle: Color(0xFF6B89A8),
    darkScaffold: true,
  ),

  // 5. Peach Sorbet — warm peach coral gradient
  AppThemeId.peachSorbet: ThemePalette(
    background: Color(0xFFFEEAC9),
    card: Color(0xFFFFF7E8),
    primary: Color(0xFFFD7979),
    primaryDark: Color(0xFFB04444),
    primaryLight: Color(0xFFFDACAC),
    accent: Color(0xFFFFCDC9),
    accentDeep: Color(0xFFFDACAC),
    magic: Color(0xFFFD7979),
    magicDeep: Color(0xFFB04444),
    success: Color(0xFF8FB079),
    danger: Color(0xFFFD7979),
    text: Color(0xFF4A2424),
    textOnDark: Color(0xFFFEEAC9),
    subtle: Color(0xFF9A6E6E),
  ),

  // 6. Sage Meadow — herbal sage greens
  AppThemeId.sageMeadow: ThemePalette(
    background: Color(0xFFF1F3E0),
    card: Color(0xFFFAFAEC),
    primary: Color(0xFF778873),
    primaryDark: Color(0xFF3F4F3D),
    primaryLight: Color(0xFFA1BC98),
    accent: Color(0xFFD2DCB6),
    accentDeep: Color(0xFFA1BC98),
    magic: Color(0xFFA1BC98),
    magicDeep: Color(0xFF778873),
    success: Color(0xFF778873),
    danger: Color(0xFFC97560),
    text: Color(0xFF2E3A2C),
    textOnDark: Color(0xFFF1F3E0),
    subtle: Color(0xFF6E7A68),
  ),

  // 7. Wine Petal — soft cream + bold wine red
  AppThemeId.winePetal: ThemePalette(
    background: Color(0xFFFCF5EE),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFFEE6983),
    primaryDark: Color(0xFF850E35),
    primaryLight: Color(0xFFFFC4C4),
    accent: Color(0xFFFFC4C4),
    accentDeep: Color(0xFFEE6983),
    magic: Color(0xFF850E35),
    magicDeep: Color(0xFF5A0824),
    success: Color(0xFF8FA67E),
    danger: Color(0xFF850E35),
    text: Color(0xFF3A0A1A),
    textOnDark: Color(0xFFFCF5EE),
    subtle: Color(0xFF8E5A6A),
  ),

  // 8. Sky Ink — modern blue + ink black
  AppThemeId.skyInk: ThemePalette(
    background: Color(0xFFEFECE3),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFF4A70A9),
    primaryDark: Color(0xFF000000),
    primaryLight: Color(0xFF8FABD4),
    accent: Color(0xFF8FABD4),
    accentDeep: Color(0xFF4A70A9),
    magic: Color(0xFF000000),
    magicDeep: Color(0xFF000000),
    success: Color(0xFF6FA85F),
    danger: Color(0xFFC85B4B),
    text: Color(0xFF000000),
    textOnDark: Color(0xFFEFECE3),
    subtle: Color(0xFF6A7488),
  ),

  // 9. Twilight — muted navy + warm cream
  AppThemeId.twilight: ThemePalette(
    background: Color(0xFFEAE0CF),
    card: Color(0xFFF5EFE0),
    primary: Color(0xFF547792),
    primaryDark: Color(0xFF213448),
    primaryLight: Color(0xFF94B4C1),
    accent: Color(0xFF94B4C1),
    accentDeep: Color(0xFF547792),
    magic: Color(0xFF213448),
    magicDeep: Color(0xFF213448),
    success: Color(0xFF7A9B7E),
    danger: Color(0xFFB85B4B),
    text: Color(0xFF213448),
    textOnDark: Color(0xFFEAE0CF),
    subtle: Color(0xFF6B7E8E),
  ),

  // 10. Terracotta — terra-cotta + warm sand
  AppThemeId.terracotta: ThemePalette(
    background: Color(0xFFFFE1AF),
    card: Color(0xFFFFF0CC),
    primary: Color(0xFFB77466),
    primaryDark: Color(0xFF5A3A30),
    primaryLight: Color(0xFFE2B59A),
    accent: Color(0xFFE2B59A),
    accentDeep: Color(0xFF957C62),
    magic: Color(0xFFB77466),
    magicDeep: Color(0xFF5A3A30),
    success: Color(0xFF7A9B7E),
    danger: Color(0xFFB77466),
    text: Color(0xFF3A1E10),
    textOnDark: Color(0xFFFFE1AF),
    subtle: Color(0xFF957C62),
  ),
};

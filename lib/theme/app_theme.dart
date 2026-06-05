import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/strings.dart';
import 'palettes.dart';

/// Active palette — swapped at runtime by ThemeController. Widgets keep using
/// `AppColors.primary` etc., but the getter returns whatever is currently set.
class AppColors {
  static ThemePalette _palette = kPalettes[AppThemeId.mintBlush]!;
  static AppThemeId _id = AppThemeId.mintBlush;

  static ThemePalette get palette => _palette;
  static AppThemeId get id => _id;
  static set current(AppThemeId id) {
    _id = id;
    _palette = kPalettes[id] ?? _palette;
  }

  static Color get background => _palette.background;
  static Color get card => _palette.card;
  static Color get primary => _palette.primary;
  static Color get primaryDark => _palette.primaryDark;
  static Color get primaryLight => _palette.primaryLight;
  static Color get accent => _palette.accent;
  static Color get accentDeep => _palette.accentDeep;
  static Color get magic => _palette.magic;
  static Color get magicDeep => _palette.magicDeep;
  static Color get success => _palette.success;
  static Color get danger => _palette.danger;
  static Color get text => _palette.text;
  static Color get textOnDark => _palette.textOnDark;
  static Color get subtle => _palette.subtle;

  // Sky / landscape overlay tones (background.png does most of the work now).
  static const Color skyTop = Color(0xFF6FB2D6);
  static const Color skyMid = Color(0xFFC0D9CC);
  static const Color skyBottom = Color(0xFFE5D3A8);
  static const Color sky = Color(0xFF6FB2D6);

  // Nature — saturated retro greens
  static const Color grass = Color(0xFF6FA85F);
  static const Color grassDark = Color(0xFF4A7B3B);
  static const Color leaf = Color(0xFF2E5A28);
  static const Color water = Color(0xFF6FA8C0);

  // Mountain — warm tan stones
  static const Color mountain = Color(0xFF9C7A4F);
  static const Color mountainDark = Color(0xFF6B5132);
  static const Color mountainSnow = Color(0xFFFBF3DE);
}

ThemeData buildAppTheme([AppLocale locale = AppLocale.ko, AppThemeId? themeId]) {
  // If a themeId is passed, switch active palette before reading colors.
  if (themeId != null) AppColors.current = themeId;
  final isDark = AppColors.palette.darkScaffold;
  // Pick text color based on the primary color's brightness so we keep contrast.
  final onPrimary = AppColors.primary.computeLuminance() > 0.55
      ? AppColors.text
      : AppColors.textOnDark;
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.card,
    ),
    scaffoldBackgroundColor: AppColors.background,
    useMaterial3: true,
  );

  // Pick a font that natively contains the glyphs for the active language.
  // Without this, switching to Chinese shows tofu/boxes because Noto Sans KR
  // doesn't cover the CJK simplified set.
  TextTheme localizedTheme(TextTheme base) {
    switch (locale) {
      case AppLocale.zh:
        return GoogleFonts.notoSansScTextTheme(base);
      case AppLocale.en:
        return GoogleFonts.notoSansTextTheme(base);
      case AppLocale.ko:
        return GoogleFonts.notoSansKrTextTheme(base);
    }
  }

  return base.copyWith(
    textTheme: localizedTheme(base.textTheme).apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 2,
      shadowColor: AppColors.text.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.text.withValues(alpha: 0.22), width: 1.2),
      ),
    ),
    appBarTheme: AppBarTheme(
      // Each theme's signature primary fills the app bar — that's where the
      // identity (vintage red, neon cyan, candy pink, forest green, …) shows.
      backgroundColor: AppColors.primary,
      elevation: 0,
      titleTextStyle: _titleStyle(locale, color: onPrimary),
      iconTheme: IconThemeData(color: onPrimary),
      foregroundColor: onPrimary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.card,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.text, width: 1.5),
        ),
        textStyle: _buttonStyle(locale),
        elevation: 2,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      labelStyle: TextStyle(color: AppColors.subtle),
      hintStyle: TextStyle(color: AppColors.subtle.withValues(alpha: 0.7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.text, width: 1.4),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.text, width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.primary, width: 2.4),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.primaryDark,
      indicatorColor: AppColors.primary,
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? AppColors.accentDeep
                : AppColors.card.withValues(alpha: 0.7),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          )),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.card
                : AppColors.card.withValues(alpha: 0.6),
          )),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.card,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.card),
        foregroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.card
                : AppColors.text),
        side: WidgetStatePropertyAll(BorderSide(color: AppColors.text, width: 1.2)),
        textStyle: WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ),
    ),
    iconTheme: IconThemeData(color: AppColors.text),
    listTileTheme: ListTileThemeData(
      iconColor: AppColors.text,
      textColor: AppColors.text,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.card,
      textStyle: TextStyle(color: AppColors.text),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.card,
      titleTextStyle: TextStyle(
        color: AppColors.text,
        fontWeight: FontWeight.w900,
        fontSize: 18,
      ),
      contentTextStyle: TextStyle(color: AppColors.text, fontSize: 14),
    ),
    dividerColor: AppColors.text.withValues(alpha: 0.18),
  );
}

TextStyle _titleStyle(AppLocale loc, {bool onDark = false, Color? color}) {
  final base = TextStyle(
    color: color ?? (onDark ? AppColors.textOnDark : AppColors.text),
    fontWeight: FontWeight.w800,
    fontSize: 20,
  );
  switch (loc) {
    case AppLocale.zh:
      return GoogleFonts.notoSansSc(textStyle: base);
    case AppLocale.en:
      return GoogleFonts.notoSans(textStyle: base);
    case AppLocale.ko:
      return GoogleFonts.notoSansKr(textStyle: base);
  }
}

TextStyle _buttonStyle(AppLocale loc) {
  const base = TextStyle(fontWeight: FontWeight.w800);
  switch (loc) {
    case AppLocale.zh:
      return GoogleFonts.notoSansSc(textStyle: base);
    case AppLocale.en:
      return GoogleFonts.notoSans(textStyle: base);
    case AppLocale.ko:
      return GoogleFonts.notoSansKr(textStyle: base);
  }
}

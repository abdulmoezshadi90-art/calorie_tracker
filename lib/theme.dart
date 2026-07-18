import 'package:flutter/material.dart';

import 'models.dart';

/// Design tokens for the app, resolved per brightness. Widgets read the active
/// palette with `AppColors.of(context)` and never hardcode colors, so light and
/// dark (per the design spec) stay in sync.
class AppColors {
  final Color pageBg;
  // Header
  final Color headerTop;
  final Color headerBottom;
  final Color headerBlob;
  final Color onHeader;
  final Color onHeaderMuted;
  // Week strip
  final Color dayIdleText;
  final Color dayIdleBg;
  final Color daySelectedBg;
  final Color daySelectedText;
  // Cards & text
  final Color card;
  final Color ink;
  final Color inkStrong;
  final Color muted;
  final List<BoxShadow> cardShadow;
  // Accent / actions
  final Color accent;
  final Color onAccent;
  final Color progressStart;
  final Color progressEnd;
  final Color progressTrack;
  final Color plusIdleBg;
  final Color plusIdleIcon;
  // Pills / accents
  final Color gold;
  final Color leftPillBg;
  final Color leftPillText;
  final Color chipBg;
  final Color chipText;
  // Macros
  final Color carb;
  final Color fat;
  final Color protein;
  final Color macroTrack;
  final Color divider;
  // Meal icon circles
  final Color mealIconColor;
  final Map<MealType, Color> mealTint;

  const AppColors({
    required this.pageBg,
    required this.headerTop,
    required this.headerBottom,
    required this.headerBlob,
    required this.onHeader,
    required this.onHeaderMuted,
    required this.dayIdleText,
    required this.dayIdleBg,
    required this.daySelectedBg,
    required this.daySelectedText,
    required this.card,
    required this.ink,
    required this.inkStrong,
    required this.muted,
    required this.cardShadow,
    required this.accent,
    required this.onAccent,
    required this.progressStart,
    required this.progressEnd,
    required this.progressTrack,
    required this.plusIdleBg,
    required this.plusIdleIcon,
    required this.gold,
    required this.leftPillBg,
    required this.leftPillText,
    required this.chipBg,
    required this.chipText,
    required this.carb,
    required this.fat,
    required this.protein,
    required this.macroTrack,
    required this.divider,
    required this.mealIconColor,
    required this.mealTint,
  });

  Color macroColor(int i) => [carb, fat, protein][i];

  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  static const light = AppColors(
    pageBg: Color(0xFFF1EEE0),
    headerTop: Color(0xFF35533B),
    headerBottom: Color(0xFF243D2A),
    headerBlob: Color(0xFF3D6147),
    onHeader: Color(0xFFF3F7EE),
    onHeaderMuted: Color(0xFFAEBEA9),
    dayIdleText: Color(0xFFEAF1E2),
    dayIdleBg: Color(0x1FFFFFFF),
    daySelectedBg: Color(0xFFEFC65B),
    daySelectedText: Color(0xFF243718),
    card: Color(0xFFFFFDF6),
    ink: Color(0xFF1E3325),
    inkStrong: Color(0xFF17301F),
    muted: Color(0xFF7E8C7F),
    cardShadow: [
      BoxShadow(
        color: Color(0x14000000),
        blurRadius: 24,
        offset: Offset(0, 10),
      ),
    ],
    accent: Color(0xFF2E8B57),
    onAccent: Colors.white,
    progressStart: Color(0xFF2E7D4F),
    progressEnd: Color(0xFF8CC69B),
    progressTrack: Color(0xFFE7E4D3),
    plusIdleBg: Color(0xFFE7F0E1),
    plusIdleIcon: Color(0xFF2E8B57),
    gold: Color(0xFFE9B949),
    leftPillBg: Color(0xFFE7F0E1),
    leftPillText: Color(0xFF2E6B45),
    chipBg: Color(0xFFE7F0E1),
    chipText: Color(0xFF4C6B54),
    carb: Color(0xFFE0A72E),
    fat: Color(0xFFD06A4F),
    protein: Color(0xFF2F8F5B),
    macroTrack: Color(0xFFE9E5D6),
    divider: Color(0xFFDAD6C6),
    mealIconColor: Color(0xFF3B4A34),
    mealTint: {
      MealType.breakfast: Color(0xFFFBF0D8),
      MealType.lunch: Color(0xFFE4F1E7),
      MealType.dinner: Color(0xFFEDECDB),
      MealType.snack: Color(0xFFF7E6E6),
    },
  );

  static const dark = AppColors(
    pageBg: Color(0xFF12160F),
    headerTop: Color(0xFF213321),
    headerBottom: Color(0xFF13200F),
    headerBlob: Color(0xFF2A3F27),
    onHeader: Color(0xFFEDF3E6),
    onHeaderMuted: Color(0xFF93A08C),
    dayIdleText: Color(0xFFD5E0CE),
    dayIdleBg: Color(0x14FFFFFF),
    daySelectedBg: Color(0xFFEFC65B),
    daySelectedText: Color(0xFF243718),
    card: Color(0xFF1B231A),
    ink: Color(0xFFEAF1E2),
    inkStrong: Color(0xFFF2F7EC),
    muted: Color(0xFF8F9C86),
    cardShadow: [
      BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 8)),
    ],
    accent: Color(0xFF34A96B),
    onAccent: Colors.white,
    progressStart: Color(0xFF2E7D4F),
    progressEnd: Color(0xFF8CC69B),
    progressTrack: Color(0xFF2A311F),
    plusIdleBg: Color(0x2634A96B),
    plusIdleIcon: Color(0xFF7FC79B),
    gold: Color(0xFFE9B949),
    leftPillBg: Color(0xFF26351F),
    leftPillText: Color(0xFFE7F0E1),
    chipBg: Color(0xFF26351F),
    chipText: Color(0xFFBFD3B6),
    carb: Color(0xFFE0A72E),
    fat: Color(0xFFD0765C),
    protein: Color(0xFF3FA873),
    macroTrack: Color(0xFF2A311F),
    divider: Color(0xFF2C3326),
    mealIconColor: Color(0xFFC7D2BC),
    mealTint: {
      MealType.breakfast: Color(0xFF3A3320),
      MealType.lunch: Color(0xFF223026),
      MealType.dinner: Color(0xFF2E2C1E),
      MealType.snack: Color(0xFF33272A),
    },
  );
}

/// Builds a ThemeData for the given brightness from the palette.
ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? AppColors.dark : AppColors.light;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.accent,
      brightness: brightness,
    ),
    scaffoldBackgroundColor: c.pageBg,
    // Unknown families are skipped on device (system fallback handles Arabic
    // and emoji); they matter for golden-test rendering.
    fontFamilyFallback: const ['SegoeUI', 'SegoeUIEmoji'],
  );
}

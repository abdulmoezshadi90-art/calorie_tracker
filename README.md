# Calorie Tracker (Libya) — متتبع السعرات

Calorie counter MVP for the Libyan market: local snack brands (Kalee, Bifa, Al Naseem…) and
home-cooked Libyan dishes that global apps don't cover.

## MVP scope

- Home screen (per the 2026-07 design PDF): greeting header with Monday-first week strip
  (gold selected day), linear calorie bar vs 2,000 kcal goal, combined carbs/fat/protein card,
  meal rows with logged-food subtitles and check/plus buttons, dashed "Add meal" button.
- Light **and** dark themes (follows system), tokens in `lib/theme.dart` — warm cream /
  forest green / gold in light, deep forest in dark.
- Search ~44 local foods (English or Arabic names) and log servings to a meal; delete from meal detail.
- Daily logs stored locally (`shared_preferences`), totals recalculated live; tap week-strip days to view other days.
- Full English/Arabic support with RTL layout and a toggle in the top bar.
  Numerals are always Western digits (0-9), including in Arabic.
- No barcode scanner, accounts, or social features yet — deliberate.

## ⚠️ Placeholder data

All nutrition values in `lib/food_db.dart` are rough development estimates.
Replace them with verified label / measured values before any release.

## Run

Flutter SDK lives at `C:\dev\flutter` (not on PATH):

```powershell
C:\dev\flutter\bin\flutter.bat run          # pick a device
C:\dev\flutter\bin\flutter.bat run -d web-server --web-port=8080   # web preview
C:\dev\flutter\bin\flutter.bat test         # widget + unit tests
```

On web, `?lang=ar` / `?lang=en` overrides the saved language (dev convenience).

Android builds: the installed Java 26 is newer than Gradle 9.1 supports; install a JDK 17–25 and run
`flutter config --jdk-dir=<path>` once before `flutter build apk`.

## Code map

| File | Purpose |
|---|---|
| `lib/theme.dart` | `AppColors` design tokens (light + dark) and `buildTheme` |
| `lib/main.dart` | App entry, theming, locale wiring |
| `lib/app_state.dart` | `AppState` (logs, totals, locale, persistence) + `AppScope` inherited widget |
| `lib/models.dart` | `FoodItem`, `LogEntry`, `MealType`, number formatting helpers |
| `lib/food_db.dart` | The local food database (placeholder values) |
| `lib/l10n.dart` | Hand-rolled EN/AR strings, month/day names |
| `lib/home_screen.dart` | Mockup home screen (ring, macros, meal cards) |
| `lib/search_screen.dart` | Food search + add-to-meal bottom sheet |
| `lib/meal_detail_screen.dart` | Logged entries per meal, delete, total |

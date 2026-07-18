# DEV NOTES — Libyan Calorie Tracker

Working notes for the solo dev environment. Full project brief lives in CLAUDE.md; roadmap details in PLAN.md.

## Machine and environment

- Windows 11.
- Flutter 3.44.6, SDK at `C:\dev\flutter`, NOT on PATH. Every command is `C:\dev\flutter\bin\flutter.bat <command>`.
- Project: `C:\Users\abdul\dev\calorie_tracker` (package `calorie_tracker`, org `ly.app`, platforms android/ios/web).
- System Java is 26, TOO NEW for Gradle 9.1. Android builds need JDK 17–25 via `flutter config --jdk-dir=<path>` first. Not set up yet. No Android builds until Phase 3.
- iOS untested, requires a Mac. Ignore until Phase 9.

## Key commands

| What | Command |
|---|---|
| Analyze | `C:\dev\flutter\bin\flutter.bat analyze` |
| All tests | `C:\dev\flutter\bin\flutter.bat test` |
| Regenerate goldens | `C:\dev\flutter\bin\flutter.bat test --update-goldens test\screenshots_test.dart` |
| Web build | `C:\dev\flutter\bin\flutter.bat build web --release` (serve `build\web` with any static server) |

- Goldens load Roboto from the SDK cache plus Segoe UI / Segoe UI Emoji from Windows fonts. Theme has `fontFamilyFallback ['SegoeUI','SegoeUIEmoji']` for this — harmless on device, do not remove.
- No Flutter/Gradle/JDK upgrades mid phase. Upgrades only between phases: clean commit before and after, then full tests + goldens.

## Release ritual

Before every release (incl. weekly beta builds): analyzer clean → full test suite → goldens
reviewed → run [QA_CHECKLIST.md](QA_CHECKLIST.md) on a device → tag.

## Hard requirements (summary — full text in CLAUDE.md)

1. Numerals ALWAYS Western digits (0-9), even in Arabic. All numbers via `fmtInt`/`fmtGrams`/`fmtServings`. Numeric input normalizes Eastern Arabic numerals (٠١٢٣٤٥٦٧٨٩) to Western.
2. Full RTL in Arabic; language toggle in top bar; choice persists.
3. Visual identity: green #16a34a (dark #1c8c5c), bg #f7f8fa, ink #1a1a1a, muted #8a8f98; carb #f59e0b, fat #ef4444, protein #3b82f6.
4. MVP scope tight: NO barcode, NO accounts, NO social.
5. All nutrition numbers in food_db.dart are PLACEHOLDERS until verified via the data pipeline. Claude never edits nutrition numbers on its own.
6. Arabic strings live in l10n.dart; foods in food_db.dart; iterate on existing screens, don't redesign.
7. Analyze + full tests after every change set; commit every session.

## Data pipeline pointers (Phase 2)

- Master source: my spreadsheet + folder of label photos named by food ID. food_db.dart is synced FROM it, never the other way.
- Category order: tuna/canned fish → dairy → snacks/biscuits → packaged bread/bakery → drinks → canned/jarred → oils/spreads/condiments → grains/pasta.
- Workflow: photograph labels → extract with Claude (web chat Project) → verify against photo myself → paste/sync into food_db.dart → tests → commit `data: verified <category>, N brands`.
- Tuna conventions: record label basis (drained vs net) in sourceNote; oil-packed and water-packed are separate entries; natural preset = one whole small can, actual drained grams.
- Home dishes: one documented reference recipe each, USDA FDC for raw ingredients, account for cooking changes (water absorption, meat shrink, frying oil). kJ labels always converted to kcal.
- Before launch: test/assertion fails if any food lacks a sourceNote.

## Android / JDK plan (Phase 3)

- Install JDK 17 (Temurin), then `C:\dev\flutter\bin\flutter.bat config --jdk-dir=<temurin-path>`.
- minSdkVersion deliberately low (~API 24) — Libyan phones skew old and cheap.
- Test on 2 physical devices incl. one cheap one. Watch: Arabic rendering, RTL mirroring (week strip, ring), font fallbacks, CustomPainter perf on weak GPUs, large system font sizes. Consider bundling a Noto Arabic font if Arabic looks poor.
- Create the signing keystore and back it up in TWO places — losing it means never updating the app on Play.
- Record adb + logcat basics here when learned.

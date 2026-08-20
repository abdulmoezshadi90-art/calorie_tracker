# Zibda — Handoff Brief
Paste this as the first message of a new chat.

---

## Who I am
Solo dev in Tripoli, Libya. IT/cybersecurity student. Building **Zibda (زبدة)**, an
offline calorie tracker for the Libyan market, as a portfolio piece and a real product.
Windows 11. Email: abdulmoezshadi.90@gmail.com

## How I want you to work with me
- Ask questions until you actually understand the request. Don't guess and build.
- Active voice, direct, concise. No filler, no marketing language, no hype words.
- **No dashes of any kind.** No hyphens between words, no en dashes, no em dashes.
- No emojis, no asterisks for emphasis, no semicolons, no colons mid-sentence.
- Vary sentence length. Short sentences are fine. Conversational, not corporate.
- Push back when I'm wrong. Tell me when something is a bad idea and why.
- Flag your own mistakes plainly. Don't bury them.
- Give exact file paths and complete code. I can't share my screen.
- **Terminal rule:** git commands in Git Bash with forward slashes
  (`/c/Users/abdul/dev/calorie_tracker`). Everything else (flutter, dart, keytool,
  findstr, dir, xcopy) in Command Prompt with backslashes
  (`C:\Users\abdul\dev\calorie_tracker`). Never mix them in one block.
- Give me one command at a time when it matters. I paste blocks and the terminal
  merges them into one line.
- Before writing anything user-facing (docs, store copy, in-app text), verify claims
  against the actual code, not against what an older doc says. Caught twice now: a
  README/PRODUCT.md claim about searchable dishes that weren't real, and an onboarding
  paragraph naming a brand ("Kalee") that was never actually sold in Libya.
- When asked to review your own work, actually check it against the codebase from
  multiple angles (accuracy, consistency, policy risk, format limits, live on-device
  behavior), not just reread the text.
- This machine has hit two environment gremlins worth recognizing fast if they recur:
  a Windows Application Control policy that suddenly blocked `flutter_tester.exe`
  from launching (blocked every test file, not just recently touched ones, resolved
  itself or got fixed on my end without a clear cause), and the Android emulator
  stalling mid-boot (qemu process alive but CPU usage flatlines after initially
  climbing normally, kill and relaunch fresh fixed it both times). Neither is a code
  problem, don't go looking for one in the diff.

---

## The product

**Zibda (زبدة)** — butter, colloquially "the best part". Single brand in both
languages: `Zibda` in Latin, `زبدة` in Arabic. The old name متتبع السعرات is retired
as a brand (may survive as a store keyword).

**The gap:** global apps don't cover Libyan food. Local packaged brands today;
named home dishes (bazin, mbakbka, couscous, usban, sfinz, maqrud) are **planned,
not shipped** — only their raw ingredients (flour, barley, couscous, pasta, produce)
are in `food_db.dart` right now. Don't describe these dishes as searchable in any
doc, store copy, or in-app text until they're actually entered. Users can work around
this themselves now with custom foods (see 20 Aug session log), but that's a manual
per-food workaround, not the same as the dishes being in the curated database.

**Differentiators, in order of importance:**
1. Fully offline. No network permission at all (confirmed: no `uses-permission` in
   `AndroidManifest.xml`). No accounts, no login.
2. No ads, ever. Stated product principle (confirmed: no ad/analytics packages in
   `pubspec.yaml`, only `shared_preferences` and `flutter_localizations`).
3. Arabic-first with full RTL and a language toggle.
4. Verified nutrition data with visible provenance (108 of 164 food_db.dart entries
   verified; that count doesn't include user-added custom foods, which are always
   unverified by definition).
5. Ramadan mode, household portion presets. Ramadan mode is **not implemented** —
   roadmap idea only, don't claim it exists. Household portion presets (plate, bowl,
   cup, glass, tbsp) are real, in `food_db.dart`'s `servingEn` fields.
6. No AI photo scanning. Every competitor does this. I deliberately don't.

**Competitive reality (checked Aug 2026):** the "local food" angle is being filled
fast. `eatsofra.com` (many cuisines), Loqma (Gulf), Loqma (South Asia), caloly.com
(Europe, German dev). Nobody has Libya. Nobody else is offline or account-free.
Speed matters more than I first thought.

---

## Hard rules, never violate

1. **Western digits (0-9) always**, including in Arabic. All numbers go through the
   custom formatters in `models.dart`. Never locale-aware number formatting.
2. **Full RTL in Arabic.** Language toggle in the top bar, choice persists.
3. **All colors from `AppColors.of(context)`.** Never hardcode a hex in a widget.
4. **All strings through `l10n.dart`**, EN and AR entries both.
5. **No new packages** without an explicit decision from me.
6. **Anti-eating-disorder guardrails.** No punishing streaks. No alarm-red for
   exceeding goals. No encouragement to under-eat. Gentle, non-blocking confirmation
   below the safety floors (1200 kcal, 1500 for men). Not medical advice, stated in
   onboarding and settings in both languages (confirmed present in both).
7. **Nutrition data honesty.** Verification status is a visible, first-class property.
   Never present unverified numbers as accurate. This extends to **feature honesty**
   too now — don't claim a food, dish, or feature exists in user-facing copy unless
   it's actually in the code.
8. **External-facing files live on a branch that won't be deleted.** Learned the hard
   way: the privacy policy was on a feature branch and the URL nearly broke.

---

## Session log — 20 Aug 2026

Three features since the 15 Aug handoff, all committed and **pushed**, `git log
--oneline -3`: `abfd99c`, `74232a1`, `69c2edc`. Branch is fully in sync with origin,
nothing pending.

**1. Custom foods** (`69c2edc`). A new "Add a food" row in the All Foods tab lets
you create your own entry: name plus per-serving calories/protein/carbs/fat, nothing
else, no gram weight or unit picker (that stays exclusive to `food_db.dart`, which
cites a real label weight). Drops into the same `FoodPicker` every built-in food
uses, so it's searchable, loggable, usable in saved meals and the meal builder, and
browsable in the Foods tab under a new "My Foods" category. Long-press a custom food
to edit or delete it; `food_db.dart` entries stay read-only.

**The important architectural change underneath this:** every place that resolved a
food by id, day totals, History, Progress, saved meals, the meal builder, went
through the static `foodById` map with no way to see a custom food. Added
`AppState.resolveFood(id)` and `AppState.allFoods` (built-in plus custom), and routed
roughly 18 call sites across 8 files through them. **If you add a new place that
looks up a food by id, use `state.resolveFood(id)`, never the bare `foodById[id]`
map, or a logged custom food will silently vanish from that screen's totals.**

**2. Animated splash screen** (`74232a1`). Logo pops in with a slight overshoot, the
"Zibda · زبدة" wordmark fades in below it (fixed English-left/Arabic-right order
regardless of the app's own RTL state, forced via an explicit `Directionality`), then
three gold dots pulse while it settles, about 1.2s, before crossfading into
onboarding or the app shell. Background matches the native splash exactly.

Two things worth remembering if you touch this again:
- `assets/branding/` was never declared as a bundled Flutter asset, it only existed
  for `flutter_native_splash`'s build-time codegen. Now in `pubspec.yaml`'s
  `flutter: assets:` list, needed for `Image.asset()` to find it at runtime.
- `AppStartup.splashDuration` is `@visibleForTesting` mutable, and
  `test/flutter_test_config.dart` zeroes it for the whole suite. Without that, the
  artificial 1.2s delay would cost real wall-clock time across every one of the ~30
  test files that construct `CalorieApp`.
- Caught after my first pass, at frame 0 the logo sat visibly shifted upward,
  because it was centered as part of one group with the name and dots below it,
  which reserved layout space for them even while they were still invisible. Fixed
  by pinning the logo to the true screen center independently (a `Stack` with
  `Positioned` name/dots underneath it, not a `Column` centered as a whole group).

**3. Calendar picker on the Today pill, plus two copy fixes** (`abfd99c`). The Today
pill (top-left of Home) used to just jump straight back to today on tap. Now opens a
calendar sheet (`date_picker_sheet.dart`), pick any day, past or future. Today gets
the exact same glowing gold treatment (`daySelectedBg` + the same blur/offset
`BoxShadow`) the week strip already uses for its selected day, so it reads as one
visual language. Month-nav chevrons stay fixed left/right regardless of Arabic RTL
on purpose, Gregorian calendar navigation isn't mirrored in real apps (Google
Calendar, WhatsApp do the same), flipping it would be the actually confusing choice.

Same session, caught two honesty/quality issues in `l10n.dart` while touching nearby
code: the onboarding intro paragraph had two em dashes and named "Kalee chips" and
"bazin" as searchable, neither is true (same false-claim pattern as the README/
PRODUCT.md catch from 15 Aug, see hard rule 7). And the training-intensity step
defined "exercise" but never "intense", even though the High and Athlete activity
levels both use it, added a second sentence to the existing helper caption.

**All verified live on the emulator, not just in tests**, for every feature above:
rebuilt the release APK, installed it, walked the actual flows (add a custom food
and confirm it logs and counts toward the day total, watch the splash render frame
by frame via rapid adb screenshots, open the calendar and tap a day and watch it
navigate). 234 tests passing, analyzer clean.

**Open work, unchanged from 15 Aug, still not done:**
- Get the phone physically present, sideload
  `build\app\outputs\flutter-apk\app-release.apk`, run the real-device parts of
  `QA_CHECKLIST.md` (launcher icon, splash light/dark, haptics, restart persistence).
  Everything above was verified on the emulator only.
- My own review of `store_assets/en/listing.md` and `store_assets/ar/listing.md`,
  especially the Arabic, before anything goes near Play Console.
- Walk `store_assets/play_console_forms.md`'s answers into the actual Play Console
  data safety / content rating / target audience / app access forms.
- Open the 12-tester closed test, starts the mandatory 14-day clock.
- `main/docs/privacy.html` is redundant (live copy serves from `gh-pages`), cleanup
  item, not urgent.
- AVD `libya_test_phone` occasionally stalls mid-boot (see the environment-gremlins
  note above), kill and relaunch works, root cause still undiagnosed.
- Named Libyan home dishes still not in `food_db.dart`, roadmap item.

---

## Current state (20 Aug 2026)

Private beta. Well ahead of the original timeline. No hard blockers left, signing
works, docs are accurate, the app itself has real feature depth now (custom foods,
polished onboarding, a proper date picker). What's left is my own review time and
the mechanical Play Console work, plus actually testing on my own phone.

**Done:** signing fully working, signed AAB and APK build and verify clean, adaptive
launcher icon, splash screen (now animated, light + dark), app rename to Zibda
verified complete, privacy policy live, feature graphics EN + AR, web demo deployed
and confirmed live, custom foods, calendar date picker, 234 tests passing, analyze
clean, Play Store listing copy and compliance-form answers drafted (pending my
review).

**Deliberately deferred:** Flutter upgrade (build chain works, don't touch it before
release), barcode scanner, accounts/sync, iOS via Codemagic + TestFlight ($99 budgeted).

---

## Architecture

Flutter 3.44.6. Local-only `shared_preferences`, JSON day-logs keyed `yyyy-MM-dd`.
No backend by design. Storage isolated in `AppState` so a backend could be swapped in.

`lib/`
- `main.dart` — MaterialApp, locale switching, web `?lang=ar|en` override. `AppScope`
  is wired via `MaterialApp`'s `builder:`, not around `home:` (which is now
  `AppStartup`, see splash_screen.dart) — it has to cover every pushed route, not
  just the first one. If you're writing a test that pumps a screen standalone, wire
  it the same way or a pushed route won't find app state.
- `splash_screen.dart` — `AppStartup` (splash then real content) + `SplashScreen`,
  see 20 Aug session log.
- `date_picker_sheet.dart` — the Today pill's calendar sheet, see 20 Aug session log.
- `custom_food_screen.dart` — add/edit form for user-created foods, see 20 Aug
  session log.
- `app_state.dart` — `AppState` (ChangeNotifier) + `AppScope` (InheritedNotifier).
  `resolveFood(id)` / `allFoods` are the correct way to look up any food now, built
  in or custom, never the bare `foodById` map from `food_db.dart` directly.
- `models.dart` — FoodItem, LogEntry, MealType, DayTotals, ServingUnit, number formatters
- `theme.dart` — `AppColors`, full light + dark palettes
- `l10n.dart` — hand-rolled EN/AR strings, no intl codegen
- `food_db.dart` — Libyan foods, EN+AR names, many now cite USDA FDC IDs. 164 entries,
  108 verified. Source of truth for what's built in, but not the whole picture
  anymore, custom foods live in `AppState` instead, use `state.allFoods` to see both.
- Screens: `home_screen`, `search_screen`, `meal_detail_screen`, `progress_screen`,
  `profile_screen`, `create_meal_screen`, `food_detail_screen` (has a draft mode for
  the meal builder, `onConfirm` callback instead of logging to today)
- Widgets: `food_picker`, `all_foods_tab`, `food_history_tab`, `saved_meals_tab`,
  `empty_state`
- `settings_screen.dart` — feedback email via native `MethodChannel` mail intent
  (`ly.app.calorie_tracker/mail`), not `url_launcher`, deliberate tiny dependency
  footprint.

## Color system (`lib/theme.dart` → `AppColors`)

Light: pageBg `#F1EEE0`, header gradient `#35533B` → `#243D2A`, accent `#2E8B57`,
gold `#E9B949`, card `#FFFDF6`, ink `#1E3325`, muted `#5F6E62`
Macros: carb `#F59E0B`, fat `#8B5CF6`, protein `#EF4444`
Also: `kcalAccent #2F8F5B`, `fieldError #D06A4F`, `daySelectedBg #EFC65B` (the glow
color, week strip and the date picker's today cell both use it)
Dark splash bg: `#12160F`
`NotoNaskhArabic` bundled for Arabic.

**The old `#16a34a` / `#f7f8fa` palette is dead. Never use it.**

---

## Paths and tooling

| Thing | Path |
|---|---|
| Project | `C:\Users\abdul\dev\calorie_tracker` |
| Flutter | `C:\dev\flutter\bin\flutter.bat` (not on PATH) |
| JDK | `C:\Program Files\Eclipse Adoptium\jdk-25.0.4.7-hotspot` |
| Android SDK | `C:\Users\abdul\AppData\Local\Android\Sdk` |
| Build tools / apksigner | `...\Sdk\build-tools\36.0.0` |
| adb | `...\Sdk\platform-tools\adb.exe` |
| Keystore | `C:\Users\abdul\dev\keystore\calorie_tracker_upload.jks` |
| AAB output | `build\app\outputs\bundle\release\app-release.aab` |
| APK output | `build\app\outputs\flutter-apk\app-release.apk` |

Gradle 9.1. `compileSdk` and `targetSdk` pinned to **36**. `minSdk 24`, deliberate,
for older Libyan phones. JDK 25 works despite the known Kotlin plugin risk.

**Signing:** exactly ONE keystore. SHA-256 starts `57:C4:D7`. DN `O=ly.app`.
Password in `android/key.properties` (gitignored, **already filled in, don't touch
it or ask about it again**). Backed up to USB drive and cloud.
`applicationId` is `ly.app.calorie_tracker` — permanent, cannot change after publish.

**Verify signing after anything that touches `android/`:**
```
"C:\Program Files\Eclipse Adoptium\jdk-25.0.4.7-hotspot\bin\keytool.exe" -printcert -jarfile build\app\outputs\bundle\release\app-release.aab
```
Expect `O=ly.app` and `57:C4:D7`. **For APKs, `keytool` will say "Not a signed jar
file", that's normal (v2/v3 scheme), use apksigner instead:**
```
"C:\Users\abdul\AppData\Local\Android\Sdk\build-tools\36.0.0\apksigner.bat" verify --print-certs build\app\outputs\flutter-apk\app-release.apk
```

**Installing a fresh build on the emulator, if the signature ever mismatches**
(`INSTALL_FAILED_UPDATE_INCOMPATIBLE`, usually means whatever's installed was a
debug build from a different signing path): `adb uninstall ly.app.calorie_tracker`
first, then a plain install, not `-r`. To re-walk onboarding on an already-installed
build without losing the signing check, `adb shell pm clear ly.app.calorie_tracker`
wipes app data only, keeps the same signed install.

---

## Git layout

Repo: `abdulmoezshadi90-art/calorie_tracker` (public)

- `main` — source of truth for source code
- `ui-restructure` — my active working branch, in sync with origin as of 20 Aug 2026
- `gh-pages` — **orphan branch**, deployed website only, no source history

GitHub Pages serves from `gh-pages` root:
- Demo: `https://abdulmoezshadi90-art.github.io/calorie_tracker/` (confirmed live)
- Policy: `https://abdulmoezshadi90-art.github.io/calorie_tracker/privacy.html` (confirmed live, HTTP 200)

**Deploying the web demo is a known trap.** `git rm -rf .` untracks files but leaves
them on disk *and removes `.gitignore`*, so a later `git add -A` stages the entire
working directory including `android/key.properties`. Always `git status --short`
before committing on `gh-pages`. The safe wipe keeps `.git`:
```
for /d %d in (calorie_tracker\*) do @if /i not "%~nxd"==".git" rd /s /q "%d"
del /q calorie_tracker\*.*
```
Web build command: `flutter build web --release --base-href /calorie_tracker/`
The `--base-href` is required or Pages serves a blank page.
`privacy.html` is not in the build output and must be added to the deploy folder.

---

## Design assets

**Figma is the single source of truth.** File `2u2WR8pff16ghV9zpWwGh1`
(`https://www.figma.com/design/2u2WR8pff16ghV9zpWwGh1`)

Frames: `icon`, `adaptive_foreground`, `adaptive_background`, `splash_mark`,
`splash_mark_dark`, `feature_graphic`.

Icon: cream bowl, gold mound, forest green gradient background. Exports to
`assets/icons/`. Splash marks to `assets/branding/` (now also declared as a bundled
Flutter asset in `pubspec.yaml`, needed at runtime by the animated splash screen).

The old generator script `tool/generate_app_icon.dart` **was deleted on purpose.**
Do not recreate it. `tool/generate_meal_icons.dart` is unrelated and stays.

**Adaptive icon constraint:** Android crops to circle/squircle/rounded-square. Keep
everything inside the centre 666 of a 1024 canvas. Android also applies a 16% inset
to the foreground layer.

Figma MCP is on a **Starter plan with a tool-call limit** that gets hit quickly.

Feature graphics (1024x500, Play Store) are done, EN + AR, at `store_assets/en/` and
`store_assets/ar/`. Same directory also holds the draft store listing copy and Play
Console form prep, still pending my own review.

---

## Verify loop

```
C:\dev\flutter\bin\flutter.bat analyze
C:\dev\flutter\bin\flutter.bat test
```
**234 tests.** Golden screenshots live in `test\goldens\`. When a layout change is
deliberate, inspect `test\failures\*_isolatedDiff.png` **before** regenerating:
```
C:\dev\flutter\bin\flutter.bat test --update-goldens test\screenshots_test.dart
```
Never update goldens blind. It bakes in bugs permanently.

If `flutter test` fails to even launch with "An Application Control policy has
blocked this file" against `flutter_tester.exe`, that's a Windows security policy,
not a code problem, see the environment-gremlins note near the top of this doc.

---

## Docs

`README.md`, `PRODUCT.md`, `HANDOFF.md` (this file, kept current directly by Claude
each session, replace it fully rather than leaving stale sections when you hand off).
`PLAN.md`, `CLAUDE.md`, and `DEV_NOTES.md` **do not exist anywhere on this machine**,
not even in a private folder, despite older docs referencing them. They were stripped
in commit `f1c22a7` ("prepare repository for public release") and never recreated.
Don't assume they exist, don't fabricate their contents, if you need that context ask
the owner where the real copies live.

`store_assets/` holds Play Store material: `en/feature_graphic.png`,
`ar/feature_graphic.png`, `en/listing.md`, `ar/listing.md` (draft store copy, pending
owner review), `play_console_forms.md` (draft compliance-form answers).

All three docs (`README.md`, `PRODUCT.md`, this file) are accurate as of 20 Aug 2026.
If you edit any of them again, verify against `food_db.dart` / `AppState` and the
actual test count first, don't just extend the existing prose.

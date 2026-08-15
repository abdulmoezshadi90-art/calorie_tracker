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
- Before writing anything user-facing (docs, store copy), verify claims against the
  actual code, not against what an older doc says. This session caught a real false
  claim (see below) by checking `food_db.dart` directly instead of trusting `README.md`.
- When asked to review your own work, actually check it against the codebase from
  multiple angles (accuracy, consistency, policy risk, format limits), not just reread
  the text. That's what caught the issues in the 15 Aug session log below.

---

## The product

**Zibda (زبدة)** — butter, colloquially "the best part". Single brand in both
languages: `Zibda` in Latin, `زبدة` in Arabic. The old name متتبع السعرات is retired
as a brand (may survive as a store keyword).

**The gap:** global apps don't cover Libyan food. Local packaged brands today;
named home dishes (bazin, mbakbka, couscous, usban, sfinz, maqrud) are **planned,
not shipped** — only their raw ingredients (flour, barley, couscous, pasta, produce)
are in `food_db.dart` right now. Don't describe these dishes as searchable in any
doc or store copy until they're actually entered.

**Differentiators, in order of importance:**
1. Fully offline. No network permission at all (confirmed: no `uses-permission` in
   `AndroidManifest.xml`). No accounts, no login.
2. No ads, ever. Stated product principle (confirmed: no ad/analytics packages in
   `pubspec.yaml`, only `shared_preferences` and `flutter_localizations`).
3. Arabic-first with full RTL and a language toggle.
4. Verified nutrition data with visible provenance (108 of 164 foods verified as of
   15 Aug 2026, shown via a checkmark badge on the food detail screen).
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
   it's actually in the code. See the bazin/mbakbka catch below.
8. **External-facing files live on a branch that won't be deleted.** Learned the hard
   way: the privacy policy was on a feature branch and the URL nearly broke.

---

## Session log — 15 Aug 2026

Continuation of the 14 Aug session. Everything below is committed to `ui-restructure`
but **not pushed** to origin (4 commits ahead as of this handoff). `git log --oneline -8`
to see them: `a32ff6b`, `6b13eed`, `384aa32`, `817b57b`, plus the 14 Aug commits under
them (`5f43d01`, `0a83f01`, `c6bd062`, `f70dcbd`).

**1. Fixed a real bug in the meal builder** (`817b57b`). Reported as: "in create a
meal, tapping a food quick-adds it instead of letting me choose quantity, like every
other add-food flow in the app." Root cause: `create_meal_screen.dart` wired both row
tap and the quick-add button to the same instant-add function, a leftover assumption
from an earlier refactor that was never actually confirmed with me. Fix: added a
draft mode to `FoodDetailScreen` (`onConfirm` callback hands back a multiplier
instead of logging to today, and `meal` becomes optional; the time-of-day row hides
itself in draft mode since a saved-meal item has no log timestamp). Row tap now
pushes that screen; quick-add is unchanged. Caught a second bug while testing this:
the test helper's `AppScope` only wrapped the initial route via `MaterialApp(home:
...)` instead of `MaterialApp(builder: ...)`, so any route a test pushes can't find
app state. Fixed the same way `main.dart` actually does it. New regression test in
`test/create_meal_screen_test.dart`.

**2. Signing is done.** `android/key.properties` now exists and is filled in
(`keyAlias`, `keyPassword`, `storePassword` sourced from the USB backup, `storeFile`
points at `C:/Users/abdul/dev/keystore/calorie_tracker_upload.jks`). Don't ask me to
recreate it, don't print its contents back to me, it's gitignored and already correct.
Built and verified both:
- `flutter build appbundle --release` → `build\app\outputs\bundle\release\app-release.aab`,
  verified with `keytool -printcert -jarfile`, `O=ly.app`, SHA-256 `57:C4:D7...`.
- `flutter build apk --release` → `build\app\outputs\flutter-apk\app-release.apk`.
  **`keytool -printcert -jarfile` says "Not a signed jar file" for this one, that's
  expected, not a bug** — modern Android builds sign APKs with the v2/v3 scheme,
  which `keytool` can't read. Use `apksigner verify --print-certs` instead:
  `C:\Users\abdul\AppData\Local\Android\Sdk\build-tools\36.0.0\apksigner.bat`.
  Confirmed same cert.

**3. The "no Android device" blocker is gone.** I have a physical Android phone now.
It wasn't physically present during this session, so nothing got sideloaded or tested
on it yet, that's the actual next step. AVD `libya_test_phone`'s launch failure is
lower priority now that a real device exists, but still unfixed if you want it back.

**4. Started Play Console prep**, three new files in `store_assets/`:
- `en/listing.md`, `ar/listing.md` — short + full store descriptions. **Drafts.** I
  haven't given final sign-off, especially the Arabic, which was AI-translated and
  needs my native-speaker read before anything gets pasted into Play Console.
- `play_console_forms.md` — draft answers for data safety, content rating (IARC),
  target audience, app access, category. Grounded in actual facts (no backend, no
  `INTERNET` permission, no accounts, no ad/analytics deps) but still needs to be
  walked through the real Play Console forms by me, wording differs there.

**5. Caught a real false claim while drafting these**, not a copy nitpick, an actual
factual error already sitting in committed docs: `README.md` and `PRODUCT.md` both
claimed bazin, mbakbka, usban, sfinz, and maqrud were searchable dishes. They aren't.
Only base ingredients are in `food_db.dart`. I confirmed with the owner (me): planned,
not shipped. Fixed both docs (`6b13eed`) to describe current coverage honestly instead.
**If you're about to write any store copy, marketing text, or doc claiming specific
food/dish coverage, check `food_db.dart`'s `nameEn` fields directly first.**

**6. Ran a 5-angle review pass** on the store copy after that catch (factual accuracy
against code, cross-file consistency, Play Store policy risk, character limits,
grammar/format) and found five more things, all fixed:
- `PRODUCT.md` still said "no physical Android devices" (stale, see #3) and "206
  passing tests" (stale, it's 207 now, one new regression test from #1).
- `en/listing.md` named **MyFitnessPal directly** in public store copy, a real
  trademark/policy risk. Removed in favor of generic "global calorie apps," matching
  what the Arabic version already said (it hadn't made the same mistake).
- Arabic short description was 79 of the 80-character limit, right at the edge, and
  had a diacritic that could count differently in Play Console's own counter. Trimmed
  to 73 chars and dropped the diacritic.
- Two Arabic phrasings reworked: a verb-gender agreement question around زبدة (sidestepped
  by making تطبيق, unambiguously masculine, the grammatical subject instead) and an
  awkward literal "nothing to lose" construction.
- Bonus, found while verifying the feedback-email claim in `play_console_forms.md`
  against the actual code: `lib/settings_screen.dart` still hardcoded `'Calorie
  Tracker feedback'` as the email subject, the retired app name, live in the shipped
  app. Fixed (`384aa32`). **This means the "Zibda everywhere" rename claim in earlier
  docs was itself not fully true until this fix. If anything else still says "Calorie
  Tracker" anywhere, that's a real bug, not a doc problem.**

All fixes verified: `flutter analyze` clean, `flutter test` 207/207, both before and
after every code change in this list.

**Immediate next steps, in order:**
1. Push the 4 local commits to `origin/ui-restructure` (not done, wasn't asked to).
2. Get the phone physically present, sideload the built APK
   (`build\app\outputs\flutter-apk\app-release.apk`), run the real-device parts of
   `QA_CHECKLIST.md` that were never possible before (launcher icon, splash light/dark,
   haptics, restart persistence).
3. My own review of `store_assets/en/listing.md` and `store_assets/ar/listing.md`,
   especially the Arabic.
4. Walk `store_assets/play_console_forms.md`'s answers into the actual Play Console
   data safety / content rating / target audience / app access forms.
5. Open the 12-tester closed test, starts the mandatory 14-day clock.

---

## Current state (15 Aug 2026)

Private beta. Well ahead of the original timeline.

**Done:** signing fully working (see session log above), signed AAB and APK built and
verified, adaptive launcher icon, splash screen (light + dark), app rename to Zibda
verified complete (including the feedback-email subject line fix), privacy policy
live, feature graphics EN + AR, web demo deployed and confirmed live, 207 tests
passing, analyze clean, meal-builder quantity-picker bug fixed, Play Store listing
copy and compliance-form answers drafted (pending my review).

**Not blocked on anything hard anymore.** Phone exists, signing works, docs are
accurate. What's left is my own review time and the mechanical Play Console work.

**Open work:**
- Push local commits to origin.
- Sideload and real-device QA (see immediate next steps above).
- My review of the drafted store listing copy, especially Arabic.
- Actually fill the Play Console forms using `store_assets/play_console_forms.md`.
- `main/docs/privacy.html` is redundant (live copy serves from `gh-pages`), cleanup
  item, not urgent.
- AVD `libya_test_phone` still fails to launch (exit code 1, empty stderr,
  undiagnosed), low priority now.
- Named Libyan home dishes (bazin, mbakbka, usban, sfinz, maqrud) are still not in
  `food_db.dart`, roadmap item whenever there's appetite for it.

**Deliberately deferred:** Flutter upgrade (build chain works, don't touch it before
release), barcode scanner, accounts/sync, iOS via Codemagic + TestFlight ($99 budgeted).

---

## Architecture

Flutter 3.44.6. Local-only `shared_preferences`, JSON day-logs keyed `yyyy-MM-dd`.
No backend by design. Storage isolated in `AppState` so a backend could be swapped in.

`lib/`
- `main.dart` — MaterialApp, locale switching, web `?lang=ar|en` override. `AppScope`
  is wired via `MaterialApp`'s `builder:`, not around `home:` — it has to cover every
  pushed route, not just the first one. If you're writing a test that pumps a screen
  standalone, wire it the same way or a pushed route won't find app state (see
  session log item 1 for what that failure looks like).
- `app_state.dart` — `AppState` (ChangeNotifier) + `AppScope` (InheritedNotifier)
- `models.dart` — FoodItem, LogEntry, MealType, DayTotals, ServingUnit, number formatters
- `theme.dart` — `AppColors`, full light + dark palettes
- `l10n.dart` — hand-rolled EN/AR strings, no intl codegen
- `food_db.dart` — Libyan foods, EN+AR names, many now cite USDA FDC IDs. 164 entries,
  108 verified. Source of truth for "what's actually searchable" — check here before
  writing any doc or copy claiming food/dish coverage.
- Screens: `home_screen`, `search_screen`, `meal_detail_screen`, `progress_screen`,
  `profile_screen`, `create_meal_screen`, `food_detail_screen` (now has a draft mode,
  see session log item 1)
- Widgets: `food_picker`, `all_foods_tab`, `food_history_tab`, `saved_meals_tab`,
  `empty_state`
- `settings_screen.dart` — feedback email via native `MethodChannel` mail intent
  (`ly.app.calorie_tracker/mail`), not `url_launcher`, deliberate tiny dependency
  footprint. Subject line now correctly says "Zibda feedback".

## Color system (`lib/theme.dart` → `AppColors`)

Light: pageBg `#F1EEE0`, header gradient `#35533B` → `#243D2A`, accent `#2E8B57`,
gold `#E9B949`, card `#FFFDF6`, ink `#1E3325`, muted `#5F6E62`
Macros: carb `#F59E0B`, fat `#8B5CF6`, protein `#EF4444`
Also: `kcalAccent #2F8F5B`, `fieldError #D06A4F`
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

---

## Git layout

Repo: `abdulmoezshadi90-art/calorie_tracker` (public)

- `main` — source of truth for source code
- `ui-restructure` — my active working branch, **4 commits ahead of origin as of
  15 Aug 2026, not pushed yet**
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
`assets/icons/`. Splash marks to `assets/branding/`. Confirmed as of 14 Aug 2026 that
`assets/icons/` and the generated Android/iOS/web launcher icons were already fully
in sync with the Figma export, `flutter pub run flutter_launcher_icons` regenerated
zero actual content (only line-ending noise, discarded).

The old generator script `tool/generate_app_icon.dart` **was deleted on purpose.**
Do not recreate it. `tool/generate_meal_icons.dart` is unrelated and stays.

**Adaptive icon constraint:** Android crops to circle/squircle/rounded-square. Keep
everything inside the centre 666 of a 1024 canvas. Android also applies a 16% inset
to the foreground layer.

Figma MCP is on a **Starter plan with a tool-call limit** that gets hit quickly.

Feature graphics (1024x500, Play Store) are done, EN + AR, at `store_assets/en/` and
`store_assets/ar/`. Same directory now also holds the draft store listing copy and
Play Console form prep, see session log above.

---

## Verify loop

```
C:\dev\flutter\bin\flutter.bat analyze
C:\dev\flutter\bin\flutter.bat test
```
**207 tests** (was 206, one new regression test added 15 Aug for the meal-builder
fix). Golden screenshots live in `test\goldens\`. When a layout change is
deliberate, inspect `test\failures\*_isolatedDiff.png` **before** regenerating:
```
C:\dev\flutter\bin\flutter.bat test --update-goldens test\screenshots_test.dart
```
Never update goldens blind. It bakes in bugs permanently.

---

## Docs

`README.md`, `PRODUCT.md`, `HANDOFF.md` (this file, kept current directly by Claude
each session, replace it fully rather than leaving stale sections when you hand off).
`PLAN.md`, `CLAUDE.md`, and `DEV_NOTES.md` **do not exist anywhere on this machine**
as of 15 Aug 2026, not even in a private folder, despite older docs referencing them.
They were stripped in commit `f1c22a7` ("prepare repository for public release") and
never recreated. Don't assume they exist, don't fabricate their contents, if you need
that context ask the owner where the real copies live.

`store_assets/` holds Play Store material: `en/feature_graphic.png`,
`ar/feature_graphic.png`, `en/listing.md`, `ar/listing.md` (draft store copy, pending
owner review), `play_console_forms.md` (draft compliance-form answers).

`README.md` and `PRODUCT.md` were both fixed 15 Aug 2026 for a real false claim about
Libyan dish coverage (see session log). Both are accurate as of this handoff. If you
edit either again, verify against `food_db.dart` and the actual test count first,
don't just extend the existing prose.

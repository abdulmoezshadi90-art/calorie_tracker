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

---

## The product

**Zibda (زبدة)** — butter, colloquially "the best part". Single brand in both
languages: `Zibda` in Latin, `زبدة` in Arabic. The old name متتبع السعرات is retired
as a brand (may survive as a store keyword).

**The gap:** global apps don't cover Libyan food. Bazin, mbakbka, couscous, usban,
sfinz, maqrud, and local packaged brands.

**Differentiators, in order of importance:**
1. Fully offline. No network permission at all. No accounts, no login.
2. No ads, ever. Stated product principle.
3. Arabic-first with full RTL and a language toggle.
4. Verified nutrition data with visible provenance.
5. Ramadan mode, household portion presets.
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
   onboarding and settings in both languages.
7. **Nutrition data honesty.** Verification status is a visible, first-class property.
   Never present unverified numbers as accurate.
8. **External-facing files live on a branch that won't be deleted.** Learned the hard
   way: the privacy policy was on a feature branch and the URL nearly broke.

---

## Current state (14 Aug 2026)

Private beta. Well ahead of the original timeline.

**Done:** signed AAB, adaptive launcher icon, splash screen (light + dark), app rename
to Zibda everywhere, privacy policy live, feature graphic (English), web demo
deployed, 206 tests passing, analyze clean.

**Blocked on one thing:** I own an iPhone 15 Pro Max and **no Android device**. This
blocks Play store screenshots, real-device testing, and the 12-tester closed test that
starts the mandatory 14-day clock. Everything else is a few hours of work.
AVD `libya_test_phone` exists but currently fails to launch (exit code 1, empty stderr,
undiagnosed).

**Open work, no phone needed:**
- Play Console listing copy, EN + AR
- Data safety form, content rating, target audience, app access
- Arabic feature graphic (Figma MCP hit the Starter plan tool-call limit)
- Remove **Kalee** and **Bifa** from `food_db.dart` — those brands aren't sold in
  Libya, it was my mistake. Phantom entries would confuse testers.
- `main/docs/privacy.html` is now redundant (live copy serves from `gh-pages`)
- Known test warning: a `tap()` on `quick-add-sample_snack_1` misses its hit target.
  Tests pass, but it may be a real layout bug on small screens.

**Deliberately deferred:** Flutter upgrade (build chain works, don't touch it before
release), barcode scanner, accounts/sync, iOS via Codemagic + TestFlight ($99 budgeted).

---

## Architecture

Flutter 3.44.6. Local-only `shared_preferences`, JSON day-logs keyed `yyyy-MM-dd`.
No backend by design. Storage isolated in `AppState` so a backend could be swapped in.

`lib/`
- `main.dart` — MaterialApp, locale switching, web `?lang=ar|en` override
- `app_state.dart` — `AppState` (ChangeNotifier) + `AppScope` (InheritedNotifier)
- `models.dart` — FoodItem, LogEntry, MealType, DayTotals, ServingUnit, number formatters
- `theme.dart` — `AppColors`, full light + dark palettes
- `l10n.dart` — hand-rolled EN/AR strings, no intl codegen
- `food_db.dart` — Libyan foods, EN+AR names, many now cite USDA FDC IDs
- Screens: `home_screen`, `search_screen`, `meal_detail_screen`, `progress_screen`,
  `profile_screen`, `create_meal_screen`, `food_detail_screen`
- Widgets: `food_picker`, `all_foods_tab`, `food_history_tab`, `saved_meals_tab`,
  `empty_state`

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
| Build tools | `...\Sdk\build-tools\36.0.0` |
| Keystore | `C:\Users\abdul\dev\keystore\calorie_tracker_upload.jks` |
| AAB output | `build\app\outputs\bundle\release\app-release.aab` |

Gradle 9.1. `compileSdk` and `targetSdk` pinned to **36**. `minSdk 24`, deliberate,
for older Libyan phones. JDK 25 works despite the known Kotlin plugin risk.

**Signing:** exactly ONE keystore. SHA-256 starts `57:C4:D7`. DN `O=ly.app`.
Password in `android/key.properties` (gitignored). Backed up to USB drive D and cloud.
`applicationId` is `ly.app.calorie_tracker` — permanent, cannot change after publish.

**Verify signing after anything that touches `android/`:**
```
"C:\Program Files\Eclipse Adoptium\jdk-25.0.4.7-hotspot\bin\keytool.exe" -printcert -jarfile build\app\outputs\bundle\release\app-release.aab
```
Expect `O=ly.app` and `57:C4:D7`.

---

## Git layout

Repo: `abdulmoezshadi90-art/calorie_tracker` (public)

- `main` — source of truth for source code
- `ui-restructure` — my active working branch
- `gh-pages` — **orphan branch**, deployed website only, no source history

GitHub Pages serves from `gh-pages` root:
- Demo: `https://abdulmoezshadi90-art.github.io/calorie_tracker/`
- Policy: `https://abdulmoezshadi90-art.github.io/calorie_tracker/privacy.html`

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
`assets/icons/`. Splash marks to `assets/branding/`.

The old generator script `tool/generate_app_icon.dart` **was deleted on purpose.**
Do not recreate it. `tool/generate_meal_icons.dart` is unrelated and stays.

**Adaptive icon constraint:** Android crops to circle/squircle/rounded-square. Keep
everything inside the centre 666 of a 1024 canvas. Android also applies a 16% inset
to the foreground layer.

Figma MCP is on a **Starter plan with a tool-call limit** that gets hit quickly.

---

## Verify loop

```
C:\dev\flutter\bin\flutter.bat analyze
C:\dev\flutter\bin\flutter.bat test
```
206 tests. Golden screenshots live in `test\goldens\`. When a layout change is
deliberate, inspect `test\failures\*_isolatedDiff.png` **before** regenerating:
```
C:\dev\flutter\bin\flutter.bat test --update-goldens test\screenshots_test.dart
```
Never update goldens blind. It bakes in bugs permanently.

---

## Docs

`README.md`, `PLAN.md`, `CLAUDE.md` (Claude Code handoff brief), `PRODUCT.md`,
plus an Obsidian vault (dashboard, phase tracker, data verification tracker, beta
feedback index, decision log, Ramadan countdown).

`PRODUCT.md` is currently stale in places (says 46 tests, says all data is placeholder).
Worth a refresh.

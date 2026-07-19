# CLAUDE CODE PROJECT BRIEF (read automatically every session)

You are working on my Flutter app. Read this entire brief before touching anything. It contains the project context, hard rules, the full plan, and your first tasks.

# PROJECT: Libyan Calorie Tracker (متتبع السعرات)

A mobile calorie counting app for the Libyan market. Global apps (MyFitnessPal etc.) do not cover Libyan products like Kalee snacks or dishes like bazin and mbakbka. This app fills that gap. I am a solo developer. Email: abdulmoezshadi.90@gmail.com.

Positioning (for any store copy or user facing text later): works offline, no signup, your data stays on your phone, built for Libyan food and Libyan life. Never add copy that contradicts this.

# MACHINE AND ENVIRONMENT

1. Windows 11.
2. Flutter 3.44.6, SDK at C:\dev\flutter, NOT on PATH. Every command is C:\dev\flutter\bin\flutter.bat <command>.
3. Project: C:\Users\abdul\dev\calorie_tracker (package calorie_tracker, org ly.app, platforms android/ios/web).
4. System Java is 26, TOO NEW for Gradle 9.1. Android builds need JDK 17 to 25 via flutter config --jdk-dir=<path> first. Not set up yet. Do not attempt Android builds until Phase 3.
5. iOS: no Mac on hand and none needed. The iOS beta path is cloud CI (Codemagic) to TestFlight, active as a best effort track in Phase 5, tested on my iPhone 15 Pro Max. Full App Store release stays a Phase 9 / July gate decision. (A weekly unsigned iOS build check already runs in GitHub Actions.)
6. Key commands:
   - Analyze: C:\dev\flutter\bin\flutter.bat analyze
   - All tests: C:\dev\flutter\bin\flutter.bat test
   - Regenerate goldens: C:\dev\flutter\bin\flutter.bat test --update-goldens test\screenshots_test.dart
   - Web build: C:\dev\flutter\bin\flutter.bat build web --release (serve build\web with any static server)
7. Goldens load Roboto from the SDK cache plus Segoe UI and Segoe UI Emoji from Windows fonts. The theme has fontFamilyFallback ['SegoeUI','SegoeUIEmoji'] for this. It is harmless on device. Do not remove it.
8. Do not upgrade Flutter, Gradle, or the JDK mid phase. Upgrades happen only between phases, with a clean commit before and after, then full tests plus goldens.

# CURRENT STATE (updated 19 July 2026 — Phase 5)

Phases 0 to 4 are COMPLETE: front end finished (settings, goals editing, history, onboarding, empty states, polish), Android release build working, emulator QA passed (user has no physical Android devices — AVD `libya_test_phone` plus wave-one testers' phones are the device lab), portion presets shipped. The Android beta build (`beta-2026-07-19`) is ready to launch. The definitive record of what exists is the code, git log, tags, and closed issues — trust those over any summary here, and update this section as phases complete.

46 tests pass, analyzer clean. Goldens are deterministic: AppState takes an injectable clock, pinned to Wed 2026-07-15 09:30. Golden helper precaches the meal-icon assets (asset images never decode under the fake-async test clock).

Repo https://github.com/abdulmoezshadi90-art/calorie_tracker, tags mvp-skeleton / v0.2-goals / v0.3-phase1 / v0.4-portions / beta-2026-07-19, milestones mirror the roadmap phases.

Related artifacts that already exist outside this repo (built earlier with Claude Code):
1. Screenshots page: https://claude.ai/code/artifact/56cb6bb6-8115-4cdd-9097-3055dc52976b
2. Interactive web demo: https://claude.ai/code/artifact/71987bee-060d-4256-a2cc-955ecfc38a77 (a hand built HTML twin of the app, same food DB and logic, localStorage, shareable for feedback). NOTE: this twin duplicates the food DB. When food_db.dart changes significantly, flag that the demo is now out of sync so I can decide whether to update or retire it.

# ARCHITECTURE (lib/)

1. main.dart: entry; MaterialApp with locale switching; web only ?lang=ar|en URL override.
2. app_state.dart: AppState (ChangeNotifier) holds logs, totals, locale, goals, persistence, and an injectable clock (constructor param `clock`, exposed as `now`; UI date reads go through it so goldens stay deterministic). AppScope (InheritedNotifier) exposes it. Goals are a persisted Goals object (defaults 2000 kcal, 220g carb, 65g fat, 110g protein) saved under prefs key 'goals'; setGoals() notifies then persists. Storage is local only via shared_preferences, JSON day logs keyed yyyy-MM-dd. Storage is isolated in AppState so a backend can be swapped in later. No backend by design.
3. models.dart: FoodItem, LogEntry, MealType (breakfast/lunch/dinner/snack with emoji and icon), Goals (immutable, null-tolerant fromJson), DayTotals, and number formatters fmtInt/fmtGrams/fmtServings.
4. food_db.dart: 44 foods (Kalee variants, Bifa, Al Naseem, bazin, couscous, mbakbka, usban, sfinz, maqrud, Libyan teas, more). Each has EN and AR names and servings, kcal, protein/carbs/fat, category.
5. l10n.dart: hand rolled EN/AR strings, no intl codegen. Arabic month and day names.
6. theme.dart: AppColors design-token system (light/dark palettes per the design PDF), AppColors.of(context), buildTheme(). Widgets never hardcode colors. ThemeMode.system.
7. home_screen.dart: green header with greeting (name hidden until profiles exist), today pill, week strip (gold selected day), calorie card with linear progress bar (no ring), combined macro card (three columns with mini bars), meal rows with dashed dividers.
8. search_screen.dart: search matching EN or AR, add sheet with 0.5 step servings stepper.
9. meal_detail_screen.dart: per meal entries, delete, total.

# HARD REQUIREMENTS (never violate, never "improve" away)

1. Numerals are ALWAYS Western digits (0-9), including in Arabic. All numbers go through fmtInt/fmtGrams/fmtServings. Never use locale aware number formatting. Any numeric text input must normalize Eastern Arabic numerals (٠١٢٣٤٥٦٧٨٩) to Western on entry.
2. Full RTL layout in Arabic. Language toggle in the top bar. Choice persists.
3. Visual identity (per the design PDF, implemented as tokens in theme.dart — change colors THERE, never inline): warm cream page bg #F1EEE0, forest green header #35533B→#243D2A, gold selected-day #EFC65B, accent green #2E8B57, card #FFFDF6, ink #1E3325, muted #7E8C7F; macros carb #E0A72E, fat #D06A4F, protein #2F8F5B. Full light AND dark palettes exist in AppColors; every color change must cover both. Rounded cards, soft shadows, dashed meal dividers.
4. MVP scope stays tight: NO barcode scanner, NO accounts or login, NO social features unless I explicitly ask.
5. All nutrition numbers in food_db.dart are PLACEHOLDERS until verified. Never present current numbers as accurate.
6. Match existing code style. Arabic strings live in l10n.dart. Foods live in food_db.dart. Do not redesign existing screens from scratch; iterate and fill gaps.
7. Run analyze and the full test suite after every change set. Commit at the end of every session.

# ROADMAP (full details, metrics, and decision gates live in PLAN.md; keep both files in the repo)

- Phase 0 (DONE 18 July 2026): git init, GitHub push, DEV_NOTES.md, GitHub issues as backlog.
- Phase 1 (5 to 6 weeks): finish front end, in this order:
  a. Goals persistence + settings screen with goals editor (Tasks 2 and 3 below).
  b. History screen: scrollable list of past days (date, total kcal, over/under indicator), tap opens a read only day view, plus a 7 day calorie bar chart via CustomPainter (no charting package). Test with empty, 1 day, and 30 days of data.
  c. Onboarding: 3 screens max, language choice FIRST (it gates everything), then a one screen logging intro, then goal setup reusing the goals editor widgets. Shown once via a prefs flag, fully skippable (defaults must carry it), replayable from settings.
  d. Polish pass: empty states for (i) no foods logged today, (ii) empty search results, (iii) empty history, (iv) empty meal detail, each with a short friendly EN+AR line and a clear action. Replace emoji meal icons with 4 bundled SVG/PNG assets. App icon (motif matching the current design language: forest green + cream, e.g. the linear progress bar or a leaf/plate mark) + splash. Haptics via HapticFeedback.lightImpact() on log and delete.
  e. Hardening: zero analyzer warnings, all tests + goldens pass, write a reusable ~20 step manual QA checklist doc (QA_CHECKLIST.md) covering language switch, logging, goal edit, restart persistence, delete, etc. This checklist runs before EVERY release from here on, including weekly beta builds.
- Phase 2 (parallel, fieldwork): verified nutrition data. See DATA PIPELINE below.
- Phase 3: Android build (JDK 17 via Temurin), set minSdkVersion low deliberately (Libyan phones skew old and cheap, target around API 24), on device testing on 2 physical devices including a cheap one. Watch: Arabic rendering, RTL mirroring of week strip and ring, device font fallbacks, CustomPainter performance on weak GPUs, large system font sizes. If Arabic looks poor on cheap devices, consider bundling a Noto Arabic font. Create the signing keystore and back it up in two places; losing it means never updating the app on Play. Learn/record adb + logcat basics in DEV_NOTES.md.
- Phase 4: household portion presets on FoodItem (each preset: EN name, AR name, exact gram weight; e.g. ladle 250g, small plate 180g). Preset chips above the existing servings stepper in the add sheet; stepper remains for fine adjustment. Populate the top 15 to 20 foods first.
- Phase 5 (CURRENT): private beta, ~4 weeks. Android track (primary): tag beta builds (version visible in settings), one Telegram/WhatsApp feedback group set up BEFORE first install, recruit in two waves (~5 close people first to catch embarrassing bugs, fix, ship beta2, then 10 to 15 more including strangers), APK via Telegram/WhatsApp plus web demo link, settings item opening a prefilled feedback email to abdulmoezshadi.90@gmail.com with app version and locale, weekly beta builds with QA checklist and git tag each, capture the foods testers search for and do not find (the Phase 8 backlog). Tester feature suggestions go to the "later" label. iOS track (best effort, parallel, NEVER blocks Android or the Ramadan deadline): Apple Developer account registered immediately (99 dollars, enrollment from Libya can take days), Codemagic pipeline in one to two timeboxed afternoons (App Store Connect API key, automatic signing, upload to TestFlight), full QA on my iPhone 15 Pro Max first (watch Arabic/RTL under iOS system fonts, Dynamic Island safe areas, persistence, the ring), then external TestFlight public link (first build needs an Apple review pass of a day or two, submit early), link shared beside the APK from wave two. iOS only bugs: fix if cheap, otherwise log and shelve. If the pipeline exceeds its timebox, iOS beta slips to post launch and the PWA covers iPhones. Also this week: register the Google Play developer account (beta is the slack that absorbs verification delays).
- Phase 6: public launch early December 2026. Register the Google Play developer account EARLY (during beta), because the 25 dollar fee and verification can hit payment friction from Libya; fallback chain is a relative abroad, then direct APK + landing page. Direct APK distribution is a legitimate primary channel in Libya regardless. Store listing: Arabic first screenshots (extend the golden generator for store sizes), description leads with Libyan foods / offline / no signup / data stays on phone. Semantic versions, git tag per release, CHANGELOG.md. Crash reporting: NONE for now by conscious decision (privacy story stays clean; the feedback email is the only telemetry); reconsider Sentry free tier after launch and update the privacy statement first if adopted. Write a one page privacy statement: no data leaves the device, no accounts, no tracking; the Play data safety form declares no data collected (true by architecture). Launch marketing is zero budget: Libyan Facebook groups (Facebook dominates in Libya), beta testers sharing, and a short demo video captured from a real phone.
- Phase 7: RAMADAN MODE, hard deadline 25 January 2027 (Ramadan 1448 starts around 8 February 2027, exact start follows moon sighting). Details:
  a. Hijri calendar via a maintained Umm al Qura conversion package; show Hijri date in week strip and settings.
  b. Suhoor/iftar/evening snack as PRESENTATION over the existing MealType model (map suhoor to breakfast internally, etc.); storage, history, and tests stay on the unchanged model.
  c. Configurable day cutoff (default ~4am during Ramadan) so a 2am suhoor logs to the fasting day that is starting. Libya is UTC+2 with no DST, which simplifies date math, but the cutoff logic gets its own test file (boundary times, month transitions, Hijri/Gregorian display in both languages).
  d. Auto suggest activation in late Shaaban + manual toggle in settings; never force it, the user is the authority on when Ramadan starts.
  e. Goals and the calorie ring keep the same numbers by default (energy needs do not drop because timing changed); home layout reflects two main meals.
  f. Optional stretch ONLY if time allows: gentle suhoor reminder notification (adds permission complexity, cut it first).
  g. Ship by 25 January so early users have it before the first suhoor and a Play review delay cannot sink the deadline; prepare the announcement posts for mid January ("the first calorie tracker built for Ramadan"). Verify the actual Ramadan start date against announced moon sighting expectations closer to the time.
  h. This deadline never moves. When behind schedule anywhere, the cut order is: animations/haptics first, then the history chart (list stays), then onboarding (defaults carry it), NEVER goals editing, NEVER data verification, NEVER this deadline. If even the buffer burns, Ramadan mode ships mid Ramadan rather than not at all.
- Phase 8 (post Ramadan, March 2027, reorder based on Ramadan usage data): missing foods batch two (from user requests), tea/coffee one tap quick log (daily retention driver), Sunnah fasting tracker (Mondays, Thursdays, White Days 13 to 15, Shawwal six, Ashura, Arafah; reuses Ramadan layout + Hijri calendar; fasting history view), Friday family meal guided flow (dish + share size [modest/normal/generous] + extras [bread, salad, maqrud, tea]; builds on portion presets; extend to both Eids), seasonal food rotation (static in code calendar), export/import of day logs as a single JSON file (uninstall currently means total data loss; this is the no backend backup story, Phase 8 at the latest).
- Phase 9 (H2 2027, all gated on the July 2027 decision review, not before): barcode scanner (only once the verified packaged DB is large enough that scans usually hit; barcodes are being collected in the spreadsheet from the first label), optional sync/accounts (guest is the DEFAULT forever, signup never required, account is only an optional backup toggle, managed auth like Firebase/Supabase, core flow never waits on the network), iOS (no Mac needed: cloud CI via Codemagic or GitHub Actions to TestFlight, tested on my iPhone 15 Pro Max, 99 dollar account at publish time; a PWA of the web build covers iPhone users at launch; optional timeboxed TestFlight experiment allowed after Phase 3), monetization (free forever core; one time premium unlock via code redemption sold through the gift card channels Libyans already use for online payment; sponsorship and clinic licensing as larger lines; NO ADS EVER as a stated principle). Standing principles: no AI inside the app, no routine/habit system beyond food adjacent one tap features, no copying competitor shapes without their reasons.

# DATA PIPELINE (Phase 2, ongoing; this governs all food_db.dart changes)

1. Add to FoodItem NOW (early Phase 1, so all new data lands in final shape): a verified bool and a sourceNote String. Unverified foods may show a subtle marker in the UI (exact treatment decided in the polish pass). Computed home dishes always display as approximate; verified packaged foods may display exact.
2. Master data source is a spreadsheet I maintain (including a barcode column for every packaged product, filled from the first label onward), plus a folder of label photos named to match food IDs. food_db.dart is synced FROM it, never the other way.
3. Collection is category by category, whole category at a time: tuna/canned fish first, then dairy, snacks/biscuits, packaged bread/bakery, drinks, canned/jarred, oils/spreads/condiments, grains/pasta. Grains later upgrade the computed dish math (bazin, mbakbka recipes stand on verified ingredients).
4. Workflow: I photograph labels (nutrition panel + front of pack) and extract values with Claude in my web chat Project; I verify the extraction against the photo myself; then entries get pasted/synced into food_db.dart here, tests run, commit message format "data: verified <category>, N brands".
5. Category conventions learned so far (tuna): log the label's stated basis (drained weight vs net with oil/brine) in sourceNote; oil packed and water packed are SEPARATE entries (fat differs ~3x); the natural portion preset is one whole small can with its actual drained grams.
6. Home dishes (bazin, mbakbka, couscous, usban, sfinz, maqrud, khubz): no labels, so one documented reference recipe per dish, nutrition computed from ingredient weights (USDA FoodData Central for raw ingredients until Libyan verified ingredients exist), recipe documented in sourceNote. Account for cooking changes (rice/couscous absorb water, meat shrinks, frying absorbs oil, critical for sfinz). Some Libyan labels use kJ; always convert and store kcal.
7. Before launch: add a test/assertion that fails if any food lacks a sourceNote. Zero foods ship presented as accurate without a source.
8. YOU (Claude Code) never invent, edit, or "correct" nutrition numbers on your own. They change only through this pipeline.

# DESIGN DECISIONS ALREADY MADE (do not relitigate)

1. Precision lives in the data, simplicity in the UI: portion presets have exact gram definitions; users pick "ladle" or "small plate", the app knows the grams. Gram entry remains available for users who weigh.
2. Anti eating disorder guardrails: no punishing streaks, no alarm red styling for going over goal (neutral wording), no under eating encouragement, goals editor warns (gentle confirm, not a hard block) below floors of 1200 kcal, 30g protein, 50g carbs, 20g fat, and caps inputs at 5 digits.
3. Disclaimer (EN + AR) shown in onboarding and settings. Draft wording (I will refine the Arabic to my voice):
   EN: "Nutrition values in this app are approximate. Packaged food values come from product labels. Home dish values are estimates based on typical recipes. This app does not provide medical advice. If you manage a medical condition such as diabetes, consult your doctor or dietitian."
   AR: "القيم الغذائية في هذا التطبيق تقريبية. قيم المنتجات المعبأة مأخوذة من ملصقات المنتجات، وقيم الأطباق المنزلية تقديرية بناءً على وصفات شائعة. هذا التطبيق لا يقدم استشارة طبية. إذا كنت تعاني من حالة صحية مثل السكري، استشر طبيبك أو أخصائي التغذية."
   No medical claims anywhere in the app or store copy; avoid words like "diet plan" or "medical". The app records, it never prescribes.
4. Emoji meal icons get replaced with bundled assets in the Phase 1 polish pass for cross device consistency.
5. Commit goldens PNGs to git; they are the visual baseline.
6. Pre approved packages (ask before ANY others; tiny dependency footprint is deliberate for small APKs on old phones): a maintained Hijri/Umm al Qura conversion package (Phase 7), flutter_launcher_icons and flutter_native_splash (dev time, Phase 1 polish). Everything else needs my explicit yes.
7. Success bars (judge honestly, details in PLAN.md): beta gate is 5 of 15 testers still logging in week 3; launch +60 days is ~300 installs and 10 unsolicited feedbacks; the Ramadan install spike in Feb 2027 validates the whole cultural strategy.
8. Profile onboarding with maintenance calculation (Phase 5, beta2 feature). NEVER called "login" or "sign up" anywhere, it is a local profile step, all answers in shared_preferences. Flow: name, sex, age, weight kg, height cm, training intensity, weight goal, metric only, chips not sliders, fully skippable (skip = defaults), recalculate entry in settings. Math: Mifflin St Jeor BMR (male: 10×kg + 6.25×cm − 5×age + 5; female: −161 instead of +5), activity multipliers sedentary 1.2, light 1.375, moderate 1.55, high 1.725, athlete 1.9, goal adjustment lose −500 (gentle option −250), maintain 0, gain +300, round final kcal to nearest 50. Macros from final kcal: protein 25%, fat 30%, carbs 45%, at 4/9/4 kcal per gram, whole grams. Guardrails (non negotiable): result appears on an editable summary screen and saves through the existing Goals object so all floors and warnings apply; clamp the deficit so the result never lands below the floors; age under 18 gets maintenance only, no deficit, with a gentle note; validate age 13 to 100, weight 30 to 250, height 120 to 230 via WesternDigitsFormatter; show "estimate, real needs vary ~10%" under the result. Name is used for the home greeting only, stored locally, never transmitted.

# YOUR FIRST WORK SESSION, IN ORDER

## Task 1: Phase 0 — DONE (18 July 2026)
1. git init in the project root. Verify .gitignore covers /build/, .dart_tool/, *.iml (goldens PNGs stay IN).
2. Commit everything: "MVP skeleton: home, search, meal detail, 12 tests passing". Tag mvp-skeleton.
3. I will create the private GitHub repo and authenticate (gh auth login if needed); help me wire the remote and push with tags.
4. Create DEV_NOTES.md capturing the MACHINE AND ENVIRONMENT section, the hard requirements summary, the data pipeline pointers (spreadsheet location, photo folder, category order), and the Android/JDK plan.
5. Add PLAN.md (I will provide the file) and this brief as CLAUDE.md. Commit.
6. Create the Phase 1 backlog as GitHub issues: (1) goals persistence, (2) settings screen + goals editor, (3) disclaimer EN/AR in l10n + settings, (4) history screen list + read only day view, (5) 7 day bar chart, (6) onboarding, (7) empty states x4, (8) custom meal icons, (9) app icon + splash, (10) haptics, (11) QA checklist doc, (12) FoodItem verified flag + sourceNote. Add a "later" label (meaning: scheduled for a later phase, not Phase 1) and park Ramadan mode, portions, export/import, tea quick log, feedback email there.

## Task 2: Goals persistence (no UI yet) — DONE (18 July 2026, issue #1 closed)
1. In models.dart add an immutable Goals class: int kcal, carbs, fat, protein; static const defaults (2000/220/65/110); toJson; null tolerant fromJson falling back to defaults per field (future proof against added fields).
2. In app_state.dart: replace goal constants with a Goals field + getter, setGoals() that notifies then persists to shared_preferences under key 'goals' as JSON, and loading in the existing init path. Search the whole project for the literal numbers 2000/220/65/110 to catch every consumer; update home_screen.dart calorie card and macro card to read AppState goals.
3. Trap to verify: after goals stop being constants, the calorie bar and macros must repaint on a goal change WITHOUT an app restart. AppScope (InheritedNotifier) handles this only if those widgets actually depend on it; check the dependency, do not assume.
4. Add a test: goals persist across AppState reload (mock shared_preferences, set custom goals, new AppState instance, expect custom values). Match the style of the existing persistence round trip test.
5. Analyze clean, all tests pass, commit.

## Task 3: Settings screen + goals editor — DONE (18 July 2026, issues #2-#3 closed)
1. l10n.dart keys: settings, dailyGoals, calories, carbs, fat, protein, save, cancel, language, about, version, disclaimerTitle, disclaimerBody, invalidNumber, valueTooLow, goalsSaved. Use the disclaimer draft above.
2. New lib/settings_screen.dart matching existing screen style: rounded cards for daily goals (opens editor as a bottom sheet, reuse the add sheet pattern from search_screen.dart), language toggle (reuse the top bar widget), about card with app version + disclaimer. Leave room for later items (replay onboarding, feedback email, export) without building them now.
3. Gear icon in home top bar pushes the settings route.
4. Goals editor: four numeric fields, keyboardType number; a WesternDigitsFormatter TextInputFormatter that converts ٠١٢٣٤٥٦٧٨٩ to Western and strips non digits; validation per the guardrails in DESIGN DECISIONS (reject empty/zero, gentle confirm below floors, 5 digit cap); save via AppState.setGoals + snackbar (goalsSaved), pop the sheet.
5. Tests: settings renders RTL at 375x812 without overflow (copy the existing overflow test pattern); editor rejects zero and a valid edit updates the home calorie bar; input of ٢٠٠٠ stores 2000 (this test protects hard requirement 1 forever).
6. Analyze, test, update goldens, review them visually, commit, tag v0.2-goals, close issues 1 to 3.

## Working rules for you (Claude Code)
1. Read the actual files before editing; this brief describes the architecture but the code is the truth.
2. Small commits with clear messages. Never force push.
3. After each change set: analyze, then full test suite. Fix warnings you introduce; do not mass fix pre existing unrelated warnings without asking.
4. When my description here conflicts with the real code, tell me instead of silently picking one.
5. Do not add packages beyond the pre approved list without asking.
6. Never edit nutrition numbers in food_db.dart on your own; those change only through my label verification pipeline.
7. While working on one issue, do not fix unrelated things you notice; they have issue numbers, leave them.
8. New feature ideas go to a GitHub issue labeled "later", never into the current phase (scope discipline is a named project risk).
9. If my live instructions in a session conflict with this file, my live instructions win; but if I ask for something that violates a HARD REQUIREMENT, point it out before doing it.

## Every future session (after the first tasks are done)
1. Start: run git status and git log --oneline -5 to orient, check open issues, work ONLY on issues from the current phase (3 to 5 items per week maximum).
2. End: analyze clean, full tests pass, commit, push. Even half finished work gets committed on a branch rather than left uncommitted.
3. End of phase: definition of done review against PLAN.md, tag the release, then I take a day off before the next phase.

Start with Task 1. Show me the git status before committing anything.

# Libyan Calorie Tracker (متتبع السعرات)
## Complete Work Plan, Roadmap, and Risk Register
Prepared 16 July 2026. Solo developer. Flutter app, local only storage, Libyan market.

---

# PART 1. GUIDING PRINCIPLES

1. Ship beats perfect. A working app on a real phone in Tripoli beats a polished mockup on a web renderer.
2. One phase at a time. Each phase has a definition of done. Do not start the next phase until the current one passes its gate.
3. The Ramadan deadline is real. Ramadan 1448 begins around 8 February 2027 (confirm against moon sighting closer to the date). Everything in this plan works backward from having Ramadan mode live in users' hands by late January 2027.
4. Data accuracy is the moat. Never ship placeholder nutrition numbers as real. Every food entry carries a verified or estimated flag until proven.
5. Protect the solo developer. You are the single point of failure. The plan includes explicit safeguards for your time, code, and motivation.

---

# PART 2. THE ROADMAP AT A GLANCE

Timeline assumes roughly 10 to 15 productive hours per week. Adjust dates proportionally if your availability differs.

1. **Phase 0. Safety and foundations** (Week of 20 July, 3 to 5 days)
2. **Phase 1. Finish the MVP front end** (late July to early September, 5 to 6 weeks)
3. **Phase 2. Real nutrition data, batch one** (runs in parallel with Phase 1, ends mid September)
4. **Phase 3. Android build and on device testing** (mid to late September, 1 to 2 weeks)
5. **Phase 4. Household portions data model** (October, 2 to 3 weeks)
6. **Phase 5. Private beta with real users** (late October to November, 4 weeks)
7. **Phase 6. Public launch** (early December 2026)
8. **Phase 7. Ramadan mode** (December to late January 2027, hard deadline 25 January 2027)
9. **Phase 8. Post Ramadan roadmap** (March 2027 onward. Sunnah fasting, Friday meal, tea quick log, seasonal rotation)
10. **Phase 9. Long horizon** (H2 2027. Barcode scanner, expanded database, evaluate backend and iOS)

Built in buffer. The plan targets launch in early December but the true deadline is Ramadan mode by late January. That gives you roughly six weeks of slack. Expect to spend it.

---

# PART 3. PHASE BY PHASE WORK PLAN

## PHASE 0. Safety and foundations (3 to 5 days)

You listed git as roadmap step 4. Move it to step 1. Right now a single disk failure erases the entire project. This phase costs a few hours and removes your largest single risk.

Tasks.
1. `git init` in `C:\Users\abdul\dev\calorie_tracker`. Add a Flutter `.gitignore` (build\, .dart_tool\, etc.).
2. First commit of the current working state. Tag it `mvp-skeleton`.
3. Create a private GitHub repository and push. GitHub is free and gives you offsite backup plus issue tracking.
4. Adopt a tiny commit habit. Commit at the end of every work session, no exceptions. One line messages are fine.
5. Record your environment in a `DEV_NOTES.md` in the repo. Flutter version 3.44.6, SDK path, the JDK caveat, the goldens command, how to serve the web build. Six months from now you will thank yourself.
6. Set up GitHub Issues as your task tracker. Create one issue per gap listed in this plan. Close them as you go. This replaces memory with a system.

Definition of done. Repo pushed to GitHub, all current tests pass from a fresh clone on your machine, DEV_NOTES.md exists.

## PHASE 1. Finish the MVP front end (5 to 6 weeks)

Order matters. Build in the sequence below because each item unblocks or simplifies the next.

**Week 1 to 2. Goals editing and settings screen.**
1. New `settings_screen.dart`. Entry point via gear icon in the home top bar.
2. Move goals from constants in `app_state.dart` to persisted values in shared_preferences with the current constants as defaults. Add `setGoals()` to AppState, notify listeners, persist immediately.
3. Goals editor UI. Four fields (kcal, carbs, fat, protein) with sensible input validation, Western digits enforced through your existing formatters, save and cancel.
4. Settings screen also houses the language toggle (moved or mirrored from the top bar), an about section with the app version, and a visible disclaimer that nutrition values are approximate and the app is not medical advice. Write the disclaimer now, in both languages, in `l10n.dart`.
5. Tests. Persistence round trip for goals, RTL layout of the settings screen, validation edge cases (zero, empty, huge numbers).

**Week 2 to 3. Stats and history view.**
1. New `history_screen.dart`. Start simple. A scrollable list of past days showing date, total kcal, and a small over or under goal indicator. Tap a day to see its log read only.
2. A basic 7 day bar chart of calories using a CustomPainter, matching the visual identity (green accent, macro colors). No charting package needed for one bar chart, and skipping the dependency keeps the app small.
3. Tests. Rendering with empty history, one day, and 30 days of data.

**Week 3 to 4. Onboarding.**
1. Three screens maximum. Language choice first (this decision gates everything else), then a one screen explanation of logging, then goal setup reusing the goals editor widgets from week 1.
2. Onboarding shows once, tracked by a shared_preferences flag. Settings gets a way to replay it.
3. Keep it skippable. Defaults must be good enough that skipping everything still gives a working app.

**Week 4 to 5. Empty states and polish pass.**
1. Empty states for. No foods logged today, empty search results, empty history, empty meal detail. Each with a short friendly line in both languages and a clear action.
2. Loading is nearly instant with local storage, so skip elaborate loading states. Add them only where the frame actually janks.
3. App icon and splash screen. Design one icon (the calorie ring motif in your green works well), generate all sizes with the `flutter_launcher_icons` package, splash with `flutter_native_splash`.
4. Replace or standardize emoji meal icons now rather than later. Simplest robust option is bundling four small SVG or PNG assets so meals render identically on every Android skin. This closes a known gap cheaply.
5. Haptics on log and delete actions via `HapticFeedback.lightImpact()`. One line each, do not overthink.

**Week 5 to 6. Hardening.**
1. Run the full test suite, update goldens, fix every analyzer warning. Target zero output from `C:\dev\flutter\bin\flutter.bat analyze`.
2. Test the web build in both languages at several widths.
3. Manual QA script. Write a 20 step checklist (change language, log food, edit goals, restart app, check persistence, delete entry, and so on). You will reuse this checklist before every release forever.

Definition of done. All screens exist, no hardcoded goals, analyzer clean, all tests pass, QA checklist passes on web.

## PHASE 2. Real nutrition data, batch one (parallel with Phase 1)

This is fieldwork, not coding, so it runs alongside Phase 1 during evenings and shopping trips.

1. Add a `verified` boolean and a `sourceNote` string to FoodItem in `models.dart` now, so the data model is ready. Unverified foods can show a subtle marker in the UI, decide the exact treatment during the polish pass.
2. Priority order for verification. Packaged goods first (Kalee variants, Bifa, Al Naseem) because labels give exact numbers. Photograph every label, store photos in a folder inside the repo or a cloud drive, named to match food IDs.
3. Home dishes second (bazin, mbakbka, couscous, usban, sfinz, maqrud). These have no labels. Method. Pick one standard recipe per dish, compute nutrition from ingredient weights using a reputable database (USDA FoodData Central works for raw ingredients), document the recipe in the source note. Present these as approximate in the UI, and that honesty becomes a trust feature.
4. Target for launch. All packaged foods verified, all dishes computed and documented. 44 foods is enough for launch. Depth of trust beats breadth of catalog.
5. Keep a simple spreadsheet as the master data source and a small script or manual process to sync it into `food_db.dart`. The spreadsheet becomes valuable later if you ever ship database updates separately from app updates.

Definition of done. Zero foods presented as accurate without a source. Every entry has a sourceNote.

## PHASE 3. Android build and on device testing (1 to 2 weeks)

1. Install JDK 17 (Temurin builds are free and reliable). Run `C:\dev\flutter\bin\flutter.bat config --jdk-dir=<path to JDK 17>` then `flutter.bat build apk --release`.
2. Set `minSdkVersion` deliberately. Android phones in Libya skew older and cheaper. Support API 24 (Android 7) or lower if Flutter allows. Check that your dependencies agree.
3. Test on at least two physical devices. Your own phone plus the oldest, cheapest Android you can borrow. Watch for. Arabic text rendering, RTL mirroring of the week strip and calorie ring, font fallbacks (device fonts differ from your Windows test fonts), performance of the CustomPainter on weak GPUs, and how the app behaves when the system font size is set to large.
4. Verify the Segoe UI fontFamilyFallback is truly harmless on device as expected. If Arabic rendering looks poor on cheap devices, consider bundling a Noto font.
5. Fix what you find. Budget the second week entirely for this. Web tested apps always surprise you on device.

Definition of done. Release APK installs and passes the full QA checklist on two physical devices, one of them low end.

## PHASE 4. Household portions data model (2 to 3 weeks)

The strategic feature that feeds Ramadan mode, Friday meals, and everything after.

1. Extend FoodItem with a list of portion presets. Each preset has an EN name, AR name, and gram weight (for example, ladle ملعقة كبيرة 250g, small plate صحن صغير 180g). Nutrition stays defined per 100g or per base serving, presets are multipliers.
2. Update the add sheet in `search_screen.dart`. Preset chips appear above the existing 0.5 step servings stepper. Tapping a chip sets the quantity. The stepper remains for fine adjustment, so gram precision users lose nothing.
3. Populate presets for the top 15 to 20 foods first, prioritized by what beta users actually log (you will know after Phase 5, so ship the model now, refine the data later).
4. Tests. Preset selection produces correct kcal math, RTL chip layout, persistence of preset based entries.

Definition of done. Presets work end to end for at least 15 foods, all tests pass, on device QA repeated.

## PHASE 5. Private beta (4 weeks)

1. Recruit 10 to 20 testers. Family, friends, and one or two strangers if possible (strangers give honest feedback, family gives polite feedback). Aim for a mix of ages and phone quality.
2. Distribution. Share the APK directly via Telegram or WhatsApp, which is normal and trusted distribution in Libya, plus the web demo link for anyone hesitant to install.
3. Feedback channel. One Telegram or WhatsApp group. Low friction beats formal surveys.
4. Add a lightweight in app feedback path. A settings item that opens a prefilled email to abdulmoezshadi.90@gmail.com with app version and locale included. No backend needed.
5. What to measure manually. Do testers still log after 7 days. Which foods do they search for and not find (this drives database growth better than any guess). Do they understand portions. Does anyone get confused by the language toggle.
6. Weekly beta build releases. Fix top issues, ship, repeat. Use git tags per build.

Definition of done. At least 5 testers logging in week 3 or later, top 10 reported issues fixed, missing foods list captured for Phase 8.

## PHASE 6. Public launch (early December 2026)

1. Google Play developer account. Register early in the beta phase, not at launch, because registration from Libya can hit payment friction (the 25 dollar fee needs a card that Google accepts, and verification can take time). If direct registration proves impossible, fallbacks in order. A relative abroad registers the account, or launch via direct APK distribution plus a simple landing page while you resolve it. Direct APK distribution is culturally normal in Libya and is a legitimate primary channel, not just a fallback.
2. Store listing. Screenshots in Arabic first (your golden generator already produces rendered PNGs, extend it for store sizes). Description leads with the differentiators. Libyan foods, works offline, no signup, your data stays on your phone.
3. Versioning discipline. Semantic versions, git tag per release, a CHANGELOG.md.
4. Launch marketing, zero budget version. Post in Libyan Facebook groups (Facebook dominates in Libya), food and health focused groups first. Ask beta testers to share. Prepare a short demo video captured from a real phone.
5. Crash visibility. Since there is no backend by design, integrate nothing at first, but reconsider after launch. A privacy respecting crash reporter (Sentry has a free tier) only fires when the device is online and sends no personal data. Decide consciously, and if you skip it, the in app email feedback is your only eyes. Document the decision.

Definition of done. App installable by a stranger in Libya through at least one channel, listing live or landing page live, version 1.0 tagged.

## PHASE 7. Ramadan mode (hard deadline 25 January 2027)

Ramadan 1448 begins around 8 February 2027. Ship by 25 January so early adopters have it before the first suhoor, and so a Play Store review delay cannot sink the deadline.

1. Hijri calendar integration. Add a maintained Umm al Qura conversion package. Show Hijri date in the week strip and settings.
2. Meal structure switch. When Ramadan mode is active, MealType presentation becomes suhoor, iftar, and evening snack. Keep the underlying data model unchanged (map suhoor to breakfast internally, and so on) so history, tests, and persistence stay stable. Presentation changes, storage does not.
3. Day boundary handling. A suhoor eaten at 2 or 3 am belongs to the fasting day that is starting. Implement a configurable day cutoff (default around 4 am during Ramadan) so post midnight logging lands on the correct date key.
4. Activation. Automatic suggestion when the Hijri calendar hits Shaaban's final days, with a manual toggle in settings. Never force it, moon sighting means the exact start varies, and the user is the authority.
5. Ramadan aware visuals. The calorie ring and goals stay the same numbers by default (energy needs do not drop just because timing changed), but the home layout reflects two main meals. Optional stretch, a gentle suhoor reminder notification, only if time allows, notifications add permission complexity.
6. Test heavily around date math. Timezone Libya is UTC+2 with no DST, which simplifies things, but test the 4 am boundary, month transitions, and Hijri Gregorian display in both languages.
7. Marketing beat. This is your loudest moment of the year. Prepare posts for mid January. The first calorie tracker built for Ramadan.

Definition of done. Ramadan mode passes QA on device by 20 January, released by 25 January, announcement ready.

## PHASE 8. Post Ramadan roadmap (March 2027 onward)

Sequence by what Ramadan usage data tells you, but the default order.

1. **Missing foods batch two.** Add the foods beta and Ramadan users searched for and did not find. This list is gold, treat it as the top of the backlog.
2. **Tea and coffee quick log.** One tap logging for the daily tea habit. Small build, daily retention driver.
3. **Sunnah fasting tracker.** Reuses Ramadan mode layout plus the Hijri calendar you already integrated. Marks Mondays, Thursdays, White Days, Shawwal six, Ashura, Arafah. Year round retention.
4. **Friday family meal flow.** Builds on portion presets. Dish selection plus share size plus extras, one guided flow.
5. **Seasonal rotation.** Static in code calendar surfacing seasonal foods and Eid presets.

## PHASE 9. Long horizon (H2 2027, decide then, not now)

1. Barcode scanner, only once the verified packaged database is large enough that scans usually hit.
2. Backend and accounts, only if users demand sync across devices. Your AppState isolation makes this swappable, which was the right call.
3. iOS, only with access to a Mac and evidence of demand. Libyan market is overwhelmingly Android, so this stays low priority.
4. Monetization, see the risk register. Default plan is free while building trust and data, then evaluate.

---

# PART 4. RISK REGISTER AND ENDURANCE PLAN

Each risk lists likelihood, impact, and how to endure it. Endure means prevent where possible, absorb where not.

## A. Technical risks

**A1. Total code loss (disk failure, laptop theft).**
Likelihood medium, impact fatal. Endure. Phase 0 fixes this. Git plus GitHub push every session. After Phase 0 this risk drops to near zero. Do not write another feature before this is done.

**A2. On device reality differs from web renderer.**
Likelihood high, impact medium. Fonts, RTL quirks, performance, and text scaling will all surprise you. Endure. Phase 3 exists for exactly this, with a full week budgeted for fixes. Test on a cheap old device, not just a good one. Keep the QA checklist and run it per release.

**A3. JDK and Gradle toolchain fights.**
Likelihood medium, impact low but time consuming. Endure. Install JDK 17 specifically (known good for Gradle 9.1), pin it via flutter config, write the exact working steps into DEV_NOTES.md so you never re debug it. Do not upgrade Flutter, Gradle, or the JDK mid phase, upgrade only between phases with a clean commit before and after.

**A4. shared_preferences data loss or bloat.**
Likelihood low to medium, impact high for the affected user. Years of day logs as JSON strings can grow large, and users lose everything on uninstall or device change. Endure. Add an export and import feature (a single JSON file the user can save or send to themselves) in Phase 8 at the latest. It doubles as your backup story without any backend and costs about a day. Also test app behavior with a year of synthetic data for size and load time.

**A5. A Flutter upgrade breaks the app.**
Likelihood medium over a year, impact medium. Endure. Pin the Flutter version in DEV_NOTES.md, upgrade deliberately between phases only, run full tests plus goldens after any upgrade, and commit before upgrading so rollback is one command.

**A6. Emoji and font inconsistency across Android skins.**
Likelihood high, impact low. Endure. Already planned, bundle custom meal icons in the Phase 1 polish pass and consider bundling a Noto Arabic font if device testing shows poor rendering.

**A7. Date and calendar bugs (Ramadan boundary, Hijri drift).**
Likelihood medium, impact high in exactly the highest visibility month. Endure. The day cutoff logic gets its own test file. Manual toggle keeps the user in control when moon sighting differs from the calculated calendar. Ship two weeks before Ramadan so early users catch issues while stakes are low.

## B. Data and trust risks

**B1. Placeholder numbers ship as real.**
Likelihood medium, impact severe (trust is the entire moat). Endure. The verified flag from Phase 2 makes placeholder status visible in the data itself, not just in your memory. Add a debug assertion or test that fails the build if any food lacks a sourceNote by launch. UI shows approximate wording for computed dishes.

**B2. A user with a medical condition relies on wrong numbers.**
Likelihood low, impact severe (health and reputation). Diabetics counting carbs is the sharpest case. Endure. The disclaimer written in Phase 1, both languages, shown in onboarding and settings. Approximate labeling on computed dishes. Prioritize verifying carb values on packaged goods. This is why data honesty is a hard requirement, not polish.

**B3. Home dishes vary wildly between households.**
Likelihood certain, impact medium. One family's bazin is not another's. Endure. This is what portion presets and approximate framing exist for. Document the reference recipe per dish so the number means something concrete. Later, the Friday meal flow's share size question absorbs most of this variance.

**B4. The app is used to fuel disordered eating.**
Likelihood low but nonzero, impact serious. Calorie trackers can harm vulnerable users. Endure. Design choices, not features. No streaks that punish missed days, no red alarm styling for going over goal (use neutral wording), no under eating encouragement, validation floors on the goals editor so absurdly low targets get a gentle warning. These cost almost nothing at design time and are hard to retrofit.

## C. Market and distribution risks

**C1. Google Play registration or payments fail from Libya.**
Likelihood medium, impact medium. Endure. Attempt registration early (during beta). Fallback chain. Relative abroad, direct APK plus landing page, regional stores. Direct APK via Telegram and Facebook is a first class channel in Libya regardless, so Play Store trouble delays discovery, not launch.

**C2. Nobody downloads it.**
Likelihood medium, impact high. Endure. Beta testers become your first advocates. Facebook groups are the channel that matters in Libya. The Ramadan release is a built in annual marketing moment. Set a modest success bar (see Part 5) so you judge progress honestly instead of against MyFitnessPal numbers.

**C3. Users install but stop logging within a week.**
Likelihood high (true of every tracker ever), impact high. Endure. This is what the whole differentiation strategy attacks. Portions reduce logging friction, tea quick log creates a daily touchpoint, Ramadan and Sunnah fasting create calendar driven reasons to return, and Friday meal flow rescues the highest abandonment moment. Measure it in beta by asking testers directly.

**C4. A competitor adds Libyan foods.**
Likelihood low near term, impact medium. Endure. Your moat is verified label data plus cultural features (Ramadan, Hijri, Friday) that require rebuilding their product assumptions, not just translating strings. Speed matters, ship the cultural features before anyone notices the niche.

**C5. Old and low storage devices.**
Likelihood high, impact medium. Endure. Low minSdkVersion, keep the APK small (no heavy packages, you have almost no dependencies, keep it that way), test on a weak device in Phase 3.

## D. Solo developer risks

**D1. Burnout or a long motivation dip.**
Likelihood high over a 9 month plan, impact high. Endure. The phase structure is the defense, every phase ends with something visibly done, which is what sustains solo motivation. Keep a strict definition of done and stop there. Schedule real weeks off after Phase 3 and after launch. If a dip hits, do data collection work (Phase 2 style fieldwork) instead of stopping entirely, it advances the project at low mental cost.

**D2. Scope creep.**
Likelihood very high (you generate good ideas quickly), impact high. Endure. The parking lot rule. New ideas go into a GitHub issue labeled later, never into the current phase. The MVP hard requirements already ban barcode, accounts, and social, extend that discipline to every phase. Re read Part 2 when tempted.

**D3. Life interrupts (work, family, Libya's realities like power and internet outages).**
Likelihood high, impact variable. Endure. Everything about this project is offline friendly by design, including your dev setup. Local Flutter SDK, local tests, git commits work offline and push later. The six week buffer before Ramadan exists precisely for this. If the buffer burns, cut Phase 8 items, never the Ramadan deadline, and if even that slips, Ramadan mode ships mid Ramadan rather than not at all.

**D4. Time estimates are wrong.**
Likelihood certain, impact medium. Endure. Estimates above are ranges, and the plan front loads must haves (goals, settings) over nice to haves (animations). The cut order when behind schedule. First animations and haptics, then the history chart (list stays), then onboarding (defaults carry it), never goals editing, never data verification, never the Ramadan deadline.

**D5. Bus factor of one.**
Likelihood low, impact fatal to the project. Endure. Cannot be fully fixed solo, but reduce it. Public enough documentation (DEV_NOTES.md, the data spreadsheet, this plan in the repo) that another developer could pick the project up. That same documentation is what makes future collaboration or handoff possible if the app succeeds.

## E. Financial and legal risks

**E1. Costs with no revenue.**
Likelihood certain, impact low. Total cash cost through launch is roughly the 25 dollar Play fee plus optional small costs (a domain for the landing page). Endure. Keep it a passion project financially. Do not spend on ads, tools, or services before users prove demand.

**E2. Monetization is structurally hard from Libya.**
Likelihood high, impact medium but only later. Google Play merchant support and card payments in Libya are limited, so in app purchases may not be available to you. Endure. Do not build the plan around app revenue. Realistic future paths. Keep it free and treat the verified database as the asset (potential licensing to clinics, dietitians, or food producers), donations via channels that work locally, or sponsorship by a Libyan food brand. Decide in 2027 with real usage numbers, not now.

**E3. Health app liability.**
Likelihood low, impact medium. Endure. The disclaimer (B2), approximate labeling, no medical claims anywhere in the listing or app, and the app never prescribes, it only records. Avoid words like diet plan or medical in store copy.

**E4. Privacy expectations.**
Likelihood low, impact low. Local only storage is your advantage here. Endure. Write a one page privacy statement for the store listing saying exactly that, no data leaves the device, no accounts, no tracking. If you later add crash reporting, update the statement first.

---

# PART 5. SUCCESS METRICS AND DECISION GATES

Without a backend you cannot measure remotely, so metrics come from beta conversations, store console numbers, and in app email feedback. Keep the bar modest and honest.

1. **Beta gate (end of Phase 5).** At least 5 of 15 testers still logging in week 3. If not, diagnose before launching, the problem is friction or relevance, and launching louder does not fix either.
2. **Launch plus 60 days.** 300 installs through all channels combined and at least 10 unsolicited pieces of feedback. Modest, achievable, meaningful for a solo niche app.
3. **Ramadan gate (March 2027).** Did installs spike in the two weeks before Ramadan. Did anyone mention Ramadan mode unprompted. This validates the entire cultural differentiation thesis and decides how hard to push Phase 8.
4. **One year decision (July 2027).** If retention signals are real, invest in Phase 9 items and consider the database as a business asset. If not, the app still serves its users at near zero running cost, which is a perfectly good steady state for a local only app. That is the quiet superpower of the no backend design, failure is cheap and survival is free.

---

# PART 6. WEEKLY OPERATING RHYTHM

1. Start of week. Pick issues from the current phase only. Three to five items maximum.
2. Every session. Commit and push at the end, even for half finished work on a branch.
3. End of week. Run `flutter.bat analyze` and `flutter.bat test`, both clean before the weekend.
4. End of phase. Definition of done review, tag the release, take one day off, read the next phase.
5. Monthly. Re read the risk register. Ten minutes. Risks change status as phases complete.

---

# PART 7. IMMEDIATE NEXT ACTIONS (this week)

1. Phase 0 in full. git init, GitHub push, DEV_NOTES.md, issues created. One evening.
2. Write the disclaimer text, EN and AR, into l10n.dart. One hour.
3. Start the goals persistence change in app_state.dart, it is the first domino of Phase 1.
4. On your next shopping trip, photograph three Kalee labels. Phase 2 starts with your phone camera, not your editor.

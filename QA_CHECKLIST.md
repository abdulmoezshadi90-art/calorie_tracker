# Manual QA Checklist

Run before **every** release, including weekly beta builds. Takes ~15 minutes on a real device
(web preview is acceptable only when no device build exists yet).

Record the run at the bottom: date, build/tag, device, result per step (✅/❌ + note).

> Automated coverage note: the widget/golden suite already guards layout, RTL, digits, and
> persistence logic. This checklist is for what tests can't see: real-device rendering, feel,
> and end-to-end flows on actual hardware.

## Fresh install & onboarding

1. **Fresh install, first launch** — onboarding appears, language page first. No home flash before it.
2. **Pick العربية** — entire onboarding flips RTL immediately; all digits stay Western (0-9).
3. **Intro page** — disclaimer text present and readable in the chosen language.
4. **Goals page → open editor → set kcal 1900 → save → Get started** — home opens showing "of 1,900 kcal".
5. **Kill the app and relaunch** — no onboarding; language and the 1,900 goal survived.

## Logging

6. **Log a food to each of the 4 meals** (search EN once, AR once) — each row updates with name + kcal; calorie bar and macros move.
7. **Servings stepper** — 0.5 steps work, add button total updates live, logged amount matches servings × per-serving kcal.
8. **Light haptic** felt on log and on delete (device only).
9. **Delete an entry in meal detail** — totals drop everywhere; empty meal shows its empty state with "Add a food".
10. **Search gibberish ("zzz")** — friendly empty state; "Clear search" restores the list.

## Goals editor

11. **Enter ٢٥٠٠ (Eastern digits)** — field shows 2500; after save the home bar reads "of 2,500 kcal".
12. **Enter 0 or empty** — inline "Enter a valid number", nothing saved.
13. **Enter 1000 kcal** — gentle "lower than typical" confirm appears; Cancel keeps old value, Save applies it. No red/alarm styling anywhere.
14. **Goal change repaints home instantly** — no restart needed.

## History

15. **With several logged days** — history lists days newest-first, over-goal days show the neutral gold chip, 7-day chart bars match the day totals, dashed goal line visible.
16. **Tap a past day** — read-only view (no delete buttons), per-meal sections and correct total.
17. **Fresh-ish install with no history** — friendly empty state; "Back to today" returns home.

## Language & display

18. **Toggle language from home and from settings** — instant full-app flip both directions; restart keeps the choice; week strip mirrors correctly in Arabic.
19. **Sweep all screens in Arabic** — no Eastern Arabic numerals anywhere (٠١٢٣٤٥٦٧٨٩ must never render).
20. **System font size at maximum** (device accessibility settings) — home, settings, onboarding remain readable, nothing overflows or clips.
21. **Dark mode** (system toggle) — all screens use the dark palette; splash and app icon look right; no unreadable text.
22. **Replay intro from settings** — onboarding plays again; Skip returns to settings, nothing reset.

## Release-only extras (Phase 3+, on device)

23. App icon renders on the launcher (and adaptive icon masks correctly); splash shows in light and dark.
24. Restart persistence on the *device* (not just tests): log → force-stop app → relaunch → data intact.

---

## Runs

| Date | Build/tag | Device | Result | Notes |
|---|---|---|---|---|
| 2026-07-18 | v0.3-phase1 | Web release (Chrome pane) | Partial ✅ | Release build boots EN + AR (`?lang=` override): correct titles, RTL strings, no console errors. Interactive steps blocked by a local browser-pane/Flutter-web input quirk — flows covered by the 38-test widget suite instead. Full device run due in Phase 3. |
| 2026-07-20 | ui-restructure branch (4 commits) | Emulator `libya_test_phone` (x86_64 release), adb-driven, Arabic | ✅ Manual RTL check | Striped overflow: 2,160/2,000 kcal shows solid fill + same-color hatch at the correct RTL end, neutral زيادة pill; carbs 300/220 shows +80 marker and striped mini bar; within-goal bars unchanged. Sticky header: greeting scrolls away, date pill + week strip pinned, content tucks under. Streak chip appears (🔥1) beside اليوم pill. Bottom nav mirrors (اليوم right → الإعدادات left), center Add opens meal chooser, gear/toggle relocated to Settings tab (language first card). 68/68 tests, analyzer clean, goldens reviewed. |
| 2026-07-19 | beta2 wizard rework (v0.5.0) | Emulator `libya_test_phone` (x86_64 release APK), adb-driven | ✅ Feature QA | Profile UX rebuilt as one-question-per-step wizard (8 steps incl. result). Verified in Arabic: mirrored back arrow, تخطي placement, x/7 progress in Western digits, activity cards with all 5 descriptions + exercise helper line (no overflow at 375-width), goal cards with plain-language descriptions, auto-advance on choice taps, continue on numeric steps. Same test profile produced identical math (2,250 / ~2,750 / 141-75-253) — presentation only. 57/57 tests, analyzer clean, goldens unchanged. |
| 2026-07-19 | beta2 (v0.5.0, branch beta2-profile-onboarding) | Emulator `libya_test_phone` (x86_64 release APK), driven via adb | ✅ Feature QA | Profile onboarding (decision 8): fresh install shows 4-page onboarding, profile step opens the RTL form (name, sex/activity/goal chips, range-hinted numeric fields). Male/30/80kg/180cm/moderate/lose calculates 2,250 kcal + 141p/75f/253c — exact spec math; maintenance ~2,750 and ~10% estimate note shown. اعتماد الهدف saves through Goals: goals page and home read 2,250, survives force-stop restart. Unit tests cover both sexes, floor clamping, under-18 maintenance-only, gentle −250/+300; widget tests cover RTL overflow + Eastern-digit input. Full 24-step regression not re-run (unchanged screens covered by 56-test suite). |
| 2026-07-19 | beta-2026-07-19 | Emulator `libya_test_phone` (Pixel 4a, API 36, x86_64 release APK), driven via adb | ✅ 21/24, 1 note | Steps 1–7, 9–10, 12–18, 20–22, 24 pass with screenshots. Step 8 (haptics) N/A on emulator. Step 11 partially: adb can't type Eastern Arabic digits — ٢٠٠٠→2000 conversion covered by the settings widget test; Western 2500 edit verified live incl. instant home repaint. Step 19 pass on all screens visited (no Eastern numerals anywhere). Step 23 not verified (launcher icon/splash render — check on first real phone). **Note (LOW):** greeting wraps mid-word in EN ("mornin g") and at max font scale; week-strip day names also wrap at max font. No overflow errors, purely cosmetic. Real-phone run still owed by a wave-1 beta tester. |

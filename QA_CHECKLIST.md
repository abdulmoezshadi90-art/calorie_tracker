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
| | | | | |

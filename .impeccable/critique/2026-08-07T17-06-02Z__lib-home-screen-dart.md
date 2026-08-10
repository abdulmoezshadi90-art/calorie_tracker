---
target: update the UI/UX (re-check after clarify/layout/distill/polish fixes)
total_score: 29
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 0
timestamp: 2026-08-07T17-06-02Z
slug: lib-home-screen-dart
---
Method: dual-agent (A: general-purpose design review · B: general-purpose live-device evidence sweep, both completed cleanly on first attempt this run)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Undo-snackbars and a save checkmark confirm every write; the search debounce has no loading affordance |
| 2 | Match System / Real World | 3 | Portion presets genuinely match Libyan home-cooking language; the fraction picker (¼ ⅓ ½ ⅔ ¾) is still an app convention layered on top |
| 3 | User Control and Freedom | 3 | Undo everywhere; the Add button locks for 350ms after tapping with no cancel |
| 4 | Consistency and Standards | 3 | Improved from the last run (Home's three add-affordances now share one shape) — but a second, separate "quick-add" icon style (`Icons.add_circle_outline`) is used consistently across Foods/History/Saved Meals/Search, unrelated to Home's system |
| 5 | Error Prevention | 3 | Quantity clamps, gentle floor confirmations on goals |
| 6 | Recognition Rather Than Recall | 4 | `FilterSortRow` always labels itself with the active selection; History/Saved Meals/copy-previous-day remove repeat recall work |
| 7 | Flexibility and Efficiency | 3 | Quick-add, saved meals, copy-previous-meal serve returning users; no bulk-delete in meal detail |
| 8 | Aesthetic and Minimalist Design | 3 | The add-food screen swung from too full to too empty — see priority issues |
| 9 | Error Recovery | 2 | One generic "Couldn't save — try again" string covers every failure path, no diagnosis |
| 10 | Help and Documentation | 2 | The "approx." marker now explains itself on tap, but nothing else (macro %, portion-preset logic) has in-context help |
| **Total** | | **29/40** | **Acceptable-to-Good** |

**Trend for `lib-home-screen-dart` (last 2 runs): 30 → 29 (out of 40)**

Read this as flat, not regressed. The four issues fixed since the last run (icon consistency, add-food decision overload, unexplained trust marker, `ListView.builder` perf) are gone — heuristic 4 (Consistency) moved 2→3, matching the layout fix directly. The 1-point net drop comes from a fresh, independent pass surfacing two things the first pass didn't dig into (the Add-button lock under heuristic 3, and a harsher read on the single generic error string under heuristic 9) plus a brand-new issue introduced by this session's own distill fix (see P2 below) — normal churn from re-running an LLM-scored heuristic pass, not a real step backward.

## Design Specificity Verdict

**Corrected assessment**: `food_db.dart` is healthier than either agent initially assumed — 108 of 164 entries are `verified: true`, with real label-sourced Libyan dairy brands (Hawaa, Almarai, Al-Naseem, Al-Jaied, Safi) entered through the documented pipeline. But the onboarding copy's own promise doesn't hold: it names "Kalee chips" and "bazin" by name, and a full-text search of `food_db.dart` finds zero entries for either — "bazin" appears only inside a `sourceNote` comment explaining why it's *not* covered yet. This is the same class of problem as the test-fixture-ordering issue from the last critique (already deferred to you as a data-pipeline decision), but sharper: it's not fixture cleanup, it's onboarding copy citing dishes that don't exist in the app yet.

Structurally, the interaction layer (portion presets, undo discipline, recall-reduction) is genuinely Libyan-aware; the visual layer remains generic-modern-wellness-app shaped, unchanged from the last assessment.

**Live-device evidence**: confirmed clean across Home, Foods, Food Detail, Progress, and Settings in both English/light and Arabic/light — RTL mirroring (including the appearance-toggle icon order reversing) and Western-digit discipline both hold under direct inspection, including after a live language switch mid-session.

**One correction to the live-evidence pass**: it flagged Foods-list bottom-row clipping again. I re-checked this myself — twice, at different scroll positions, plus the widget tree (`FoodsScreen`'s `ListView.builder` sits inside `Scaffold.body`, which the outer `AppShell` Scaffold already insets above `bottomNavigationBar`) — and it's the same false positive from the last audit: a partially-scrolled row peeking in at the viewport edge, which is what any scrollable list looks like mid-scroll. No pixel overlap with the nav bar exists in the render tree. Not a bug.

**A second correction**: the live-evidence pass read a number/unit spacing difference as Arabic-vs-English ("242جم" vs "242 g"). I checked the source — it's not a language issue, it's a **cross-file** one. `home_screen.dart`'s macro card uses a spaced template (`'${goal} ${l.grams}'`); every other screen showing grams (food detail, create-meal, profile summary, settings goals summary) concatenates with no space (`'${fmtGrams(x)}${l.grams}'`) — in *both* languages equally. Minor, but worth naming correctly since the fix is different (one inconsistent template, not a translation bug).

## Overall Impression

The fixes from the last pass held up under fresh, independent scrutiny — that's the real signal here, more than the raw score. What's new: the distill pass that decluttered the add-food screen worked almost too well on short-content foods (see P2), and a closer read of the onboarding→search path found the same "promise the data doesn't back up yet" pattern that showed up with the test fixtures, this time in the onboarding copy itself.

## What's Working

- Undo-snackbar discipline is applied everywhere destructive or appendive (quick-add, delete, copy-meal, saved-meal delete) — the right safety net for an offline, no-backup app.
- Anti-ED guardrails are still real code behavior on direct re-inspection: `_LeftPill` uses identical styling for over/under goal, `WeekBarChartPainter` never uses red for over-goal bars, `_StreakChip` hides at zero with a neutral accessibility label. Verified fresh, not just carried over from the last pass.
- The token system remains fully enforced — no new hardcoded colors found anywhere touched this session.

## Priority Issues

**[P2] The add-food screen now has a large dead zone for short-content foods.** Verified directly (Apples, a 3-macro food): roughly the bottom 55% of the screen is empty whitespace between the collapsed "Nutrition details" row and the "Add" button. The distill pass correctly removed the always-visible donut/macro chips, but nothing fills the space they left behind, and the result reads like unfinished content rather than a deliberately simple screen. Fix: either vertically center the content column within the available viewport height (via `LayoutBuilder` + a min-height `ConstrainedBox`) so short screens don't look broken, or add a small amount of intentional breathing room/illustration instead of raw empty space. Suggested command: **/impeccable layout**.

**[P2] Onboarding names two dishes the food database doesn't contain.** Verified: `l10n.dart`'s intro copy says "from Kalee chips to bazin"; `food_db.dart` has zero entries for either — "bazin" exists only in an ingredient `sourceNote` explaining it's not covered. Why it matters: same failure mode as the earlier test-fixture-ordering finding (a promise made one screen before the data can back it up), but now in the copy that sets first-time expectations, not just list ordering. Fix: either add placeholder/real entries for the 5-10 dishes onboarding actually names before the next testing wave, or adjust the copy to name what's searchable today. This is a data-pipeline-adjacent decision like the fixture-ordering one — flagging, not fixing on my own. Suggested command: **/impeccable clarify**.

**[P3] A second "quick-add" icon system exists alongside Home's newly-unified one.** Verified: `foods_screen.dart` (and, per the app's existing code-duplication pattern, `search_screen.dart`/`food_history_tab.dart`/`saved_meals_tab.dart`) use `Icons.add_circle_outline` as a self-contained glyph with no background container — a different construction than Home's filled-circle `_RoundBtn` system, for the same underlying "log this now" action. The quantity +/- stepper on the add-food screen (neutral gray, `IconButton`) and the Progress tab's AppBar "+" (standard bare Material action icon) are *not* part of this — they're different concepts (adjust-a-number, and a conventional AppBar action) correctly styled differently, not additional inconsistencies. Fix: extend the Home fix's shape to the quick-add icon used across the other four screens. Suggested command: **/impeccable layout**.

**[P3] The "approx." marker doesn't visually signal that it's tappable.** It functions correctly now (tap → explanation), but still looks like a static label — no chevron, border, or elevation change distinguishes it from non-interactive chips elsewhere in the app. Suggested command: **/impeccable clarify**.

**[P3] Number/unit spacing is inconsistent across files, not languages.** `home_screen.dart`'s macro card spaces the unit (`242 g`); food detail, create-meal, profile, and settings goals summaries don't (`242g`) — in both EN and AR. Suggested command: **/impeccable typeset**.

## Persona Red Flags

**Jordan (first-timer)**: follows onboarding's own "bazin" promise into search, lands on the empty-results state, and the hint text ("Try another name, in Arabic or English") misdiagnoses the actual problem as a spelling issue rather than a coverage gap.

**Casey (distracted mobile)**: the 200ms search debounce plus the add-food screen's 350ms save-lock stack to roughly half a second of unresponsiveness on the single action quick-add exists to speed up.

**Invented persona — Amal, first-time Libyan calorie-app user**: opens a food and sees macro percentages with no explanatory text the first time; the quantity picker defaults to whichever mode (fraction/decimal) was last used app-wide rather than starting on the friendlier fraction picker that maps to how portions are actually described at home.

## Minor Observations

- `settings_screen.dart` hardcodes `appVersion = '0.5.0'` per its own comment, separate from `pubspec.yaml` — drift risk, not urgent.
- `WeekBarChartPainter` hardcodes `fontFamily: 'Roboto'` inside its `CustomPaint`, bypassing the app-wide Arabic font-fallback chain — harmless today since its labels are Western digits only, but inconsistent with the rest of the theme discipline if that ever changes.
- The mixed English-greeting/Arabic-name line on Home ("Good morning, عبدالمعز") observed during the live sweep is correct, not a bug — a personal name isn't translated regardless of app language.
- CLAUDE.md's locked macro hex values were out of sync with `theme.dart` (a real, deliberate palette change from some earlier session, documented in a `theme.dart` comment but never written back to the spec) — already corrected during this session at your request.

## Questions to Consider

- Now that the add-food screen is simpler for a 3-macro fruit, does it need to look different (more filled, more centered) for a food with more nutrition detail, or is the emptiness only jarring on the simplest foods where it's least likely to matter to a user just tapping "Add" quickly?
- The onboarding-promises-undelivered-dishes pattern has now shown up twice (test fixtures ranking first, "bazin" not existing at all) — is it worth a single pass auditing every dish/food named in onboarding, empty-state, and marketing copy against what `food_db.dart` actually contains, rather than fixing these one at a time as they surface?

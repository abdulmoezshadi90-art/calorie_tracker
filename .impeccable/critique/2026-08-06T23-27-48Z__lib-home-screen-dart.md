---
target: update the UI/UX (app-wide, anchored on Home + logging flow)
total_score: 30
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 0
timestamp: 2026-08-06T23-27-48Z
slug: lib-home-screen-dart
---
Method: dual-agent (A: general-purpose design review · B: general-purpose live-device evidence sweep, required one retry after a 600s stall on the first attempt — final run completed as a clean isolated pair)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Save confirmation on the add-food screen is a bare checkmark for ~350ms with no text — easy to miss |
| 2 | Match System / Real World | 3 | Portion presets (ladle, plate-share) model real Libyan eating well; undercut by leftover test-fixture foods sitting at the top of the Snacks list |
| 3 | User Control and Freedom | 4 | Undo on every add/delete/copy action; mode switches preserve value |
| 4 | Consistency and Standards | 2 | Two different "+" icon styles used for add-affordances in the same Home list; "History" names two unrelated concepts (search-flow tab vs. Progress day list) |
| 5 | Error Prevention | 3 | Quantity clamps, gentle floor confirmations on goals |
| 6 | Recognition Rather Than Recall | 4 | History prefills last-used servings; saved meals + copy-previous-day remove repeat recall work |
| 7 | Flexibility and Efficiency | 3 | Quick-add, saved meals, copy-previous-meal serve returning users; no swipe-to-delete anywhere |
| 8 | Aesthetic and Minimalist Design | 3 | Home stacks 5-6 equal-weight shadowed cards with little hierarchy between primary (calories) and secondary (macros) info |
| 9 | Error Recovery | 3 | Generic single string for any storage failure; acceptable for local-only but undifferentiated |
| 10 | Help and Documentation | 2 | The "تقريبي" (approx.) marker on unverified foods is never explained where it appears |
| **Total** | | **30/40** | **Acceptable-to-Good** |

(Consistency score adjusted from the design-review draft after verifying the underlying list-clipping and icon-inconsistency evidence directly against the live app.)

## Design Specificity Verdict

**Verified assessment**: Mixed, and the verdict changes materially once checked against the actual data. The interaction layer has real cultural authorship — household portion presets (ladle, modest/normal/generous share) model shared-plate Libyan eating, not the individually-pre-portioned Western nutrition-label mental model, and RTL/Western-digit discipline is enforced everywhere via `WesternDigitsFormatter`, not bolted on.

The visual language — cream/forest-green/gold palette, dashed dividers, donut chart, rounded shadow cards — is competent but reads as generic wellness-app grammar (MyFitnessPal/Lifesum shape) with a single 🌿 emoji as the only overt cultural mark.

One claim from the design-review pass needed correction: it read `food_db.dart` as "100% placeholder," which I verified against the file directly — it's actually 164 foods with 13 literal `Sample Snack A/B/C/D`-style test fixtures (about 8%), sitting alongside a substantial base of real, previously-verified Libyan foods (dairy, fruits, meats, grains) from your data pipeline. The corrected, and still real, problem: those 13 leftover fixtures sort to the *top* of the Snacks section — confirmed live on the Foods tab, where "وجبة خفيفة تجريبية أ/ب/ج/د" are literally the first four rows a tester sees, ahead of real entries like تمر، برتقال، موز. It's a cleanup gap, not a data-coverage gap, but it lands at the exact moment (first open of Foods) where it looks like the coverage gap the onboarding copy explicitly promises isn't there.

**Live-device evidence**: No detector applies (native Flutter app, no web build) — the on-device sweep is the evidence layer here. It confirmed: all numerals observed across four screens (Home, Meal Detail, Foods, Progress) are Western digits with zero Eastern Arabic digit leaks; RTL back-arrow and day-strip ordering are correctly mirrored; and it surfaced two concrete, unreported layout defects (below).

## Overall Impression

The product's hardest requirements — RTL correctness, Western digits, anti-ED color/copy restraint — are genuinely, verifiably held to in the code, not just claimed in CLAUDE.md. What's missing is polish at the seams: inconsistent icon treatment for the same affordance, a content-clipping bug at the bottom nav, a placeholder-chart rendering anomaly on Progress, an unexplained trust marker, and an add-food screen that hands every decision to the user at once regardless of how trivial the food is. None of these are structural; all are fixable without touching the token system or the data pipeline.

## What's Working

- **Anti-ED discipline is load-bearing, not aspirational**: no red anywhere in `AppColors`, overage uses a neutral gold tint, goal-floor violations get a gentle confirm dialog rather than a block — verified in the token file and the goals editor, not just described in the brief.
- **Portion presets are a genuine interaction-level cultural adaptation**: ladle/plate-share framing matches how Libyan households actually portion food, not a translated Western serving-size UI.
- **Recall-reduction is systematic**: History prefilling, saved meals, and copy-previous-day all attack the same real friction (retyping the same breakfast every day) from three angles.

## Priority Issues

**[P2] Foods list bottom row is clipped by the bottom nav bar.** Live evidence: on the Foods tab, the last visible row (بطيخ, watermelon) has its secondary line (portion size) cut off under the nav bar, with only a sliver of text visible. Why it matters: users can't read the portion size of whatever food happens to land at the scroll boundary, and it reads as an unfinished list rather than a designed cutoff. Fix: add bottom padding/inset to the list equal to the nav bar height plus a safe margin. Suggested command: **/impeccable audit** (this is exactly the kind of concrete layout regression `audit` is built to catch systematically across the rest of the app).

**[P2] Test-fixture foods sort ahead of real foods in the Snacks list.** Verified: 13 of 164 `food_db.dart` entries are literal `Sample Snack A-D` / `Sample Main Dish A-C` placeholders, and they appear as the first four rows of the Snacks section on the live Foods tab — ahead of real, verified entries. Why it matters: this is the first thing a tester sees when they open Foods, and it visually undercuts the "search Libyan foods" promise made one screen earlier in onboarding, even though the real database is substantially populated. Fix: either exclude `id`/name-flagged sample fixtures from the shipped list, or move them to the very end of their category so real data leads. Suggested command: **/impeccable clarify** (this is a data-presentation decision, not a visual redesign).

**[P2] Two different "+" icon styles for the same add-affordance on Home.** Live evidence: the empty-state row's "+" is a filled circular icon; the breakfast meal row's "+" is an outline-only circle — both mean "add a food" in the same list, styled differently. Why it matters: users learn icon meaning by consistent shape; two shapes for one action adds recognition cost for no benefit (Nielsen heuristic 4). Fix: standardize on one add-icon treatment across all meal rows and empty states. Suggested command: **/impeccable layout**.

**[P2] The add-food quantity screen front-loads every decision regardless of food complexity.** Source review: unit picker, fraction/decimal mode toggle, quantity stepper, macro chip row, and the full donut chart are all shown simultaneously for every food — logging a single cracker gets the same five-decision screen as logging a home-cooked dish. Why it matters: this is the highest-traffic screen in the app (every logged item passes through it) and it fails the cognitive-load "≤4 simultaneous choices" guideline. Fix: default to a plain whole-number stepper with the fraction/decimal toggle and macro donut behind a "more detail" disclosure. Suggested command: **/impeccable distill**.

**[P3] The macro-percentage donut chart has no Semantics label.** Verified directly: `DonutChartPainter`'s `CustomPaint` in `food_detail_screen.dart` (line ~672) is unwrapped, while the equivalent charts in `progress_screen.dart` (weight line, 7-day bar) both wrap their `CustomPaint` in `Semantics(label: ...)`. Why it matters: this is the one hand-painted chart every food-logging session passes through, and it's currently invisible to screen readers even though the pattern for making it accessible already exists elsewhere in the same codebase. Fix: add a `Semantics` label summarizing the carb/fat/protein percentages, mirroring the existing pattern. Suggested command: **/impeccable audit**.

**[P3] The 7-day calorie bar chart may be rendering a placeholder artifact, not real proportional data.** Live evidence: on Progress, 6 of the 7 day-bars render at visually identical height in a dim fill, while only the one day with actual logged data differs in both height and color — worth a direct check against `WeekBarChartPainter`'s empty/zero-value rendering path, since visually-identical bars for what should be six different (mostly zero, but not necessarily identical) totals looks like a rendering floor rather than true data. Suggested command: **/impeccable audit**.

## Persona Red Flags

**Jordan (first-timer)**: opens Foods expecting the Libyan food coverage onboarding just promised, and the first four rows are literally "وجبة خفيفة تجريبية أ/ب/ج/د" (Test Snack A/B/C/D) — a credibility stumble in the first 10 seconds, even though real food is one scroll away. Also hits the fraction-vs-decimal mode choice before completing a single successful log.

**Amal (invented persona — Libyan user, no prior calorie-app experience)**: the goals screen hands her raw kcal/carb/fat/protein numeric targets with no explanation of what a "macro" is; every food she opens shows a donut chart of calorie-share percentages, vocabulary never introduced in onboarding; she has to choose between fraction chips and a decimal stepper just to log a plate of food. None of this is wrong, but all of it assumes a vocabulary (macros, percentage-of-calories) that a first-time Libyan user of this specific app category is not guaranteed to have.

**Sam (screen-reader user)**: the donut chart gap above is the concrete red flag — every other hand-painted chart in the app (`progress_screen.dart`'s two charts) has a screen-reader label; the highest-traffic one doesn't.

## Minor Observations

- Quick-add/undo/snackbar logic is duplicated near-verbatim across four files (`search_screen.dart`, `food_history_tab.dart`, `foods_screen.dart`, `saved_meals_tab.dart`) — not a UX issue today, but a consistency risk as the four copies drift over time.
- "History" names two unrelated concepts app-wide (the search-flow aggregated log tab vs. the Progress day-by-day list) — `l10n.dart` itself has a comment acknowledging the ambiguity.
- The streak chip (`_StreakChip`, home_screen.dart) was checked against the "no punishing streaks" guardrail directly: it's hidden entirely at zero and its own code comment cites "design decision 2" — it was deliberately built to avoid scolding, not an oversight. The one residual question is whether a flame icon still carries "don't break the chain" connotations even with the scolding removed; worth a product judgment call, not a code defect.
- Create-meal/copy-meal action icons use generic Material glyphs (`add_circle_outline`, `content_copy_outlined`) with no cultural specificity — consistent with the broader "generic wellness-app visual grammar" finding above.

## Questions to Consider

- Is it worth a five-minute cleanup pass to move the 13 test-fixture foods to the end of their categories (or hide them behind a debug flag) before the next beta wave, given how visible they are on first open?
- Should every food, a single cracker included, get the full macro-percentage donut treatment by default, or is that a borrowed framing that could be reserved for foods with more than one macro-significant nutrient?
- Now that the anti-ED guardrails are verified as genuinely enforced in code, is there room to add one moment of warmth or delight (the app is currently flat-affect everywhere) without reopening the door to gamification pressure?

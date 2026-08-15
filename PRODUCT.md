# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Primary users are people in the Libyan market who want to track daily calorie and macro intake but are underserved by global calorie apps. Solo developer building for a local audience; testers recruited in waves via Telegram/WhatsApp (close contacts first, then a wider group including strangers).

## Product Purpose

A mobile calorie-counting app that fills the gap global apps (e.g. MyFitnessPal) leave for Libyan food culture: local packaged brands (Al Naseem, Al-Jaied, Almarai, Hawaa) and home dishes (bazin, mbakbka, couscous, usban, sfinz, maqrud) aren't in their databases. The app lets users log meals against daily calorie/macro goals, works fully offline, and keeps all data on-device.

## Positioning

Libyan-specific food database (packaged products and home dishes, searchable in Arabic or English) combined with full Arabic RTL support, no account/signup requirement, and zero data leaving the device — a combination no global calorie app offers for this market.

## Operating Context

Solo-developer workflow: Windows 11, Flutter 3.44.6. Android is the primary distribution channel (direct APK plus eventual Play Store), with iOS as a best-effort parallel track via cloud CI (no Mac owned). Private beta is underway with real testers on their own phones; the developer has no physical Android devices and relies on an emulator (AVD `libya_test_phone`) for local QA. A weekly manual QA checklist runs before every release. Nutrition data enters through a manual verification pipeline (label photos + spreadsheet), not automated sourcing.

## Capabilities and Constraints

- MVP scope is deliberately tight: no barcode scanner, no accounts/login, no social features, no ads, no in-app AI.
- All numerals must render as Western digits (0-9) everywhere, including in Arabic UI text; Eastern Arabic numeral input is normalized on entry. This is a hard, never-relax requirement.
- Full Arabic RTL layout with a persistent language toggle.
- Nutrition data enters through a documented verification pipeline (label photo, extraction, owner check against the photo) before it's marked verified. 108 of 164 foods carry a verified source note as of this update; the rest are placeholder estimates. Verified vs. unverified status must stay visible to users, never silently presented as accurate.
- Anti-eating-disorder guardrails: no punishing streaks, no alarm-red styling for exceeding goals, no under-eating encouragement, gentle (non-blocking) confirmation below safety floors for calorie/macro goals.
- Local-only storage (shared_preferences); no backend by design. An optional account/sync layer is a future-phase decision, never required.
- Not medical advice — the app records intake, it does not prescribe or diagnose. This disclaimer is shown in onboarding and settings, in English and Arabic.
- Product name and food entries carry English and Arabic names/servings throughout.

## Brand Commitments

Name: "Zibda · زبدة" (one brand, both languages; the earlier name متتبع السعرات is retired). Positioning language that must never be contradicted by UI or store copy: works offline, no signup, data stays on the user's phone, built for Libyan food and Libyan life. Visual identity tokens (warm cream background, forest green header, gold accent, macro colors) are already established in the codebase (`lib/theme.dart`) with full light and dark palettes — treated as existing visual authority, not open for reinvention without a deliberate redesign decision.

## Evidence on Hand

- Live codebase with an established Flutter design-token system (`lib/theme.dart`), 206 passing tests, analyzer clean, and committed golden-image baselines (`test/goldens/`).
- A prior interactive web demo (hand-built HTML twin of the app) and a screenshots artifact exist outside this repo; the web demo duplicates the food database and can drift out of sync when `food_db.dart` changes significantly.
- Public GitHub repository: https://github.com/abdulmoezshadi90-art/calorie_tracker (tagged releases mirror roadmap phases).
- No customer testimonials, press, or case studies exist yet (private beta stage) — future work must not fabricate these.

## Product Principles

- Precision lives in the data, simplicity in the UI: exact gram weights sit behind friendly portion presets (e.g. "ladle," "small plate").
- Never present unverified nutrition numbers as accurate; verification status is a first-class, visible data property.
- The product is local-first and privacy-first by architecture, not just policy — no telemetry beyond an opt-in feedback email.
- Scope discipline: every new idea is captured (e.g. as a backlog item) rather than pulled into the current phase.
- Cultural fit over feature parity with global apps — Libyan food coverage and Arabic-first UX are the core differentiators, not a checklist of generic fitness features.

## Accessibility & Inclusion

No formal accessibility standard (e.g. WCAG level) has been established. Confirmed requirements: numerals always render as Western digits regardless of locale, and the UI fully mirrors for Arabic RTL. No additional low-vision, motor, or tap-target requirements have been set yet.

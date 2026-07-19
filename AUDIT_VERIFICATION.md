# Independent Verification of Public-Release Audit

Re-derived from the repository on 2026-07-19 by a fresh session. No prior
report was consulted; every verdict below cites the command or file that
proves it.

| # | Item | Verdict | Evidence |
|---|------|---------|----------|
| 1 | Secrets | **CONFIRMED** (with tool caveat) | `git log -p --all \| grep -inE 'keystore\|\.jks\|\.p8\|key\.properties\|password\|secret\|token\|apiKey\|api_key\|AuthKey\|BEGIN PRIVATE KEY\|BEGIN RSA\|calorie_tracker_upload'` — hits are documentation/prose and the signing *fallback logic* in `android/app/build.gradle.kts`; zero secret values. File-level: `git log --all --name-only --format= \| sort -u` (204 files ever committed) contains no `.jks/.keystore/.p8/.p12/.pem/key.properties`. `.gitignore` covers `key.properties`, `*.jks`, `*.keystore`, `*.p8`, `*.p12`, `*.pem`, `/beta-notes/`, `/docs-private/`, `/data-private/`, `/CLAUDE.md`. Caveat: gitleaks and trufflehog are **not installed** on this machine, so no automated entropy scan ran — manual grep only. |
| 2 | Fonts | **CONFIRMED** | Only fonts ever committed (same 204-file history list): `assets/fonts/NotoNaskhArabic-{Regular,SemiBold,Bold}.ttf` + `assets/fonts/OFL.txt` (open license). No `Segoe*` file in tree or history. Segoe is referenced only as a *name*: `test/screenshots_test.dart:24` loads `C:\Windows\Fonts\segoeui.ttf` etc. at test time; `lib/theme.dart:204` lists it as a device font fallback. No Microsoft font bytes ship. |
| 3 | CI | **CONTRADICTED (premise) / CONFIRMED (substance)** | **There is no `codemagic.yaml` in the repo** — the audit item's premise is wrong. The only CI is `.github/workflows/ios-build-check.yml`: no secrets, no base64 blobs, no integration references at all (unsigned `--no-codesign` build). It has **no `pull_request` trigger** (only `workflow_dispatch`, weekly cron, `v*` tags), so fork PRs cannot trigger it from config. Repo-level GitHub Actions permissions for forks are a dashboard setting: **UNVERIFIABLE-FROM-REPO** — check Settings → Actions manually. If a Codemagic app exists, it lives entirely in their dashboard: also UNVERIFIABLE-FROM-REPO. |
| 4 | Identity & personal data | **CONFIRMED** | `git log --format='%an <%ae>' \| sort -u` → exactly one identity: `Abdulmoez Shadi <abdulmoezshadi.90@gmail.com>` (eyeball it — it is your real name + email; that is normal for a source-available repo but it is public). No tester names/contacts in history; `QA_CHECKLIST.md` logs only an emulator run. EXIF: all 99 tracked images are PNG (zero JPEGs); byte-scanned every one of the 99 for an `eXIf` chunk — none found. Files checked = the full `git ls-files \| grep -iE '\.(png\|jpg\|jpeg\|webp\|gif)$'` list (android res, assets/branding, assets/icons, ios appicons/launch images, test/goldens, web icons/splash). |
| 5 | Separation | **CONFIRMED (tracked side) / PARTIAL (local side)** | `git ls-files` shows no CLAUDE.md, PLAN.md, playbooks, label photos, or spreadsheet; `.gitignore` blocks `/CLAUDE.md`, `/docs-private/`, `/beta-notes/`, `/data-private/`. Locally, `docs-private/` holds `CLAUDE.md`, `PLAN.md`, `DEV_NOTES.md` — **PLAN.md is safe**. However: no files matching *playbook*, no `.xlsx`, no label photos, and no `beta-notes/` or `data-private/` folders exist anywhere under the repo directory. If those live elsewhere (e.g. OneDrive) fine; if the prep session claimed it moved them into the private folder, **that claim is not supported** — verify their location yourself. |
| 6 | Public files | **CONFIRMED** | `README.md` contains all five required clauses (all rights reserved; as-is no warranty; not medical advice; trademark acknowledgment; honest data-status line). Claims audit: golden images referenced exist; `verified`/`sourceNote` fields exist (`lib/models.dart:33,37` — README says "in food_db.dart", a minor imprecision since the entries are there but the fields are declared in models.dart); features listed match the code. Two soft flags: the "web demo" link is a claude.ai artifact URL (confirm it's public and stays up), and "Public launch planned for December 2026" is a forward-looking claim you should be comfortable publishing. `SECURITY.md` exists with your real email. No LICENSE/LICENCE/COPYING file anywhere in `git ls-files` (the only extra README is Flutter's stock `ios/.../LaunchImage.imageset/README.md`). |
| 7 | Build integrity | **CONFIRMED** | From the current tree: `flutter analyze` → "No issues found!" and `flutter test` → "00:10 +46: All tests passed!" (full suite incl. goldens/screenshots). Nothing broke from the file shuffle. |
| 8 | Fresh-clone list | **CONFIRMED** | Reviewed all ~190 `git ls-files` entries name by name. Nothing with private/draft/notes/env in the name; no editor configs beyond stock platform `.gitignore`s. Deliberate inclusions worth a conscious nod: `QA_CHECKLIST.md` (contains internal QA history incl. emulator/AVD details — harmless but it is process detail), `pubspec.lock` (normal for apps), `tool/generate_*.dart` (icon generators). |

## Verdict

**SAFE TO FLIP** — the repository itself is clean: no secrets ever committed, no
proprietary fonts, single author identity, clean CI config, required legal text
present, LICENSE absent as intended, and the tree analyzes and tests green.

Non-blocking follow-ups, in priority order:

1. Locate and back up the label photos, nutrition spreadsheet, and both
   playbooks — they are not in `docs-private/` or anywhere in the repo folder
   (preservation risk, not a leak risk).
2. Manually check GitHub Settings → Actions fork-PR permissions (and the
   Codemagic dashboard, if an app exists there) — unverifiable from the repo.
3. Confirm the claude.ai web-demo link in README.md is publicly reachable.
4. Optional: run gitleaks once from any machine that has it, since no
   automated scanner was available here.

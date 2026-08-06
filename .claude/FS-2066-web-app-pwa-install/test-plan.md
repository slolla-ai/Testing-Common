# Test Plan: px-web-app PWA Installability (FS-2066)

**Feature**: `FS-2066-web-app-pwa-install`
**Jira Epic**: [FS-2066](https://safefleet.atlassian.net/browse/FS-2066)
**Component under test**: px-web-app (sidebar Download entry, install-guidance dialog, "update available" prompt, standalone window branding)
**Spec source**: [spec.md](./spec.md)
**Test case source**: [tests/component-ui-test-cases.md](./tests/component-ui-test-cases.md)
**Test level in this plan**: Component UI — manual execution only
**Status**: Test cases Approved; published to Jira as Zephyr Test issues [FS-2299–FS-2323](https://safefleet.atlassian.net/browse/FS-2299)

---

## 1. Purpose

Validate that px-web-app can be installed as a Progressive Web App on all supported browsers, that the installed app launches as a correctly branded standalone window, and that the custom install affordance ("Download" sidebar entry), its guidance dialog, and the in-app "update available" prompt behave correctly, accessibly, and only when they should — without this feature ever degrading the existing browser-tab experience or the sign-in flow.

This plan covers manual verification only. Scope is installability, standalone launch/branding, and the update-notification UI — **not** offline capability, which is explicitly out of scope for FS-2066 (FR-009).

---

## 2. Scope

### 2.1 In Scope (covered by this test plan and its 25 test cases)

| Area | User Story / Requirement |
|---|---|
| Install affordance discovery & triggering | US1, FR-003a |
| Guidance dialog behavior (persistence, dedup, platform-specific copy) | FR-003a, EC-1, EC-8, EC-9 |
| Visibility rules & graceful degradation | US1, EC-2, EC-3, FR-004 |
| Standalone window launch & branding | US2, FR-002, FR-002a, FR-003 |
| In-app "update available" prompt | US4, FR-008 |
| Accessibility of the Download entry, guidance dialog, and update prompt | FR-012, SC-008 |
| Environment gating / rollback toggle | FR-010, SC-009 |

### 2.2 Out of Scope for this plan (tracked as gaps — see §7)

| Area | Why excluded here | Requires |
|---|---|---|
| US3 — Sign-in / auth redirect & session renewal in the installed app | Not a single UI component in isolation; validates identity-provider integration | Integration / E2E-UI (not generated — E2E is excluded from dev repos by default per the QA test-case-generator's E2E Scope Gate, unless explicitly requested) |
| EC-4 — Offline / lost connectivity | Explicit non-goal of FS-2066 (FR-009); no UI behavior to assert beyond "unchanged from today" | N/A — confirmed by design, not a test case |
| EC-7 — Broken/stale service worker recovery | No dedicated user-facing UI; recovery is a background/service-worker mechanism | Integration |
| EC-10 — First-load byte-count regression (SC-004) | Performance/network measurement, not an observable UI assertion | Performance / Integration |
| EC-11 — Install layer must not intercept auth redirect/callback (FR-005, FR-006) | Network-layer behavior, not a UI component | Integration |
| FR-001, FR-007, FR-013 | Structural/build-time or explicitly not-applicable (FR-013: no i18n in px-web-app) requirements with no dedicated UI assertion | N/A / build verification |
| SC-003 (auth), SC-004 (byte budget) | Depend on the excluded areas above | Integration / Performance |

This split is intentional, not an oversight: the user asked for **manual UI test cases only**, and the QA Constitution's Lowest Practical Layer Principle means auth, network-interception, and byte-budget concerns belong at Integration/Performance layers, not Component-UI. If Integration or E2E coverage for US3/EC-4/EC-7/EC-10/EC-11 is wanted, it should be requested as a separate generation pass.

---

## 3. Test Approach

- **Method**: Manual exploratory + scripted execution against the 25 Gherkin scenarios in [component-ui-test-cases.md](./tests/component-ui-test-cases.md). Every scenario carries `Automation Recommendation: Do Not Automate` by design (this pass targets manual QA, not automation candidates).
- **Technique**: Black-box, behavior-driven (Given/When/Then), asserting only observable UI state — visible text, focus, enabled/disabled state, dialog presence/absence — never internal framework state.
- **Execution record**: Each scenario is tracked as its own Zephyr Test issue in Jira project **FS**, so pass/fail/notes are logged per scenario rather than as one lump result.
- **Order of execution**: Recommended to follow the grouping below (§6), since later groups (accessibility, gating) assume the basic affordance behavior from group 1 already passed.

---

## 4. Environments & Platforms

Every scenario must be exercised on the platforms relevant to it. At minimum:

| Platform | Role in this plan |
|---|---|
| Chrome (desktop) | Primary Chromium install-prompt path |
| Edge (desktop) | Secondary Chromium install-prompt path |
| Chrome (Android) | Chromium mobile install path |
| Safari (iOS/iPadOS) | Manual Add-to-Home-Screen guidance path |
| Safari (macOS, version 17+) | Manual Add-to-Dock guidance path; verify the Safari-17 caveat text on < 17 if reachable |
| A browser with neither install prompt nor standalone support (e.g. older/unsupported browser) | Confirms graceful degradation (FS-2310) |

Feature flags: both the **installability flag** (service worker, app-identity metadata, update prompt) and the **sidebar-entry flag** must be independently toggled per environment to exercise FS-2323 (gating/rollback). Per the spec's Assumptions, installability is **not enabled in production** by default — run this plan in an environment (dev/qa) where both flags can be turned on.

---

## 5. Entry / Exit Criteria

**Entry criteria**
- px-web-app build under test has the installability flag and sidebar-entry flag available to toggle per environment.
- Manifest, service worker, and Apple-specific meta tags/icons are deployed to the environment under test.
- All 25 Zephyr Test issues (FS-2299–FS-2323) exist under Epic FS-2066 with Status `Open`/`Approved` in Jira.

**Exit criteria**
- Every in-scope test case (§2.1) has been executed at least once on its relevant platform(s) and recorded in Jira.
- No open blocking defect against US1 (install) or US2 (standalone launch) — these are the P1 MVP stories.
- Any failure on US4 (update prompt, P2) is triaged but does not block sign-off, per the spec's own priority ordering.
- Gaps in §2.2 are explicitly acknowledged (not silently treated as "tested") in the close-out report.

---

## 6. Test Case Groups & Traceability

Each row maps this plan's coverage to the underlying spec item(s) and the published Jira Test issue.

| # | Jira Key | Scenario | Traceability |
|---|---|---|---|
| 1 | [FS-2299](https://safefleet.atlassian.net/browse/FS-2299) | Download entry appears unaided on a cold authenticated Chromium load | US1-AC1, FR-003a, SC-001, SC-007 |
| 2 | [FS-2300](https://safefleet.atlassian.net/browse/FS-2300) | Activating Download entry on Chromium triggers the native install prompt | US1-AC2, FR-003a, SC-002 |
| 3 | [FS-2301](https://safefleet.atlassian.net/browse/FS-2301) | Download entry opens Add-to-Home-Screen guidance on Safari iOS/iPadOS | US1-AC3, EC-1, FR-003a |
| 4 | [FS-2302](https://safefleet.atlassian.net/browse/FS-2302) | Download entry opens Add-to-Dock guidance on macOS Safari with version caveat | US1-AC3, EC-1, FR-003a |
| 5 | [FS-2303](https://safefleet.atlassian.net/browse/FS-2303) | iOS guidance text does not assume the Share control is in the browser toolbar | EC-1, FR-003a |
| 6 | [FS-2304](https://safefleet.atlassian.net/browse/FS-2304) | Guidance dialog opens on Chromium once the single-use install prompt is spent | US1-AC3a, EC-8, SC-007 |
| 7 | [FS-2305](https://safefleet.atlassian.net/browse/FS-2305) | Guidance dialog persists until explicitly dismissed | FR-003a |
| 8 | [FS-2306](https://safefleet.atlassian.net/browse/FS-2306) | Repeated activation of Download entry does not stack duplicate dialogs | FR-003a |
| 9 | [FS-2307](https://safefleet.atlassian.net/browse/FS-2307) | Download entry and any open guidance dialog disappear once installation completes | US1-AC4, EC-3 |
| 10 | [FS-2308](https://safefleet.atlassian.net/browse/FS-2308) | Open guidance dialog closes when the app becomes installed via another window | EC-3 |
| 11 | [FS-2309](https://safefleet.atlassian.net/browse/FS-2309) | Download entry is not shown when the app is already running standalone | EC-3, SC-007 |
| 12 | [FS-2310](https://safefleet.atlassian.net/browse/FS-2310) | Download entry is absent and the app remains usable on unsupported browsers | US1-AC6, EC-2, SC-006 |
| 13 | [FS-2311](https://safefleet.atlassian.net/browse/FS-2311) | Dismissing the native Chromium install prompt keeps the Download entry available | EC-8 |
| 14 | [FS-2312](https://safefleet.atlassian.net/browse/FS-2312) | Download entry activation never results in a no-op when the native prompt is unusable | EC-9 |
| 15 | [FS-2313](https://safefleet.atlassian.net/browse/FS-2313) | App remains fully usable in a normal browser tab prior to installation | US1-AC5, FR-004 |
| 16 | [FS-2314](https://safefleet.atlassian.net/browse/FS-2314) | Standalone window opens without browser tab/address-bar chrome | US2-AC1, FR-003 |
| 17 | [FS-2315](https://safefleet.atlassian.net/browse/FS-2315) | Standalone window is identified by the Fus1on name and icon in the OS | US2-AC2, FR-002, FR-002a, FR-003 |
| 18 | [FS-2316](https://safefleet.atlassian.net/browse/FS-2316) | Standalone window theming matches the app's visual identity | US2-AC3, FR-002 |
| 19 | [FS-2317](https://safefleet.atlassian.net/browse/FS-2317) | "Update available" prompt is shown with reload and close controls | US4-AC1, FR-008, SC-005 |
| 20 | [FS-2318](https://safefleet.atlassian.net/browse/FS-2318) | Accepting the update prompt reloads into the new version | US4-AC2, FR-008, SC-005 |
| 21 | [FS-2319](https://safefleet.atlassian.net/browse/FS-2319) | Closing the update prompt dismisses the notification only, without declining the update | US4-AC3, EC-5, EC-6, FR-008, SC-005 |
| 22 | [FS-2320](https://safefleet.atlassian.net/browse/FS-2320) | Download entry meets accessibility requirements | FR-012, SC-008 |
| 23 | [FS-2321](https://safefleet.atlassian.net/browse/FS-2321) | Guidance dialog meets accessibility requirements | FR-012, SC-008 |
| 24 | [FS-2322](https://safefleet.atlassian.net/browse/FS-2322) | "Update available" prompt meets accessibility requirements | FR-012, SC-008 |
| 25 | [FS-2323](https://safefleet.atlassian.net/browse/FS-2323) | No Download entry or update prompt is shown when installability is disabled | FR-010, SC-009 |

**Coverage by user story**: US1 — 11 cases · US2 — 3 cases · US3 — 0 cases (see §2.2) · US4 — 3 cases · Cross-cutting accessibility — 3 cases · Environment gating — 1 case · Dialog-behavior hardening — 4 cases.

---

## 7. Risks, Assumptions & Known Gaps

- **US3 (sign-in) has zero manual UI coverage in this plan.** It is the highest-risk gap: a regression here would make the installed app worse than the browser (per the spec's own stated priority rationale). Recommend an Integration or E2E-UI pass specifically for US3 before this feature is considered fully verified end-to-end.
- **Safari version detection is a platform limitation, not a defect** (FS-2302, EC-1): the app cannot distinguish Safari versions, so testers must manually confirm the "Safari 17+" caveat text is present rather than expecting the guidance to adapt.
- **Production is flag-gated off by default** — this plan must run in an environment where both feature flags can be enabled; do not attempt to execute it against production as currently configured.
- **Update-prompt testing requires a live redeploy** (FS-2317–FS-2319): triggering the "update available" prompt needs an actual new build to be deployed mid-session, which may require coordinating a test deploy rather than being reproducible on demand.
- **No dedicated performance/byte-budget test exists yet** for SC-004 (≤ 50 KB first-load regression) — flagged as a gap, not silently assumed passing.

---

## 8. Roles & Responsibilities

- **Owning team**: Fus1on Telemetricians
- **Test execution & result logging**: QA / manual testers assigned in Jira against FS-2299–FS-2323
- **Fix version**: `TM`
- **Test category**: Release Validation
- **Provenance**: Test cases and this plan are AI Influenced / Assisted (generated from spec.md, human-reviewed and approved before publication)

---

## 9. Deliverables

1. [component-ui-test-cases.md](./tests/component-ui-test-cases.md) — 25 Gherkin-based manual test cases (source of truth for scenario content)
2. This test plan (`test-plan.md`)
3. 25 Zephyr Test issues in Jira project FS, parented to [FS-2066](https://safefleet.atlassian.net/browse/FS-2066): FS-2299–FS-2323
4. A close-out note recording pass/fail per case and an explicit statement of the §2.2/§7 gaps at sign-off time

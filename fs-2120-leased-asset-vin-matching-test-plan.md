# Test Plan: Leased Asset Upload & List — VIN-Based Trailer Matching (FS-2120)

**Feature**: `FS-2120-leased-asset-vin-matching`
**Jira Epic**: [FS-2120](https://safefleet.atlassian.net/browse/FS-2120) — Enhance Leased Asset File Processing to Support VIN-Based Trailer Matching
**Component under test**: px-web-app (Leased Asset upload template, upload-results display, Exception Report, Leased Assets list)
**Spec source**: `specs/FS-2120-leased-asset-vin-matching/spec.md` (fus1on-sdd repo, branch `FS-2120-manual-ui-tests`)
**Test case source**: [fs-2120-leased-asset-vin-matching-component-ui-test-cases.md](./fs-2120-leased-asset-vin-matching-component-ui-test-cases.md)
**Test level in this plan**: Component UI — manual execution only
**Status**: Test cases published to Jira as Zephyr Test issues [FS-2328–FS-2346](https://safefleet.atlassian.net/browse/FS-2328)

---

## 1. Purpose

Validate that the px-web-app Leased Assets upload template, upload-results display (success section telemetry, renamed/downloadable Exception Report), and Leased Assets list correctly present the outcomes of VIN-based trailer matching — **without** validating the VIN-matching, duplicate-detection, or lease-resolution logic itself, which belongs to the Component-API/Integration layer (px-asset-service, FS-2267) and is out of scope here.

This plan covers manual verification only. Scope is the UI's presentation of upload templates, success/failure results, and the Leased Assets list — not the matching, validation, or lessor-scoping rules that produce those results.

---

## 2. Scope

### 2.1 In Scope (covered by this test plan and its 19 test cases)

| Area | User Story / Requirement |
|---|---|
| Upload template & column-hint reflect VIN, drop MCU/GPS ID | US3, FR-001 |
| Success section displays VIN, Trailer Name, and live telemetry (incl. blank-telemetry handling and VIN case preservation) | US1 (display slice only), FR-011, FR-012, FR-013, SC-007 |
| Exception Report presence, per-row content, duplicate/joined reasons, download | US2, FR-002, FR-005, FR-007, FR-010, FR-020, FR-021, FR-029, SC-002 |
| Idempotent delete row shown as successful, not failed | US5 (display slice only), FR-018, SC-002 |
| Leased Assets list VIN column, export, Search By, GPS ID retained, acting-lessor scoping as rendered | US6, FR-023, FR-032 |

### 2.2 Out of Scope for this plan (tracked as gaps — see §7)

| Area | Why excluded here | Requires |
|---|---|---|
| US1 — VIN + Trailer Name matching logic itself (AC2, AC5–AC8), including lessor-scoping enforcement and rejection of an upload with no acting lessor | Backend matching/authorization logic, not an observable UI component in isolation | Component-API / Integration (px-asset-service, FS-2267) |
| US2 — duplicate-detection rules (AC4a/4b, AC5), API-route row reporting (AC7), non-trailer-asset handling (AC8), damaged-VIN handling (AC9) | Matching/validation logic and API-only behavior, not UI-observable | Component-API / Integration |
| US2 AC10/AC11 — persisted upload-result payload (FR-031) | No retrieval screen ships in this feature by design (spec Assumptions); nothing to assert in the UI | Data-layer verification, not Component-UI |
| US4 — existing upload processing/reporting continues unaffected (non-regression) | A regression guarantee across the whole flow, not a discrete new UI assertion | Regression pass / Integration |
| US5 — delete-row resolution logic (AC1, AC2, AC4, AC5): resolving against the existing entry rather than the trailer, placeholder-VIN delete, re-activation | Backend resolution logic; only the idempotent-display slice (AC3) is UI-observable and is covered here (FS-2341) | Component-API / Integration |
| US6 AC4 — that the API actually scopes list results to the acting lessor | This plan covers only that the list **renders what the API returns** (FS-2346); it does not verify the API computed the correct scoped set | Component-API / Integration (FR-032) |
| FR-024, FR-025 — VIN validation (presence-only, case-insensitive/whitespace-insensitive comparison) | Comparison/validation logic; the UI-observable slice (VIN displayed exactly as returned, no UI-side normalization) is covered by FS-2332 | Component-API / Integration |
| FR-026, FR-027 — non-trailer asset exclusion; unrecognized columns ignored, file size/row limits unchanged | File-processing/backend rules with no dedicated new UI surface | Integration / regression |
| FR-015 — migration backfill and placeholder-VIN generation | One-time data migration, not a UI flow; its visible effect (placeholder VIN appearing in the list) is covered indirectly by FS-2342 | Data migration verification |

This split mirrors the test-case file's own stated Purpose: this pass validates **display of outcomes**, not the rules that produce them. If Integration or E2E coverage for the matching/lease-resolution/persistence logic above is wanted, it should be requested as a separate generation pass against px-asset-service and px-web-app-api.

---

## 3. Test Approach

- **Method**: Manual exploratory + scripted execution against the 19 Gherkin scenarios in [fs-2120-leased-asset-vin-matching-component-ui-test-cases.md](./fs-2120-leased-asset-vin-matching-component-ui-test-cases.md). Every scenario carries `Automation Recommendation: Do Not Automate` by design (this pass targets manual QA, not automation candidates).
- **Technique**: Black-box, behavior-driven (Given/When/Then), asserting only observable UI state — table contents, column presence, downloaded-file contents, on-screen messages — never internal matching/backend state.
- **Shared background**: Every scenario assumes the user is authenticated in px-web-app with an account selected, is on the Leased Assets view within Assets Settings, and has a Lessee Organization selected via the {Lessee Organization} selector.
- **Test data / stubbed responses**: Because matching logic is explicitly out of scope, most scenarios are driven by a **given upload response** (already containing the success/failure rows to render) rather than by first producing that response through real matching. Testers should stub or arrange upload responses with the specific field values each scenario calls for (e.g., a row with blank VIN and a named Failure Reason) rather than trying to organically trigger every case through live data.
- **Execution record**: Each scenario is tracked as its own Zephyr Test issue in Jira project **FS**, so pass/fail/notes are logged per scenario rather than as one lump result.
- **Order of execution**: Recommended to follow the grouping below (§6) — template/hint first, then success-section display, then Exception Report, then the Leased Assets list, since later groups assume the basic rendering surfaces from earlier groups already work.

---

## 4. Environments & Platforms

- **Browsers**: Chrome (desktop) and Edge (desktop) — px-web-app's standard supported admin-console browsers. No mobile or Safari-specific behavior is implied by this feature.
- **Roles**: Admin and SuperAdmin holding the "Upload Leased Assets" permission (unchanged by this feature) — exercise at least one scenario under each role.
- **Test data setup required**:
  - A Lessee Organization with at least one leased-asset record carrying a **placeholder VIN** (from the FR-015 migration), to exercise FS-2342.
  - A Lessee Organization that leases from **two different Lessor Organizations**, with entries under each, to exercise FS-2346 (list renders only the acting lessor's entries as returned by the API).
  - Upload responses (real or stubbed) covering: a clean success row with telemetry, a success row with blank telemetry, a VIN with mixed letter case, and each of the Exception Report row shapes (blank VIN, unmatched VIN/Trailer Name, duplicate-record, two-joined-reasons, already-deleted no-op, whole-file rejection).
- **Deployment order dependency**: Per the spec's Cross-Repo Implementation section, this feature is **not backward compatible** and ships in the fixed order px-asset-service → px-web-app-api → px-web-app. Run this plan against an environment where all three have been deployed in that order — a partially-deployed stack will not degrade gracefully and is not representative.

---

## 5. Entry / Exit Criteria

**Entry criteria**
- px-web-app build under test includes the VIN-based upload template/column hint, the renamed Exception Report with download, live success-section telemetry, and the Leased Assets list VIN column/export/Search By.
- px-asset-service and px-web-app-api have already been deployed ahead of px-web-app per the required release order.
- Test data per §4 (placeholder-VIN record, dual-lessor lessee, and the upload-response shapes needed per scenario) is available in the test environment.
- All 19 Zephyr Test issues (FS-2328–FS-2346) exist under Epic FS-2120 with Status `Open` in Jira.

**Exit criteria**
- Every in-scope test case (§2.1) has been executed at least once and recorded in Jira.
- No open blocking defect against US2 (Exception Report, P1) or the US1 display slice (success-section telemetry, P1) — these back the epic's two P1 stories.
- Any failure on US3 (template, P2), US5's display slice (P2), or US6 (list, P3) is triaged but does not block sign-off, per the spec's own priority ordering.
- Gaps in §2.2/§7 are explicitly acknowledged (not silently treated as "tested") in the close-out report — in particular, that the matching, duplicate-detection, and lessor-scoping **logic** has not been verified by this plan.

---

## 6. Test Case Groups & Traceability

Each row maps this plan's coverage to the underlying spec item(s) and the published Jira Test issue.

| # | Jira Key | Scenario | Traceability |
|---|---|---|---|
| 1 | [FS-2328](https://safefleet.atlassian.net/browse/FS-2328) | Downloaded template reflects the VIN-based 3-column format | US3-AC1, FR-001, SC-003 |
| 2 | [FS-2329](https://safefleet.atlassian.net/browse/FS-2329) | Upload form column hint names VIN instead of MCUID | US3-AC1, FR-001 |
| 3 | [FS-2330](https://safefleet.atlassian.net/browse/FS-2330) | Successful match displays VIN, Trailer Name, and live telemetry | US1-AC1, FR-011, SC-007 |
| 4 | [FS-2331](https://safefleet.atlassian.net/browse/FS-2331) | Success row shows blank telemetry without becoming an error state | US1-AC3, FR-012, SC-007 |
| 5 | [FS-2332](https://safefleet.atlassian.net/browse/FS-2332) | Success row displays the VIN exactly as returned, without normalization | US1-AC4, FR-013 |
| 6 | [FS-2333](https://safefleet.atlassian.net/browse/FS-2333) | Exception Report is shown on screen whenever a row fails | US2-AC3, FR-007 |
| 7 | [FS-2334](https://safefleet.atlassian.net/browse/FS-2334) | Exception Report row shows the "VIN is missing" reason for a blank VIN | US2-AC1, FR-002, FR-010, SC-002 |
| 8 | [FS-2335](https://safefleet.atlassian.net/browse/FS-2335) | Exception Report row shows the "not found" reason for an unmatched VIN/Trailer Name | US2-AC2, FR-005, FR-010, SC-002 |
| 9 | [FS-2336](https://safefleet.atlassian.net/browse/FS-2336) | Exception Report row shows a duplicate-record reason naming the VIN | US2-AC4, FR-021 |
| 10 | [FS-2337](https://safefleet.atlassian.net/browse/FS-2337) | Exception Report row displays two joined failure reasons together | US2-AC4a, FR-021, FR-029, SC-002 |
| 11 | [FS-2338](https://safefleet.atlassian.net/browse/FS-2338) | Exception Report preserves the original row number and uploaded values | FR-010 |
| 12 | [FS-2339](https://safefleet.atlassian.net/browse/FS-2339) | Exception Report can be downloaded from the results view | US2-AC3, FR-007 |
| 13 | [FS-2340](https://safefleet.atlassian.net/browse/FS-2340) | Whole-file rejection message is shown with no result tables | US2-AC6, FR-020 |
| 14 | [FS-2341](https://safefleet.atlassian.net/browse/FS-2341) | An already-deleted delete row appears as successful, not failed | US5-AC3, FR-018, SC-002 |
| 15 | [FS-2342](https://safefleet.atlassian.net/browse/FS-2342) | Leased Assets list displays the VIN column, including placeholder VINs | US6-AC1, FR-023, SC-009 |
| 16 | [FS-2343](https://safefleet.atlassian.net/browse/FS-2343) | Leased Assets list export includes the VIN column | US6-AC2, FR-023 |
| 17 | [FS-2344](https://safefleet.atlassian.net/browse/FS-2344) | "Search By" includes VIN and filters the list | US6-AC3, FR-023 |
| 18 | [FS-2345](https://safefleet.atlassian.net/browse/FS-2345) | Leased Assets list still shows the existing GPS ID column | FR-001 |
| 19 | [FS-2346](https://safefleet.atlassian.net/browse/FS-2346) | Leased Assets list renders only the entries returned for the acting lessor | US6-AC4, FR-032 |

**Coverage by user story**: US1 — 3 cases (display slice only) · US2 — 8 cases · US3 — 2 cases · US4 — 0 cases (see §2.2) · US5 — 1 case (display slice only) · US6 — 5 cases.

---

## 7. Risks, Assumptions & Known Gaps

- **The matching/lease-resolution logic itself has zero coverage in this plan.** Every scenario here consumes an already-computed upload response or list payload; none of them prove the backend correctly matched by VIN + Trailer Name, correctly scoped by lessor–lessee pair (FR-032), or correctly rejected an upload with no acting lessor. This is the highest-risk gap — recommend the Component-API/Integration pass against px-asset-service (FS-2267) be treated as equally mandatory before sign-off, not optional follow-up.
- **US4 (non-regression) has no dedicated case.** Existing create/update/soft-delete business rules and results display are asserted only insofar as the other 19 cases incidentally touch them; a targeted regression pass is recommended alongside this plan.
- **FS-2346 can give a false sense of coverage for FR-032 if read carelessly.** It confirms the list renders exactly what the API returned — it does **not** confirm the API returned the correct, lessor-scoped set. Testers/reviewers should not check this off as "lessor scoping verified" without the Integration-layer test.
- **Deployment-order dependency**: this plan assumes px-asset-service and px-web-app-api are already live with the new contract. Running it against a stack deployed out of order (per the spec's explicit "no grace period" warning) will produce misleading failures unrelated to the UI itself.
- **Placeholder-VIN and dual-lessor test data may not pre-exist** in the target environment (mirrors the spec's own noted risk: "Test data needs seeding... a configuration that may not exist in QA today") — confirm both are seeded before executing FS-2342 and FS-2346.
- **FR-031 (persisted upload-result payload) is untestable at the UI layer by design** — this feature ships no retrieval screen. Its absence from this plan is a confirmed non-goal, not an oversight.

---

## 8. Roles & Responsibilities

- **Owning team**: Fus1on Avengers
- **Test execution & result logging**: QA / manual testers assigned in Jira against FS-2328–FS-2346
- **Fix version**: `AV-08.31.26`
- **Test category**: Release Validation
- **Provenance**: Test cases and this plan are AI Influenced / Assisted (generated from spec.md, human review and approval expected before execution)

---

## 9. Deliverables

1. [fs-2120-leased-asset-vin-matching-component-ui-test-cases.md](./fs-2120-leased-asset-vin-matching-component-ui-test-cases.md) — 19 Gherkin-based manual test cases (source of truth for scenario content; mirrored at `specs/FS-2120-leased-asset-vin-matching/tests/component-ui-test-cases.md` in the fus1on-sdd repo)
2. This test plan (`fs-2120-leased-asset-vin-matching-test-plan.md`)
3. 19 Zephyr Test issues in Jira project FS, parented to [FS-2120](https://safefleet.atlassian.net/browse/FS-2120): FS-2328–FS-2346
4. A close-out note recording pass/fail per case and an explicit statement of the §2.2/§7 gaps — especially that matching/lease-resolution logic requires a separate Component-API/Integration pass — at sign-off time

# Test Plan: Leased Asset Management Enhancements for Lessor-to-Lessee Leasing (FS-2324)

**Feature**: `FS-2324-lessee-org-billing`
**Jira Epic**: [FS-2324](https://safefleet.atlassian.net/browse/FS-2324)
**Component under test**: px-web-app (Leased Asset page — Lessee Organization selection, upload gating, upload-results display)
**Spec source**: `specs/FS-2324-lessee-org-billing/spec.md` (fus1on-sdd, branch `FS-2324-lessee-org-billing`)
**Test case source**: [tests/component-ui-test-cases.md](./tests/component-ui-test-cases.md)
**Test level in this plan**: Component UI — manual execution only
**Status**: Test cases Approved; published to Jira as Zephyr Test issues [FS-2347–FS-2355](https://safefleet.atlassian.net/browse/FS-2347), parented under Epic FS-2324

---

## 1. Purpose

Validate that the px-web-app Leased Asset page correctly scopes and gates Lessee Organization selection for a leased asset upload, and that the upload-results display shows the right device telemetry and success/failure state per record — without regressing the existing access-control, file-storage, or leased-asset business rules.

This plan covers manual verification only. Scope is the Lessee Organization selector, upload gating, single-select constraint, and the upload-results display (telemetry fields and success/failure rendering) — **not** the underlying VIN+Trailer Name matching/validation engine or the backend-only Bill to Lessor indicator, which have no dedicated UI surface in this feature (see §2.2).

---

## 2. Scope

### 2.1 In Scope (covered by this test plan and its 9 test cases)

| Area | User Story / Requirement |
|---|---|
| Lessee Organization list display, scoped to the Lessor's authorization | US1, FR-001, SC-001 |
| Zero-authorized-organizations edge case | EC-1, FR-002, FR-003 |
| Upload gating on Lessee Organization selection | US1, FR-003, SC-002 |
| Single-select constraint on the selection control | US1, FR-002 |
| Selection control reflects a changed choice | US1, FR-002 |
| Upload-results telemetry display (Last Communication Date, MCU Battery Level) | US4, FR-012 |
| Blank-telemetry fallback (no device / retrieval failure) | US4, EC-6, FR-013, SC-006 |
| Cross-organization match rendered as a failure, not a success | US2, EC-5 |
| Page access control (regression) | US5, FR-008, SC-004 |

### 2.2 Out of Scope for this plan (tracked as gaps — see §7)

| Area | Why excluded here | Requires |
|---|---|---|
| US2 — the VIN+Trailer Name matching/validation engine itself (why a record passes or fails) | A backend business rule, not a UI component in isolation; this plan's UI test cases treat a record's pass/fail state as a given precondition rather than exercising the matching logic end-to-end | Integration / Component-API |
| US3 — "Bill to Lessor" indicator | No Lessor-facing UI exists for it — the epic frames it as a backend-only field, confirmed by the spec's own Assumptions | Component-API / Integration (persistence + downstream query) |
| US5-AC2 — file-storage process | Not independently UI-observable; storage happens before/behind the UI | Integration |
| US5-AC3 — existing leased-asset business rules (creation, update, soft-delete) | Backend behavior, not a distinct new UI surface introduced by this feature | Integration |
| EC-2 (soft-deleted asset), EC-3 (authorization removed post-lease), EC-4 (Bill to Lessor backfill default) | Backend/data-state behavior with no new UI surface | Integration |
| px-asset-service, px-web-app-api, and (if needed) px-account-service | Not UI components | Component-API / Integration |

This split is intentional, not an oversight: the user asked for **manual UI test cases only**, and the QA Constitution's Lowest Practical Layer Principle means the matching engine, the billing indicator, and file-storage/business-rule regressions belong at Integration/Component-API layers, not Component-UI. If that coverage is wanted, it should be requested as a separate generation pass.

---

## 3. Test Approach

- **Method**: Manual, scripted execution against the 9 Gherkin scenarios in [component-ui-test-cases.md](./tests/component-ui-test-cases.md). Every scenario carries `Automation Recommendation: Do Not Automate` by design (this pass targets manual QA, not automation candidates).
- **Technique**: Black-box, behavior-driven (Given/When/Then), asserting only observable UI state — visible list contents, selection state, enabled/gated actions, validation messaging, and success/failure section placement — never internal framework state.
- **Execution record**: Each scenario is tracked as its own Zephyr Test issue in Jira project **FS**, so pass/fail/notes are logged per scenario rather than as one lump result.
- **Order of execution**: Recommended to follow the grouping in §6 — verify organization listing and selection behavior first (group 1), since the gating, telemetry, and failure-rendering scenarios all assume a working selection control.

---

## 4. Environments & Platforms

| Precondition | Role in this plan |
|---|---|
| A Lessor account authorized to one or more Lessee Organizations | Required for the happy-path listing, gating, single-select, and selection-change scenarios (FS-2347, FS-2349–FS-2351) |
| A Lessor account authorized to **zero** Lessee Organizations | Required for the zero-orgs edge case (FS-2348) |
| A test asset currently **unassigned**, and a test asset already **leased to the selected Lessee Organization** | Needed to stage records that pass validation for the telemetry scenarios (FS-2352, FS-2353) |
| A test asset already leased to a Lessee Organization **other than** the one selected for the upload | Needed to stage the cross-organization failure case (FS-2354) |
| A matched asset with **no device attached**, or one whose live telemetry is unavailable | Needed for the blank-telemetry fallback (FS-2353) |
| A user account **without** the Upload Leased Assets permission | Needed for the access-control regression (FS-2355) |

No browser/platform matrix is required here (unlike FS-2066's PWA install testing) — this feature has no platform-specific behavior. Standard supported desktop browsers for px-web-app apply.

---

## 5. Entry / Exit Criteria

**Entry criteria**
- px-web-app build under test includes the Lessee Organization selector, upload gating, and upload-results telemetry/failure-rendering changes for FS-2324.
- Test data is staged per §4 (authorized/unauthorized Lessor accounts, unassigned/leased/cross-org assets, a device-less or telemetry-unavailable asset).
- All 9 Zephyr Test issues (FS-2347–FS-2355) exist under Epic FS-2324 with Status `Open`/`Approved` in Jira.

**Exit criteria**
- Every in-scope test case (§2.1) has been executed at least once and recorded in Jira.
- No open blocking defect against US1 (organization selection/gating) or US2's UI-observable rendering (FS-2354) — these gate the epic's core value.
- Any failure on US4 (telemetry display, P3) is triaged but does not block sign-off, per the spec's own priority ordering.
- Gaps in §2.2 are explicitly acknowledged (not silently treated as "tested") in the close-out report.

---

## 6. Test Case Groups & Traceability

Each row maps this plan's coverage to the underlying spec item(s) and the published Jira Test issue.

| # | Jira Key | Scenario | Traceability |
|---|---|---|---|
| 1 | [FS-2347](https://safefleet.atlassian.net/browse/FS-2347) | Leased Asset page lists only the Lessor's authorized Lessee Organizations | US1-AC1, FR-001, SC-001 |
| 2 | [FS-2348](https://safefleet.atlassian.net/browse/FS-2348) | No selectable Lessee Organizations shown when the Lessor has none authorized | EC-1, FR-002, FR-003 |
| 3 | [FS-2349](https://safefleet.atlassian.net/browse/FS-2349) | Upload is gated on whether a Lessee Organization is selected | US1-AC2, FR-003, SC-002 |
| 4 | [FS-2350](https://safefleet.atlassian.net/browse/FS-2350) | Selection control allows exactly one selection | US1-AC3, FR-002 |
| 5 | [FS-2351](https://safefleet.atlassian.net/browse/FS-2351) | Changing the selected Lessee Organization updates the displayed selection | US1-AC3, FR-002 |
| 6 | [FS-2352](https://safefleet.atlassian.net/browse/FS-2352) | Successful upload results display live device telemetry per record | US4-AC1, FR-012 |
| 7 | [FS-2353](https://safefleet.atlassian.net/browse/FS-2353) | Missing device telemetry shows blank fields without marking the record as failed | US4-AC2, EC-6, FR-013, SC-006 |
| 8 | [FS-2354](https://safefleet.atlassian.net/browse/FS-2354) | A record matched to an asset leased to a different Lessee Organization is shown as failed | US2-AC3, EC-5 |
| 9 | [FS-2355](https://safefleet.atlassian.net/browse/FS-2355) | Leased Asset page access control is unchanged by this feature | US5-AC1, FR-008, SC-004 |

**Coverage by user story**: US1 — 4 cases · US2 — 1 case (UI-observable rendering only; see §2.2 for the excluded matching-engine coverage) · US3 — 0 cases (no UI surface, see §2.2) · US4 — 2 cases · US5 — 1 case (access-control regression only) · Environment/authorization edge case — 1 case.

---

## 7. Risks, Assumptions & Known Gaps

- **US2's actual pass/fail determination has zero coverage in this plan.** FS-2354 confirms a cross-org match *renders* as a failure, but nothing here exercises the matching engine's decision logic (unassigned-vs-leased-to-selected-org-vs-leased-elsewhere) directly. Recommend a Component-API or Integration pass for US2 before this feature is considered fully verified end-to-end.
- **US3 (Bill to Lessor) has zero coverage in this plan by design** — there is no Lessor-facing UI to test; verification belongs at Component-API/Integration (persistence + downstream query availability).
- **Telemetry scenarios (FS-2352, FS-2353) depend on live device data availability**, consistent with FS-2120's existing pattern — testers need access to an environment where device telemetry can be reliably present or reliably absent on demand.
- **No dedicated test exists yet for SC-003** (100% of cross-org records rejected) beyond the single rendering check in FS-2354 — flagged as a gap, not silently assumed passing.
- **No dedicated test exists for SC-005** (100% of persisted records carry a queryable Bill to Lessor indicator) — this is backend-only and out of scope here (see §2.2).

---

## 8. Roles & Responsibilities

- **Owning team**: Fus1on Avengers
- **Test execution & result logging**: QA / manual testers assigned in Jira against FS-2347–FS-2355
- **Fix version**: `TM-08.31.26`
- **Test category**: Release Validation
- **Provenance**: Test cases and this plan are AI Influenced / Assisted (generated from spec.md, human-reviewed and approved before publication)

---

## 9. Deliverables

1. [component-ui-test-cases.md](./tests/component-ui-test-cases.md) — 9 Gherkin-based manual test cases (source of truth for scenario content)
2. This test plan (`test-plan.md`)
3. 9 Zephyr Test issues in Jira project FS, parented to [FS-2324](https://safefleet.atlassian.net/browse/FS-2324): FS-2347–FS-2355
4. A close-out note recording pass/fail per case and an explicit statement of the §2.2/§7 gaps at sign-off time

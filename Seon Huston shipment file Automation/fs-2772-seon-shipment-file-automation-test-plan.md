# Test Plan: SEON Houston Shipment File Processing, Validation & Notification Automation (FS-2772)

**Feature**: `FS-2772-seon-shipment-file-automation`
**Jira Epic**: [FS-2772](https://safefleet.atlassian.net/browse/FS-2772) — SEON Houston Shipment File Processing, Validation & Notification Automation
**Components under test**: px-asset-service (customer shipment processing, PRIMAX receipts, audit, error file, notification trigger), px-web-app-api (super-admin shipment upload), the shared intake mailbox (FS-2428 intake Lambda), the asset database (PostgreSQL), the device registry (DDP), Fus1on Billing (transfer notifications), px-notification-service (emails, reused unchanged), and environment configuration (px-app-config)
**Spec source**: `specs/FS-2772-seon-shipment-file-automation/spec.md` (fus1on-sdd repo, branch `FS-2772-seon-shipment-file-automation`, ratified 2026-09-27, re-ratified `@v2` 2026-09-30)
**Test case sources**: [fs-2772-seon-shipment-file-automation-integration-test-cases.md](./fs-2772-seon-shipment-file-automation-integration-test-cases.md) (61 cases) and [fs-2772-seon-shipment-file-automation-component-api-test-cases.md](./fs-2772-seon-shipment-file-automation-component-api-test-cases.md) (12 cases), copied from the spec's `tests/` folder and reviewed on the [FS-2772 Test Case Review](https://claude.ai/artifact/5K522VyaqpqABdQN3qDoSo) page
**Test levels in this plan**: Integration and Component API. No UI ships with this feature: outcomes reach people only through the notification email and the audit trail.
**Status**: All 73 cases published as Zephyr Test issues **FS-2848–FS-2920**, parented under Epic FS-2772, workflow status **Approved**.

---

## 1. Purpose

Validate that customer shipment files from the Houston Shipment Team (the "SEON Houston team") in the new 12-column layout are received by email or web app upload, checked row by row, and delivered to the right customer account without anyone starting processing by hand. Devices already received from PRIMAX are **transferred** out of the Road Ready holding account (with their placeholder trailer and attached assets). Devices not yet in Fus1on are **created** in the customer's account. Shipments to PSI land in the PSI holding account and can be forwarded on. Every invalid row must be rejected with its specific reason while the file carries on. Every run must produce exactly one email (with an error file when rows fail) and a complete audit record. Resending a file must be safe. The existing AS500 and PRIMAX processing must keep their current results.

---

## 2. Scope

### 2.1 In Scope (covered by this test plan and its 73 test cases)

| Group | Area | User Story / Requirement | Jira Keys |
|---|---|---|---|
| A. Intake and routing | Mailbox routes each file by its headers, two attachments are two runs, untrusted senders dropped, submitter recorded, web app upload processed the same way | US1-AC1, US1-AC8, US1-AC9, EC-3, EC-4, FR-002, FR-003, FR-021, EC-5, FR-001 | FS-2860, FS-2861, FS-2862, FS-2863, FS-2864 |
| B. Record limit and environment gates | 10,001 rows rejected whole, exactly 10,000 processed, limit changed by configuration, processing refused when switched off or PSI holding missing, header-only file | US1-AC7, US3-AC4, FR-014, FR-020, US1-AC6, SC-002, FR-026, SC-005, EC-16 | FS-2865, FS-2866, FS-2867, FS-2868, FS-2869 |
| C. Device type and field validation | Part-number mapping decides type, gateway IMEI/ICCID rules, shared IMEI rule, sensor identifiers, order fields and Shipping Date, customer IDs, several failures on one row | US1-AC2, US1-AC3, FR-004, FR-005, US2-AC2, EC-7, FR-006, SC-004, US2-AC1, US2-AC3, EC-6, EC-8, FR-006a, US2-AC10, US2-AC12, EC-20, EC-21, EC-22, FR-008, FR-008a, US2-AC9, EC-11, EC-12, FR-012, FR-013, US2-AC11, EC-13, FR-009 | FS-2870, FS-2871, FS-2872, FS-2873, FS-2874, FS-2875, FS-2876 |
| D. Device resolution and duplicates | Row disagrees with existing device, identifier already used, same device twice in a file, simultaneous files, device already delivered is skipped | EC-2, FR-007, FR-022, SC-003, US2-AC6, EC-9, US2-AC7, US2-AC8, US2-AC5, FR-028 | FS-2852, FS-2853, FS-2877, FS-2878, FS-2879, FS-2882 |
| E. Delivery: transfer and creation | Gateway moves from Road Ready holding with everything attached, new gateway and new sensor created, partial move rolled back | US1-AC4, EC-18, EC-19, FR-013, FR-022, FR-023, FR-025, FR-027, SC-010, SC-011, US1-AC5, EC-17, FR-013a, US2-AC3, FR-006a, EC-14, FR-010, FR-011 | FS-2848, FS-2849, FS-2850, FS-2851 |
| F. Device registry (DDP) | Refused registration rolls the device back, 'already exists' is success, no double registration, old history does not block | FR-010, FR-030 | FS-2856, FS-2857, FS-2858, FS-2859 |
| G. Billing | One transfer notification per batch, billing outage never fails the shipment, shipment record keeps billing values | US1-AC10, FR-024, FR-027, SC-011, FR-024a, FR-025, SC-012 | FS-2854, FS-2855, FS-2896 |
| H. Transferability and correction | Devices in customer accounts cannot be shipped elsewhere, no shipping to Road Ready holding, wrong-customer correction by resend, correction stopped by install, stale resend after PSI forward | US2-AC4, US6-AC5, FR-023, US6-AC4, FR-024, SC-013, FR-022, EC-1 | FS-2880, FS-2881, FS-2883, FS-2884, FS-2885 |
| I. PSI holding account | Shipments to PSI land in PSI holding, PSI forwards to its customer, PSI holding set up per environment | US5-AC1, FR-013, FR-026, US5-AC2, FR-023, FR-024, US5-AC3 | FS-2886, FS-2887, FS-2888 |
| J. Resend and recovery | Unchanged resend changes nothing, fixed rows delivered on resend, exhausted retries reported, interrupted run resumes without doubling | US6-AC1, FR-028, SC-003, SC-013, US6-AC2, EC-10, US6-AC3, FR-029, SC-005, FR-024, SC-002 | FS-2889, FS-2890, FS-2891, FS-2892 |
| K. Audit trail | Run recorded before processing, counts add up, stopped run never looks complete, failed rows retrievable without email, no shipment data in logs | US4-AC1, FR-016, US4-AC2, FR-028, SC-007, US4-AC3, US4-AC4, FR-015 | FS-2897, FS-2898, FS-2899, FS-2900, FS-2901 |
| L. Notifications and error file | One email per run with counts, error file lists exactly the failed rows, no spreadsheet formulas, uploader copied, configuration-driven recipients and messages, email failure keeps results | US3-AC1, US3-AC3, FR-017, FR-018, FR-019, SC-005, SC-006, US3-AC2, US3-AC5, FR-015, US3-AC6, SC-008, EC-15, FR-016 | FS-2902, FS-2903, FS-2904, FS-2905, FS-2906, FS-2907 |
| M. Regression: PRIMAX, AS500 and database upgrade | PRIMAX receipts and resend, PRIMAX retry failure, AS500 unchanged, database upgrade on existing data | US6-AC6, FR-017, FR-021, FR-025, FR-028, SC-012, FR-029, SC-005, US1-AC8, SC-009 | FS-2893, FS-2894, FS-2895, FS-2908 |
| P1. Component API: web app upload | Super-admin upload accepted, wrong columns, 10,000-row limit, header-only, over 10 MB, non-super-admin refused | US1-AC1, FR-001, FR-002, US1-AC7, FR-003, FR-020, US1-AC6, FR-014, SC-005, EC-16, FR-031 | FS-2909, FS-2910, FS-2911, FS-2912, FS-2913, FS-2914 |
| P2. Component API: asset service import | Super-admin import recorded, non-super-admin refused, feature switched off, empty request, old FS-2430 format, mailbox hand-off accepted | FR-001, FR-031, SC-005, FR-020, FR-002, US1-AC1 | FS-2915, FS-2916, FS-2917, FS-2918, FS-2919, FS-2920 |

### 2.2 Out of Scope for this plan (tracked as gaps — see §7)

| Area | Why excluded here | Requires |
|---|---|---|
| Re-tenanting a transferred device in the device registry (DDP), including the PSI indicator | Separate Epic, pending on DDP; this plan only confirms the registry tenant is **unchanged** in phase 1 (FR-027) | The DDP re-tenant Epic's own test plan — and it is a release prerequisite for FS-2772 |
| Billing's handling of re-deliveries and PSI-holding forwards | Billing team work item (research O8, raised by T097); this plan confirms billing is **notified**, not that billing corrects its records | Billing team verification; conditional release gate (FR-024a) |
| Moving AS500 onto the 12-column layout, or retiring the 10-column layout | Out of scope per spec; AS500 is regression-tested only (FS-2895) | A later change |
| Associating a BLE sensor with a gateway or asset | Sensors are received as inventory only | Future feature |
| Any user interface for viewing runs | None exists; outcomes are checked through email and the database | Not applicable |
| Returning devices to a holding account, or correcting devices outside the same-shipment re-delivery rule | Out of scope per spec | Not applicable |
| A support tool to re-run a failed run or re-send a lost email | Recovery is by resending the file (FR-029) | Not applicable |
| Pre-existing issues found during review (AS500 re-creates devices on resend; weekly org-to-org transfer report; JobRunr dashboard without password) | Recorded for their owners, not part of this feature | Their owning teams |
| End-to-end validation and rollout tasks (FS-2797) | Feature gates run by hand after the three repos ship; not dispatchable | FS-2797's own task list |

---

## 3. Test Approach

- **Method**: Execution of all 73 Gherkin scenarios (61 Integration, 12 Component API), logged per scenario in Jira. Most cases are marked `Automation Recommendation: Candidate`, meaning they suit the development team's automated integration and component API tests. 5 cases are `Do Not Automate` and must always be run by hand: FS-2862, FS-2867, FS-2872, FS-2888, FS-2906.
- **Technique**: Black-box, behaviour-driven (Given/When/Then). Outcomes are checked only through what can be observed: the API response, the run and shipment records in the database, device and account state, the device registry and billing requests, the notification email and its error file, and the application logs.
- **Shared background (Integration)**: asset service, device registry, billing and email notifications running; customer shipment processing switched on with a 10,000-record limit; support recipients known; PSI holding and Road Ready holding accounts configured; part numbers mapped to TrackRR Lite, TrackRR Gateway and a sensor type; two customers each with one active main account.
- **Shared background (Component API)**: the web app API and asset service are reachable; customer shipment processing is switched on; callers with and without super-admin rights are available.
- **Execution record**: each scenario is its own Zephyr Test issue in Jira project **FS**, under Epic FS-2772.
- **Order of execution**: Group M (AS500/PRIMAX regression and database upgrade) first, against the baseline captured before the change. Then the Component API groups (P1, P2), then A (intake), B (limits and gates), C (validation), D (device resolution), E (delivery), F (registry), G (billing), H (transferability and correction), I (PSI), J (resend and recovery), K (audit) and L (notifications), which checks emails produced by the earlier runs.
- **Total estimated manual effort (EMTE)**: 53.5 hours across 73 cases.

---

## 4. Environments & Platforms

- **Services**: px-asset-service, px-web-app-api and px-app-config at the FS-2772 builds; the FS-2428 intake mailbox enabled for the environment; px-notification-service unchanged.
- **Configuration**: customer shipment processing switch on (and off for the gate case); record limit 10,000 (and a changed value for FS-2867); support recipient list; PSI holding organization key; Road Ready holding account (read from the PRIMAX configuration); IMEI/ICCID rules shared with AS500; error descriptions.
- **Accounts and data**: PSI holding organization and main account created in the environment (FR-026); two customer organizations with known customer IDs; an inactive customer and a customer ID with two main accounts (for the customer ID failures); part-number mappings (dummy values in lower environments) for TrackRR Lite, TrackRR Gateway variants and a sensor type, plus one unmapped part number.
- **Devices**: gateways received from PRIMAX sitting in Road Ready holding (some with attached assets and loose sensors); devices already delivered to a customer (some installed on a real asset, some moved by organization transfer); deleted devices and devices whose identifiers are reused, for duplicate checks.
- **Stand-ins**: a controllable device registry (DDP) and billing endpoint that can return errors, time out or answer "DEVICE_ALREADY_EXISTS"; access to the support mailbox to read notifications and error files.
- **Access**: an approved sender address for the intake mailbox plus an unapproved one; super-admin and non-super-admin users of the web app.
- **Test files**: 12-column files (any column order); AS500 10-column files; PRIMAX files; the old FS-2430 11-column file; header-only files; files of exactly 10,000 and 10,001 rows; a file over 10 MB; files with every validation failure in Groups C and D; and a regression baseline for AS500 and PRIMAX captured **before** the change (SC-009). Large files should be generated by script.

---

## 5. Entry / Exit Criteria

**Entry criteria**
- px-app-config (FS-2789), px-web-app-api (FS-2790) and the px-asset-service Stories FS-2791 to FS-2796 are deployed to the test environment.
- The AS500 and PRIMAX regression baseline was captured before the change.
- The PSI holding organization and account exist and are configured; part-number mappings are seeded.
- The intake mailbox is enabled for the environment, with approved senders configured.
- Test data and files per §4 are ready.
- All 73 Zephyr Test issues (FS-2848–FS-2920) exist under Epic FS-2772 at workflow status `Approved` — confirmed.

**Exit criteria**
- Every case in Groups A–M and P1–P2 has been run at least once and its result recorded in Jira.
- No open blocking defect in Groups C, D, E or H. These protect the epic's core promise: no duplicate devices, and no device moved to the wrong account (SC-003, SC-004, SC-010).
- No open blocking defect in Group M. A change in AS500 or PRIMAX results affects files already in production use (SC-009).
- Every run in the test cycle produced exactly one email whose counts add up (SC-005), and every run with failures carried a matching error file (SC-006).
- The release prerequisites in §7 are confirmed, or accepted in writing by engineering review, and the §2.2 gaps are acknowledged in the close-out report.

---

## 6. Test Case Groups & Traceability

| # | Jira Key | Group | Test Level | Scenario | EMTE (h) | Automation | Traceability |
|---|---|---|---|---|---|---|---|
| 1 | [FS-2848](https://safefleet.atlassian.net/browse/FS-2848) | E | Integration | Gateway waiting in Road Ready holding moves to the customer with everything attached to it | 0.5 | Candidate | US1-AC4, EC-18, EC-19, FR-013, FR-022, FR-023, FR-025, FR-027, SC-010, SC-011 |
| 2 | [FS-2849](https://safefleet.atlassian.net/browse/FS-2849) | E | Integration | New gateway not yet in Fus1on is created in the customer's account | 0.5 | Candidate | US1-AC5, EC-17, FR-013a, SC-010 |
| 3 | [FS-2850](https://safefleet.atlassian.net/browse/FS-2850) | E | Integration | New BLE sensor is created inactive and not attached to anything | 0.5 | Candidate | US1-AC5, US2-AC3, FR-006a, FR-013a, SC-010 |
| 4 | [FS-2851](https://safefleet.atlassian.net/browse/FS-2851) | E | Integration | Gateway that can only be partly moved is not moved at all and the file keeps going | 0.5 | Candidate | EC-14, FR-010, FR-011, FR-022 |
| 5 | [FS-2852](https://safefleet.atlassian.net/browse/FS-2852) | D | Integration | Two files shipping the same gateway at the same time move it only once | 0.5 | Candidate | EC-2, FR-007, FR-022, SC-003 |
| 6 | [FS-2853](https://safefleet.atlassian.net/browse/FS-2853) | D | Integration | Two files creating the same new device at the same time create it only once | 0.5 | Candidate | FR-007, SC-003 |
| 7 | [FS-2854](https://safefleet.atlassian.net/browse/FS-2854) | G | Integration | Billing is told about transferred devices once per batch | 0.5 | Candidate | US1-AC10, FR-024, FR-027, SC-011 |
| 8 | [FS-2855](https://safefleet.atlassian.net/browse/FS-2855) | G | Integration | Billing being unavailable never fails the shipment | 1.0 | Candidate | FR-024, SC-011 |
| 9 | [FS-2856](https://safefleet.atlassian.net/browse/FS-2856) | F | Integration | Device the registry refuses is not kept and the row fails | 1.5 | Candidate | FR-010, FR-030 |
| 10 | [FS-2857](https://safefleet.atlassian.net/browse/FS-2857) | F | Integration | Registry answer "already exists" counts as a successful registration | 0.5 | Candidate | FR-030 |
| 11 | [FS-2858](https://safefleet.atlassian.net/browse/FS-2858) | F | Integration | Device already registered for the customer is not registered a second time | 0.5 | Candidate | FR-030 |
| 12 | [FS-2859](https://safefleet.atlassian.net/browse/FS-2859) | F | Integration | Old registry history does not block re-creating a device that was rolled back | 0.5 | Candidate | FR-030 |
| 13 | [FS-2860](https://safefleet.atlassian.net/browse/FS-2860) | A | Integration | Files emailed to the intake mailbox go to the right processing by their column headers | 1.5 | Candidate | US1-AC1, US1-AC8, US1-AC9, EC-3, EC-4, FR-002, FR-003, FR-021 |
| 14 | [FS-2861](https://safefleet.atlassian.net/browse/FS-2861) | A | Integration | One email with an AS500 file and an FS-2772 file is handled as two separate runs | 0.5 | Candidate | EC-5, FR-003 |
| 15 | [FS-2862](https://safefleet.atlassian.net/browse/FS-2862) | A | Integration | Emails from untrusted senders are dropped without a run or a notification | 1.0 | Do Not Automate | FR-001 |
| 16 | [FS-2863](https://safefleet.atlassian.net/browse/FS-2863) | A | Integration | Each run records who submitted it | 0.5 | Candidate | FR-001 |
| 17 | [FS-2864](https://safefleet.atlassian.net/browse/FS-2864) | A | Integration | Uploading in the web app gives the same results as emailing the file | 0.5 | Candidate | FR-001, FR-002 |
| 18 | [FS-2865](https://safefleet.atlassian.net/browse/FS-2865) | B | Integration | Emailed file with more than 10000 rows is rejected whole | 0.5 | Candidate | US1-AC7, US3-AC4, FR-014, FR-020 |
| 19 | [FS-2866](https://safefleet.atlassian.net/browse/FS-2866) | B | Integration | File with exactly 10000 rows is processed in full | 0.5 | Candidate | US1-AC6, FR-014, SC-002 |
| 20 | [FS-2867](https://safefleet.atlassian.net/browse/FS-2867) | B | Integration | Record limit can be changed in configuration without a new build | 0.5 | Do Not Automate | FR-014 |
| 21 | [FS-2868](https://safefleet.atlassian.net/browse/FS-2868) | B | Integration | Emailed file is refused when shipment processing or the PSI holding setup is not available | 1.0 | Candidate | FR-026, SC-005 |
| 22 | [FS-2869](https://safefleet.atlassian.net/browse/FS-2869) | B | Integration | Emailed file with only a header row still produces a run and an email | 0.5 | Candidate | EC-16, FR-020 |
| 23 | [FS-2870](https://safefleet.atlassian.net/browse/FS-2870) | C | Integration | Device type comes only from the part-number mapping | 1.5 | Candidate | US1-AC2, US1-AC3, FR-004, FR-005 |
| 24 | [FS-2871](https://safefleet.atlassian.net/browse/FS-2871) | C | Integration | Gateway IMEI and ICCID are checked exactly as AS500 checks them | 1.5 | Candidate | US2-AC2, EC-7, FR-004, FR-006, SC-004 |
| 25 | [FS-2872](https://safefleet.atlassian.net/browse/FS-2872) | C | Integration | Changing the IMEI rule changes AS500 and customer shipments together | 0.5 | Do Not Automate | FR-006 |
| 26 | [FS-2873](https://safefleet.atlassian.net/browse/FS-2873) | C | Integration | Sensor rows need a Sensor ID or an IMEI | 1.5 | Candidate | US2-AC1, US2-AC3, EC-6, EC-8, FR-006a, SC-004 |
| 27 | [FS-2874](https://safefleet.atlassian.net/browse/FS-2874) | C | Integration | Order numbers and Shipping Date are checked | 1.5 | Candidate | US2-AC10, US2-AC12, EC-20, EC-21, EC-22, FR-008, FR-008a, SC-004 |
| 28 | [FS-2875](https://safefleet.atlassian.net/browse/FS-2875) | C | Integration | Customer IDs decide which customer gets the device | 1.5 | Candidate | US2-AC9, EC-11, EC-12, FR-008, FR-012, FR-013, SC-004 |
| 29 | [FS-2876](https://safefleet.atlassian.net/browse/FS-2876) | C | Integration | Row with several problems reports all of them, in order | 1.0 | Candidate | US2-AC11, EC-13, FR-009 |
| 30 | [FS-2877](https://safefleet.atlassian.net/browse/FS-2877) | D | Integration | Row that disagrees with the device Fus1on already has is rejected | 1.0 | Candidate | US2-AC6, EC-9, FR-007 |
| 31 | [FS-2878](https://safefleet.atlassian.net/browse/FS-2878) | D | Integration | New device is refused if one of its identifiers already belongs to another device | 1.5 | Candidate | US2-AC7, FR-007, SC-003 |
| 32 | [FS-2879](https://safefleet.atlassian.net/browse/FS-2879) | D | Integration | When a file lists the same device twice, the first good row wins | 1.0 | Candidate | US2-AC8, FR-007 |
| 33 | [FS-2880](https://safefleet.atlassian.net/browse/FS-2880) | H | Integration | Device sitting in a customer's account cannot be shipped to another customer | 1.5 | Candidate | US2-AC4, US6-AC5, FR-023 |
| 34 | [FS-2881](https://safefleet.atlassian.net/browse/FS-2881) | H | Integration | Devices cannot be shipped to the Road Ready holding account | 0.5 | Candidate | FR-023 |
| 35 | [FS-2882](https://safefleet.atlassian.net/browse/FS-2882) | D | Integration | Device the customer already has is skipped, not failed | 0.5 | Candidate | US2-AC5, FR-028 |
| 36 | [FS-2883](https://safefleet.atlassian.net/browse/FS-2883) | H | Integration | Device sent to the wrong customer is corrected by resending the same shipment | 1.5 | Candidate | US6-AC4, US6-AC5, FR-023, FR-024, SC-013 |
| 37 | [FS-2884](https://safefleet.atlassian.net/browse/FS-2884) | H | Integration | Correction stops if the device is installed while it is being processed | 0.5 | Candidate | FR-022, FR-023 |
| 38 | [FS-2885](https://safefleet.atlassian.net/browse/FS-2885) | H | Integration | Resending an older file does not pull back a device PSI has already forwarded | 0.5 | Candidate | EC-1, FR-023 |
| 39 | [FS-2886](https://safefleet.atlassian.net/browse/FS-2886) | I | Integration | Shipment to PSI lands in the PSI holding account | 1.0 | Candidate | US5-AC1, FR-013, FR-026 |
| 40 | [FS-2887](https://safefleet.atlassian.net/browse/FS-2887) | I | Integration | PSI can forward a device on to its own customer | 0.5 | Candidate | US5-AC2, FR-023, FR-024 |
| 41 | [FS-2888](https://safefleet.atlassian.net/browse/FS-2888) | I | Integration | PSI holding account is set up in every environment | 0.5 | Do Not Automate | US5-AC3, FR-026 |
| 42 | [FS-2889](https://safefleet.atlassian.net/browse/FS-2889) | J | Integration | Resending a file unchanged changes nothing and reports no failures | 0.5 | Candidate | US6-AC1, FR-028, SC-003, SC-013 |
| 43 | [FS-2890](https://safefleet.atlassian.net/browse/FS-2890) | J | Integration | Resending after fixing failed rows delivers the fixed rows and skips the rest | 0.5 | Candidate | US6-AC2, EC-10, FR-028 |
| 44 | [FS-2891](https://safefleet.atlassian.net/browse/FS-2891) | J | Integration | Run that keeps failing is marked failed and support is told to resend | 0.5 | Candidate | US6-AC3, FR-029, SC-005 |
| 45 | [FS-2892](https://safefleet.atlassian.net/browse/FS-2892) | J | Integration | Run interrupted part-way picks up without doubling anything | 0.5 | Candidate | FR-024, SC-002, SC-003 |
| 46 | [FS-2893](https://safefleet.atlassian.net/browse/FS-2893) | M | Integration | PRIMAX file records devices as received and skips them when resent | 0.5 | Candidate | US6-AC6, FR-017, FR-021, FR-025, FR-028, SC-012 |
| 47 | [FS-2894](https://safefleet.atlassian.net/browse/FS-2894) | M | Integration | PRIMAX run that keeps failing is marked failed and support is told | 0.5 | Candidate | FR-021, FR-029, SC-005 |
| 48 | [FS-2895](https://safefleet.atlassian.net/browse/FS-2895) | M | Integration | AS500 files give exactly the same results as before this change | 0.5 | Candidate | US1-AC8, FR-021, SC-009 |
| 49 | [FS-2896](https://safefleet.atlassian.net/browse/FS-2896) | G | Integration | Shipment record keeps every value billing and reporting need | 0.5 | Candidate | FR-024a, FR-025, SC-012 |
| 50 | [FS-2897](https://safefleet.atlassian.net/browse/FS-2897) | K | Integration | Run is recorded in the database before any row is processed | 0.5 | Candidate | US4-AC1, FR-016 |
| 51 | [FS-2898](https://safefleet.atlassian.net/browse/FS-2898) | K | Integration | Finished run shows counts that add up and the right status | 0.5 | Candidate | US4-AC2, FR-016, FR-028, SC-007 |
| 52 | [FS-2899](https://safefleet.atlassian.net/browse/FS-2899) | K | Integration | Run that stopped part-way never looks like it completed | 0.5 | Candidate | US4-AC3, FR-016, SC-007 |
| 53 | [FS-2900](https://safefleet.atlassian.net/browse/FS-2900) | K | Integration | Failed rows and their reasons can be looked up without the email | 0.5 | Candidate | US4-AC4, FR-015, FR-016, SC-007 |
| 54 | [FS-2901](https://safefleet.atlassian.net/browse/FS-2901) | K | Integration | Shipment data never appears in application logs | 0.5 | Candidate | FR-016 |
| 55 | [FS-2902](https://safefleet.atlassian.net/browse/FS-2902) | L | Integration | Clean run sends one email with the full counts and no attachment | 0.5 | Candidate | US3-AC1, US3-AC3, FR-017, FR-018, FR-019, SC-005, SC-006 |
| 56 | [FS-2903](https://safefleet.atlassian.net/browse/FS-2903) | L | Integration | Run with failures sends the error file listing exactly the failed rows | 0.5 | Candidate | US3-AC2, US3-AC5, FR-015, FR-018, SC-006 |
| 57 | [FS-2904](https://safefleet.atlassian.net/browse/FS-2904) | L | Integration | Error file cannot run spreadsheet formulas | 1.5 | Candidate | FR-015 |
| 58 | [FS-2905](https://safefleet.atlassian.net/browse/FS-2905) | L | Integration | Web app uploads also email the uploader's contact address | 0.5 | Candidate | US3-AC1, FR-019 |
| 59 | [FS-2906](https://safefleet.atlassian.net/browse/FS-2906) | L | Integration | Email recipients and error messages change through configuration and a restart | 1.5 | Do Not Automate | US3-AC6, FR-015, FR-019, SC-008 |
| 60 | [FS-2907](https://safefleet.atlassian.net/browse/FS-2907) | L | Integration | If the email cannot be sent, the run's results are still saved | 1.0 | Candidate | EC-15, FR-016, FR-019 |
| 61 | [FS-2908](https://safefleet.atlassian.net/browse/FS-2908) | M | Integration | Database upgrade works on a database that already holds shipment data | 0.5 | Candidate | FR-021, SC-009 |
| 62 | [FS-2909](https://safefleet.atlassian.net/browse/FS-2909) | P1 | Component API | Super-admin's 12-column file is accepted and passed on with all 12 values | 0.5 | Candidate | US1-AC1, FR-001, FR-002 |
| 63 | [FS-2910](https://safefleet.atlassian.net/browse/FS-2910) | P1 | Component API | File with the wrong columns is refused straight away | 1.0 | Candidate | US1-AC7, FR-002, FR-003, FR-020 |
| 64 | [FS-2911](https://safefleet.atlassian.net/browse/FS-2911) | P1 | Component API | Upload limit of 10000 rows is enforced | 1.0 | Candidate | US1-AC6, US1-AC7, FR-014, FR-020, SC-005 |
| 65 | [FS-2912](https://safefleet.atlassian.net/browse/FS-2912) | P1 | Component API | File with a header but no rows is refused straight away | 0.5 | Candidate | EC-16, FR-020, SC-005 |
| 66 | [FS-2913](https://safefleet.atlassian.net/browse/FS-2913) | P1 | Component API | File larger than 10 MB is refused straight away | 0.5 | Candidate | FR-020, SC-005 |
| 67 | [FS-2914](https://safefleet.atlassian.net/browse/FS-2914) | P1 | Component API | Non-super-admin upload is refused with 403 | 0.5 | Candidate | FR-031 |
| 68 | [FS-2915](https://safefleet.atlassian.net/browse/FS-2915) | P2 | Component API | Super-admin import is accepted and recorded as a customer shipment run | 0.5 | Candidate | FR-001, FR-031 |
| 69 | [FS-2916](https://safefleet.atlassian.net/browse/FS-2916) | P2 | Component API | Import from a non-super-admin is refused with 403 and nothing is recorded | 0.5 | Candidate | FR-031 |
| 70 | [FS-2917](https://safefleet.atlassian.net/browse/FS-2917) | P2 | Component API | Import is refused with 404 and an empty response while the feature is switched off | 0.5 | Candidate | SC-005 |
| 71 | [FS-2918](https://safefleet.atlassian.net/browse/FS-2918) | P2 | Component API | Empty import request is refused with 400 | 0.5 | Candidate | FR-020, SC-005 |
| 72 | [FS-2919](https://safefleet.atlassian.net/browse/FS-2919) | P2 | Component API | Import in the old FS-2430 format is refused | 0.5 | Candidate | FR-002 |
| 73 | [FS-2920](https://safefleet.atlassian.net/browse/FS-2920) | P2 | Component API | File handed over by the intake mailbox is accepted with 202 and a run number | 0.5 | Candidate | US1-AC1, FR-001 |

**Coverage by user story**: US1 — 13 cases · US2 — 11 cases · US3 — 5 cases · US4 — 4 cases · US5 — 3 cases · US6 — 6 cases · Cases with no user-story code (edge cases, FR/SC only) — 34

---

## 7. Risks, Assumptions & Known Gaps

- **Release is blocked on the DDP re-tenant Epic.** In phase 1, devices move between accounts in Fus1on only; their registry tenant does not change. FS-2772 must not reach users until that Epic ships (FR-027).
- **Billing may not correct re-deliveries or PSI forwards.** Billing is notified, but its handling of these moves is a separate billing-team work item (research O8). Until it is resolved, a re-delivery fixes the account in Fus1on but possibly not in billing (FR-024a).
- **The intake mailbox is not yet live in production** (FS-2428 production enablement). The email channel cannot be released before it is.
- **Real part numbers are a production data step.** Lower environments use dummy mappings; a device-type failure in production may be missing data rather than a defect.
- **Race-condition cases need tooling.** FS-2852 and FS-2853 (two files for the same device at once) need parallel submissions, not manual timing.
- **Large-file cases need generated data.** 10,000 / 10,001-row and 10 MB files should be produced by script before the session.
- **Configuration-change cases need restarts.** FS-2867, FS-2872 and FS-2906 change configuration and restart the asset service; schedule them where a restart is acceptable.
- **The regression baseline must exist first.** Without a pre-change AS500/PRIMAX baseline, Group M cannot be judged (SC-009).
- **The audit trail is the source of truth.** If an email is lost, the run is still in the database (FS-2907); there is no tool to re-send a lost email.
- **Provenance**: this plan and its test cases were generated with AI assistance from `spec.md`; every case was human-reviewed and approved before Jira publication.

---

## 8. Roles & Responsibilities

- **Owning team**: Fus1on Telemetricians (component Telemetricians)
- **Development stories**: FS-2789 (px-app-config), FS-2790 (px-web-app-api), FS-2791–FS-2796 (px-asset-service), FS-2797 (end-to-end validation and rollout, not dispatchable)
- **Test execution and result logging**: QA testers assigned in Jira against FS-2848–FS-2920
- **Test category**: Release Validation
- **AI involvement**: AI Influenced / Assisted

---

## 9. Deliverables

1. [fs-2772-seon-shipment-file-automation-integration-test-cases.md](./fs-2772-seon-shipment-file-automation-integration-test-cases.md) — 61 Gherkin Integration test cases
2. [fs-2772-seon-shipment-file-automation-component-api-test-cases.md](./fs-2772-seon-shipment-file-automation-component-api-test-cases.md) — 12 Gherkin Component API test cases
3. This test plan, in Markdown and Word (`fs-2772-seon-shipment-file-automation-test-plan.md` / `.docx`)
4. 73 Zephyr Test issues in Jira project FS, parented to [FS-2772](https://safefleet.atlassian.net/browse/FS-2772): **FS-2848–FS-2920**, workflow status `Approved`
5. A close-out note recording pass/fail per case and the status of every §7 release prerequisite

---

## Appendix A. BDD Test Cases

Each case below is the approved Gherkin scenario exactly as published to its Jira Test issue. The shared Background for each test level is listed first.

### Integration — shared Background

```gherkin
Background:
Given the asset service, device registry, billing and email notifications are running
And customer shipment processing is switched on with a limit of 10000 records per file
And shipment emails go to the support recipients {support recipients}
And the PSI holding account exists and is configured for this environment
And the Road Ready holding account is configured as the account where PRIMAX devices arrive
And part numbers {Lite part number}, {Gateway part number} and {Sensor part number} are mapped to TrackRR Lite, TrackRR Gateway and a sensor type
And customers {Customer A} with customer ID {Customer A ID} and {Customer B} with customer ID {Customer B ID} each have one active main account
```

#### FS-2848 — Gateway waiting in Road Ready holding moves to the customer with everything attached to it

**Group**: E · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: US1-AC4, EC-18, EC-19, FR-013, FR-022, FR-023, FR-025, FR-027, SC-010, SC-011

```gherkin
Scenario: Successful interaction - a gateway already received from PRIMAX is shipped to a customer
  Given gateway {Gateway IMEI} arrived from PRIMAX and is in the Road Ready holding account with its placeholder trailer
  And asset {Attached asset} is attached to the gateway, and sensor {Loose sensor} sits in the same account unattached
  And a shipment file ships {Gateway IMEI} to {Customer A ID}
  When the asset service processes the file
  Then the gateway, its placeholder trailer and {Attached asset} now belong to {Customer A}'s main account
  And {Loose sensor} stays in the Road Ready holding account
  And the shipment record for the gateway says it was transferred from Road Ready holding to {Customer A}
  And the gateway appears in the organization transfer history
  And the gateway's registration in the device registry is unchanged
```

#### FS-2849 — New gateway not yet in Fus1on is created in the customer's account

**Group**: E · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: US1-AC5, EC-17, FR-013a, SC-010

```gherkin
Scenario: Successful interaction - a TrackRR Lite that PRIMAX never sent is created directly for the customer
  Given no device in Fus1on has IMEI {New IMEI} or ICCID {New ICCID}
  And a shipment file has a valid TrackRR Lite row with IMEI {New IMEI}, ICCID {New ICCID} and Ship To {Customer A ID}
  When the asset service processes the file
  Then the TrackRR Lite is created in {Customer A}'s main account with the same placeholder trailer an AS500 file would create
  And the device is registered successfully in the device registry
  And the shipment record for the device says it was created
  And the run reports 1 succeeded
```

#### FS-2850 — New BLE sensor is created inactive and not attached to anything

**Group**: E · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: US1-AC5, US2-AC3, FR-006a, FR-013a, SC-010

```gherkin
Scenario: Successful interaction - a sensor not yet in Fus1on is created for the customer
  Given no device in Fus1on has Sensor ID {New Sensor ID}
  And a shipment file has a sensor row with Sensor ID {New Sensor ID}, no IMEI, no ICCID and Ship To {Customer A ID}
  When the asset service processes the file
  Then the sensor is created as inactive and is visible to {Customer A}
  And the sensor is not attached to any gateway or asset
  And the row is not rejected for having no gateway
  And the shipment record for the sensor says it was created
```

#### FS-2851 — Gateway that can only be partly moved is not moved at all and the file keeps going

**Group**: E · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: EC-14, FR-010, FR-011, FR-022

```gherkin
Scenario: Failure or resilience behavior - part of the gateway's group leaves the holding account during processing
  Given gateway {Gateway IMEI} is in the Road Ready holding account with its placeholder trailer
  And while the file is being processed, one item attached to the gateway is moved out of the holding account
  And the same file has another valid row after the gateway's row
  When the asset service processes the file
  Then the gateway's row fails with code "TRANSFER_FAILED" and a message starting "Device could not be transferred:"
  And nothing in the gateway's group has changed account
  And no shipment or transfer history is written for the gateway
  And the next row in the file is still processed successfully
```

#### FS-2852 — Two files shipping the same gateway at the same time move it only once

**Group**: D · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: EC-2, FR-007, FR-022, SC-003

```gherkin
Scenario: Failure or resilience behavior - two submissions race for the same holding-account gateway
  Given gateway {Gateway IMEI} is in the Road Ready holding account
  And file 1 ships it to {Customer A ID} and file 2 ships it to {Customer B ID} with a different Sales Order Number
  When file 1 arrives by email and file 2 arrives through the web app at the same time
  Then the gateway ends up in exactly one customer's account
  And only one shipment record says it was transferred
  And the other file's row fails with "DEVICE_NOT_TRANSFERABLE"
```

#### FS-2853 — Two files creating the same new device at the same time create it only once

**Group**: D · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: FR-007, SC-003

```gherkin
Scenario: Failure or resilience behavior - two submissions race to create the same device
  Given no device in Fus1on has IMEI {New IMEI}
  And two files each ship {New IMEI} to {Customer A ID}
  When both files are processed at the same time
  Then exactly one device with IMEI {New IMEI} exists in Fus1on
  And only one shipment record says it was created
  And the other file reports the row as skipped or as a duplicate, never as a second device
```

#### FS-2854 — Billing is told about transferred devices once per batch

**Group**: G · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: US1-AC10, FR-024, FR-027, SC-011

```gherkin
Scenario: Successful interaction - billing is notified of the devices moved in a batch
  Given one batch of a file moves {N} gateways from Road Ready holding to {Customer A} and {M} gateways from PSI holding to {Customer B}
  When the batch is saved
  Then billing receives one transfer notification for the batch
  And the notification lists, for each "from account to account" pair, the devices that moved between them
  And no device is listed twice
  And the devices' registrations in the device registry are unchanged
```

#### FS-2855 — Billing being unavailable never fails the shipment

**Group**: G · **Test level**: Integration · **EMTE**: 1.0 h · **Automation**: Candidate · **Traceability**: FR-024, SC-011

```gherkin
Scenario Outline: Interaction variation matrix - billing does not accept the transfer notification
  Given a file moves gateway {Gateway IMEI} from Road Ready holding to {Customer A}
  When the asset service notifies billing and billing <billing problem>
  Then the asset service tries <tries> time(s) in total
  And the gateway's row still counts as succeeded and the gateway stays with {Customer A}
  And the failure is logged with the run number only, and the billing failure counter goes up by 1
  And the run finishes as "Completed"

Examples:
  | billing problem                   | tries |
  | times out every time              | 3     |
  | returns a server error every time | 3     |
  | rejects the request (4xx)         | 1     |
```

#### FS-2856 — Device the registry refuses is not kept and the row fails

**Group**: F · **Test level**: Integration · **EMTE**: 1.5 h · **Automation**: Candidate · **Traceability**: FR-010, FR-030

```gherkin
Scenario Outline: Interaction variation matrix - the device registry refuses a new device
  Given a shipment file has a valid row for new gateway {New IMEI}
  When the asset service registers the device and the device registry <registry answer>
  Then the row fails with code "PROVISIONING_FAILED" and message "Device could not be created: {reason}. Resend the record to retry."
  And no device or placeholder trailer for {New IMEI} is left in Fus1on
  And the file carries on with the next row

Examples:
  | registry answer                                     |
  | returns an error status                             |
  | does not answer in time                             |
  | returns an empty answer                             |
  | returns an error other than "DEVICE_ALREADY_EXISTS" |
```

#### FS-2857 — Registry answer "already exists" counts as a successful registration

**Group**: F · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: FR-030

```gherkin
Scenario: Successful interaction - the device registry already holds the device
  Given a shipment file has a valid row for gateway {New IMEI}, which is not in Fus1on
  And the device registry already holds {New IMEI}
  When the asset service registers the device and the registry answers "DEVICE_ALREADY_EXISTS"
  Then the gateway is created in the customer's account with its placeholder trailer
  And the row counts as succeeded and is not failed with "PROVISIONING_FAILED"
```

#### FS-2858 — Device already registered for the customer is not registered a second time

**Group**: F · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: FR-030

```gherkin
Scenario: Successful interaction - Fus1on's own records show the registry already accepted the device
  Given gateway {Gateway IMEI} is not in Fus1on
  And Fus1on's registration history shows the registry already accepted it for {Customer A}'s tenant
  And a shipment file ships {Gateway IMEI} to {Customer A ID}
  When the asset service processes the file
  Then no new registration request is sent to the device registry
  And the gateway is created in {Customer A}'s account and the row counts as succeeded
```

#### FS-2859 — Old registry history does not block re-creating a device that was rolled back

**Group**: F · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: FR-030

```gherkin
Scenario: Failure or resilience behavior - registry history exists for a device that is not in Fus1on
  Given the registry history has an entry for gateway {Gateway IMEI}, but the device itself is not in Fus1on
  And a shipment file has a valid row for {Gateway IMEI}
  When the asset service processes the file
  Then the row is not treated as a duplicate or as already received
  And the gateway is created again in the customer's account
```

#### FS-2860 — Files emailed to the intake mailbox go to the right processing by their column headers

**Group**: A · **Test level**: Integration · **EMTE**: 1.5 h · **Automation**: Candidate · **Traceability**: US1-AC1, US1-AC8, US1-AC9, EC-3, EC-4, FR-002, FR-003, FR-021

```gherkin
Scenario Outline: Interaction variation matrix - the shared mailbox routes each file by its header
  Given an approved sender emails the intake mailbox a file with <file header>
  When the mailbox hands the file to the asset service
  Then the file is handled by <processing>
  And <result>

Examples:
  | file header                                                      | processing                    | result |
  | the 12 FS-2772 columns, in any order                             | customer shipment processing  | every row is checked |
  | the 10 AS500 columns                                             | the existing AS500 processing | the result is exactly what AS500 gave before this change |
  | the 10 AS500 columns plus an extra Sensor ID column              | the existing AS500 processing | the file is not rejected as a wrong layout |
  | the PRIMAX columns                                               | PRIMAX processing             | each device is recorded as received from the manufacturer |
  | the old FS-2430 11 columns                                       | the existing AS500 processing | the whole file is rejected and support is emailed, as AS500 does today |
  | Sensor ID and Bill To Customer ID but no Agreement Number column | customer shipment processing  | the whole file fails with "The file is missing the required column: Agreement Number" and support is emailed |
```

#### FS-2861 — One email with an AS500 file and an FS-2772 file is handled as two separate runs

**Group**: A · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: EC-5, FR-003

```gherkin
Scenario: Successful interaction - two attachments on one email
  Given an approved sender emails one message with an AS500 file and an FS-2772 file attached
  When the mailbox hands both files to the asset service
  Then two separate runs are created, one per file
  And the AS500 file goes to AS500 processing and the FS-2772 file goes to customer shipment processing
  And support receives one email per run
```

#### FS-2862 — Emails from untrusted senders are dropped without a run or a notification

**Group**: A · **Test level**: Integration · **EMTE**: 1.0 h · **Automation**: Do Not Automate · **Traceability**: FR-001

```gherkin
Scenario Outline: Failure or resilience behavior - the mailbox refuses the message
  Given an FS-2772 file is emailed to the intake mailbox by <sender>
  When the mailbox checks the message
  Then the file never reaches the asset service and no run is created
  And no notification email is sent
  And the refused message is counted so it can be monitored

Examples:
  | sender                                                       |
  | someone not on the approved sender list                      |
  | an approved address that fails email authentication          |
  | an approved sender whose message is flagged as virus or spam |
```

#### FS-2863 — Each run records who submitted it

**Group**: A · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: FR-001

```gherkin
Scenario: Successful interaction - mailbox and web app runs are attributed correctly
  Given one file is emailed to the intake mailbox and another is uploaded in the web app by super-admin {Super Admin}
  When the asset service processes both
  Then the emailed run shows it came from the mailbox and was submitted by the system
  And the uploaded run shows it came from the web app, was submitted by {Super Admin}, and keeps contact email {Contact Email}
```

#### FS-2864 — Uploading in the web app gives the same results as emailing the file

**Group**: A · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: FR-001, FR-002

```gherkin
Scenario: Successful interaction - web app upload is passed to the asset service and processed the same way
  Given super-admin {Super Admin} uploads a 12-column shipment file with {Good rows} valid and {Bad rows} invalid rows and contact email {Contact Email}
  When the web app passes the file to the asset service
  Then the asset service receives all 12 values of every row exactly as typed, including the customer IDs
  And the run is recorded as a customer shipment
  And every row gets the same result it would get if the same file were emailed
```

#### FS-2865 — Emailed file with more than 10000 rows is rejected whole

**Group**: B · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: US1-AC7, US3-AC4, FR-014, FR-020

```gherkin
Scenario: Failure or resilience behavior - mailbox file over the record limit
  Given a shipment file with 10001 rows is emailed to the intake mailbox
  When the asset service reads the file
  Then no row is checked and no device is created or moved
  And the run is marked "Failed" with counts 0 total, 0 succeeded, 0 skipped, 0 failed
  And the reason is "The file contains 10001 records, more than the limit of 10000."
  And support receives one email stating the failure and the reason, with no error file attached
```

#### FS-2866 — File with exactly 10000 rows is processed in full

**Group**: B · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: US1-AC6, FR-014, SC-002

```gherkin
Scenario: Successful interaction - a file at the record limit
  Given a shipment file with exactly 10000 rows is emailed to the intake mailbox
  When the asset service processes it
  Then all 10000 rows are checked in a single run
  And succeeded plus skipped plus failed adds up to 10000
  And the run finishes and support receives exactly one email
```

#### FS-2867 — Record limit can be changed in configuration without a new build

**Group**: B · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Do Not Automate · **Traceability**: FR-014

```gherkin
Scenario: Successful interaction - changing the record limit
  Given the record limit is changed to {New limit} in the environment configuration and the asset service is restarted
  When a shipment file with {New limit} + 1 rows is emailed
  Then the run fails with "The file contains {New limit + 1} records, more than the limit of {New limit}."
  And no code change or new build was needed
```

#### FS-2868 — Emailed file is refused when shipment processing or the PSI holding setup is not available

**Group**: B · **Test level**: Integration · **EMTE**: 1.0 h · **Automation**: Candidate · **Traceability**: FR-026, SC-005

```gherkin
Scenario Outline: Interaction variation matrix - processing refused because of environment setup
  Given <setup problem> and the asset service has been restarted
  When a valid shipment file is emailed to the intake mailbox
  Then no row is checked
  And the run is marked "Failed" with the reason "<reason>"
  And support receives exactly one email stating the reason

Examples:
  | setup problem                                           | reason |
  | customer shipment processing is switched off            | V2 shipment processing is not enabled in this environment. |
  | the PSI holding organization is not configured          | The PSI holding account is not configured in this environment. |
  | the PSI holding organization's main account is inactive | The PSI holding account is not usable in this environment. |
```

#### FS-2869 — Emailed file with only a header row still produces a run and an email

**Group**: B · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: EC-16, FR-020

```gherkin
Scenario: Successful interaction - header-only mailbox file
  Given a shipment file that contains only the 12 column headers is emailed to the intake mailbox
  When the asset service processes it
  Then a run is recorded with 0 total, 0 succeeded, 0 skipped and 0 failed
  And support receives one email for the run
```

#### FS-2870 — Device type comes only from the part-number mapping

**Group**: C · **Test level**: Integration · **EMTE**: 1.5 h · **Automation**: Candidate · **Traceability**: US1-AC2, US1-AC3, FR-004, FR-005

```gherkin
Scenario Outline: Interaction variation matrix - part number decides the device type
  Given <mapping setup>
  When the asset service checks a shipment row with Part Number <part number>
  Then <result>

Examples:
  | mapping setup                                       | part number            | result |
  | the standard mapping                                | {Lite part number}     | the row is treated as a gateway, so IMEI and ICCID are both required |
  | the standard mapping                                | {Gateway part number}  | the row is treated as a gateway, so IMEI and ICCID are both required |
  | the standard mapping                                | {Sensor part number}   | the row is treated as a sensor, so Sensor ID or IMEI is required |
  | the standard mapping                                | {Unmapped part number} | the row fails with "No asset type key mapping found for part number {Unmapped part number}." and the file carries on |
  | the standard mapping                                | blank                  | the row fails with "No Part Number found." |
  | a new mapping row for {New part number} as a sensor | {New part number}      | the row is accepted as a sensor without any code change |
```

#### FS-2871 — Gateway IMEI and ICCID are checked exactly as AS500 checks them

**Group**: C · **Test level**: Integration · **EMTE**: 1.5 h · **Automation**: Candidate · **Traceability**: US2-AC2, EC-7, FR-004, FR-006, SC-004

```gherkin
Scenario Outline: Interaction variation matrix - gateway identifier checks
  Given a <device type> row with IMEI <IMEI> and ICCID <ICCID>
  When the asset service checks the row using the same IMEI and ICCID rules AS500 uses
  Then <result>

Examples:
  | device type     | IMEI                       | ICCID                                   | result |
  | TrackRR Lite    | blank                      | a valid 19-digit ICCID                  | fails with "No IMEI found." |
  | TrackRR Gateway | 14 digits                  | a valid 19-digit ICCID                  | fails with "Invalid IMEI." |
  | TrackRR Gateway | 15 characters with letters | a valid 19-digit ICCID                  | fails with "Invalid IMEI." |
  | TrackRR Gateway | a valid 15-digit IMEI      | blank                                   | fails with "No ICCID found." |
  | TrackRR Gateway | a valid 15-digit IMEI      | 18 digits                               | fails with "Invalid ICCID." |
  | TrackRR Gateway | a valid 15-digit IMEI      | a valid 20-digit ICCID                  | accepted |
  | TrackRR Lite    | a valid 15-digit IMEI      | a valid 19-digit ICCID, plus a Sensor ID | accepted; the Sensor ID is ignored |
```

#### FS-2872 — Changing the IMEI rule changes AS500 and customer shipments together

**Group**: C · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Do Not Automate · **Traceability**: FR-006

```gherkin
Scenario: Successful interaction - one shared IMEI rule for both file types
  Given the IMEI rule is changed to {New IMEI rule} in the environment configuration and the asset service is restarted
  When an AS500 file and an FS-2772 file each contain a gateway with IMEI {IMEI valid only under the new rule}
  Then both files apply the new rule
  And both give the same accept or reject result for that IMEI
```

#### FS-2873 — Sensor rows need a Sensor ID or an IMEI

**Group**: C · **Test level**: Integration · **EMTE**: 1.5 h · **Automation**: Candidate · **Traceability**: US2-AC1, US2-AC3, EC-6, EC-8, FR-006a, SC-004

```gherkin
Scenario Outline: Interaction variation matrix - sensor identifier checks
  Given a sensor row with Sensor ID <Sensor ID>, IMEI <IMEI> and ICCID <ICCID>
  When the asset service checks the row
  Then <result>

Examples:
  | Sensor ID                       | IMEI                  | ICCID            | result |
  | blank                           | blank                 | blank            | fails with "A sensor requires a Sensor ID or an IMEI." |
  | {New Sensor ID}                 | blank                 | blank            | accepted |
  | blank                           | a valid 15-digit IMEI | blank            | accepted |
  | blank                           | 14 digits             | blank            | fails with "Invalid IMEI." |
  | {New Sensor ID}                 | blank                 | contains letters | accepted; a sensor's ICCID is not format-checked |
  | longer than the maximum allowed | blank                 | blank            | fails with "Sensor ID exceeds the maximum length of {max} characters." |
```

#### FS-2874 — Order numbers and Shipping Date are checked

**Group**: C · **Test level**: Integration · **EMTE**: 1.5 h · **Automation**: Candidate · **Traceability**: US2-AC10, US2-AC12, EC-20, EC-21, EC-22, FR-008, FR-008a, SC-004

```gherkin
Scenario Outline: Interaction variation matrix - order fields and Shipping Date
  Given an otherwise valid gateway row with <field> set to <value>
  When the asset service checks the row
  Then <result>

Examples:
  | field                   | value       | result |
  | Sales Order Number      | blank       | fails with "No Sales Order Number found." |
  | Sales Order Number      | only spaces | fails with "No Sales Order Number found." |
  | Agreement Number        | blank       | fails with "No Agreement Number found." |
  | Shipping Date           | blank       | fails with "No Shipping Date found." |
  | Shipping Date           | 2026-02-30  | fails with "Invalid Shipping Date." |
  | Shipping Date           | 15/03/2026  | fails with "Invalid Shipping Date." |
  | Shipping Date           | 2026-03-15  | accepted and stored as typed |
  | Shipping Date           | 03/15/2026  | accepted and stored as typed |
  | Shipping Date           | 3/15/26     | accepted and stored as typed |
  | Sales Order Line Number | blank       | accepted |
  | Part Description        | blank       | accepted |
  | Shipment Number         | blank       | accepted |
```

#### FS-2875 — Customer IDs decide which customer gets the device

**Group**: C · **Test level**: Integration · **EMTE**: 1.5 h · **Automation**: Candidate · **Traceability**: US2-AC9, EC-11, EC-12, FR-008, FR-012, FR-013, SC-004

```gherkin
Scenario Outline: Interaction variation matrix - Bill To and Ship To customer IDs
  Given an otherwise valid row with Bill To <Bill To> and Ship To <Ship To>
  When the asset service looks up the customers
  Then <result>

Examples:
  | Bill To         | Ship To                              | result |
  | blank           | blank                                | fails with "A Bill To Customer ID or Ship To Customer ID is required." |
  | {Customer B ID} | {Customer A ID}                      | delivered to {Customer A} (Ship To wins) |
  | {Customer B ID} | blank                                | delivered to {Customer B} (Bill To is used when Ship To is blank) |
  | blank           | {Customer A ID}                      | delivered to {Customer A} |
  | {Customer B ID} | {Unknown ID}                         | fails with "Ship To Customer ID {Unknown ID} does not match a known organization." |
  | {Unknown ID}    | {Customer A ID}                      | fails with "Bill To Customer ID {Unknown ID} does not match a known organization." |
  | blank           | {Inactive customer ID}               | fails with "Customer ID {Inactive customer ID} belongs to an inactive account." |
  | blank           | {Customer ID with two main accounts} | fails with "Customer ID {Customer ID with two main accounts} matches more than one master account; contact support." |
```

#### FS-2876 — Row with several problems reports all of them, in order

**Group**: C · **Test level**: Integration · **EMTE**: 1.0 h · **Automation**: Candidate · **Traceability**: US2-AC11, EC-13, FR-009

```gherkin
Scenario Outline: Interaction variation matrix - several failures on one row
  Given a shipment row with <problems>
  When the asset service checks the row
  Then the row fails once, listing the error codes "<error codes>" in that order
  And every matching error message is listed in the same order, separated by ";"

Examples:
  | problems                                                         | error codes |
  | a gateway part number, no IMEI, no ICCID and no Agreement Number | MISSING_IMEI;MISSING_ICCID;MISSING_AGREEMENT_NUMBER |
  | an unmapped part number, no IMEI and no Shipping Date            | UNKNOWN_PART_NUMBER;MISSING_SHIPPING_DATE |
```

#### FS-2877 — Row that disagrees with the device Fus1on already has is rejected

**Group**: D · **Test level**: Integration · **EMTE**: 1.0 h · **Automation**: Candidate · **Traceability**: US2-AC6, EC-9, FR-007

```gherkin
Scenario Outline: Interaction variation matrix - file details conflict with the existing device
  Given Fus1on already has <existing device>
  And a shipment row has <row details>
  When the asset service matches the row to Fus1on's devices
  Then the row fails with "<message>"
  And no device is moved or created

Examples:
  | existing device                                                        | row details                                              | message |
  | gateway {Gateway IMEI} with ICCID {Stored ICCID} in Road Ready holding | IMEI {Gateway IMEI} with a different ICCID {Other ICCID} | ICCID {Other ICCID} does not match the ICCID recorded for this device. |
  | TrackRR Lite {Lite IMEI} in Road Ready holding                         | IMEI {Lite IMEI} with the TrackRR Gateway part number    | Part number {Gateway part number} does not match this device's type. |
  | one sensor with Sensor ID {Sensor ID X} and another with IMEI {IMEI Y} | Sensor ID {Sensor ID X} and IMEI {IMEI Y}                | More than one device in Fus1on matches this record. |
```

#### FS-2878 — New device is refused if one of its identifiers already belongs to another device

**Group**: D · **Test level**: Integration · **EMTE**: 1.5 h · **Automation**: Candidate · **Traceability**: US2-AC7, FR-007, SC-003

```gherkin
Scenario Outline: Interaction variation matrix - identifiers must be unique across the platform
  Given Fus1on already has <existing device>
  And a shipment row for a new device has <row details>
  When the asset service checks the row
  Then the row fails with "<message>"
  And no device is created

Examples:
  | existing device                                        | row details                                              | message |
  | a gateway created by AS500 with ICCID {ICCID X}        | a new gateway with ICCID {ICCID X}                       | Duplicate ICCID detected. |
  | a gateway with IMEI {IMEI X}                           | a new sensor with IMEI {IMEI X}                          | Duplicate IMEI detected. |
  | a manually created sensor with Sensor ID {Sensor ID X} | a new sensor with Sensor ID {Sensor ID X} and a new IMEI | Duplicate Sensor ID detected. |
  | a sensor with ICCID {ICCID Y}                          | a new sensor with ICCID {ICCID Y}                        | Duplicate ICCID detected. |
  | a deleted gateway that had IMEI {IMEI Z}               | a new gateway with IMEI {IMEI Z}                         | Duplicate IMEI detected. |
```

#### FS-2879 — When a file lists the same device twice, the first good row wins

**Group**: D · **Test level**: Integration · **EMTE**: 1.0 h · **Automation**: Candidate · **Traceability**: US2-AC8, FR-007

```gherkin
Scenario Outline: Interaction variation matrix - duplicate rows inside one file
  Given a shipment file has <first row> followed by <later row>
  When the asset service processes the file
  Then <result>

Examples:
  | first row                                                | later row                                       | result |
  | a valid gateway row with IMEI {IMEI X}                   | a valid sensor row with IMEI {IMEI X}           | the first is delivered; the later fails with "Duplicate IMEI detected." |
  | a valid sensor row with Sensor ID {Sensor ID X}          | a valid sensor row with Sensor ID {Sensor ID X} | the first is delivered; the later fails with "Duplicate Sensor ID detected." |
  | a gateway row with IMEI {IMEI X} and no Agreement Number | a valid gateway row with IMEI {IMEI X}          | the first fails; the later is delivered |
```

#### FS-2880 — Device sitting in a customer's account cannot be shipped to another customer

**Group**: H · **Test level**: Integration · **EMTE**: 1.5 h · **Automation**: Candidate · **Traceability**: US2-AC4, US6-AC5, FR-023

```gherkin
Scenario Outline: Interaction variation matrix - device is not in an account it may be shipped from
  Given gateway {Gateway IMEI} is <where the device is>
  And a shipment row ships {Gateway IMEI} to {Customer B ID}
  When the asset service processes the row
  Then the row fails with "This device cannot be shipped from its current account (installed, moved since its shipment, not received from the manufacturer, or named by a different shipment)."
  And the gateway and everything attached to it stay where they are

Examples:
  | where the device is |
  | in {Customer A}'s account, created there by an AS500 file |
  | in {Customer A}'s account from an FS-2772 shipment, and now installed on a real asset |
  | in {Customer A}'s account from an FS-2772 shipment, and moved by an organization transfer since |
  | in {Customer A}'s account from an FS-2772 shipment with Sales Order Number {SO 1}, while the row has {SO 2} |
  | in {Customer A}'s account from an FS-2772 shipment with Shipment Number {Shipment 1}, while the row has {Shipment 2} |
  | in the Road Ready holding account but never received from a manufacturer file |
```

#### FS-2881 — Devices cannot be shipped to the Road Ready holding account

**Group**: H · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: FR-023

```gherkin
Scenario: Failure or resilience behavior - row names the Road Ready holding organization as the customer
  Given a shipment row whose Ship To customer ID belongs to the Road Ready holding organization
  When the asset service processes the row
  Then the row fails with "Devices cannot be shipped to the Road Ready holding account."
  And no device is moved or created
```

#### FS-2882 — Device the customer already has is skipped, not failed

**Group**: D · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: US2-AC5, FR-028

```gherkin
Scenario: Successful interaction - the device was already delivered to this customer
  Given gateway {Gateway IMEI} is already in one of {Customer A}'s accounts
  And a shipment row ships it to {Customer A ID} with a different Part Description
  When the asset service processes the file
  Then the row is counted as skipped, not failed
  And nothing about the gateway changes, including its Part Description
  And the row does not appear in the error file
```

#### FS-2883 — Device sent to the wrong customer is corrected by resending the same shipment

**Group**: H · **Test level**: Integration · **EMTE**: 1.5 h · **Automation**: Candidate · **Traceability**: US6-AC4, US6-AC5, FR-023, FR-024, SC-013

```gherkin
Scenario Outline: Interaction variation matrix - correcting a wrong-customer shipment
  Given gateway {Gateway IMEI} was shipped to {Customer A} by mistake with Sales Order Number <original SO> and Shipment Number <original shipment>
  And the gateway has not been installed or moved since
  When a corrected row ships it to {Customer B ID} with Sales Order Number <row SO> and Shipment Number <row shipment>
  Then <result>

Examples:
  | original SO | original shipment | row SO     | row shipment | result |
  | SO-100      | SH-1              | SO-100     | SH-1         | the gateway moves to {Customer B}, the move is recorded as a re-delivery, and billing is notified |
  | SO-100      | SH-1              | " so-100 " | "sh-1"       | re-delivered; spaces and upper/lower case are ignored |
  | SO-100      | blank             | SO-100     | blank        | re-delivered; a blank Shipment Number matches only a blank one |
  | SO-100      | blank             | SO-100     | SH-1         | fails with "DEVICE_NOT_TRANSFERABLE" |
  | SO-100      | SH-1              | SO-200     | SH-1         | fails with "DEVICE_NOT_TRANSFERABLE" |
```

#### FS-2884 — Correction stops if the device is installed while it is being processed

**Group**: H · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: FR-022, FR-023

```gherkin
Scenario: Failure or resilience behavior - the device is installed during a correction
  Given gateway {Gateway IMEI} qualifies to be corrected from {Customer A} to {Customer B}
  And while the correction is processing, the gateway is installed on a real asset
  When the asset service tries to move it
  Then the row fails with "TRANSFER_FAILED" or "DEVICE_NOT_TRANSFERABLE"
  And the gateway, its trailer and the real asset all stay with {Customer A}
  And no re-delivery is recorded
```

#### FS-2885 — Resending an older file does not pull back a device PSI has already forwarded

**Group**: H · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: EC-1, FR-023

```gherkin
Scenario: Failure or resilience behavior - stale file resent after a PSI forward
  Given gateway {Gateway IMEI} was shipped to PSI holding by file 1 with Sales Order Number {SO 1}
  And PSI then forwarded it to {Customer A} with file 2 and Sales Order Number {SO 2}
  When file 1 is resent unchanged
  Then the gateway's row fails with "DEVICE_NOT_TRANSFERABLE"
  And the gateway stays with {Customer A}
```

#### FS-2886 — Shipment to PSI lands in the PSI holding account

**Group**: I · **Test level**: Integration · **EMTE**: 1.0 h · **Automation**: Candidate · **Traceability**: US5-AC1, FR-013, FR-026

```gherkin
Scenario Outline: Interaction variation matrix - devices shipped to PSI
  Given <device>
  And a shipment row names it with the PSI holding organization's customer ID in Bill To and Ship To
  When the asset service processes the file
  Then the device is in the PSI holding account
  And the shipment record says it was <how>

Examples:
  | device                                                                | how |
  | gateway {Gateway IMEI} is in Road Ready holding, received from PRIMAX | transferred |
  | gateway {New IMEI} is not yet in Fus1on                               | created |
  | sensor {New Sensor ID} is not yet in Fus1on                           | created |
```

#### FS-2887 — PSI can forward a device on to its own customer

**Group**: I · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: US5-AC2, FR-023, FR-024

```gherkin
Scenario: Successful interaction - shipping out of the PSI holding account
  Given gateway {Gateway IMEI} is in the PSI holding account
  And a shipment row ships it to {Customer A ID}
  When the asset service processes the file
  Then the gateway and everything attached to it are now in {Customer A}'s account
  And the shipment record says it was transferred from PSI holding
  And billing is notified of the move
```

#### FS-2888 — PSI holding account is set up in every environment

**Group**: I · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Do Not Automate · **Traceability**: US5-AC3, FR-026

```gherkin
Scenario: Successful interaction - PSI holding setup per environment
  Given the feature is deployed to {Environment}
  When the asset service reads the PSI holding organization from the environment configuration
  Then that organization exists in {Environment}
  And it has exactly one active main account
```

#### FS-2889 — Resending a file unchanged changes nothing and reports no failures

**Group**: J · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: US6-AC1, FR-028, SC-003, SC-013

```gherkin
Scenario: Successful interaction - safe resend of a processed file
  Given file 1 was processed once and delivered {Delivered} devices with no failures
  When file 1 is sent again unchanged, by email or through the web app
  Then the new run reports {Delivered} skipped and 0 failed
  And no device is created or moved
  And the email has no error file attached
```

#### FS-2890 — Resending after fixing failed rows delivers the fixed rows and skips the rest

**Group**: J · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: US6-AC2, EC-10, FR-028

```gherkin
Scenario: Successful interaction - resend after correcting failed rows
  Given file 1 delivered {Good} rows and failed {Bad} rows
  And {Fixed} of the failed rows are corrected and the whole file is sent again
  When the asset service processes it
  Then the corrected rows are delivered
  And the rows delivered the first time are counted as skipped
  And the error file lists only the {Bad} - {Fixed} rows that still fail
```

#### FS-2891 — Run that keeps failing is marked failed and support is told to resend

**Group**: J · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: US6-AC3, FR-029, SC-005

```gherkin
Scenario: Failure or resilience behavior - automatic retries run out on a customer shipment run
  Given a customer shipment run keeps hitting a temporary error after {Processed} rows were saved
  When all automatic retries are used up
  Then the run is marked "Failed" with an end time
  And support receives one email saying "The run could not be completed; resend the file to finish the remaining records."
  And resending the file delivers the remaining rows and skips the {Processed} already handled
```

#### FS-2892 — Run interrupted part-way picks up without doubling anything

**Group**: J · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: FR-024, SC-002, SC-003

```gherkin
Scenario: Failure or resilience behavior - processing is interrupted and retried
  Given a run of {Total} rows is interrupted after {Saved} rows were saved
  When the run is retried automatically
  Then no device is created or moved twice
  And each row is counted once, so succeeded plus skipped plus failed equals {Total}
  And billing is notified again for any transfer whose notification may have been lost
```

#### FS-2893 — PRIMAX file records devices as received and skips them when resent

**Group**: M · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: US6-AC6, FR-017, FR-021, FR-025, FR-028, SC-012

```gherkin
Scenario: Successful interaction - PRIMAX receipts and resend
  Given a PRIMAX file with {PRIMAX devices} devices is emailed to the intake mailbox
  When it is processed, and then the same file is sent again after a partial failure
  Then each device from the first run is recorded as received from the manufacturer into Road Ready holding
  And neither run records any customer shipment
  And the second run skips devices already received and receives only the rest
  And the PRIMAX email shows the skipped count, and its total includes the skipped devices
```

#### FS-2894 — PRIMAX run that keeps failing is marked failed and support is told

**Group**: M · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: FR-021, FR-029, SC-005

```gherkin
Scenario: Failure or resilience behavior - automatic retries run out on a PRIMAX run
  Given a PRIMAX run fails on every automatic retry
  When all retries are used up
  Then the run is marked "Failed" with an end time
  And support receives exactly one email for the run
```

#### FS-2895 — AS500 files give exactly the same results as before this change

**Group**: M · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: US1-AC8, FR-021, SC-009

```gherkin
Scenario: Successful interaction - AS500 regression check
  Given the results of {AS500 regression files} were recorded before the FS-2772 change was deployed
  When the same files are emailed to the intake mailbox after the change
  Then the checks, created devices, shipment records, run details and emails are identical to the recorded results
  And the AS500 runs are not labelled as customer shipments or manufacturer receipts
```

#### FS-2896 — Shipment record keeps every value billing and reporting need

**Group**: G · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: FR-024a, FR-025, SC-012

```gherkin
Scenario: Successful interaction - shipment record contents in the database
  Given a shipment row for gateway {Gateway IMEI} with all 12 columns filled in is delivered to {Customer A}
  When the row is saved
  Then the database shipment record for the gateway holds:
    | field                                                   | validation_type                |
    | destination organization                                | equals {Customer A}            |
    | Bill To and Ship To organizations                       | equals the looked-up customers |
    | IMEI, ICCID, Sensor ID                                  | equals the values in the file  |
    | Sales Order Number, Line Number, Shipment Number        | equals the values in the file  |
    | Part Number, Part Description, Shipping Date, Agreement | equals the values in the file  |
    | customer name                                           | is empty                       |
  And the shipment record and the transfer history entry have the same timestamp
```

#### FS-2897 — Run is recorded in the database before any row is processed

**Group**: K · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: US4-AC1, FR-016

```gherkin
Scenario: Successful interaction - run start is recorded
  Given shipment file {File name} arrives by email or through the web app
  When the asset service starts processing it
  Then the database has a run record named "Filename: {File name}" with a start time
  And the start time is earlier than every shipment record and failed row saved for the run
```

#### FS-2898 — Finished run shows counts that add up and the right status

**Group**: K · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: US4-AC2, FR-016, FR-028, SC-007

```gherkin
Scenario: Successful interaction - run totals are recorded
  Given a file with {Succeeded} rows to deliver, {Skipped} rows already delivered and {Failed} invalid rows
  When the asset service finishes the run
  Then the database run record shows:
    | field     | validation_type                           |
    | end time  | not_empty                                 |
    | total     | equals {Succeeded} + {Skipped} + {Failed} |
    | succeeded | equals {Succeeded}                        |
    | skipped   | equals {Skipped}                          |
    | failed    | equals {Failed}                           |
    | status    | equals Completed with errors              |
```

#### FS-2899 — Run that stopped part-way never looks like it completed

**Group**: K · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: US4-AC3, FR-016, SC-007

```gherkin
Scenario: Failure or resilience behavior - an abnormal stop is visible in the run record
  Given a run stops part-way because of a system failure and is no longer processing
  When an operator looks up the run in the database
  Then the run has a start time and is either marked "Failed" or has no end time
  And it is not marked "Completed" or "Completed with errors"
```

#### FS-2900 — Failed rows and their reasons can be looked up without the email

**Group**: K · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: US4-AC4, FR-015, FR-016, SC-007

```gherkin
Scenario: Successful interaction - failed rows are kept in the database
  Given an emailed run had {Failed} failed rows, one of which had an extra column {Extra column}
  When an operator looks up the run's failed rows in the database
  Then exactly {Failed} rows are found
  And each one shows:
    | field          | validation_type                                      |
    | original row   | equals the row as received, including {Extra column} |
    | error codes    | equals every code, separated by ";"                  |
    | error messages | equals every message, separated by ";"               |
```

#### FS-2901 — Shipment data never appears in application logs

**Group**: K · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: FR-016

```gherkin
Scenario: Failure or resilience behavior - no file contents in logs or traces
  Given a file with valid and invalid rows containing easy-to-spot values {Marker IMEI}, {Marker ICCID} and {Marker Sensor ID}
  When the asset service processes the file
  Then no log line or trace contains {Marker IMEI}, {Marker ICCID}, {Marker Sensor ID} or any error message text
  And the rejection metric is labelled only with error codes
```

#### FS-2902 — Clean run sends one email with the full counts and no attachment

**Group**: L · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: US3-AC1, US3-AC3, FR-017, FR-018, FR-019, SC-005, SC-006

```gherkin
Scenario: Successful interaction - email for a run with no failures
  Given an emailed shipment run finishes with every row delivered or skipped
  When the asset service sends the run email
  Then support receives exactly one email with subject "Shipment Intake Notification - run {Run number} completed"
  And the email shows:
    | field                                            | validation_type          |
    | file name                                        | equals {File name}       |
    | processing reference                             | equals {Run number}      |
    | processed at                                     | not_empty                |
    | status                                           | equals Completed         |
    | total, succeeded, skipped, failed                | equals the run's counts  |
    | how many were transferred, re-delivered, created | equals the run's results |
  And there is no attachment, and the person who sent the file is not emailed
```

#### FS-2903 — Run with failures sends the error file listing exactly the failed rows

**Group**: L · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: US3-AC2, US3-AC5, FR-015, FR-018, SC-006

```gherkin
Scenario: Successful interaction - error file attached to the email
  Given an emailed file with its columns in a different order and one extra column has {Failed} failed rows
  When the asset service sends the run email
  Then the subject ends with "completed with errors" and the email has the attachment "shipment-{Run number}-errors.csv"
  And the attachment has a header row and exactly {Failed} rows, in file order
  And its first 12 columns are the standard FS-2772 columns in the standard order, with values exactly as received
  And its last 3 columns are Error Code, Error Description and Processing Timestamp
  And the extra column is not included
```

#### FS-2904 — Error file cannot run spreadsheet formulas

**Group**: L · **Test level**: Integration · **EMTE**: 1.5 h · **Automation**: Candidate · **Traceability**: FR-015

```gherkin
Scenario Outline: Interaction variation matrix - values that look like spreadsheet formulas
  Given a failed row whose Part Description is "<value>"
  When the error file is attached to the run email
  Then the Part Description cell is prefixed so it cannot run as a formula when opened in a spreadsheet
  And every other value in the row is exactly as received

Examples:
  | value       |
  | =SUM(A1:A2) |
  | +1          |
  | -1          |
  | @cmd        |
```

#### FS-2905 — Web app uploads also email the uploader's contact address

**Group**: L · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: US3-AC1, FR-019

```gherkin
Scenario: Successful interaction - who receives the run email
  Given one file is uploaded in the web app with contact email {Contact Email} and another is emailed by {Sender}
  When both runs finish
  Then the web app run's email goes to {support recipients} and {Contact Email}
  And the emailed run's email goes to {support recipients} only, never to {Sender}
```

#### FS-2906 — Email recipients and error messages change through configuration and a restart

**Group**: L · **Test level**: Integration · **EMTE**: 1.5 h · **Automation**: Do Not Automate · **Traceability**: US3-AC6, FR-015, FR-019, SC-008

```gherkin
Scenario Outline: Interaction variation matrix - configuration controls the email
  Given <configuration change> in the environment configuration for {Environment}
  When the asset service is restarted and a run with a failed sensor row finishes
  Then <result>
  And no code change or new build was needed

Examples:
  | configuration change                                                              | result |
  | the support recipients are changed to {New recipients}                            | the email goes to {New recipients} |
  | the sensor error message is changed to "Sensor rows need a Sensor ID or an IMEI." | the error file shows "Sensor rows need a Sensor ID or an IMEI." |
  | the sensor error message is set to blank                                          | the error file shows the default "A sensor requires a Sensor ID or an IMEI." |
  | the same changes are made but the service is not restarted                        | the old recipients and messages are still used |
```

#### FS-2907 — If the email cannot be sent, the run's results are still saved

**Group**: L · **Test level**: Integration · **EMTE**: 1.0 h · **Automation**: Candidate · **Traceability**: EC-15, FR-016, FR-019

```gherkin
Scenario Outline: Failure or resilience behavior - the run email fails
  Given <email problem>
  When a customer shipment run finishes
  Then the failure is logged with the run number only
  And the run's status, times, counts and failed rows are still saved

Examples:
  | email problem                          |
  | the email notification service is down |
  | no support recipients are configured   |
```

#### FS-2908 — Database upgrade works on a database that already holds shipment data

**Group**: M · **Test level**: Integration · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: FR-021, SC-009

```gherkin
Scenario: Successful interaction - database changes applied over existing data
  Given the database already holds AS500, PRIMAX and old FS-2430 runs, shipment records and failed rows
  When the FS-2772 database upgrade is applied
  Then the upgrade completes and all of its new checks pass
  And existing data is unchanged, with the new fields empty and old shipment records read as "created"
  And AS500 files still process successfully afterwards
```

### Component API — shared Background

```gherkin
Background:
Given the web app upload API "POST ~/v2/assets/shipments/import-shipments" accepts a CSV file and a contact email from a signed-in user
And the asset service import API "POST v2/shipments/import-shipments" accepts shipment rows from the web app
And the asset service mailbox API "POST /v1/shipments/intake" accepts files handed over by the intake mailbox
And every service behind the API under test is replaced by a predictable test stand-in
```

#### FS-2909 — Super-admin's 12-column file is accepted and passed on with all 12 values

**Group**: P1 · **Test level**: Component API · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: US1-AC1, FR-001, FR-002

```gherkin
Scenario: A valid 12-column file is accepted, whatever the column order
  Given the user is super-admin {Super Admin}
  And the asset service stand-in accepts the request
  When the user uploads reordered_file with contact email {Contact Email}
  Then the web app API responds with status {import success status}
  And the request passed to the asset service contains:
    | field                         | expected_value                                     | validation_type |
    | file name                     | {File name}                                        | equals          |
    | contact email                 | {Contact Email}                                    | equals          |
    | fields on each row            | the 12 FS-2772 columns                             | equals          |
    | Bill To Customer ID on a row  | the value in the file, unchanged                   | equals          |
    | old Serial Number field       | —                                                  | not_exists      |
```

#### FS-2910 — File with the wrong columns is refused straight away

**Group**: P1 · **Test level**: Component API · **EMTE**: 1.0 h · **Automation**: Candidate · **Traceability**: US1-AC7, FR-002, FR-003, FR-020

```gherkin
Scenario Outline: Upload with a header that is not the 12-column layout
  Given the user is super-admin {Super Admin}
  When the user uploads <file>
  Then the web app API responds with status 400
  And response body contains:
    | field   | expected_value                                     | validation_type |
    | message | File header does not match the expected V2 layout. | contains        |
  And nothing is passed to the asset service and no run is created

Examples:
  | file                          |
  | old_fs2430_file               |
  | as500_file                    |
  | file_missing_agreement_column |
```

#### FS-2911 — Upload limit of 10000 rows is enforced

**Group**: P1 · **Test level**: Component API · **EMTE**: 1.0 h · **Automation**: Candidate · **Traceability**: US1-AC6, US1-AC7, FR-014, FR-020, SC-005

```gherkin
Scenario Outline: Row count at and over the limit
  Given the user is super-admin {Super Admin}
  When the user uploads <file>
  Then the web app API responds with status <status>
  And <what happens next>

Examples:
  | file            | status                  | what happens next |
  | file_10000_rows | {import success status} | all 10000 rows are passed to the asset service in one request |
  | file_10001_rows | 400                     | nothing is passed to the asset service and no run is created |
```

#### FS-2912 — File with a header but no rows is refused straight away

**Group**: P1 · **Test level**: Component API · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: EC-16, FR-020, SC-005

```gherkin
Scenario: Header-only upload
  Given the user is super-admin {Super Admin}
  When the user uploads header_only_file
  Then the web app API responds with status 400
  And response body contains:
    | field   | expected_value                     | validation_type |
    | message | File contains no shipment records. | contains        |
  And nothing is passed to the asset service and no run is created
```

#### FS-2913 — File larger than 10 MB is refused straight away

**Group**: P1 · **Test level**: Component API · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: FR-020, SC-005

```gherkin
Scenario: Upload over the size limit
  Given the user is super-admin {Super Admin}
  When the user uploads file_over_10mb
  Then the web app API responds with status 400
  And nothing is passed to the asset service and no run is created
```

#### FS-2914 — Non-super-admin upload is refused with 403

**Group**: P1 · **Test level**: Component API · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: FR-031

```gherkin
Scenario: The asset service refuses an ordinary user and the web app passes that on
  Given the user is ordinary user {Ordinary User}
  And the asset service stand-in answers 403
  When the user uploads valid_file
  Then the web app API responds with status 403
```

#### FS-2915 — Super-admin import is accepted and recorded as a customer shipment run

**Group**: P2 · **Test level**: Component API · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: FR-001, FR-031

```gherkin
Scenario: A valid import from a super-admin
  Given customer shipment processing is switched on
  And the request comes from super-admin {Super Admin}
  When the web app sends import_request to the asset service
  Then the asset service responds with status {import success status}
  And the run recorded for the request shows:
    | field         | expected_value      | validation_type |
    | came from     | web app             | equals          |
    | file type     | FS-2772 (V2)        | equals          |
    | kind of run   | customer shipment   | equals          |
    | contact email | {Contact Email}     | equals          |
    | submitted by  | {Super Admin}       | equals          |
```

#### FS-2916 — Import from a non-super-admin is refused with 403 and nothing is recorded

**Group**: P2 · **Test level**: Component API · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: FR-031

```gherkin
Scenario: An ordinary user's import is refused
  Given customer shipment processing is switched on
  And the request comes from ordinary user {Ordinary User}, who is not a super-admin
  When the web app sends import_request to the asset service
  Then the asset service responds with status 403
  And no run is recorded and no row is processed
```

#### FS-2917 — Import is refused with 404 and an empty response while the feature is switched off

**Group**: P2 · **Test level**: Component API · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: SC-005

```gherkin
Scenario: Customer shipment processing is switched off
  Given customer shipment processing is switched off
  And the request comes from super-admin {Super Admin}
  When the web app sends import_request to the asset service
  Then the asset service responds with status 404
  And response body contains:
    | field | expected_value | validation_type |
    | body  | —              | empty           |
  And no run is recorded
```

#### FS-2918 — Empty import request is refused with 400

**Group**: P2 · **Test level**: Component API · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: FR-020, SC-005

```gherkin
Scenario: An import request with nothing in it
  Given customer shipment processing is switched on
  And the request comes from super-admin {Super Admin}
  When the web app sends an empty request to the asset service
  Then the asset service responds with status 400
  And response body contains:
    | field   | expected_value | validation_type |
    | message | File is empty  | contains        |
  And no run is recorded
```

#### FS-2919 — Import in the old FS-2430 format is refused

**Group**: P2 · **Test level**: Component API · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: FR-002

```gherkin
Scenario: Rows use the retired FS-2430 field names
  Given customer shipment processing is switched on
  And the request comes from super-admin {Super Admin}
  When the web app sends old_shape_import_request to the asset service
  Then the asset service responds with status {old format refusal status}
  And no run is recorded and no row is processed
```

#### FS-2920 — File handed over by the intake mailbox is accepted with 202 and a run number

**Group**: P2 · **Test level**: Component API · **EMTE**: 0.5 h · **Automation**: Candidate · **Traceability**: US1-AC1, FR-001

```gherkin
Scenario: The mailbox hands a file to the asset service
  Given mailbox intake is switched on
  When the intake mailbox sends mailbox_handoff_request to the asset service as the system user
  Then the asset service responds with status 202
  And response body contains:
    | field      | expected_value | validation_type |
    | shipmentId | —              | not_empty       |
```

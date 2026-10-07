# Test Plan: PSI Tire Sensor Pairing for TrackRR (NGG) Gateways (FS-2798)

**Feature**: `FS-2798-psi-ngg-sensor-pairing`
**Jira Epic**: [FS-2798](https://safefleet.atlassian.net/browse/FS-2798) — PSI Tire Sensor Pairing for TrackRR (NGG) Gateways
**Components under test**: device-management-service (DMS: pairing request `POST /ota/trailer/ngg/locationSet`, status lookup `GET /ota/trailer/ngg/locationSet/{requestId}`, PSI acknowledgement sender), dms-web-app (Commands and sent command history screens), px-asset-service (IMEI to device type and trailer), Device Delivery Service (DDP), message-processor-lambda (device acknowledgements), TrackRR test gateway, PSI acknowledgement receiver (test stand-in)
**Spec source**: `specs/FS-2798-psi-ngg-sensor-pairing/spec.md` (fus1on-sdd repo, branch `FS-2798-psi-ngg-sensor-pairing`)
**Test case sources**: [fs-2798-psi-ngg-sensor-pairing-component-ui-test-cases.md](./fs-2798-psi-ngg-sensor-pairing-component-ui-test-cases.md) (11 cases) and [fs-2798-psi-ngg-sensor-pairing-integration-test-cases.md](./fs-2798-psi-ngg-sensor-pairing-integration-test-cases.md) (37 cases)
**Test levels in this plan**: Component UI and Integration, manual execution. Component API tests are owned by the development team's automated suite (see §2.2).
**Status**: All 48 cases published as Zephyr Test issues **FS-2923–FS-2970**, parented under Epic FS-2798, workflow status **Approved**.

---

## 1. Purpose

Validate that PSI (TireView Live) can pair tire sensors to TrackRR, TrackRR Cargo and TrackRR Solar gateways through the platform. Each PSI request carries the gateway's complete tire layout. The platform must check it, send it to the gateway as one command (the full layout plus the "start pairing" trigger), and tell PSI exactly once whether it worked: Success when the gateway accepts; Unsuccess when it rejects, expires, is cancelled or is replaced by a newer request. Bad requests must be refused before anything reaches a gateway. PSI must be able to look up a request's status. Operators must see pairing commands in DMS command history but must not be able to create or send them by hand. The existing MCU pairing request and the TrackRR Firmware Ready command must keep working, with Firmware Ready changing only where it carries its message ID.

---

## 2. Scope

### 2.1 In Scope (covered by this test plan and its 48 test cases)

| Group | Area | User Story / Requirement | Jira Keys |
|---|---|---|---|
| U1. UI: Pairing command kept out of operators' hands | Not in the commands list, not sendable by hand, no edit or delete | FR-009a | FS-2923, FS-2924, FS-2925 |
| U2. UI: Pairing visible in command history | One history row per pairing, details match PSI's layout, status at each stage | US1-AC1, FR-008c, FR-009a, FR-018, FR-005, FR-009c, US2-AC1, US2-AC2, US2-AC4, US3-AC1, FR-010, FR-011 | FS-2926, FS-2927, FS-2928 |
| U3. UI: Operator actions on a sent pairing | Cancel, resend, and a replaced pairing shown as Cancelled | US2-AC3, FR-009a, FR-011, FR-008, US3-AC1, US3-AC3, FR-013, SC-009 | FS-2929, FS-2930, FS-2931 |
| U4. UI: Refusals and Firmware Ready display | Refused requests leave no row; Firmware Ready looks unchanged | US5-AC1, US5-AC2, US5-AC3, US5-AC4, US5-AC5, FR-003, FR-019, FR-021, SC-005, FR-009c, SC-010 | FS-2932, FS-2933 |
| A. Pairing delivery and layout | 8 sensors, one-tire swap, omitted tire cleared, 70-sensor maximum, factory pairing, all TrackRR models, unpair-all, lower-case IDs and gaps | US1-AC1, FR-002, FR-007, FR-008, FR-008c, FR-009c, US1-AC3, US1-AC4, US1-AC5, FR-003, SC-004, US1-AC7, FR-006a, FR-010, FR-012, SC-001, FR-006, US4-AC1, FR-008b, EC-8, EC-9, FR-005 | FS-2934, FS-2936, FS-2937, FS-2938, FS-2940, FS-2941, FS-2951, FS-2956 |
| B. Outcome reported to PSI | Success on accept; Unsuccess on reject, operator cancel, expiry; resend while unanswered; late answer still Success; outcome independent of telemetry | US1-AC2, FR-010, FR-011, FR-012, SC-002, US1-AC6, FR-016, US2-AC1, US2-AC2, US2-AC5, US2-AC3, FR-022, US2-AC4 | FS-2935, FS-2939, FS-2942, FS-2943, FS-2944, FS-2945, FS-2946 |
| C. A newer pairing replaces a waiting one | Older request cancelled and reported Unsuccess, gateway ends on the newer layout, older never resent, identical request sent twice | US3-AC1, FR-004, FR-011, FR-013, SC-009, US3-AC2, FR-014, EC-6, US3-AC3, EC-5 | FS-2947, FS-2948, FS-2949, FS-2950 |
| D. Refusals and access control | Every invalid-request reason, non-TrackRR devices, undeliverable gateway, old firmware, missing permission, feature switched off | US5-AC1, US5-AC2, US5-AC3, US5-AC4, US5-AC5, FR-003, SC-005, US5-AC6, US5-AC7, US5-AC8, FR-006, FR-007, EC-11, EC-12, FR-021, EC-13, FR-019 | FS-2952, FS-2953, FS-2954, FS-2955, FS-2965, FS-2966 |
| E. Edge behaviour of complete layouts | Sensor moved from another gateway, hand-provisioned sensors overwritten, request after a failure, trailer at request time | EC-7, EC-4, FR-008, EC-3, EC-10, FR-012, FR-018 | FS-2957, FS-2958, FS-2959, FS-2960 |
| F. PSI acknowledgement reliability | Exactly one result despite duplicate or simultaneous replies; 3 retries then 'undeliverable' with outcome kept | EC-1, FR-014, SC-003, EC-2, US6-AC2, FR-015, FR-018, FR-022, SC-008 | FS-2961, FS-2962 |
| G. Status lookup | State and result at every stage; unknown IDs and unauthorised callers see nothing | US6-AC1, US6-AC2, US6-AC3, FR-022, US6-AC4, FR-021 | FS-2963, FS-2964 |
| H. Regression: MCU pairing and Firmware Ready | MCU request points PSI to the TrackRR request, MCU pairing unchanged, Firmware Ready reply matched via message ID 104 | EC-14, FR-020, FR-001, FR-021, SC-006, FR-009c, SC-010 | FS-2967, FS-2968, FS-2969 |
| I. Audit and credential safety | Accepted, refused and retried activity recorded; PSI key never stored or logged | FR-018, SC-007 | FS-2970 |

### 2.2 Out of Scope for this plan (tracked as gaps — see §7)

| Area | Why excluded here | Requires |
|---|---|---|
| Component API contract of both endpoints (every refusal code in isolation, response body convention) | Planned as automated component-api and integration tests inside device-management-service (plan.md, Testing Strategy) | DMS automated suite; this plan covers the same refusals end to end in Group D |
| Firmware v1.4 pairing-result event, and telling PSI the real pairing result | Separate Epic (FR-016); Success today means only "the gateway accepted the command" | The future Epic's own test plan |
| TrackRR tire pressure/temperature thresholds (1110–1121) and scheduler settings (1126–1138) | Out of scope per spec Assumptions | Future feature |
| Reading a gateway's configuration back through the platform (element 1211) | Not used by this feature; testers read back through the device console instead | Not applicable |
| Sending the "start pairing" trigger alone to re-apply a saved layout | Out of scope per spec | Not applicable |
| TrackRR Lite (AS500) pairing | No tire receiver; only its refusal is tested (Group D) | Not applicable |
| Showing pairing state in the web apps | Out of scope per spec; only the DMS command screens are tested | Future feature |
| Fixing the MCU request's handling of several sensors, or changing MCU request fields | Out of scope per spec; MCU is regression-tested only | Not applicable |
| PSI's own FAST system behaviour | Outside the platform; a PSI test client stands in for it | PSI's own testing and the PSI integration preconditions (§7) |
| HMAC signing of PSI acknowledgements | Known inherited gap (FS-2367); acknowledgements still use the flat shared key | Separate security work agreed with PSI |

---

## 3. Test Approach

- **Method**: Manual execution of all 48 Gherkin scenarios (11 Component UI, 37 Integration). Every case is `Automation Recommendation: Manual`, published to Jira as `Do not automate`.
- **Technique**: Black-box, behaviour-driven (Given/When/Then). Results are checked only through what can be observed: the API response, the message received by DDP, the gateway's device console, the message received by the PSI test receiver, the DMS command history screen, the status lookup and the DMS logs.
- **Shared background (Integration)**: all services are running; TrackRR pairing is switched on; the PSI test client holds a token with the `pair:tpms-sensors` permission; a registered, DDP-connected TrackRR test gateway installed on a known trailer is online with console access; the PSI receiver records every message.
- **Shared background (Component UI)**: the DMS web app opens without errors; the tester is an operator who can view, send, cancel and resend commands; pairing is switched on; a registered TrackRR test gateway is available.
- **Execution record**: each scenario is its own Zephyr Test issue in Jira project **FS**, under Epic FS-2798, so pass/fail and notes are logged per scenario.
- **Order of execution**: Group H (regression) first, to confirm the MCU and Firmware Ready baseline before pairing traffic starts. Then Group A (core delivery), B (outcomes to PSI), D (refusals), C (replacement), E (edge behaviour), F (reliability) and G (lookup). Run the UI groups U1–U4 alongside B and C, since they reuse the same pairings. Run Group I (audit) last, because it inspects records from the whole test run.
- **Total estimated manual effort (EMTE)**: 36 hours across 48 cases, excluding waiting time for delivery windows and expiry.

---

## 4. Environments & Platforms

- **Gateways**: at least two TrackRR test gateways (needed for "sensor moved between gateways"), plus one TrackRR Cargo and one TrackRR Solar, all on firmware build `4a5c7657` or later, with device console access. Also: one TrackRR registered in the platform but not in DDP (DISPATCH_FAILED case), one gateway not installed on any trailer (factory pairing), and, if available, one with a known firmware version older than build `ffad85ee`.
- **Other devices**: one TrackRR Lite, one MCU (refusal and MCU regression cases), and one other non-TrackRR device type.
- **PSI acknowledgement receiver**: a test stand-in set as the environment's PSI acknowledgement URL, able to record messages and to be switched to answer HTTP 503 (PSI-unreachable case).
- **Configuration**: `psi.ngg.tpms.enabled` (on, and off for the switched-off case); a shortened delivery window (`ngg.command.expiry-hours`) and resend budget (`ngg.command.requeue.budget-days`) with `ngg.command.requeue.dry-run=false`, so resend and expiry cases finish in test time; `psi.ngg.ack.max-attempts=3` and `psi.ngg.ack.first-retry-delay-seconds=30`.
- **Access**: Auth0 tokens for the DMS audience with and without the `pair:tpms-sensors` permission, plus no-token and invalid-token calls. A DMS web app operator account with view, send, cancel and resend rights.
- **Test data**: request bodies for 8 sensors, a one-sensor change on tire 3, a layout missing tire 5, 70 sensors with 6-character IDs, unpair-all (0 tires, empty list), lower-case and gapped layouts, and one body per refusal row in the Group D tables. Payloads must not contain any environment secret.

---

## 5. Entry / Exit Criteria

**Entry criteria**
- The device-management-service build under test includes the pairing request and lookup, the pairing system command (`T1 - TPMS Configure (TrackRR)`), the Firmware Ready template correction (V45, merged in PR 16533) and the pairing migration (V46).
- The `pair:tpms-sensors` permission exists and is granted to the test client.
- The PSI acknowledgement URL in the test environment points to the agreed test receiver, **not** PSI's production host (task T045).
- Gateways, devices, configuration and test data per §4 are ready.
- All 48 Zephyr Test issues (FS-2923–FS-2970) exist under Epic FS-2798 at workflow status `Approved` — confirmed.

**Exit criteria**
- Every case in Groups A–I and U1–U4 has been run at least once and its result recorded in Jira.
- No open blocking defect in Group A (delivery), Group B (outcomes to PSI) or Group D (refusals). These carry the P1 stories and the "nothing reaches a gateway" guarantee.
- No open blocking defect in Group H. A regression in MCU pairing or Firmware Ready affects devices already in the field.
- SC-003 (exactly one outcome per request) and SC-007 (PSI key found zero times) pass in every run.
- Each release dependency in §7 is confirmed or explicitly accepted by engineering review, and the §2.2 gaps are acknowledged in the close-out report.

---

## 6. Test Case Groups & Traceability

| # | Jira Key | Group | Test Level | Scenario | EMTE (h) | Traceability |
|---|---|---|---|---|---|---|
| 1 | [FS-2923](https://safefleet.atlassian.net/browse/FS-2923) | U1 | Component UI | The pairing command is not listed in the commands list | 0.5 | FR-009a |
| 2 | [FS-2924](https://safefleet.atlassian.net/browse/FS-2924) | U1 | Component UI | The pairing command cannot be sent by hand | 0.5 | FR-009a |
| 3 | [FS-2925](https://safefleet.atlassian.net/browse/FS-2925) | U1 | Component UI | The pairing command cannot be edited or deleted | 0.5 | FR-009a |
| 4 | [FS-2926](https://safefleet.atlassian.net/browse/FS-2926) | U2 | Component UI | A pairing sent by PSI shows up once in the gateway's command history | 0.5 | US1-AC1, FR-008c, FR-009a, FR-018 |
| 5 | [FS-2927](https://safefleet.atlassian.net/browse/FS-2927) | U2 | Component UI | The pairing details match what PSI sent | 0.5 | US1-AC1, FR-005, FR-008c, FR-009c, FR-018 |
| 6 | [FS-2928](https://safefleet.atlassian.net/browse/FS-2928) | U2 | Component UI | The pairing's status in history changes as it progresses | 1.0 | US2-AC1, US2-AC2, US2-AC4, US3-AC1, FR-009a, FR-010, FR-011 |
| 7 | [FS-2929](https://safefleet.atlassian.net/browse/FS-2929) | U3 | Component UI | Operator cancels a pairing that is still waiting | 0.5 | US2-AC3, FR-009a, FR-011 |
| 8 | [FS-2930](https://safefleet.atlassian.net/browse/FS-2930) | U3 | Component UI | Operator resends a pairing and the same layout goes out again | 1.0 | FR-009a, FR-008 |
| 9 | [FS-2931](https://safefleet.atlassian.net/browse/FS-2931) | U3 | Component UI | A newer pairing replaces an older one that was still waiting | 1.0 | US3-AC1, US3-AC3, FR-013, SC-009 |
| 10 | [FS-2932](https://safefleet.atlassian.net/browse/FS-2932) | U4 | Component UI | A pairing request that was refused never appears in the history | 0.75 | US5-AC1, US5-AC2, US5-AC3, US5-AC4, US5-AC5, FR-003, FR-019, FR-021, SC-005 |
| 11 | [FS-2933](https://safefleet.atlassian.net/browse/FS-2933) | U4 | Component UI | The Firmware Ready command looks the same as before | 0.5 | FR-009c, SC-010 |
| 12 | [FS-2934](https://safefleet.atlassian.net/browse/FS-2934) | A | Integration | Pairing 8 sensors puts exactly those 8 sensors on the gateway | 1.0 | US1-AC1, FR-002, FR-007, FR-008, FR-008c, FR-009c |
| 13 | [FS-2935](https://safefleet.atlassian.net/browse/FS-2935) | B | Integration | PSI gets one "Success" message when the gateway accepts | 0.5 | US1-AC2, FR-010, FR-011, FR-012, SC-002 |
| 14 | [FS-2936](https://safefleet.atlassian.net/browse/FS-2936) | A | Integration | Swapping one sensor changes only that tire | 1.0 | US1-AC3, FR-008 |
| 15 | [FS-2937](https://safefleet.atlassian.net/browse/FS-2937) | A | Integration | A tire left out of the request is cleared on the gateway | 1.0 | US1-AC4, FR-008, FR-008c |
| 16 | [FS-2938](https://safefleet.atlassian.net/browse/FS-2938) | A | Integration | The maximum of 70 sensors is delivered complete | 1.0 | US1-AC5, FR-003, SC-004 |
| 17 | [FS-2939](https://safefleet.atlassian.net/browse/FS-2939) | B | Integration | PSI's result depends only on the gateway's reply to the command | 0.5 | US1-AC6, FR-010, FR-016 |
| 18 | [FS-2940](https://safefleet.atlassian.net/browse/FS-2940) | A | Integration | A gateway not yet on a trailer can be paired at the factory | 0.5 | US1-AC7, FR-006a, FR-010, FR-012, SC-001 |
| 19 | [FS-2941](https://safefleet.atlassian.net/browse/FS-2941) | A | Integration | All three TrackRR models can be paired | 0.75 | FR-006, SC-001 |
| 20 | [FS-2942](https://safefleet.atlassian.net/browse/FS-2942) | B | Integration | PSI gets "Unsuccess" when the gateway rejects the pairing | 0.5 | US2-AC1, FR-011, FR-012 |
| 21 | [FS-2943](https://safefleet.atlassian.net/browse/FS-2943) | B | Integration | An unanswered pairing is sent again and PSI is not told yet | 1.0 | US2-AC2, FR-010, FR-011 |
| 22 | [FS-2944](https://safefleet.atlassian.net/browse/FS-2944) | B | Integration | A gateway that answers late still gives a normal "Success" | 1.0 | US2-AC5, FR-010, FR-011 |
| 23 | [FS-2945](https://safefleet.atlassian.net/browse/FS-2945) | B | Integration | An operator cancelling the pairing gives PSI "Unsuccess" | 0.5 | US2-AC3, FR-011, FR-022 |
| 24 | [FS-2946](https://safefleet.atlassian.net/browse/FS-2946) | B | Integration | When the platform gives up resending, PSI gets "Unsuccess" | 1.0 | US2-AC4, FR-010, FR-011, SC-002 |
| 25 | [FS-2947](https://safefleet.atlassian.net/browse/FS-2947) | C | Integration | A new pairing replaces an older one that is still waiting | 0.5 | US3-AC1, FR-004, FR-011, FR-013, SC-009 |
| 26 | [FS-2948](https://safefleet.atlassian.net/browse/FS-2948) | C | Integration | After a replacement the gateway ends up with the newer layout | 1.0 | US3-AC2, FR-013, FR-014, SC-009, EC-6 |
| 27 | [FS-2949](https://safefleet.atlassian.net/browse/FS-2949) | C | Integration | A replaced pairing is never sent again | 1.0 | US3-AC3, FR-013, SC-009 |
| 28 | [FS-2950](https://safefleet.atlassian.net/browse/FS-2950) | C | Integration | Sending the same pairing twice counts as two requests | 1.0 | EC-5, FR-013 |
| 29 | [FS-2951](https://safefleet.atlassian.net/browse/FS-2951) | A | Integration | "Unpair all" removes every sensor from the gateway | 1.0 | US4-AC1, FR-008b, FR-008c |
| 30 | [FS-2952](https://safefleet.atlassian.net/browse/FS-2952) | D | Integration | Mistakes in the request are refused and nothing is sent to any gateway | 0.75 | US5-AC1, US5-AC2, US5-AC3, US5-AC4, US5-AC5, FR-003, SC-005 |
| 31 | [FS-2953](https://safefleet.atlassian.net/browse/FS-2953) | D | Integration | Devices that are not TrackRR gateways are refused | 0.75 | US5-AC6, US5-AC7, US5-AC8, FR-006, SC-005 |
| 32 | [FS-2954](https://safefleet.atlassian.net/browse/FS-2954) | D | Integration | A gateway the delivery service cannot reach is refused | 0.5 | FR-007 |
| 33 | [FS-2955](https://safefleet.atlassian.net/browse/FS-2955) | D | Integration | Gateways on old firmware are refused when the version is known | 0.75 | EC-11 |
| 34 | [FS-2956](https://safefleet.atlassian.net/browse/FS-2956) | A | Integration | Lower-case sensor IDs and gaps between tires are handled | 1.0 | EC-8, EC-9, FR-005, FR-008c |
| 35 | [FS-2957](https://safefleet.atlassian.net/browse/FS-2957) | E | Integration | A sensor moved from another gateway is accepted and the other gateway is left alone | 1.0 | EC-7 |
| 36 | [FS-2958](https://safefleet.atlassian.net/browse/FS-2958) | E | Integration | Sensors set up by hand on the gateway are overwritten | 1.0 | EC-4, FR-008 |
| 37 | [FS-2959](https://safefleet.atlassian.net/browse/FS-2959) | E | Integration | A request after a failed one is sent exactly as given | 0.5 | EC-3, FR-008 |
| 38 | [FS-2960](https://safefleet.atlassian.net/browse/FS-2960) | E | Integration | The result shows the trailer the gateway was on when PSI asked | 0.5 | EC-10, FR-012, FR-018 |
| 39 | [FS-2961](https://safefleet.atlassian.net/browse/FS-2961) | F | Integration | PSI gets only one result even if the gateway replies more than once | 0.75 | EC-1, FR-014, SC-003 |
| 40 | [FS-2962](https://safefleet.atlassian.net/browse/FS-2962) | F | Integration | If PSI cannot be reached, the platform tries 3 times and keeps the result | 1.0 | EC-2, US6-AC2, FR-015, FR-018, FR-022, SC-008 |
| 41 | [FS-2963](https://safefleet.atlassian.net/browse/FS-2963) | G | Integration | Looking up a request shows where it stands | 1.0 | US6-AC1, US6-AC2, US6-AC3, FR-022 |
| 42 | [FS-2964](https://safefleet.atlassian.net/browse/FS-2964) | G | Integration | The lookup reveals nothing for unknown requests or callers without permission | 0.75 | US6-AC4, FR-021, FR-022 |
| 43 | [FS-2965](https://safefleet.atlassian.net/browse/FS-2965) | D | Integration | Callers without the pairing permission are stopped before anything happens | 0.75 | EC-12, FR-021 |
| 44 | [FS-2966](https://safefleet.atlassian.net/browse/FS-2966) | D | Integration | With pairing switched off, requests are refused | 0.5 | EC-13, FR-019 |
| 45 | [FS-2967](https://safefleet.atlassian.net/browse/FS-2967) | H | Integration | The old MCU pairing request tells PSI to use the TrackRR request | 0.5 | EC-14, FR-020 |
| 46 | [FS-2968](https://safefleet.atlassian.net/browse/FS-2968) | H | Integration | MCU pairing works exactly as before | 0.5 | FR-001, FR-020, FR-021, SC-006 |
| 47 | [FS-2969](https://safefleet.atlassian.net/browse/FS-2969) | H | Integration | The gateway's reply to Firmware Ready is matched to the right command | 0.5 | FR-009c, SC-010 |
| 48 | [FS-2970](https://safefleet.atlassian.net/browse/FS-2970) | I | Integration | Everything is recorded for audit, and PSI's password never appears | 1.0 | FR-018, SC-007 |

**Coverage by user story**: US1 — 9 cases · US2 — 7 cases · US3 — 5 cases · US4 — 1 case · US5 — 3 cases · US6 — 3 cases · Cases with no user-story code (edge cases, FR/SC only) — 21

---

## 7. Risks, Assumptions & Known Gaps

- **QA acknowledgements could reach PSI production.** QA's `psi.api.ack.url` is the same host as production's. Until it points to an agreed receiver (task T045), no Integration case should run.
- **Production resending runs in dry-run.** Without `ngg.command.requeue.dry-run=false` in production (DMS PR 16524, task T044), an unanswered pairing never expires and PSI never gets Unsuccess. The expiry case (FS-2946) passing in QA does not prove production behaviour.
- **Delivery order through DDP is unconfirmed.** "The gateway ends on the newer layout" (FS-2948) relies on DDP delivering one gateway's messages in the order it received them. Engineering review (task T047) must confirm this; a failure here may be an accepted limitation rather than a defect.
- **Accepted residual race.** If a replacement arrives in the second a resend is in flight, the older layout can still land after the newer one (research R7). Do not try to reproduce this as a pass/fail case.
- **No per-gateway lock.** Two requests for one gateway at the same instant may both be sent; the gateway ends on whichever DDP delivers last. Accepted at PSI's request rates.
- **Success means "accepted by the gateway", not "pairing finished".** The tire receiver may still fail to pair. PSI must be told this at release (FR-016).
- **Long waits.** The real delivery window is about 47 hours and the resend budget 365 days. Resend and expiry cases need shortened settings; record the values used with each result.
- **Real hardware is required** for console read-back cases (Groups A, C and E). Gateway availability is a scheduling risk.
- **PSI integration preconditions** must be confirmed before release: PSI sends the IMEI, uses tire positions 1–70, sends the complete layout every time, accepts one acknowledgement per request (including Unsuccess for a replaced request), and understands what Success means.
- **Route assumption.** The feature assumes PSI sends TrackRR pairings through the platform, not by the direct path in NG-681. If that changes, this plan no longer applies.
- **Known security gap.** Acknowledgements carry a flat shared key over plain HTTP (FS-2367). This plan only tests that the key is absent from logs and stored records (FS-2970).
- **Provenance**: this plan and its test cases were generated with AI assistance from `spec.md` and its contracts; every case was human-approved before Jira publication.

---

## 8. Roles & Responsibilities

- **Owning team**: Fus1on Telemetricians (component Telemetricians)
- **Development stories**: FS-2803 (foundation), FS-2804 (pairing and PSI acknowledgement), FS-2805 (failures and replacement), FS-2806 (refusals, unpair-all and lookup), FS-2807 (release readiness)
- **Test execution and result logging**: QA / manual testers assigned in Jira against FS-2923–FS-2970
- **Fix version**: `TM`
- **Test category**: Release Validation
- **AI involvement**: AI Influenced / Assisted

---

## 9. Deliverables

1. [fs-2798-psi-ngg-sensor-pairing-component-ui-test-cases.md](./fs-2798-psi-ngg-sensor-pairing-component-ui-test-cases.md) — 11 Gherkin Component UI test cases
2. [fs-2798-psi-ngg-sensor-pairing-integration-test-cases.md](./fs-2798-psi-ngg-sensor-pairing-integration-test-cases.md) — 37 Gherkin Integration test cases
3. This test plan, in Markdown and Word (`fs-2798-psi-ngg-sensor-pairing-test-plan.md` / `.docx`)
4. 48 Zephyr Test issues in Jira project FS, parented to [FS-2798](https://safefleet.atlassian.net/browse/FS-2798): **FS-2923–FS-2970**, workflow status `Approved`
5. A close-out note recording pass/fail per case and the status of every §7 release dependency

---

## Appendix A. BDD Test Cases

Each case below is the approved Gherkin scenario exactly as published to its Jira Test issue. The shared Background for each test level is listed first.

### Component UI — shared Background

```gherkin
Background:
Given the DMS web app opens without errors
And the tester is signed in as an operator who can view, send, cancel and resend commands
And tire sensor pairing is switched on in this environment
And a TrackRR test gateway {gateway_imei} is registered and available
```

#### FS-2923 — The pairing command is not listed in the commands list

**Group**: U1 · **Test level**: Component UI · **EMTE**: 0.5 h · **Traceability**: FR-009a

```gherkin
Scenario: Operator searches the commands list and does not find the pairing command
Given the operator opens the Commands page at {commands_page}
When the operator searches the list for "TPMS Configure"
Then no command named "T1 - TPMS Configure (TrackRR)" is shown
And the existing Firmware Ready command is not shown either, just as before
```

#### FS-2924 — The pairing command cannot be sent by hand

**Group**: U1 · **Test level**: Component UI · **EMTE**: 0.5 h · **Traceability**: FR-009a

```gherkin
Scenario: Operator cannot pick the pairing command when sending a command
Given the operator opens the Send Command screen at {send_command_page} for gateway {gateway_imei}
When the operator opens the command picker and types "TPMS Configure"
Then "T1 - TPMS Configure (TrackRR)" is not offered
And the operator has no way to send the pairing command to the gateway by hand
```

#### FS-2925 — The pairing command cannot be edited or deleted

**Group**: U1 · **Test level**: Component UI · **EMTE**: 0.5 h · **Traceability**: FR-009a

```gherkin
Scenario: Operator finds no Edit or Delete option for the pairing command
Given the operator opens the Commands page at {commands_page}
When the operator looks for a way to open, edit or delete "T1 - TPMS Configure (TrackRR)"
Then no Edit button {edit_button_id} is shown for it
And no Delete button {delete_button_id} is shown for it
And the command cannot be opened for editing from any screen
```

#### FS-2926 — A pairing sent by PSI shows up once in the gateway's command history

**Group**: U2 · **Test level**: Component UI · **EMTE**: 0.5 h · **Traceability**: US1-AC1, FR-008c, FR-009a, FR-018

```gherkin
Scenario: Operator sees the pairing in the gateway's sent command history
Given PSI has sent a pairing request for gateway {gateway_imei}, and the system accepted it with request number {request_id}
When the operator opens the gateway's sent command history at {command_history_page}
Then exactly one new row is shown for this pairing
And the row shows these details:
  | field          | what to check                           |
  | command name   | shows "T1 - TPMS Configure (TrackRR)"   |
  | device         | shows {gateway_imei}                    |
  | command number | shows {request_id}                      |
  | status         | is shown                                |
  | sent time      | is shown                                |
```

#### FS-2927 — The pairing details match what PSI sent

**Group**: U2 · **Test level**: Component UI · **EMTE**: 0.5 h · **Traceability**: US1-AC1, FR-005, FR-008c, FR-009c, FR-018

```gherkin
Scenario: Operator opens a sent pairing and sees exactly the tire layout PSI asked for
Given PSI has sent a pairing for gateway {gateway_imei} with 8 tires, 2 axles and sensors on tires 1, 2 and 5
And one of those sensor IDs was typed in lower case as "8fb179"
When the operator opens the details {details_view_id} of that pairing in the command history
Then the details show these values:
  | field                     | what to check                                         |
  | number of tires           | 8                                                     |
  | number of axles           | 2                                                     |
  | sensor ID for each tire   | 70 slots; tires 1, 2 and 5 have the sensor IDs sent; all other slots are empty |
  | axle for each tire        | 70 slots; tires 1, 2 and 5 have the axles sent; all other slots are 0          |
  | tire group for each tire  | 70 slots; tires 1, 2 and 5 have the groups sent; all other slots are 0         |
  | "start pairing" trigger   | is included                                           |
  | message ID                | is included                                           |
And the sensor ID sent as "8fb179" is shown in capitals as "8FB179"
```

#### FS-2928 — The pairing's status in history changes as it progresses

**Group**: U2 · **Test level**: Component UI · **EMTE**: 1.0 h · **Traceability**: US2-AC1, US2-AC2, US2-AC4, US3-AC1, FR-009a, FR-010, FR-011

```gherkin
Scenario Outline: Operator sees the right status for the pairing at each stage
Given a pairing command was sent to gateway {gateway_imei}
And the pairing is in this situation: {situation}
When the operator opens the gateway's sent command history at {command_history_page}
Then the pairing row shows the status {status_shown}
And the Cancel button {cancel_button_id} is {cancel_button}

Examples:
| situation                                                          | status_shown | cancel_button                                |
| sent, but the gateway has not answered yet                         | Queued       | available                                    |
| the gateway did not answer for about 2 days, so it was sent again  | Queued       | available                                    |
| the gateway accepted it                                            | Completed    | {not available - confirm with test reviewer} |
| the gateway rejected it                                            | Failed       | {not available - confirm with test reviewer} |
| the system gave up resending it                                    | Expired      | {not available - confirm with test reviewer} |
| PSI sent a newer pairing for the same gateway before it was answered | Cancelled  | {not available - confirm with test reviewer} |
```

#### FS-2929 — Operator cancels a pairing that is still waiting

**Group**: U3 · **Test level**: Component UI · **EMTE**: 0.5 h · **Traceability**: US2-AC3, FR-009a, FR-011

```gherkin
Scenario: Operator cancels a waiting pairing from the command history
Given PSI has sent a pairing for gateway {gateway_imei} while the gateway is switched off
And the operator opens the gateway's sent command history at {command_history_page}
And the pairing row shows "Queued"
When the operator clicks Cancel {cancel_button_id} on that row and confirms
Then the row changes to "Cancelled" within {N} seconds
And the Cancel button is no longer available on that row
```

#### FS-2930 — Operator resends a pairing and the same layout goes out again

**Group**: U3 · **Test level**: Component UI · **EMTE**: 1.0 h · **Traceability**: FR-009a, FR-008

```gherkin
Scenario: Resending a pairing sends that same pairing's layout again
Given a pairing with request number {request_id} was sent to gateway {gateway_imei}
And the operator opens the gateway's sent command history at {command_history_page}
When the operator clicks Resend {resend_button_id} on that row and confirms
Then the history shows the pairing sent again to the gateway
And its details show the same tires, axles, sensor IDs and tire groups as request {request_id}
And nothing from any other pairing is mixed into it
```

#### FS-2931 — A newer pairing replaces an older one that was still waiting

**Group**: U3 · **Test level**: Component UI · **EMTE**: 1.0 h · **Traceability**: US3-AC1, US3-AC3, FR-013, SC-009

```gherkin
Scenario: History shows the older pairing cancelled and the newer one waiting
Given gateway {gateway_imei} is switched off
And PSI has sent pairing A (request {request_id_a}), which shows "Queued" in the history
When PSI sends pairing B (request {request_id_b}) for the same gateway
And the operator refreshes the gateway's command history
Then pairing A shows "Cancelled"
And pairing B shows "Queued"
And after about 2 more days, the history shows no new attempt to send pairing A
```

#### FS-2932 — A pairing request that was refused never appears in the history

**Group**: U4 · **Test level**: Component UI · **EMTE**: 0.75 h · **Traceability**: US5-AC1, US5-AC2, US5-AC3, US5-AC4, US5-AC5, FR-003, FR-019, FR-021, SC-005

```gherkin
Scenario Outline: A refused pairing request adds nothing to the command history
Given the operator opens the gateway's sent command history at {command_history_page} and notes how many pairing rows there are
When PSI sends a pairing for gateway {gateway_imei} that is refused because {reason}
And the operator refreshes the history
Then no new pairing row is shown

Examples:
| reason                                              |
| a sensor ID starts with "0x"                        |
| the same tire is listed twice                       |
| the same sensor ID is on two tires                  |
| a sensor has tire group 0                           |
| a sensor is on an axle higher than the axle count   |
| the number of tires is missing                      |
| tire sensor pairing is switched off here            |
| the caller is not allowed to pair sensors           |
```

#### FS-2933 — The Firmware Ready command looks the same as before

**Group**: U4 · **Test level**: Component UI · **EMTE**: 0.5 h · **Traceability**: FR-009c, SC-010

```gherkin
Scenario: Firmware Ready only changes where it stores its message ID
Given a Firmware Ready command was sent to gateway {gateway_imei} after this release
And the operator opens the gateway's sent command history at {command_history_page}
When the operator opens the details {details_view_id} of that Firmware Ready command
Then the message ID is shown in field 104 instead of field 100
And field 1210 still shows "[02]"
And the command's name, status and Cancel/Resend buttons look and work the same as before this release
```

### Integration — shared Background

```gherkin
Background:
Given all the services listed above are running
And tire sensor pairing is switched on in this environment
And the PSI test client has a valid login token with the "pair tire sensors" permission
And a TrackRR test gateway {gateway_imei} is registered, connected, installed on trailer {trailer_id} named {trailer_name}, and the tester can read its settings from its console
And the PSI reply receiver is running and records every message it gets
```

#### FS-2934 — Pairing 8 sensors puts exactly those 8 sensors on the gateway

**Group**: A · **Test level**: Integration · **EMTE**: 1.0 h · **Traceability**: US1-AC1, FR-002, FR-007, FR-008, FR-008c, FR-009c

```gherkin
Scenario: Successful interaction - 8 sensors reach the gateway in one command
Given PSI prepares a pairing for gateway {gateway_imei} with:
  | field           | description                                         |
  | number of tires | 8                                                   |
  | number of axles | 2                                                   |
  | sensors         | 8 sensors on tires 1 to 8, each with axle and group |
When PSI sends the pairing
Then the platform replies "Pairing request accepted." with a request number and the gateway IMEI
And the gateway receives exactly one command holding the whole layout and the "start pairing" trigger
And once the gateway accepts it, its console shows 8 tires, 2 axles, the 8 sensors on tires 1 to 8, and slots 9 to 70 empty
```

#### FS-2935 — PSI gets one "Success" message when the gateway accepts

**Group**: B · **Test level**: Integration · **EMTE**: 0.5 h · **Traceability**: US1-AC2, FR-010, FR-011, FR-012, SC-002

```gherkin
Scenario: Successful interaction - gateway accepts and PSI is told once
Given PSI's pairing for gateway {gateway_imei} was accepted with request number {request_id}
When the gateway replies that it accepted the command
Then the command shows "Completed" in the DMS command history
And within 2 minutes the PSI reply receiver gets exactly one message with:
  | field             | what to check          |
  | status            | "Success"              |
  | message ID        | {request_id}           |
  | gateway IMEI      | {gateway_imei}         |
  | trailer ID        | {trailer_id}           |
  | trailer name      | {trailer_name}         |
  | sensor ID         | empty                  |
  | location          | empty                  |
  | date and time     | filled in              |
```

#### FS-2936 — Swapping one sensor changes only that tire

**Group**: A · **Test level**: Integration · **EMTE**: 1.0 h · **Traceability**: US1-AC3, FR-008

```gherkin
Scenario: Successful interaction - new sensor on tire 3, everything else the same
Given gateway {gateway_imei} already has sensors on tires 1 to 8
When PSI sends the same full layout again but with a different sensor on tire 3
And the gateway accepts it
Then the gateway console shows the new sensor on tire 3
And tires 1, 2 and 4 to 8 are exactly as they were
And PSI gets one "Success" message for the new request
```

#### FS-2937 — A tire left out of the request is cleared on the gateway

**Group**: A · **Test level**: Integration · **EMTE**: 1.0 h · **Traceability**: US1-AC4, FR-008, FR-008c

```gherkin
Scenario: Successful interaction - leaving out tire 5 empties it
Given gateway {gateway_imei} already has sensors on tires 1 to 8
When PSI sends a layout of 8 tires that lists tires 1 to 4 and 6 to 8 only
And the gateway accepts it
Then tire 5 is sent to the gateway as empty
And the gateway console shows tire 5 empty and the other tires as sent
And the platform did not copy anything from the gateway's earlier layout
```

#### FS-2938 — The maximum of 70 sensors is delivered complete

**Group**: A · **Test level**: Integration · **EMTE**: 1.0 h · **Traceability**: US1-AC5, FR-003, SC-004

```gherkin
Scenario: Successful interaction - 70 sensors, the most allowed
Given PSI prepares a pairing for gateway {gateway_imei} with 70 tires, 24 axles and 70 sensors with 6-character IDs
When PSI sends the pairing
Then the platform accepts it
And the command sent to the gateway is no bigger than 2048 bytes
And once the gateway accepts it, its console shows all 70 sensors exactly as sent
And the gateway's pairing status goes back to "idle/succeeded" when it finishes
```

#### FS-2939 — PSI's result depends only on the gateway's reply to the command

**Group**: B · **Test level**: Integration · **EMTE**: 0.5 h · **Traceability**: US1-AC6, FR-010, FR-016

```gherkin
Scenario: Successful interaction - no other gateway data is needed
Given PSI's pairing {request_id} for gateway {gateway_imei} was accepted
And the gateway sends no tire readings or other reports afterwards
When the gateway replies that it accepted the command
Then PSI still gets one "Success" message for {request_id}
```

#### FS-2940 — A gateway not yet on a trailer can be paired at the factory

**Group**: A · **Test level**: Integration · **EMTE**: 0.5 h · **Traceability**: US1-AC7, FR-006a, FR-010, FR-012, SC-001

```gherkin
Scenario: Successful interaction - factory pairing with no trailer
Given gateway {factory_imei} is registered but not installed on any trailer
When PSI sends a valid pairing for {factory_imei}
Then the platform accepts it, just as for an installed gateway
And once the gateway accepts it, PSI gets "Success" with the gateway IMEI and an empty trailer ID and trailer name
And looking up the request shows no trailer
```

#### FS-2941 — All three TrackRR models can be paired

**Group**: A · **Test level**: Integration · **EMTE**: 0.75 h · **Traceability**: FR-006, SC-001

```gherkin
Scenario Outline: Interaction variation matrix - each TrackRR model
When PSI sends a valid pairing for a registered {model} gateway {model_imei}
Then the platform accepts it and sends one pairing command to that gateway
And the platform never replies "device information is missing or incomplete"

Examples:
| model         |
| TrackRR       |
| TrackRR Cargo |
| TrackRR Solar |
```

#### FS-2942 — PSI gets "Unsuccess" when the gateway rejects the pairing

**Group**: B · **Test level**: Integration · **EMTE**: 0.5 h · **Traceability**: US2-AC1, FR-011, FR-012

```gherkin
Scenario: Failure or resilience behavior - gateway rejects the command
Given PSI's pairing {request_id} for gateway {gateway_imei} was accepted
When the gateway replies that it rejected the command
Then the command shows "Failed" in the DMS command history
And PSI gets exactly one "Unsuccess" message for {request_id}
And the message gives no reason for the failure
```

#### FS-2943 — An unanswered pairing is sent again and PSI is not told yet

**Group**: B · **Test level**: Integration · **EMTE**: 1.0 h · **Traceability**: US2-AC2, FR-010, FR-011

```gherkin
Scenario: Failure or resilience behavior - gateway is off for one delivery window (about 2 days)
Given gateway {gateway_imei} is switched off
And PSI's pairing {request_id} was accepted and sent
When one delivery window passes with no reply (about 47 hours, or a shorter time set up for testing)
Then the platform sends the same pairing to the gateway again
And the command still shows "Queued"
And PSI has received nothing yet for {request_id}
And looking up {request_id} shows "in progress" with no result yet
```

#### FS-2944 — A gateway that answers late still gives a normal "Success"

**Group**: B · **Test level**: Integration · **EMTE**: 1.0 h · **Traceability**: US2-AC5, FR-010, FR-011

```gherkin
Scenario: Successful interaction - gateway comes back online after being resent
Given pairing {request_id} for gateway {gateway_imei} was sent again at least once while the gateway was off
When the gateway is switched on and accepts the command
Then PSI gets exactly one "Success" message for {request_id}
And the gateway console shows the layout from {request_id}
```

#### FS-2945 — An operator cancelling the pairing gives PSI "Unsuccess"

**Group**: B · **Test level**: Integration · **EMTE**: 0.5 h · **Traceability**: US2-AC3, FR-011, FR-022

```gherkin
Scenario: Failure or resilience behavior - operator cancels a waiting pairing in DMS
Given PSI's pairing {request_id} for switched-off gateway {gateway_imei} was accepted
When an operator cancels that pairing from the DMS command history
Then the command shows "Cancelled"
And PSI gets exactly one "Unsuccess" message for {request_id}
And looking up {request_id} shows "cancelled"
```

#### FS-2946 — When the platform gives up resending, PSI gets "Unsuccess"

**Group**: B · **Test level**: Integration · **EMTE**: 1.0 h · **Traceability**: US2-AC4, FR-010, FR-011, SC-002

```gherkin
Scenario: Failure or resilience behavior - the pairing expires
Given the test environment is set up to stop resending after a short time
And PSI's pairing {request_id} was accepted for a gateway that never answers
When the platform stops resending and marks the command "Expired"
Then within 10 minutes PSI gets exactly one "Unsuccess" message for {request_id}
And looking up {request_id} shows "failed", with the command status "Expired"
```

#### FS-2947 — A new pairing replaces an older one that is still waiting

**Group**: C · **Test level**: Integration · **EMTE**: 0.5 h · **Traceability**: US3-AC1, FR-004, FR-011, FR-013, SC-009

```gherkin
Scenario: Successful interaction - pairing B replaces waiting pairing A
Given gateway {gateway_imei} is switched off
And PSI has sent pairing A and got request number {request_id_a}
When PSI sends pairing B for the same gateway, which differs from A only on tire 3
Then the platform accepts B and its reply says it replaced request {request_id_a}
And pairing A is marked "Cancelled" before pairing B is sent
And PSI gets exactly one "Unsuccess" message for {request_id_a}
```

#### FS-2948 — After a replacement the gateway ends up with the newer layout

**Group**: C · **Test level**: Integration · **EMTE**: 1.0 h · **Traceability**: US3-AC2, FR-013, FR-014, SC-009, EC-6

```gherkin
Scenario: Successful interaction - gateway holds exactly pairing B
Given pairing B (request {request_id_b}) replaced pairing A for gateway {gateway_imei}
When the gateway is switched on and accepts pairing B
Then the gateway console shows exactly pairing B, including B's sensor on tire 3
And PSI gets one "Success" message for {request_id_b}
And if a late reply for pairing A arrives, A stays "Cancelled" and PSI gets no second message for A
```

#### FS-2949 — A replaced pairing is never sent again

**Group**: C · **Test level**: Integration · **EMTE**: 1.0 h · **Traceability**: US3-AC3, FR-013, SC-009

```gherkin
Scenario: Failure or resilience behavior - old pairing stays stopped
Given pairing A was replaced while the gateway had not answered
When one or more delivery windows (about 2 days each) pass with the gateway still off
Then pairing A is not sent to the gateway again
And only pairing B is sent again
```

#### FS-2950 — Sending the same pairing twice counts as two requests

**Group**: C · **Test level**: Integration · **EMTE**: 1.0 h · **Traceability**: EC-5, FR-013

```gherkin
Scenario: Successful interaction - PSI repeats a pairing after a timeout
Given gateway {gateway_imei} is switched off
And PSI has sent pairing A and got request number {request_id_1}
When PSI sends exactly the same pairing again
Then the platform accepts it with a new request number {request_id_2} and says it replaced {request_id_1}
And PSI gets "Unsuccess" for {request_id_1}
And once the gateway accepts, PSI gets "Success" for {request_id_2} and the gateway console shows pairing A
```

#### FS-2951 — "Unpair all" removes every sensor from the gateway

**Group**: A · **Test level**: Integration · **EMTE**: 1.0 h · **Traceability**: US4-AC1, FR-008b, FR-008c

```gherkin
Scenario: Successful interaction - 0 tires and no sensors
Given gateway {gateway_imei} has sensors on tires 1 to 8
When PSI sends a pairing with 0 tires, 0 axles and an empty sensor list
Then the platform accepts it
And the gateway is sent 0 tires with every one of the 70 slots empty, plus the "start pairing" trigger
And once the gateway accepts, its console shows no tires in use and every slot cleared
And PSI gets exactly one result message for the request
```

#### FS-2952 — Mistakes in the request are refused and nothing is sent to any gateway

**Group**: D · **Test level**: Integration · **EMTE**: 0.75 h · **Traceability**: US5-AC1, US5-AC2, US5-AC3, US5-AC4, US5-AC5, FR-003, SC-005

```gherkin
Scenario Outline: Interaction variation matrix - bad request is refused before sending
When PSI sends a pairing for gateway {gateway_imei} with this mistake: {mistake}
Then the platform refuses it with status 400 and the reason code {reason_code}
And the refusal message points to {what_is_named}
And no request number is given
And nothing is sent to any gateway, and nothing is added to the DMS command history

Examples:
| mistake                                       | reason_code             | what_is_named                     |
| sensor ID "0x8FB179" (has a 0x prefix)        | INVALID_SENSOR_ID       | the sensor                        |
| sensor ID "8FB1790" (7 characters, too long)  | INVALID_SENSOR_ID       | the sensor                        |
| sensor ID "8FG179" (G is not allowed)         | INVALID_SENSOR_ID       | the sensor                        |
| tire 3 listed twice                           | DUPLICATE_POSITION      | tire 3                            |
| sensor "8FB179" on both tire 2 and tire 6     | DUPLICATE_SENSOR_ID     | the sensor and tires 2 and 6      |
| 71 tires                                      | COUNT_OUT_OF_RANGE      | number of tires                   |
| 25 axles                                      | COUNT_OUT_OF_RANGE      | number of axles                   |
| 8 tires but a sensor on tire 9                | POSITION_OUT_OF_RANGE   | the tire                          |
| 0 tires but one sensor listed                 | POSITION_OUT_OF_RANGE   | the tire                          |
| 2 axles but a sensor on axle 3                | AXLE_OUT_OF_RANGE       | the axle                          |
| a sensor on axle 0                            | AXLE_OUT_OF_RANGE       | the axle                          |
| a sensor in tire group 0                      | TIRE_GROUP_OUT_OF_RANGE | the tire group                    |
| a sensor in tire group 11                     | TIRE_GROUP_OUT_OF_RANGE | the tire group                    |
| number of tires left out                      | MISSING_FIELD           | number of tires                   |
| number of axles left out                      | MISSING_FIELD           | number of axles                   |
| sensor list left out                          | MISSING_FIELD           | sensor list                       |
| a sensor with no sensor ID                    | MISSING_FIELD           | sensor ID and which tire          |
| a sensor with no axle                         | MISSING_FIELD           | axle and which tire               |
| a sensor with no tire group                   | MISSING_FIELD           | tire group and which tire         |
| IMEI with 14 digits instead of 15             | INVALID_IMEI            | the IMEI                          |
```

#### FS-2953 — Devices that are not TrackRR gateways are refused

**Group**: D · **Test level**: Integration · **EMTE**: 0.75 h · **Traceability**: US5-AC6, US5-AC7, US5-AC8, FR-006, SC-005

```gherkin
Scenario Outline: Interaction variation matrix - wrong or unknown device
Given the Asset Service shows IMEI {target_imei} as {device}
When PSI sends a valid pairing for {target_imei}
Then the platform refuses it with status {status} and the reason code {reason_code}
And the refusal message says {message}
And nothing is sent to any gateway

Examples:
| device                        | status | reason_code              | message                                                        |
| not known to the platform     | 404    | GATEWAY_NOT_REGISTERED   | the gateway is not registered                                  |
| a TrackRR Lite (AS500)        | 422    | TRACKRR_LITE_UNSUPPORTED | TrackRR Lite does not support tire sensors                     |
| an MCU                        | 422    | MCU_USE_LOCATION_SET     | it is not a TrackRR, and to use the existing MCU pairing request |
| any other kind of device      | 422    | NOT_A_TRACKRR            | it is not a TrackRR                                            |
```

#### FS-2954 — A gateway the delivery service cannot reach is refused

**Group**: D · **Test level**: Integration · **EMTE**: 0.5 h · **Traceability**: FR-007

```gherkin
Scenario: Failure or resilience behavior - the command cannot be delivered
Given TrackRR gateway {unreachable_imei} is registered in the platform but not set up in the Device Delivery Service
When PSI sends a valid pairing for {unreachable_imei}
Then the platform refuses it with status 502 and the reason code "DISPATCH_FAILED"
And the platform never says the request was accepted
And PSI gets no result message afterwards for this request
```

#### FS-2955 — Gateways on old firmware are refused when the version is known

**Group**: D · **Test level**: Integration · **EMTE**: 0.75 h · **Traceability**: EC-11

```gherkin
Scenario Outline: Interaction variation matrix - gateway firmware version
Given the platform shows gateway {gateway_imei} with firmware {firmware}
When PSI sends a valid pairing for {gateway_imei}
Then {result}

Examples:
| firmware                                | result                                                       |
| known, and older than build ffad85ee    | the platform refuses it with a reason, and nothing is sent   |
| not known                               | the platform accepts it and sends the pairing                |
| known, build 4a5c7657 or newer          | the platform accepts it and sends the pairing                |
```

#### FS-2956 — Lower-case sensor IDs and gaps between tires are handled

**Group**: A · **Test level**: Integration · **EMTE**: 1.0 h · **Traceability**: EC-8, EC-9, FR-005, FR-008c

```gherkin
Scenario: Successful interaction - lower-case ID and gaps in the layout
Given PSI prepares a pairing for gateway {gateway_imei} with 8 tires and sensors on tires 1, 2 and 5
And the sensor on tire 1 is typed in lower case as "8fb179"
When PSI sends the pairing and the gateway accepts it
Then the gateway receives the sensor ID in capitals as "8FB179"
And tires 3, 4, 6, 7 and 8 are sent empty, with 8 tires in use
And the gateway console shows 8 tires in use with sensors only on tires 1, 2 and 5
```

#### FS-2957 — A sensor moved from another gateway is accepted and the other gateway is left alone

**Group**: E · **Test level**: Integration · **EMTE**: 1.0 h · **Traceability**: EC-7

```gherkin
Scenario: Successful interaction - sensor moved between trailers
Given sensor "8FB179" was earlier paired to another gateway {other_imei}
When PSI sends a pairing for gateway {gateway_imei} that includes sensor "8FB179"
Then the platform accepts it and sends it to {gateway_imei}
And nothing is sent to {other_imei}
And the console of {other_imei} shows its layout unchanged
```

#### FS-2958 — Sensors set up by hand on the gateway are overwritten

**Group**: E · **Test level**: Integration · **EMTE**: 1.0 h · **Traceability**: EC-4, FR-008

```gherkin
Scenario: Successful interaction - PSI's layout replaces a hand-made change
Given a technician added a sensor on tire 9 of gateway {gateway_imei} through its console
When PSI sends a layout of 8 tires with sensors on tires 1 to 8
And the gateway accepts it
Then the gateway console shows tire 9 cleared and only the 8 sensors PSI sent
And the platform did not read the gateway's settings before sending
```

#### FS-2959 — A request after a failed one is sent exactly as given

**Group**: E · **Test level**: Integration · **EMTE**: 0.5 h · **Traceability**: EC-3, FR-008

```gherkin
Scenario: Successful interaction - an earlier failure does not affect the next pairing
Given pairing {request_id_1} for gateway {gateway_imei} failed because the gateway rejected it
When PSI sends a new valid pairing for {gateway_imei}
Then the reply says it replaced nothing
And the gateway receives exactly the new layout, with nothing taken from {request_id_1}
```

#### FS-2960 — The result shows the trailer the gateway was on when PSI asked

**Group**: E · **Test level**: Integration · **EMTE**: 0.5 h · **Traceability**: EC-10, FR-012, FR-018

```gherkin
Scenario: Successful interaction - gateway moved to another trailer before it answered
Given PSI's pairing {request_id} was accepted while gateway {gateway_imei} was on trailer {trailer_id}
And the gateway is then moved to trailer {new_trailer_id} before it answers
When the gateway accepts the command
Then PSI's result message for {request_id} shows trailer {trailer_id} and its name
And looking up {request_id} also shows trailer {trailer_id}
```

#### FS-2961 — PSI gets only one result even if the gateway replies more than once

**Group**: F · **Test level**: Integration · **EMTE**: 0.75 h · **Traceability**: EC-1, FR-014, SC-003

```gherkin
Scenario Outline: Interaction variation matrix - repeated or simultaneous replies
Given PSI's pairing {request_id} for gateway {gateway_imei} was accepted
When the gateway's "accepted" reply {reply_pattern}
Then PSI gets exactly one result message for {request_id}
And the platform records the result as delivered to PSI only once

Examples:
| reply_pattern                                              |
| arrives twice                                              |
| is handled by two copies of the platform at the same time  |
| is followed later by a "rejected" reply for the same command |
```

#### FS-2962 — If PSI cannot be reached, the platform tries 3 times and keeps the result

**Group**: F · **Test level**: Integration · **EMTE**: 1.0 h · **Traceability**: EC-2, US6-AC2, FR-015, FR-018, FR-022, SC-008

```gherkin
Scenario: Failure or resilience behavior - PSI's receiver is down
Given the PSI reply receiver is set to answer every message with an error (HTTP 503)
When the gateway accepts pairing {request_id}
Then the platform tries to send PSI the result 3 times: the 2nd try about 30 seconds after the 1st, and the 3rd about 60 seconds after the 2nd
And each failed try is logged as a warning, and one error is logged after the last try
And the platform records the result as "could not be delivered", with 3 tries and the time of the last try
And the command still shows "Completed"
And looking up {request_id} shows "accepted", result "success", and that delivery to PSI failed
```

#### FS-2963 — Looking up a request shows where it stands

**Group**: G · **Test level**: Integration · **EMTE**: 1.0 h · **Traceability**: US6-AC1, US6-AC2, US6-AC3, FR-022

```gherkin
Scenario Outline: Interaction variation matrix - status lookup at each stage
Given pairing {request_id} for gateway {gateway_imei} is {situation}
When PSI looks up request {request_id}
Then the lookup shows the gateway IMEI, the state {state}, the result {result} and whether PSI was told: {psi_told}
And looking it up does not change anything

Examples:
| situation                                    | state       | result       | psi_told     |
| sent, waiting for the gateway                | in progress | none yet     | not yet      |
| accepted, and PSI was told                   | accepted    | success      | yes          |
| rejected by the gateway                      | failed      | unsuccessful | yes          |
| expired                                      | failed      | unsuccessful | yes          |
| cancelled by an operator                     | cancelled   | unsuccessful | yes          |
| replaced by a newer pairing                  | cancelled   | unsuccessful | yes          |
```

#### FS-2964 — The lookup reveals nothing for unknown requests or callers without permission

**Group**: G · **Test level**: Integration · **EMTE**: 0.75 h · **Traceability**: US6-AC4, FR-021, FR-022

```gherkin
Scenario Outline: Interaction variation matrix - lookup is refused
When a caller {caller} looks up {lookup_id}
Then {result}

Examples:
| caller                                       | lookup_id                              | result                                                        |
| with the pairing permission                  | a request number that does not exist   | refused with status 404 "REQUEST_NOT_FOUND" and no other data |
| with the pairing permission                  | the number of a non-pairing command    | refused with status 404 "REQUEST_NOT_FOUND" and no other data |
| whose login lacks the pairing permission     | a real pairing request number          | refused with HTTP 403 and no request data                     |
| with no login token                          | a real pairing request number          | refused with HTTP 401 and no request data                     |
```

#### FS-2965 — Callers without the pairing permission are stopped before anything happens

**Group**: D · **Test level**: Integration · **EMTE**: 0.75 h · **Traceability**: EC-12, FR-021

```gherkin
Scenario Outline: Failure or resilience behavior - caller not allowed to pair
When a caller {caller} sends a valid pairing for gateway {gateway_imei}
Then the platform refuses it with HTTP {http_status}
And the platform does not look up the gateway
And nothing is sent to any gateway

Examples:
| caller                                   | http_status |
| whose login lacks the pairing permission | 403         |
| with no login token                      | 401         |
| with an invalid login token              | 401         |
```

#### FS-2966 — With pairing switched off, requests are refused

**Group**: D · **Test level**: Integration · **EMTE**: 0.5 h · **Traceability**: EC-13, FR-019

```gherkin
Scenario: Failure or resilience behavior - feature switched off in this environment
Given tire sensor pairing is switched off in this environment
When PSI sends a valid pairing for gateway {gateway_imei}
Then the platform refuses it with status 503, reason code "PAIRING_DISABLED", and a message saying TrackRR pairing is not available here
And nothing is sent to any gateway
```

#### FS-2967 — The old MCU pairing request tells PSI to use the TrackRR request

**Group**: H · **Test level**: Integration · **EMTE**: 0.5 h · **Traceability**: EC-14, FR-020

```gherkin
Scenario: Failure or resilience behavior - MCU request sent for a TrackRR trailer
Given trailer {trailer_id} has a TrackRR gateway
When PSI sends the existing MCU pairing request for trailer {trailer_id}
Then the platform still refuses it
And the refusal message tells PSI to use the TrackRR pairing request instead
And nothing is sent to any gateway
```

#### FS-2968 — MCU pairing works exactly as before

**Group**: H · **Test level**: Integration · **EMTE**: 0.5 h · **Traceability**: FR-001, FR-020, FR-021, SC-006

```gherkin
Scenario: Successful interaction - MCU pairing is not affected
Given an MCU test gateway is installed on trailer {mcu_trailer_id}
When PSI sends the existing MCU pairing request for one sensor, with the same fields and login as today
And the MCU gateway confirms the pairing
Then PSI's reply and result message have the same fields, values and timing as before this release
And the MCU result message has no gateway IMEI field
```

#### FS-2969 — The gateway's reply to Firmware Ready is matched to the right command

**Group**: H · **Test level**: Integration · **EMTE**: 0.5 h · **Traceability**: FR-009c, SC-010

```gherkin
Scenario: Successful interaction - Firmware Ready now carries its message ID in field 104
Given a TrackRR test gateway is waiting for a firmware update
When DMS sends it the Firmware Ready command
Then the command carries the message ID in field 104, field 1210 set to "[02]", and no field 100
And the gateway's reply repeats that message ID in field 104
And DMS matches the reply to the correct Firmware Ready command
```

#### FS-2970 — Everything is recorded for audit, and PSI's password never appears

**Group**: I · **Test level**: Integration · **EMTE**: 1.0 h · **Traceability**: FR-018, SC-007

```gherkin
Scenario: Successful interaction - check the audit records and logs after testing
Given during testing one pairing was accepted, one was refused, and one result message to PSI needed a retry
When the tester checks the DMS command history, the stored result messages and the DMS logs from the test run
Then the accepted pairing's record shows the layout sent, the gateway's answer, the gateway, and its trailer and organization at the time
And the refused pairing is logged with its reason
And every try to send a result to PSI is logged, with the number of tries and the last try recorded
And the stored copy of each result message shows the PSI key as "***REDACTED***"
And searching all records and logs finds PSI's shared key zero times
```

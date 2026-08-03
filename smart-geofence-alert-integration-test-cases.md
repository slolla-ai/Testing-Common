Test Type: Integration

Feature: Integration - Alert Rules Engine to Snapshot Persistence Interaction

Purpose:
Validate that the alert rules engine correctly resolves in-scope trailers for a Smart Geofence, captures crossing snapshots and alert details on boundary events, and persists them without disrupting existing geofence processing.

Base URLs:
px-alert-rules-engine: resolved via environment configuration
asset (PostgreSQL): resolved via environment configuration

Background:
Given px-alert-rules-engine is operational and consuming geofence crossing events
And a Smart Geofence configuration references one or more existing STANDARD alert configurations
And the asset schema tables mmr_smart_geofence_ref_config, dat_smart_geofence_crossing_snapshot, and dat_smart_geofence_alert_detail exist

Automation Recommendation: automatable

Payloads (optional):
entry_crossing_event: geofence entry event for an in-scope trailer
exit_crossing_event: geofence exit event for an in-scope trailer

---

Scenario: Successful interaction - entry crossing produces a persisted snapshot with alert details
When an in-scope trailer with active alerts crosses into a Smart Geofence boundary
Then the rules engine should resolve the trailer as in-scope via the union of referenced configuration asset sets
And a dat_smart_geofence_crossing_snapshot row should be persisted with crossing_direction=ENTRY, the trailer identifier, geofence identifier, timestamp, and active alert count
And one dat_smart_geofence_alert_detail row should be persisted per active alert, each with type, category, and trigger
Automation Recommendation: automatable
Traceability: US2-AC1, FR-005, FR-006, FR-007

---

Scenario: Successful interaction - exit crossing produces a separate persisted snapshot reflecting alert state at exit
When the same trailer later crosses out of the Smart Geofence boundary
Then a separate dat_smart_geofence_crossing_snapshot row should be persisted with crossing_direction=EXIT and the alert state at the moment of exit
And the entry snapshot should remain unchanged
Automation Recommendation: automatable
Traceability: US2-AC2, FR-006

---

Scenario: Successful interaction - zero-alert crossing still produces a snapshot
When a trailer with zero active alerts crosses a Smart Geofence boundary
Then a snapshot should be persisted with active_alert_count=0 and no dat_smart_geofence_alert_detail rows
Automation Recommendation: automatable
Traceability: US2-AC3, FR-008

---

Scenario: Successful interaction - trailer belonging to multiple selected configurations is evaluated once
When a trailer that belongs to more than one of the Smart Geofence's selected existing alert configurations crosses the boundary
Then exactly one snapshot should be persisted for that trailer and crossing direction
And the notification payload should include the union of active alert details from all applicable configurations, not duplicated per configuration
Automation Recommendation: automatable
Traceability: EC-2, FR-005

---

Scenario: Successful interaction - deactivated referenced configuration is silently excluded from scope
When a previously referenced existing alert configuration is deleted or deactivated
And a trailer that belonged only to that deactivated configuration crosses the Smart Geofence boundary
Then no snapshot should be persisted for that trailer
And the remaining selected configurations should continue to be evaluated normally with no error surfaced
Automation Recommendation: automatable
Traceability: EC-1, FR-013

---

Scenario: Failure or resilience behavior - out-of-scope trailer produces no snapshot
When a trailer that does not belong to any of the Smart Geofence's selected existing alert configurations crosses the boundary
Then no dat_smart_geofence_crossing_snapshot row should be persisted for that trailer at that geofence
And no unintended side effects should occur to other in-scope trailers' processing
Automation Recommendation: automatable
Traceability: US2-AC4

---

Scenario: Failure or resilience behavior - snapshot persistence failure does not interrupt geofence event processing
When the snapshot persistence step fails for a given crossing event due to a downstream data error
Then the failure should be logged
And the main geofence event processing flow should continue uninterrupted for other trailers and configurations
Automation Recommendation: automatable
Traceability: FR-007

---

Scenario: Successful interaction - independent evaluation of Standard and Smart configurations on the same boundary
When a geofence has both a Standard and a Smart alert configuration saved for the same boundary
And a trailer in scope of both crosses the boundary
Then each configuration should be evaluated independently
And the Smart configuration's snapshot capture should not be affected by the Standard configuration's processing, or vice versa
Automation Recommendation: automatable
Traceability: EC-4

---

Scenario Outline: Interaction variation matrix - in-scope resolution outcomes
When a trailer crosses the Smart Geofence boundary under <input_variant>
Then <expected interaction outcome> should occur

Examples:
| input_variant | expected interaction outcome |
| trailer in exactly one referenced configuration | one snapshot persisted, scoped alerts from that configuration only |
| trailer in two referenced configurations (overlap) | one snapshot persisted, union of alert details from both configurations |
| trailer in zero referenced configurations | no snapshot persisted |
| referenced configuration deactivated between crossings | trailer silently drops out of scope for subsequent crossings |

Automation Recommendation: automatable
Traceability: US2-AC1, US2-AC4, EC-1, EC-2, FR-005, FR-013

---

Scenario: Snapshot capture completes within 60 seconds under real GPS connectivity in a staging environment
When an in-scope trailer with active GPS connectivity crosses a Smart Geofence boundary in a staging environment with real IoT ingest
Then the crossing snapshot should be persisted within 60 seconds of the boundary event
And this holds across a representative sample of trailers, achieving a 100% capture rate for trailers with active GPS connectivity
Automation Recommendation: manual
Traceability: US2-AC1, SC-002

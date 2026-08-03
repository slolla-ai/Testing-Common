Test Type: Component API

Feature: Component API - Alert Configuration API Smart Geofence Behavior

Purpose:
Validate the alert configuration API's handling of Smart geofence mode — create/update/read of geofenceMode and referencedAlertConfigKeys, and rejection of invalid payload combinations.

Base URLs:
px-alert-notify-service: resolved via environment configuration

Background:
Given the px-alert-notify-service API is operational
And required test data (existing STANDARD alert configurations) is available for the account

Automation Recommendation: automatable

Payloads (optional):
smart_geofence_create_payload: geofenceMode=SMART, referencedAlertConfigKeys=[configA, configB]
standard_geofence_create_payload: geofenceMode=STANDARD, trailerAssetKeys=[...]

---

Scenario: Successful request - create a Smart Geofence alert configuration
When px-alert-notify-service sends POST request to /v{n}/alerts with a valid Smart geofence payload (geofenceMode=SMART, referencedAlertConfigKeys populated, no asset keys)
Then the response status should be 2xx
And the response should conform to the API contract, including the persisted geofenceMode and referencedAlertConfigKeys
Automation Recommendation: automatable
Traceability: US1-AC2, FR-002, FR-004, FR-005

---

Scenario: Validation or error handling - Smart Geofence payload missing referencedAlertConfigKeys
When px-alert-notify-service sends POST request to /v{n}/alerts with geofenceMode=SMART and an empty or missing referencedAlertConfigKeys list
Then the response status should be 400
And the response should contain an error indicating at least one existing alert configuration is required
And no configuration should be persisted
Automation Recommendation: automatable
Traceability: US1-AC3, FR-004

---

Scenario: Validation or error handling - Smart Geofence payload includes asset or asset-group keys
When px-alert-notify-service sends POST request to /v{n}/alerts with geofenceMode=SMART and non-empty trailerAssetKeys or trailerAssetGroupKeys
Then the response status should be 400
And the response should contain an error indicating assets are not permitted in Smart mode
And no configuration should be persisted with asset associations
Automation Recommendation: automatable
Traceability: FR-002

---

Scenario: Successful request - read a Smart Geofence alert configuration
When px-alert-notify-service sends GET request to /v{n}/alerts/{key} for a saved Smart geofence configuration
Then the response status should be 200
And the response should include geofenceMode=SMART and the full list of referencedAlertConfigKeys
Automation Recommendation: automatable
Traceability: US1-AC2, FR-002

---

Scenario: Validation or error handling - referenced alert configuration key does not reference a STANDARD configuration
When px-alert-notify-service sends POST request to /v{n}/alerts with a referencedAlertConfigKeys entry pointing to another SMART configuration
Then the response status should be 400
And the response should contain an error indicating only STANDARD configurations may be referenced
And no configuration should be persisted
Automation Recommendation: automatable
Traceability: FR-005

---

Scenario Outline: Input variation matrix - geofence mode payload combinations
When px-alert-notify-service sends request with <payload_variant>
Then <expected outcome> should occur

Examples:
| payload_variant | expected outcome |
| geofenceMode=SMART, referencedAlertConfigKeys=[validKey], no asset keys | 2xx success, configuration persisted with mode SMART |
| geofenceMode=SMART, referencedAlertConfigKeys=[], no asset keys | 400 validation error |
| geofenceMode=STANDARD, trailerAssetKeys=[validKey] | 2xx success, unchanged existing behavior |
| geofenceMode=SMART, referencedAlertConfigKeys=[selfKey] (self-reference) | 400 validation error |

Automation Recommendation: automatable
Traceability: US1-AC2, US1-AC3, FR-002, FR-004, FR-005

---

Feature: Component API - Smart Geofence Alert Health Report API Behavior

Purpose:
Validate the paginated and full Smart Geofence Alert Health Report endpoints — response shape, entry/exit counts, alert detail drill-down, and date-range filtering.

Base URLs:
px-report-service: resolved via environment configuration

Background:
Given the px-report-service API is operational
And crossing snapshot and alert detail test data exists for a Smart Geofence location

Automation Recommendation: automatable

---

Scenario: Successful request - paginated Smart Geofence Alert Health report
When px-report-service sends POST request to /v{n}/reports/smartgeofencealert with a valid organizationKey, accountKey, and date range
Then the response status should be 200
And the response should conform to the API contract, returning crossings with trailer identifier, entry alert count, exit alert count, and alert detail arrays
Automation Recommendation: automatable
Traceability: US3-AC1, US3-AC2, FR-010

---

Scenario: Successful request - Smart Geofence Alert Health report filtered by date range
When px-report-service sends POST request to /v{n}/reports/smartgeofencealert with fromDate and toDate set to a bounded range
Then the response status should be 200
And the response should include only crossings whose snapshotDatetime falls within the requested range
Automation Recommendation: automatable
Traceability: US3-AC4, FR-011

---

Scenario: Validation or error handling - report request with an invalid date range
When px-report-service sends POST request to /v{n}/reports/smartgeofencealert with fromDate later than toDate
Then the response status should be 400
And the response should contain an error describing the invalid range
And no partial or malformed result set should be returned
Automation Recommendation: automatable
Traceability: FR-011

---

Scenario: Successful request - unpaginated full report retrieval
When px-report-service sends POST request to /v{n}/reports/smartgeofencealert/all with a valid filter set
Then the response status should be 200
And the response should return the complete unpaginated set of matching crossings
Automation Recommendation: automatable
Traceability: US3-AC1, FR-010

---

Scenario Outline: Input variation matrix - report crossing states
When px-report-service sends request with <payload_variant>
Then <expected outcome> should occur

Examples:
| payload_variant | expected outcome |
| crossing with activeAlertCount=0 on exit | crossing returned with activeAlertCount=0 and an empty alertDetails array |
| crossing with activeAlertCount>0 on exit | crossing returned with activeAlertCount>0 and populated alertDetails array |
| crossing with entry snapshot only (no exit) | crossing returned with entry fields populated and exit fields absent/null |

Automation Recommendation: automatable
Traceability: US2-AC3, US3-AC3, EC-3, FR-008, FR-012

---

Scenario: Report response time meets the platform's standard reporting response expectations under representative data volume
When px-report-service sends POST request to /v{n}/reports/smartgeofencealert against a representative production-scale volume of crossing snapshots and alert details
Then the response is returned within a time consistent with the platform's other standard reporting endpoints
And no timeout or degraded response is observed
Automation Recommendation: manual
Traceability: US3-AC4, SC-005

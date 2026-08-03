Test Type: Component UI

Feature: Component UI - Alert Configuration Form Geofence Mode Behavior

Purpose:
Validate the Standard/Smart geofence mode toggle, the existing-alert-configuration picker, save validation, and mode-switch state handling on the alert configuration form.

Automation Recommendation: automatable

Background:
Given the user is on the geofence alert configuration form
And the user has permission to create or edit alert configurations for the current account

---

Scenario: Selecting Smart mode replaces asset selection with the existing alert configuration picker
Given the alert configuration form is displayed with the asset/asset-group selection section visible
When the user selects the "Smart" geofence mode radio option
Then the asset/asset-group selection section is hidden
And a multi-select picker for existing alert configurations within the account is displayed in its place
Automation Recommendation: automatable
Traceability: US1-AC1, FR-001, FR-002, FR-003

---

Scenario: Saving a Smart Geofence configuration with configurations selected persists correctly and stores no assets
Given Smart mode is active and the user selects one or more existing alert configurations
When the user saves the configuration
Then the configuration is saved with mode set to Smart
And the selected existing alert configurations are recorded
And no assets or asset-groups are stored on this configuration
Automation Recommendation: automatable
Traceability: US1-AC2, FR-002, FR-004

---

Scenario: Save is blocked when Smart mode is active and no existing alert configuration is selected
Given Smart mode is active and no existing alert configuration has been selected
When the user attempts to save the form
Then validation prevents the save from proceeding
And a clear error message is displayed indicating at least one existing alert configuration is required
Automation Recommendation: automatable
Traceability: US1-AC3, FR-004

---

Scenario: Switching from Smart mode back to Standard mode restores asset selection
Given Smart mode is active with the existing-alert-configuration picker displayed
When the user switches the geofence mode back to "Standard"
Then the asset/asset-group selection section reappears
And the existing-alert-configuration picker is hidden
Automation Recommendation: automatable
Traceability: US1-AC4, FR-001

---

Scenario: Shared configuration fields retain their values when switching between Standard and Smart mode on an unsaved form
Given the user has entered values in the shared fields (geofence boundary, recipients, schedule, messaging) on an unsaved form
When the user switches the geofence mode between Standard and Smart one or more times
Then the shared field values are not lost or corrupted
Automation Recommendation: automatable
Traceability: FR-014, FR-015

---

Scenario Outline: Geofence mode selection controls which selector is visible
Given the alert configuration form is displayed
When the user selects the "<mode>" geofence mode
Then the "<visible_selector>" is displayed
And the "<hidden_selector>" is hidden

Automation Recommendation: automatable
Traceability: US1-AC1, US1-AC4, FR-001, FR-002, FR-003

Examples:
| mode     | visible_selector                     | hidden_selector                       |
| Standard | asset/asset-group selector           | existing alert configuration picker   |
| Smart    | existing alert configuration picker  | asset/asset-group selector            |

---

Scenario: Manager completes a Smart Geofence configuration within the 5-minute usability target
Given a yard or operations manager opens the alert configuration form for the first time in this session
When the manager selects Smart mode, selects existing alert configurations, sets the geofence boundary, configures recipients and schedule, and saves
Then the configuration is saved successfully
And the end-to-end elapsed time from opening the form to a saved configuration is under 5 minutes
Automation Recommendation: manual
Traceability: US1-AC2, SC-001

---

Feature: Component UI - Smart Geofence Alert Health Report View Behavior

Purpose:
Validate the per-location alert health report list, crossing drill-down, visual distinction of unresolved-alert exits, and date-range filtering.

Automation Recommendation: automatable

Background:
Given a Smart Geofence location has one or more recorded crossing snapshots
And the user has permission to view the alert health report for the location

---

Scenario: Alert health report lists crossings with entry and exit alert counts
Given the user opens the alert health report for a Smart Geofence location
When the report loads
Then the report displays a list of crossings with trailer identifier, entry alert count, and exit alert count for each crossing
Automation Recommendation: automatable
Traceability: US3-AC1, FR-010

---

Scenario: Expanding a crossing row reveals individual entry and exit alert details
Given a crossing row is shown in the alert health report
When the user expands the row
Then the individual alerts for both the entry and exit snapshots are displayed
And each alert shows its type, category, and trigger
Automation Recommendation: automatable
Traceability: US3-AC2, FR-010

---

Scenario: Crossings with unresolved exit alerts are visually distinguished
Given a trailer exited a Smart Geofence with one or more active alerts
When that crossing is shown in the alert health report
Then the crossing row is visually distinguished from crossings where the exit alert count is zero
Automation Recommendation: manual
Traceability: US3-AC3, FR-012

---

Scenario: Date-range filter restricts the report to crossings within the selected range
Given the alert health report is displayed with crossings spanning multiple dates
When the user applies a date-range filter
Then the report shows only crossings within that range
Automation Recommendation: automatable
Traceability: US3-AC4, FR-011

---

Scenario: An open crossing with no exit event is shown as incomplete in the report
Given a trailer entered a Smart Geofence and no exit event was ever received
When the alert health report is displayed for that location
Then the crossing is shown as open/incomplete with the entry snapshot present and no exit data
Automation Recommendation: automatable
Traceability: EC-3, FR-010

---

Scenario: Reviewer identifies a trailer that exited with unresolved alerts within 5 minutes of the exit event
Given a trailer has just exited a Smart Geofence with one or more active alerts
When a reviewer opens the alert health report within 5 minutes of the exit event
Then the reviewer can identify the unresolved-alert crossing without additional investigation or manual data lookup
Automation Recommendation: manual
Traceability: US3-AC3, SC-004

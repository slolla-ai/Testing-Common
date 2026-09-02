Test Type: Component UI

Feature: Component UI - Associate Device Screen Behavior

Purpose:
Validate GPS ID lookup, device ribbon rendering, asset properties form, required-field validation, no-match handling, error states, and navigation on the Associate Device screen of the Fus1on Mobile App.

Automation Recommendation: automatable

Background:
Given the Fus1on Mobile App is running on a compatible mobile device
And the user is authenticated and has been redirected to the Associate Device screen
And the authenticated user belongs to organization "Fleet-Org-A"

---

Scenario: Save asset properties after successful GPS device lookup
Given the Associate Device screen is displayed
And a GPS device with GPS ID "800000000000030" exists within "Fleet-Org-A"
And the user has entered GPS ID "800000000000030" manually and the device is found
And the Asset Properties form is displayed with Asset Name, Description, VIN, and Asset Status fields
When the user enters Asset Name "Truck-Alpha", VIN "1HGCM82633A004352", and leaves Asset Status as "Active"
And the user submits the save action
Then the system persists the asset association for GPS ID "800000000000030"
And a success confirmation is displayed to the user
And the device ribbon updates to show Asset Name "Truck-Alpha", VIN "1HGCM82633A004352", Status "Active", GPS ID "800000000000030"
Automation Recommendation: automatable
Traceability: US2-AC2, US2-AC3, FR-010, FR-011, FR-012, SC-003

---

Scenario: Required-field validation blocks save when Asset Name is blank
Given a GPS device has been found and the Asset Properties form is displayed
And the user leaves the Asset Name field blank
And the user fills in VIN "1HGCM82633A004352" and Asset Status "Active"
When the user attempts to save
Then a validation error is surfaced on the Asset Name field
And the save operation does not proceed
And no asset association is persisted
Automation Recommendation: automatable
Traceability: US2-AC4, FR-009, SC-006

---

Scenario: Required-field validation blocks save when VIN is blank
Given a GPS device has been found and the Asset Properties form is displayed
And the user fills in Asset Name "Truck-Alpha" and Asset Status "Active"
And the user leaves the VIN field blank
When the user attempts to save
Then a validation error is surfaced on the VIN field
And the save operation does not proceed
And no asset association is persisted
Automation Recommendation: automatable
Traceability: US2-AC4, FR-009, SC-006

---

Scenario: Required-field validation blocks save when Asset Status is cleared
Given a GPS device has been found and the Asset Properties form is displayed
And the user fills in Asset Name "Truck-Alpha" and VIN "1HGCM82633A004352"
And the user clears the Asset Status dropdown so no value is selected
When the user attempts to save
Then a validation error is surfaced on the Asset Status field
And the save operation does not proceed
Automation Recommendation: automatable
Traceability: US2-AC4, FR-009, SC-006

---

Scenario: GPS device found via manual GPS ID entry
Given the Associate Device screen is displayed with "Fleet-Org-A" selected
And a GPS device with GPS ID "800000000000030" and GPS Model "TrackRR Solar" exists within "Fleet-Org-A"
When the user manually enters GPS ID "800000000000030" and submits the search
Then the system displays the read-only device ribbon containing GPS ID "800000000000030" and GPS Model "TrackRR Solar"
And the Asset Properties form is displayed with Asset Name, Description, VIN, and Asset Status fields
Automation Recommendation: automatable
Traceability: US1-AC3, FR-002, FR-005, FR-006, FR-007, SC-001, SC-002

---

Scenario: GPS device found via camera scan
Given the Associate Device screen is displayed with "Fleet-Org-A" selected
And the device camera is available and camera permission is granted
And a GPS device with GPS ID "800000000000030" exists within "Fleet-Org-A"
When the user scans the GPS ID barcode using the device camera
Then the system reads and submits GPS ID "800000000000030"
And the device ribbon is displayed with the GPS device details
And the Asset Properties form is displayed
Automation Recommendation: manual
Traceability: US1-AC4, FR-003, FR-005, FR-006, FR-007, SC-001, SC-002

---

Scenario: Network unavailable during GPS ID search shows appropriate error
Given the Associate Device screen is displayed with "Fleet-Org-A" selected
And the device has no network connectivity
When the user enters a GPS ID and submits the search
Then the system displays a network error message indicating the search could not be completed
And the GPS entry area remains active so the user can retry once connectivity is restored
And no partial device or asset data is displayed
Automation Recommendation: automatable
Traceability: US1-AC3, EC-2, FR-005

---

Scenario: Save operation fails due to server error
Given a GPS device has been found and the Asset Properties form is displayed
And all required fields are filled in correctly
And the backend service returns a server error on save
When the user submits the save action
Then the success confirmation is NOT displayed
And an error message communicating the save failure is shown to the user
And the Asset Properties form remains populated so the user can retry
Automation Recommendation: automatable
Traceability: US2-AC2, EC-3, FR-010

---

Scenario: Save operation fails due to connectivity error
Given a GPS device has been found and the Asset Properties form is displayed
And all required fields are filled in correctly
And the device loses network connectivity before the save completes
When the user submits the save action
Then the system displays a connectivity error message
And the Asset Properties form remains populated with the user's input
And no partial asset association is persisted
Automation Recommendation: automatable
Traceability: US2-AC2, EC-3, FR-010

---

Scenario: No Match Found message shown with Retry and Exit options
Given the Associate Device screen is displayed with "Fleet-Org-A" selected
And no GPS device with GPS ID "000000000000000" exists within "Fleet-Org-A"
When the user enters GPS ID "000000000000000" and submits the search
Then the system displays a "No Match Found" message
And both a "Retry" option and an "Exit" option are presented to the user
And the device ribbon and Asset Properties form are NOT displayed
Automation Recommendation: automatable
Traceability: US1-AC6, US3-AC1, FR-013, FR-014, SC-004

---

Scenario: Retry from No Match Found returns user to GPS ID entry step
Given the "No Match Found" screen is displayed with Retry and Exit options
When the user selects "Retry"
Then the user is returned to the GPS ID entry and scanning step
And the GPS ID input field is empty and ready for a new entry
Automation Recommendation: automatable
Traceability: US3-AC2, FR-015

---

Scenario: Exit from No Match Found returns user to app main navigation
Given the "No Match Found" screen is displayed with Retry and Exit options
When the user selects "Exit"
Then the Associate Device flow ends
And the user is returned to the app's main navigation
Automation Recommendation: automatable
Traceability: US3-AC3

---

Scenario: Unassigned GPS device ribbon shows N/A for asset fields and Unassigned status
Given the Associate Device screen is displayed with "Fleet-Org-A" selected
And GPS device with GPS ID "800000000000030" is not associated with any asset
When the device is found via GPS ID lookup
Then the device ribbon displays Asset Name as "N/A"
And the ribbon displays VIN as "N/A"
And the ribbon displays Status as "Unassigned"
And the ribbon displays GPS ID "800000000000030" and GPS Model "TrackRR Solar"
Automation Recommendation: automatable
Traceability: US1-AC5, FR-006

---

Scenario: Camera permission denied prevents scanning and shows appropriate message
Given the Associate Device screen is displayed
And the user has denied camera permission for the mobile app
When the user attempts to activate the GPS ID camera scanner
Then the camera viewfinder does not activate
And the system displays a message informing the user that camera permission is required for scanning
And the manual GPS ID text input remains accessible as an alternative
Automation Recommendation: manual
Traceability: US1-AC4, EC-1, FR-003

---

Scenario: Camera hardware unavailable prevents scanning
Given the Associate Device screen is displayed
And the mobile device has no functioning camera hardware
When the camera viewfinder area is presented
Then the camera scanning functionality is non-functional or hidden
And the manual GPS ID text input remains accessible as the primary entry method
Automation Recommendation: manual
Traceability: US1-AC4, EC-1, FR-003

---

Scenario: Multiple devices share the same GPS ID and the system handles the result
Given GPS ID "800000000000030" is registered to more than one GPS device within "Fleet-Org-A"
When the user submits GPS ID "800000000000030" as a search
Then the system returns a deterministic result or surfaces a meaningful error
And the user is not left on a broken or blank screen
And no unintended asset association can occur due to the ambiguous match
Automation Recommendation: manual
Traceability: US1-AC3, EC-4, FR-005

---

Scenario: Navigating away mid-edit without saving does not persist partial changes
Given a GPS device has been found and the user has partially filled the Asset Properties form
And the user has entered Asset Name "Truck-Alpha" but has NOT submitted a save
When the user navigates away from the Associate Device screen using the back navigation arrow
Then the partial asset property data is NOT persisted
And the GPS device retains its previous association state
Automation Recommendation: automatable
Traceability: US2-AC2, EC-5, FR-010

---

Scenario: Organization pre-populated with user's own organization on screen load
Given the authenticated user belongs to organization "Fleet-Org-A"
When the Associate Device screen loads
Then the Organization field is pre-populated with "Fleet-Org-A"
And no GPS ID has been entered yet
Automation Recommendation: automatable
Traceability: US1-AC1, FR-001

---

Scenario: User changes organization to another accessible organization before search
Given the Associate Device screen is displayed with "Fleet-Org-A" pre-selected
And the user has access to organization "Fleet-Org-B"
And a GPS device with GPS ID "900000000000001" exists within "Fleet-Org-B" only
When the user changes the Organization field to "Fleet-Org-B"
And the user enters GPS ID "900000000000001" and submits the search
Then the GPS device from "Fleet-Org-B" is found and displayed
And the asset properties form is shown scoped to "Fleet-Org-B"
Automation Recommendation: automatable
Traceability: US1-AC2, FR-001

---

Scenario: Asset Properties form displays correct fields including optional Description
Given a GPS device has been found on the Associate Device screen
When the Asset Properties form loads
Then the form displays Asset Name field marked as required
And the form displays Description field marked as optional
And the form displays VIN field marked as required
And the form displays Asset Status dropdown marked as required
Automation Recommendation: automatable
Traceability: US2-AC1, FR-007

---

Scenario: Asset Status field defaults to Active when the Asset Properties form first loads
Given a GPS device has been found on the Associate Device screen
When the Asset Properties form loads for the first time
Then the Asset Status dropdown is pre-set to "Active"
Automation Recommendation: automatable
Traceability: US2-AC1, FR-008

---

Scenario: GPS ID field validates that a non-empty value is required before search is submitted
Given the Associate Device screen is displayed with an organization selected
And the GPS ID input field is empty
When the user attempts to submit a search without entering a GPS ID
Then the system prevents the search submission
And a validation message is shown indicating a GPS ID is required
Automation Recommendation: automatable
Traceability: US1-AC3, FR-004

---

Scenario: Login redirects authenticated user to the Associate Device screen
Given a user with valid credentials launches the Fus1on Mobile App
When the user completes the login flow
Then the Associate Device screen is displayed as the landing screen
And the Organization field is pre-populated with the user's organization
Automation Recommendation: automatable
Traceability: FR-016, US1-AC1

---

Scenario Outline: Required-field validation across all three mandatory fields
Given a GPS device has been found and the Asset Properties form is displayed
And the user leaves <blank_field> empty while filling in the other required fields
When the user attempts to save
Then a validation error is surfaced on the <blank_field> field
And the save operation does not proceed

Automation Recommendation: automatable
Traceability: US2-AC4, FR-009, SC-006

Examples:
| blank_field  |
| Asset Name   |
| VIN          |
| Asset Status |

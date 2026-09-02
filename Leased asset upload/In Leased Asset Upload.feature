Feature: Leased Asset Upload
  Validate the Leased Assets tab in Assets Settings: list view with search, filter, pagination, and export;
  upload workflow with lessee org selection, file processing, and results view; template download;
  post-upload navigation; and upload audit trail.

  Background:
    Given the user is authenticated and has an account selected in the navbar
    And the account has associated lessee organizations
    And the user has Admin role unless stated otherwise

  # ── US1: Browse Leased Assets List ─────────────────────────────────────

  @TC-LAU-001
  Scenario: Admin sees Leased Assets tab after SKF Assets tab
    Given the user has Admin role with an account selected
    When the user navigates to Assets Settings
    Then the "Leased Assets" tab is visible immediately after the "SKF Assets" tab
    And the list view loads as the default content

  @TC-LAU-002
  Scenario: List table shows the four required columns
    Given the Leased Assets tab is selected for an account with leased records
    When the list view loads
    Then the table displays columns "Lessee Organization Name", "Trailer Name", "MCU Device ID", and "Status"
    And Status shows "Active" for active records and "Inactive" for soft-deleted records

  @TC-LAU-003
  Scenario: Trailer Name search filters rows in real-time
    Given the Leased Assets list view is loaded with records including Trailer Name "TRAILER-001"
    When the user types "TRAILER-001" in the Trailer Name search field
    Then the table updates to show only rows whose Trailer Name contains "TRAILER-001"
    And rows not containing "TRAILER-001" are removed from view

  @TC-LAU-004
  Scenario: MCU Device ID search filters rows in real-time
    Given the Leased Assets list view is loaded with records including MCU Device ID "MCU123456"
    When the user types "MCU123" in the MCU Device ID search field
    Then the table updates to show only rows whose MCU Device ID contains "MCU123"

  @TC-LAU-005
  Scenario: List view is paginated matching the asset search page pattern
    Given the selected account has more than 25 leased asset records
    When the Leased Assets tab opens
    Then the table shows at most 25 rows on the first page
    And pagination controls are displayed matching the asset search page pattern

  @TC-LAU-006
  Scenario: Export CSV with no active filter contains all records and correct columns
    Given the Leased Assets list view is loaded with no search filter applied
    When the user clicks the export button and selects "CSV"
    Then a CSV file downloads containing Lessee Organization Name, Trailer Name, MCU Device ID, and Status columns
    And the file contains all records for the selected account

  @TC-LAU-007
  Scenario: Export Excel with no active filter uses correct content type
    Given the Leased Assets list view is loaded with no search filter applied
    When the user clicks the export button and selects "Excel"
    Then an Excel file downloads with Content-Type "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

  @TC-LAU-008
  Scenario: Export CSV respects the active Trailer Name search filter
    Given the Leased Assets list view has a Trailer Name filter of "TRAILER-A" applied
    When the user clicks the export button and selects "CSV"
    Then the downloaded CSV contains only rows where Trailer Name contains "TRAILER-A"
    And records not matching the active filter are excluded

  @TC-LAU-009
  Scenario: Non-Admin user cannot see the Leased Assets tab
    Given the user has Viewer role with an account selected
    When the user navigates to Assets Settings
    Then the "Leased Assets" tab is not visible

  @TC-LAU-010
  Scenario: Empty state shown when account has no leased asset records
    Given the selected account has no leased asset records
    When the Leased Assets tab is opened
    Then the table displays an empty state with no error message

  # ── US2: Select Lessee Organization and Upload File ──────────────────────

  @TC-LAU-011
  Scenario: Upload view opens with org list inline and file zone inactive until org selected
    Given the user is an Admin on the Leased Assets list view
    When the user clicks "Upload File"
    Then the upload view opens and displays the lessee organization list inline at the top
    And the file drop zone is inactive
    And the Upload button is inactive

  @TC-LAU-012
  Scenario: Selecting a lessee organization activates the full upload form
    Given the upload view is open with the lessee organization list displayed
    When the user selects a lessee organization from the list
    Then the file drop zone becomes active
    And the Browse Files control becomes active
    And the column format hint shows TrailerName, MCUID, IsDeleted
    And the Download Template link is visible
    And the Upload button becomes active

  @TC-LAU-013 @manual
  Scenario: Drag-and-drop accepts a .xlsx file onto the drop zone
    Given the upload form is active with a lessee organization selected
    When the user drags a valid .xlsx file onto the drop zone
    Then the file is accepted and shown as ready for upload

  @TC-LAU-014
  Scenario: Browse Files accepts a .xls file
    Given the upload form is active with a lessee organization selected
    When the user selects a .xls file via Browse Files
    Then the file is accepted and shown as ready for upload

  @TC-LAU-015
  Scenario: Browse Files accepts a .csv file
    Given the upload form is active with a lessee organization selected
    When the user selects a .csv file via Browse Files
    Then the file is accepted and shown as ready for upload

  @TC-LAU-016
  Scenario: All-success upload shows success chip and green success table
    Given a valid 10-row CSV is selected with a lessee organization chosen
    When the user clicks Upload and all 10 rows pass validation
    Then a "10 Successful" chip is displayed
    And a green success table shows all 10 rows with columns Trailer Name, MCU Device ID, Lease Key, Processed At
    And no failure table is shown

  @TC-LAU-017
  Scenario: Partial upload shows both chips and failure table with per-row reasons
    Given a 10-row CSV where 8 rows are valid and 2 rows reference non-existent Trailer Names
    When the user clicks Upload and the upload completes
    Then an "8 Successful" chip is displayed
    And a "2 Failed" chip is displayed
    And a failure table shows the 2 failed rows with a specific Failure Reason per row

  @TC-LAU-018
  Scenario: Non-Admin user cannot see the Upload File button
    Given the user has Viewer role on the Leased Assets list view
    When the list view loads
    Then the "Upload File" button is not visible

  @TC-LAU-019
  Scenario: Upload is blocked with inline error when no account is selected
    Given the upload form is displayed and no account is selected in the navbar
    When the user clicks Upload
    Then an inline error message is displayed
    And no upload request is sent to the server

  @TC-LAU-020
  Scenario: Unsupported file format is rejected before upload submission
    Given the upload form is active with a lessee organization selected
    When the user attempts to attach a .pdf file
    Then the file is rejected with an error indicating accepted formats are .xlsx, .xls, .csv
    And no upload request is sent to the server

  # ── US3: Download Upload Template ───────────────────────────────────────

  @TC-LAU-021
  Scenario: Download Template triggers immediate file download
    Given the upload form is displayed with a lessee organization selected
    When the user clicks "Download Template"
    Then a file named "leased_asset_template.csv" downloads immediately within 3 seconds

  @TC-LAU-022
  Scenario: Downloaded template has correct headers, example row, and no Lease ID column
    Given the user has downloaded the leased asset upload template
    When the user opens the file
    Then it contains column headers TrailerName, MCUID, IsDeleted
    And it contains at least one example data row
    And the file does not contain a LeaseID or Lease Key column

  # ── US4: Return to List After Upload ────────────────────────────────────

  @TC-LAU-023
  Scenario: Back button from results view returns user to the list view
    Given the upload results view is displayed after a completed upload
    When the user clicks Back
    Then the user is returned to the Leased Assets list view

  @TC-LAU-024
  Scenario: List view reloads and reflects uploaded changes within 5 seconds
    Given the user just completed an upload that created new leased asset records
    When the user clicks Back from the results view
    Then the list includes the records created by the upload
    And the reload completes within 5 seconds

  # ── US5: Upload Audit ────────────────────────────────────────────────────

  @TC-LAU-025 @manual
  Scenario: Successful upload generates a complete linked audit record
    Given an Admin uploads a valid 10-row CSV where all rows succeed
    When the upload completes and the audit log is inspected
    Then one audit record exists with uploader identity, original filename, S3 storage path, total rows 10, success 10, failure 0, and status COMPLETED
    And the S3 path resolves to the original uploaded file

  @TC-LAU-026 @manual
  Scenario: All-failure upload produces audit record with status FAILED
    Given an Admin uploads a 5-row CSV where all 5 rows fail validation
    When the upload completes and the audit record is inspected
    Then the audit record status is FAILED
    And success count is 0 and failure count is 5

  @TC-LAU-027 @manual
  Scenario: Partial upload produces audit record with status PARTIAL
    Given an Admin uploads a 10-row CSV where 6 rows succeed and 4 rows fail
    When the upload completes and the audit record is inspected
    Then the audit record status is PARTIAL
    And success count is 6 and failure count is 4

  @TC-LAU-028 @manual
  Scenario: S3 archival failure aborts upload with no rows processed and no audit record
    Given S3 storage is configured to reject writes
    When an Admin submits a valid upload file
    Then the upload is aborted immediately
    And the user sees an error indicating the file could not be archived
    And no data rows are processed
    And no audit record is written to the database

  # ── Edge Cases ───────────────────────────────────────────────────────────

  @TC-LAU-029
  Scenario: Account with no lessee organizations shows empty state and blocks upload
    Given the selected account has no lessee organizations in the dat_leased table
    When the user clicks "Upload File"
    Then the lessee organization list shows an empty state message
    And the file drop zone and Upload button remain unavailable

  @TC-LAU-030
  Scenario: Header-only CSV completes with zero counts and COMPLETED audit status
    Given a CSV containing only the header row (TrailerName,MCUID,IsDeleted) is selected
    When the user clicks Upload
    Then the results view shows "0 Successful" and "0 Failed"
    And the audit record is created with status COMPLETED and zero row counts

  @TC-LAU-031
  Scenario: Row with unrecognized MCU Device ID fails with specific failure reason
    Given the upload CSV contains a row with MCUID "MCU-DOES-NOT-EXIST" not in the asset registry
    When the upload completes
    Then that row appears in the failure table with a reason indicating the MCU Device ID was not found

  @TC-LAU-032
  Scenario: Row with unrecognized Trailer Name fails with specific failure reason
    Given the upload CSV contains a row with TrailerName "TRAILER-UNKNOWN-XYZ" not matching any registered trailer
    When the upload completes
    Then that row appears in the failure table with a reason indicating the Trailer Name was not found

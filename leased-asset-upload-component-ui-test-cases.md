Test Type: Component UI + API Integration

Feature: Component UI + API — Leased Asset Upload

Purpose:
Validate the Leased Assets tab in Assets Settings: list view with search, filter, pagination, and export; upload workflow with lessee org selection, file processing, and results view; template download; post-upload navigation; and upload audit trail.

Automation Recommendation: mixed — list, upload flow, and navigation scenarios are automatable; drag-and-drop, S3 fault injection, and direct audit log inspection require manual execution

Background:
Given the user is authenticated and has an account selected in the navbar
And the account has associated lessee organizations unless the scenario specifies otherwise
And the user has Admin role unless the scenario specifies a different role

---

Scenario: Leased Assets tab is visible to Admin after SKF Assets tab
Given the user has Admin role with an account selected
When the user navigates to Assets Settings
Then the "Leased Assets" tab is visible immediately after the "SKF Assets" tab
And the list view loads as the default content
Automation Recommendation: automatable
Traceability: US1-AC1, FR-001, FR-003, SC-004

---

Scenario: List table shows the four required columns
Given the Leased Assets tab is selected for an account with leased records
When the list view loads
Then the table displays columns: Lessee Organization Name, Trailer Name, MCU Device ID, and Status
And Status shows "Active" for active records and "Inactive" for soft-deleted records
Automation Recommendation: automatable
Traceability: US1-AC2, FR-002

---

Scenario: Typing in Trailer Name search field filters rows in real-time
Given the Leased Assets list view is loaded with multiple records
And at least one record has Trailer Name "TRAILER-001"
When the user types "TRAILER-001" in the Trailer Name search field
Then the table updates to show only rows whose Trailer Name contains "TRAILER-001"
And rows that do not contain "TRAILER-001" in the Trailer Name are removed from view
Automation Recommendation: automatable
Traceability: US1-AC3, FR-018, SC-007

---

Scenario: Typing in MCU Device ID search field filters rows in real-time
Given the Leased Assets list view is loaded with multiple records
And at least one record has MCU Device ID "MCU123456"
When the user types "MCU123" in the MCU Device ID search field
Then the table updates to show only rows whose MCU Device ID contains "MCU123"
Automation Recommendation: automatable
Traceability: US1-AC4, FR-018, SC-007

---

Scenario: List view is paginated matching the asset search page pattern
Given the selected account has more than 25 leased asset records
When the Leased Assets tab opens
Then the table shows at most 25 rows on the first page
And pagination controls are displayed matching the asset search page pattern
And navigating to the next page shows the next set of records
Automation Recommendation: automatable
Traceability: US1-AC5, FR-022

---

Scenario: Export CSV with no active filter contains all records and correct columns
Given the Leased Assets list view is loaded with no search filter applied
When the user clicks the export button and selects "CSV"
Then a file is downloaded with Content-Disposition containing "leased-assets-export.csv"
And the file contains the four columns: Lessee Organization Name, Trailer Name, MCU Device ID, Status
And the file contains all records for the selected account
Automation Recommendation: automatable
Traceability: US1-AC6, FR-023

---

Scenario: Export Excel with no active filter streams with correct content type
Given the Leased Assets list view is loaded with no search filter applied
When the user clicks the export button and selects "Excel"
Then an Excel file is downloaded
And the response Content-Type is "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
And Content-Disposition contains "leased-assets-export.xlsx"
Automation Recommendation: automatable
Traceability: US1-AC6, FR-023

---

Scenario: Export CSV respects the active Trailer Name search filter
Given the Leased Assets list view has a Trailer Name filter of "TRAILER-A" applied
And the account has records both matching and not matching "TRAILER-A"
When the user clicks the export button and selects "CSV"
Then the downloaded CSV contains only rows where Trailer Name contains "TRAILER-A"
And records not matching the active filter are excluded from the export
Automation Recommendation: automatable
Traceability: US1-AC7, FR-023

---

Scenario: Non-Admin user cannot see the Leased Assets tab
Given the user has Viewer role with an account selected
When the user navigates to Assets Settings
Then the "Leased Assets" tab is not visible
Automation Recommendation: automatable
Traceability: US1-AC8, FR-001, SC-004

---

Scenario: Empty state shown when account has no leased asset records
Given the selected account has no leased asset records
When the Leased Assets tab is opened
Then the table displays an empty state with no error message
And no data rows are shown
Automation Recommendation: automatable
Traceability: US1-AC9, FR-002

---

Scenario: Upload view opens with org list inline and file zone inactive until org selected
Given the user is an Admin on the Leased Assets list view
And the account has at least one associated lessee organization
When the user clicks "Upload File"
Then the upload view opens and displays the lessee organization list inline at the top
And the file drop zone is inactive and does not accept files
And the Upload button is inactive
Automation Recommendation: automatable
Traceability: US2-AC1, FR-019, FR-020

---

Scenario: Selecting a lessee organization activates the upload form
Given the upload view is open with the lessee organization list displayed
When the user selects a lessee organization from the list
Then the file drop zone becomes active
And the Browse Files control becomes active
And the column format hint is visible showing TrailerName, MCUID, IsDeleted
And the Download Template link is visible
And the Upload button becomes active
Automation Recommendation: automatable
Traceability: US2-AC2, FR-020, FR-008

---

Scenario: Drag-and-drop accepts a .xlsx file onto the drop zone
Given the upload form is active with a lessee organization selected
When the user drags a valid .xlsx file onto the drop zone
Then the file is accepted and shown as ready for upload
Automation Recommendation: manual
Traceability: US2-AC3, FR-005, FR-006

---

Scenario: Browse Files accepts a .xls file
Given the upload form is active with a lessee organization selected
When the user selects a .xls file via Browse Files
Then the file is accepted and shown as ready for upload
Automation Recommendation: automatable
Traceability: US2-AC3, FR-005, FR-006

---

Scenario: Browse Files accepts a .csv file
Given the upload form is active with a lessee organization selected
When the user selects a .csv file via Browse Files
Then the file is accepted and shown as ready for upload
Automation Recommendation: automatable
Traceability: US2-AC3, FR-005, FR-006

---

Scenario: All-success upload shows success chip and green success table
Given a valid 10-row CSV file is selected with a lessee organization chosen
When the user clicks Upload and all 10 rows pass validation
Then a "10 Successful" chip is displayed with green styling
And a success table with green row highlighting shows all 10 rows
And each success row shows: Trailer Name, MCU Device ID, Lease Key, Processed At
And no failure table is shown or the failure table is empty
Automation Recommendation: automatable
Traceability: US2-AC5, FR-010

---

Scenario: Partial upload shows both chips and failure table with per-row reasons
Given a 10-row CSV where 8 rows are valid and 2 rows reference Trailer Names that do not exist
When the user clicks Upload and the upload completes
Then an "8 Successful" chip is displayed
And a "2 Failed" chip is displayed
And a failure table with red row highlighting shows the 2 failed rows
And each failure row displays the specific Failure Reason for that row
Automation Recommendation: automatable
Traceability: US2-AC6, FR-010, FR-011, SC-003

---

Scenario: Non-Admin user cannot see the Upload File button
Given the user has Viewer role on the Leased Assets list view
When the list view loads
Then the "Upload File" button is not visible
Automation Recommendation: automatable
Traceability: US2-AC7, FR-004, FR-016, SC-004

---

Scenario: Upload is blocked with inline error when no account is selected
Given the upload form is displayed
And no account is selected in the navbar
When the user clicks Upload
Then an inline error message is displayed
And no upload request is sent to the server
Automation Recommendation: automatable
Traceability: US2-AC8, FR-009

---

Scenario: Unsupported file format is rejected before upload submission
Given the upload form is active with a lessee organization selected
When the user attempts to attach a .pdf file
Then the file is rejected
And an error message is displayed indicating accepted formats are .xlsx, .xls, .csv
And no upload request is sent to the server
Automation Recommendation: automatable
Traceability: US2-AC9, FR-005

---

Scenario: Download Template triggers immediate file download within 3 seconds
Given the upload form is displayed with a lessee organization selected
When the user clicks "Download Template"
Then a file named "leased_asset_template.csv" downloads immediately
And the download completes within 3 seconds
Automation Recommendation: automatable
Traceability: US3-AC1, FR-007, SC-006

---

Scenario: Downloaded template has correct headers and example row with no Lease ID column
Given the user has downloaded the leased asset upload template
When the user opens the file
Then it contains column headers: TrailerName, MCUID, IsDeleted
And it contains at least one example data row
And the file does not contain a LeaseID or Lease Key column
And the column format hint in the upload form confirms Lease ID is resolved automatically
Automation Recommendation: automatable
Traceability: US3-AC2, US3-AC3, FR-007, FR-008

---

Scenario: Back button from results view returns user to the list view
Given the upload results view is displayed after a completed upload
When the user clicks Back
Then the user is returned to the Leased Assets list view
Automation Recommendation: automatable
Traceability: US4-AC1, FR-012

---

Scenario: List view reloads and reflects uploaded changes within 5 seconds of clicking Back
Given the user just completed an upload that created new leased asset records
When the user clicks Back from the results view and the list reloads
Then the list includes the records created by the upload
And the reload completes within 5 seconds
Automation Recommendation: automatable
Traceability: US4-AC2, FR-012, SC-005

---

Scenario: Successful upload generates a complete linked audit record
Given an Admin uploads a valid 10-row CSV where all rows succeed
When the upload completes and the audit log is inspected
Then one audit record exists containing: uploader identity, original filename, S3 storage path, total row count 10, success count 10, failure count 0, and status COMPLETED
And the S3 storage path in that record resolves to the original uploaded file
Automation Recommendation: manual
Traceability: US5-AC1, US5-AC2, FR-013, SC-002

---

Scenario: All-failure upload produces audit record with status FAILED and zero success count
Given an Admin uploads a 5-row CSV where all 5 rows fail validation
When the upload completes and the audit record is inspected
Then the audit record status is FAILED
And success count is 0
And failure count is 5
Automation Recommendation: manual
Traceability: US5-AC3, FR-013, SC-002

---

Scenario: Partial upload produces audit record with status PARTIAL
Given an Admin uploads a 10-row CSV where 6 rows succeed and 4 rows fail
When the upload completes and the audit record is inspected
Then the audit record status is PARTIAL
And success count is 6
And failure count is 4
Automation Recommendation: manual
Traceability: US5-AC4, FR-013, SC-002

---

Scenario: S3 archival failure aborts upload with no rows processed and no audit record
Given the S3 storage is configured to reject writes
When an Admin submits a valid upload file
Then the upload is aborted immediately
And the user sees an error message indicating the file could not be archived
And no data rows are processed or persisted
And no audit record is written to the database
Automation Recommendation: manual
Traceability: US5-AC1, FR-014, EC-7

---

Scenario: Account with no lessee organizations shows empty state and prevents upload
Given the selected account has no lessee organizations in the dat_leased table
When the user clicks "Upload File"
Then the lessee organization list shows an empty state message
And the file drop zone and Upload button remain unavailable
Automation Recommendation: automatable
Traceability: FR-021, EC-1

---

Scenario: Uploading a header-only CSV completes with zero counts and COMPLETED audit status
Given the upload form is active and a CSV containing only the header row (TrailerName,MCUID,IsDeleted) is selected
When the user clicks Upload
Then the results view shows "0 Successful" and "0 Failed"
And the audit record is created with status COMPLETED and zero success and failure counts
Automation Recommendation: automatable
Traceability: EC-3, FR-013

---

Scenario: Row with unrecognized MCU Device ID fails with a specific failure reason
Given the upload CSV contains a row with MCUID "MCU-DOES-NOT-EXIST" not in the asset registry
When the upload completes
Then that row appears in the failure table
And the failure reason for that row indicates the MCU Device ID was not found
Automation Recommendation: automatable
Traceability: EC-4, FR-011, SC-003

---

Scenario: Row with unrecognized Trailer Name fails with a specific failure reason
Given the upload CSV contains a row with TrailerName "TRAILER-UNKNOWN-XYZ" not matching any registered trailer
When the upload completes
Then that row appears in the failure table
And the failure reason for that row indicates the Trailer Name was not found
Automation Recommendation: automatable
Traceability: EC-5, FR-011, SC-003

---

Scenario Outline: All three accepted file formats are accepted via Browse Files
Given the upload form is active with a lessee organization selected
When the user selects a file with extension <extension> via Browse Files
Then the file is accepted and shown as ready for upload

Automation Recommendation: automatable
Traceability: US2-AC3, FR-005

Examples:
| extension |
| .xlsx     |
| .xls      |
| .csv      |

---

Scenario Outline: Unsupported file formats are rejected before submission
Given the upload form is active with a lessee organization selected
When the user attempts to attach a file with extension <extension>
Then the file is rejected before submission
And an error message is shown indicating only .xlsx, .xls, and .csv are accepted

Automation Recommendation: automatable
Traceability: US2-AC9, FR-005

Examples:
| extension |
| .pdf      |
| .txt      |
| .docx     |

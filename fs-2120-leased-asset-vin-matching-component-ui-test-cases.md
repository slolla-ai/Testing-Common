Test Type: Component UI

Feature: Leased Asset Upload & List - VIN Template, Upload Results Display, Exception Report, and List VIN Support

Purpose:\
Validate that the px-web-app Leased Assets upload template, upload-results display (success section
telemetry, renamed/downloadable Exception Report), and Leased Assets list correctly present the
outcomes of VIN-based trailer matching (FS-2120) — without validating the VIN-matching, duplicate-
detection, or lease-resolution logic itself, which is exercised at the Component-API/Integration layer.

Component Location:
microservice: px-web-app

```gherkin
Background:
Given the user is authenticated in px-web-app with an account selected
And the user is on the Leased Assets view within Assets Settings
And a Lessee Organization is selected via the {Lessee Organization} selector
```

## [px-web-app][FS-2120-leased-asset-vin-matching] - Downloaded template reflects the VIN-based 3-column format

```gherkin
Scenario: Downloaded template names VIN and drops MCUID
  Given the user is on the Leased Asset Upload view with a Lessee Organization selected
  When the user activates {Download Template}
  Then a file named "leased_asset_template.csv" downloads
  And the file's header row reads "TrailerName,VIN,IsDeleted"
  And the file does not contain an "MCUID" column
  And the example data row carries a well-formed 17-character VIN
```

Automation Recommendation: Do Not Automate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: US3-AC1, FR-001, SC-003

---

## [px-web-app][FS-2120-leased-asset-vin-matching] - Upload form column hint names VIN instead of MCUID

```gherkin
Scenario: Column-format hint on the upload form reflects the VIN column
  Given the user is on the Leased Asset Upload view with a Lessee Organization selected
  When the upload form renders its column-format hint
  Then the hint text names "TrailerName, VIN, IsDeleted"
  And the hint text does not name "MCUID"
```

Automation Recommendation: Do Not Automate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: US3-AC1, FR-001

---

## [px-web-app][FS-2120-leased-asset-vin-matching] - Successful match displays VIN, Trailer Name, and live telemetry

```gherkin
Scenario: Success row shows VIN, Uploaded Asset Name, Last Communication Date, and MCU Battery Level
  Given the upload response contains a successful row with VIN "1FUJGLDR9CSBW1234", Uploaded Asset Name
    "TRAILER-001", Last Communication Date "2026/07/31 08:00:00", and MCU Battery Level "87"
  When the "Successfully Updated" table renders that row
  Then the row's {VIN} column shows "1FUJGLDR9CSBW1234"
  And the row's {Uploaded Asset Name} column shows "TRAILER-001"
  And the row's {Last Communication Date} column shows "2026/07/31 08:00:00"
  And the row's {MCU Battery Level} column shows "87"
```

Automation Recommendation: Do Not Automate

Status: N/A

EMTE: {It must be updated by the test reviewer}

Traceability: US1-AC1, FR-011, SC-007

---

## [px-web-app][FS-2120-leased-asset-vin-matching] - Success row shows blank telemetry without becoming an error state

```gherkin
Scenario: Success row with no telemetry data renders blank Last Communication Date and MCU Battery Level
  Given the upload response contains a successful row whose Last Communication Date and MCU Battery
    Level are both absent
  When the "Successfully Updated" table renders that row
  Then the row still appears in the success table, not the Exception Report
  And the row's {Last Communication Date} column is blank
  And the row's {MCU Battery Level} column is blank
  And no error or warning indicator is shown on that row
```

Automation Recommendation: Do Not Automate

Status: N/A

EMTE: {It must be updated by the test reviewer}

Traceability: US1-AC3, FR-012, SC-007

---

## [px-web-app][FS-2120-leased-asset-vin-matching] - Success row displays the VIN exactly as returned, without normalization

```gherkin
Scenario: VIN column preserves the letter case returned by the API
  Given the upload response contains a successful row with VIN "1FujGLdr9csBW1234"
  When the "Successfully Updated" table renders that row
  Then the row's {VIN} column shows "1FujGLdr9csBW1234" exactly, with no case change applied by the UI
```

Automation Recommendation: Do Not Automate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: US1-AC4, FR-013

---

## [px-web-app][FS-2120-leased-asset-vin-matching] - Exception Report is shown on screen whenever a row fails

```gherkin
Scenario: Failure section renders under the Exception Report heading
  Given the upload response contains at least one row in the failed list
  When the upload results view renders
  Then a section titled "Exception Report" is displayed on screen
```

Automation Recommendation: Do Not Automate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: US2-AC3, FR-007

---

## [px-web-app][FS-2120-leased-asset-vin-matching] - Exception Report row shows the "VIN is missing" reason for a blank VIN

```gherkin
Scenario: Blank-VIN failure row displays its reason, blank VIN, and row number
  Given the upload response contains a failed row with VIN blank, Uploaded Asset Name "TRAILER-002",
    Row Number "4", and Failure Reason "VIN is missing"
  When the Exception Report renders that row
  Then the row's {VIN} column is blank
  And the row's {Uploaded Asset Name} column shows "TRAILER-002"
  And the row's {Row Number} column shows "4"
  And the row's {Failure Reason} column shows "VIN is missing"
```

Automation Recommendation: Do Not Automate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: US2-AC1, FR-002, FR-010, SC-002

---

## [px-web-app][FS-2120-leased-asset-vin-matching] - Exception Report row shows the "not found" reason for an unmatched VIN/Trailer Name

```gherkin
Scenario: Unmatched-row failure displays the not-found reason, VIN, and row number
  Given the upload response contains a failed row with VIN "1FUJGLDR9CSBW9999", Uploaded Asset Name
    "TRAILER-UNKNOWN", Row Number "7", and Failure Reason "VIN and Trailer Name not found in Lessee
    Organization"
  When the Exception Report renders that row
  Then the row's {VIN} column shows "1FUJGLDR9CSBW9999"
  And the row's {Uploaded Asset Name} column shows "TRAILER-UNKNOWN"
  And the row's {Row Number} column shows "7"
  And the row's {Failure Reason} column shows "VIN and Trailer Name not found in Lessee Organization"
```

Automation Recommendation: Do Not Automate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: US2-AC2, FR-005, FR-010, SC-002

---

## [px-web-app][FS-2120-leased-asset-vin-matching] - Exception Report row shows a duplicate-record reason naming the VIN

```gherkin
Scenario: Duplicate-VIN failure row displays the duplicate reason naming that VIN
  Given the upload response contains a failed row whose Failure Reason names the duplicated VIN
    "1FUJGLDR9CSBW1234" as a duplicate record
  When the Exception Report renders that row
  Then the row's {Failure Reason} column shows the duplicate-record text naming "1FUJGLDR9CSBW1234"
```

Automation Recommendation: Do Not Automate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: US2-AC4, FR-021

---

## [px-web-app][FS-2120-leased-asset-vin-matching] - Exception Report row displays two joined failure reasons together

```gherkin
Scenario: A row failing for two reasons shows both, joined, with a blank VIN
  Given the upload response contains a failed row with VIN blank and Failure Reason
    "VIN is missing; duplicate record for Trailer Name TRAILER-003"
  When the Exception Report renders that row
  Then the row's {Failure Reason} column shows both "VIN is missing" and the duplicate-record text
    naming "TRAILER-003"
  And the row's {VIN} column is blank
```

Automation Recommendation: Do Not Automate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: US2-AC4a, FR-021, FR-029, SC-002

---

## [px-web-app][FS-2120-leased-asset-vin-matching] - Exception Report preserves the original row number and uploaded values

```gherkin
Scenario: Failed row shows its original row number and the values as uploaded
  Given the upload response contains a failed row with Row Number "12", VIN blank, and Uploaded Asset
    Name blank
  When the Exception Report renders that row
  Then the row's {Row Number} column shows "12"
  And the row's {VIN} and {Uploaded Asset Name} columns are both blank, unaltered from the upload
```

Automation Recommendation: Do Not Automate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FR-010

---

## [px-web-app][FS-2120-leased-asset-vin-matching] - Exception Report can be downloaded from the results view

```gherkin
Scenario: Download control on the Exception Report produces a file
  Given the Exception Report is displayed with at least one failed row
  When the user activates the {Download} control beside the Exception Report heading
  Then a file downloads in the same format as the existing Leased Assets list export
```

Automation Recommendation: Do Not Automate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: US2-AC3, FR-007

---

## [px-web-app][FS-2120-leased-asset-vin-matching] - Whole-file rejection message is shown with no result tables

```gherkin
Scenario: A rejection message suppresses both the success and failure tables
  Given the upload response carries a rejection message directing the user to the current template,
    with no successful and no failed rows
  When the upload results view renders
  Then the rejection message is displayed on screen
  And neither the "Successfully Updated" table nor the Exception Report is displayed
```

Automation Recommendation: Do Not Automate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: US2-AC6, FR-020

---

## [px-web-app][FS-2120-leased-asset-vin-matching] - An already-deleted delete row appears as successful, not failed

```gherkin
Scenario: Idempotent delete row is shown in the success table, not the Exception Report
  Given the upload response contains a row for a delete that resolved to an entry already removed,
    placed in the successful list
  When the upload results view renders
  Then that row appears in the "Successfully Updated" table
  And that row does not appear in the Exception Report
```

Automation Recommendation: Do Not Automate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: US5-AC3, FR-018, SC-002

---

## [px-web-app][FS-2120-leased-asset-vin-matching] - Leased Assets list displays the VIN column, including placeholder VINs

```gherkin
Scenario: List renders a VIN column for every row
  Given the Leased Assets list response includes entries carrying a VIN, including one entry carrying
    a placeholder-style VIN
  When the Leased Assets list renders
  Then every row's {VIN} column shows its VIN value exactly as returned
```

Automation Recommendation: Do Not Automate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: US6-AC1, FR-023, SC-009

---

## [px-web-app][FS-2120-leased-asset-vin-matching] - Leased Assets list export includes the VIN column

```gherkin
Scenario: Exported list file contains the VIN column shown on screen
  Given the Leased Assets list view is loaded with at least one entry
  When the user activates the list's {Download} control and selects an export format
  Then the exported file contains a VIN column matching what is shown on screen
```

Automation Recommendation: Do Not Automate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: US6-AC2, FR-023

---

## [px-web-app][FS-2120-leased-asset-vin-matching] - "Search By" includes VIN and filters the list

```gherkin
Scenario: Selecting VIN in Search By filters the Leased Assets list
  Given the Leased Assets list view is loaded with multiple entries
  When the user selects "VIN" in {Search By} and enters a VIN value
  Then the list request includes that VIN value as the active filter
  And the list updates to show only entries matching that VIN
```

Automation Recommendation: Do Not Automate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: US6-AC3, FR-023

---

## [px-web-app][FS-2120-leased-asset-vin-matching] - Leased Assets list still shows the existing GPS ID column

```gherkin
Scenario: GPS ID column remains present alongside the new VIN column
  Given the Leased Assets list response includes entries carrying a GPS ID value
  When the Leased Assets list renders
  Then every row's {GPS ID} column shows its stored value
  And "GPS ID" remains available as a {Search By} option
```

Automation Recommendation: Do Not Automate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FR-001

---

## [px-web-app][FS-2120-leased-asset-vin-matching] - Leased Assets list renders only the entries returned for the acting lessor

```gherkin
Scenario: List shows exactly what the API returns for the acting Lessor Organization
  Given the Leased Assets list response for the selected Lessee Organization contains only entries
    belonging to the acting Lessor Organization
  When the Leased Assets list renders
  Then only those entries are displayed
  And no entry belonging to a different Lessor Organization appears in the table
```

Automation Recommendation: Do Not Automate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: US6-AC4, FR-032

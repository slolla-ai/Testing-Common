Test Type: Component API

Feature: Shipment upload and intake APIs - web app upload, asset service import and mailbox hand-off behavior

Purpose:\
Check that each shipment API, tested on its own, accepts good requests and refuses bad ones with the right response

Base URLs:\
web_app_api: {It must be updated by the test reviewer}\
asset_service: {It must be updated by the test reviewer}

Payloads (optional):\
valid_file: {a 12-column FS-2772 CSV with valid rows — attached to the Zephyr test case}\
reordered_file: {a 12-column FS-2772 CSV with the columns in a different order}\
file_10000_rows: {a 12-column FS-2772 CSV with exactly 10000 rows}\
file_10001_rows: {a 12-column FS-2772 CSV with 10001 rows}\
header_only_file: {a 12-column FS-2772 CSV with the header row and no data rows}\
file_over_10mb: {a 12-column FS-2772 CSV larger than 10 MB}\
old_fs2430_file: {an FS-2430 11-column CSV}\
as500_file: {an AS500 10-column CSV}\
file_missing_agreement_column: {an FS-2772 CSV without the Agreement Number column}\
import_request: {the asset service import request with file name, contact email and 12-field rows}\
old_shape_import_request: {an asset service import request using the retired FS-2430 field names}\
mailbox_handoff_request: {the mailbox hand-off request with the stored file location, file name, received time, message ID and sender}

```gherkin
Background:
Given the web app upload API "POST ~/v2/assets/shipments/import-shipments" accepts a CSV file and a contact email from a signed-in user
And the asset service import API "POST v2/shipments/import-shipments" accepts shipment rows from the web app
And the asset service mailbox API "POST /v1/shipments/intake" accepts files handed over by the intake mailbox
And every service behind the API under test is replaced by a predictable test stand-in
```

[NEEDS CLARIFICATION: The spec does not say which success status code and response body the two import APIs return, or which status the asset service returns for a request in the old FS-2430 format. The reviewer must fill in {import success status}, {old format refusal status} and any response fields before approving these cases.]

@FS-2909
## [px-web-app-api][FS-2772-seon-shipment-file-automation] - Super-admin's 12-column file is accepted and passed on with all 12 values

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

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: US1-AC1, FR-001, FR-002

---

@FS-2910
## [px-web-app-api][FS-2772-seon-shipment-file-automation] - File with the wrong columns is refused straight away

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

Automation Recommendation: Candidate

Status: Created

EMTE: 1.0

Traceability: US1-AC7, FR-002, FR-003, FR-020

---

[NEEDS CLARIFICATION: FR-015 says the web app "forwards only the twelve columns", which suggests a file with an extra column is accepted and the extra column dropped. The routing contract says any other header is refused with 400. Confirm which is right before a test case is added for a file with an extra column.]

@FS-2911
## [px-web-app-api][FS-2772-seon-shipment-file-automation] - Upload limit of 10000 rows is enforced

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

Automation Recommendation: Candidate

Status: Created

EMTE: 1.0

Traceability: US1-AC6, US1-AC7, FR-014, FR-020, SC-005

---

@FS-2912
## [px-web-app-api][FS-2772-seon-shipment-file-automation] - File with a header but no rows is refused straight away

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

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: EC-16, FR-020, SC-005

---

@FS-2913
## [px-web-app-api][FS-2772-seon-shipment-file-automation] - File larger than 10 MB is refused straight away

```gherkin
Scenario: Upload over the size limit
  Given the user is super-admin {Super Admin}
  When the user uploads file_over_10mb
  Then the web app API responds with status 400
  And nothing is passed to the asset service and no run is created
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: FR-020, SC-005

---

@FS-2914
## [px-web-app-api][FS-2772-seon-shipment-file-automation] - Non-super-admin upload is refused with 403

```gherkin
Scenario: The asset service refuses an ordinary user and the web app passes that on
  Given the user is ordinary user {Ordinary User}
  And the asset service stand-in answers 403
  When the user uploads valid_file
  Then the web app API responds with status 403
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: FR-031

---

@FS-2915
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Super-admin import is accepted and recorded as a customer shipment run

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

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: FR-001, FR-031

---

@FS-2916
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Import from a non-super-admin is refused with 403 and nothing is recorded

```gherkin
Scenario: An ordinary user's import is refused
  Given customer shipment processing is switched on
  And the request comes from ordinary user {Ordinary User}, who is not a super-admin
  When the web app sends import_request to the asset service
  Then the asset service responds with status 403
  And no run is recorded and no row is processed
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: FR-031

---

@FS-2917
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Import is refused with 404 and an empty response while the feature is switched off

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

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: SC-005

---

@FS-2918
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Empty import request is refused with 400

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

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: FR-020, SC-005

---

@FS-2919
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Import in the old FS-2430 format is refused

```gherkin
Scenario: Rows use the retired FS-2430 field names
  Given customer shipment processing is switched on
  And the request comes from super-admin {Super Admin}
  When the web app sends old_shape_import_request to the asset service
  Then the asset service responds with status {old format refusal status}
  And no run is recorded and no row is processed
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: FR-002

---

@FS-2920
## [px-asset-service][FS-2772-seon-shipment-file-automation] - File handed over by the intake mailbox is accepted with 202 and a run number

```gherkin
Scenario: The mailbox hands a file to the asset service
  Given mailbox intake is switched on
  When the intake mailbox sends mailbox_handoff_request to the asset service as the system user
  Then the asset service responds with status 202
  And response body contains:
    | field      | expected_value | validation_type |
    | shipmentId | —              | not_empty       |
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: US1-AC1, FR-001

---

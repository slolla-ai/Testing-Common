Test Type: Component UI

Feature: Shipment Processing Results - View summary, failed records, and export

Purpose:\
Confirm the shipment processing results screen shows accurate summary counts and failed-record details, and is only reachable by authenticated internal users

Base URLs (optional):\
app_ui: {It must be updated by the test reviewer}

Component Location:
microservice: dms-web-app

```gherkin
Background:
Given the shipment results page is accessible
And the page loads without errors
And the coordinator is logged in as an internal user
And a shipment file has finished processing
```

@FS-2550
## [dms-web-app][FS-2541-primax-shipment-ddp-provisioning] - Coordinator sees the processing summary as soon as processing finishes

```gherkin
Scenario: Processing summary appears immediately with no extra step
Given the coordinator opens the shipment results page
And the shipment that just finished processing has 2 records that succeeded and 1 record that failed
When the results page finishes loading
Then the Summary panel shows "Total: 3"
And the Summary panel shows "Succeeded: 2"
And the Summary panel shows "Failed: 1"
And the coordinator does not need to click anything to see these counts
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: US2-AC1, US2-AC2, FR-008, FR-009

---

@FS-2551
## [dms-web-app][FS-2541-primax-shipment-ddp-provisioning] - Coordinator sees IMEI, ICCID, GPS Part Number, and failure reason for each failed record

```gherkin
Scenario: Failed Records list shows every identifying field plus the failure reason
Given the coordinator opens the shipment results page
And the shipment has at least one failed record
When the coordinator views the Failed Records list
Then each row in the Failed Records list shows the following details:
  | field           | shown   |
  | IMEI            | visible |
  | ICCID           | visible |
  | GPS Part Number | visible |
  | Failure Reason  | visible |
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: US2-AC3, FR-010

---

@FS-2552
## [dms-web-app][FS-2541-primax-shipment-ddp-provisioning] - Coordinator sees every reason when a record fails for more than one reason

```gherkin
Scenario: A record that fails for two reasons shows both reasons, not just one
Given the coordinator opens the shipment results page
And one failed record in the Failed Records list failed both because its IMEI was missing and because it was a duplicate
When the coordinator views that record's row
Then the Failure Reason column for that row shows "Missing IMEI" and "Duplicate record"
And neither reason is hidden or dropped
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: US2-AC4, FR-011

---

@FS-2553
## [dms-web-app][FS-2541-primax-shipment-ddp-provisioning] - Coordinator downloads the failed-records export

```gherkin
Scenario: Clicking Export downloads the current shipment's failed records
Given the coordinator opens the shipment results page
And the shipment has one or more failed records
And the Export button is visible
When the coordinator clicks the Export button
Then a file download starts in CSV or Excel format
And the downloaded file name identifies the current shipment
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.75

Traceability: US3-AC1, US3-AC2, FR-012, FR-013, FR-014

---

@FS-2554
## [dms-web-app][FS-2541-primax-shipment-ddp-provisioning] - Logged-out visitor cannot reach the shipment results page

```gherkin
Scenario: Visiting the results page while logged out redirects to login
Given the visitor is not logged in
When the visitor tries to open the shipment results page
Then the visitor is redirected to the login page
And none of the shipment results are shown
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: FR-020

---

@FS-2555
## [dms-web-app][FS-2541-primax-shipment-ddp-provisioning] - Customer/lessee account cannot reach the shipment results page

```gherkin
Scenario: A customer or lessee account is denied access to the shipment results page
Given the user is logged in with a customer/lessee account rather than an internal account
When the user tries to open the shipment results page
Then an access-denied message is shown with the text "{It must be updated by the test reviewer}"
And none of the shipment results are shown
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: FR-020

---

@FS-2556
## [dms-web-app][FS-2541-primax-shipment-ddp-provisioning] - Summary counts stay accurate no matter how large the shipment is

```gherkin
Scenario Outline: The summary displays correctly for small and very large shipments alike
Given the coordinator opens the shipment results page
And the shipment that just finished processing has <total> total records, <succeeded> succeeded, and <failed> failed
When the results page finishes loading
Then the Summary panel shows "Total: <total>", "Succeeded: <succeeded>", and "Failed: <failed>"

Examples:
| total  | succeeded | failed |
| 1      | 1         | 0      |
| 1      | 0         | 1      |
| 100000 | 99999     | 1      |
```

Automation Recommendation: Candidate

Status: Created

EMTE: 1.0

Traceability: US2-AC1, EC-4, SC-001, SC-002

---

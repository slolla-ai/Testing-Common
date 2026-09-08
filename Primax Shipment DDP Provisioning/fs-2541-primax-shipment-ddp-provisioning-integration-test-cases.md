Test Type: Integration

Feature: Integration - Shipment intake, validation, DDP provisioning, and organization assignment

Purpose:\
Confirm that a shipment file moves correctly across every internal and external handoff — intake, validation, DDP provisioning, organization assignment, export, and audit — and that a failure at any one handoff is handled without disrupting the others

Components:\
shipment-file-intake: {It must be updated by the test reviewer}\
device-management-service: {It must be updated by the test reviewer}\
ddp: {It must be updated by the test reviewer}\
px-report-service: {It must be updated by the test reviewer}

Base URLs (optional):\
ddp: {It must be updated by the test reviewer}\
px-report-service: {It must be updated by the test reviewer}

```gherkin
Background:
Given shipment-file-intake, device-management-service, ddp, and px-report-service are all up and running
And a shipment file with device records is ready to be submitted
```

@FS-2557
## [device-management-service][FS-2541-primax-shipment-ddp-provisioning] - A shipment file dropped at the scheduled location starts processing automatically

```gherkin
Scenario: Successful interaction - the scheduled job hands off a dropped shipment file for processing
Given the following fields have been set on shipment-file-intake:
  | field    | description                                             |
  | source   | shipment file placed at the scheduled drop location     |
  | records  | device records each with IMEI, ICCID, and GPS Part Number |
When shipment-file-intake hands the shipment file to device-management-service
Then the interaction should complete successfully
And device-management-service reflects the following fields from shipment-file-intake:
  | field             | validation_type       |
  | record_count      | equals                |
  | processing_status | equals "in_progress"  |
And processing starts with no manual step needed to kick it off
```

Automation Recommendation: Candidate

Status: Created

EMTE: 1.0

Traceability: US1-AC1, FR-001, FR-001a, FR-004

---

@FS-2558
## [device-management-service][FS-2541-primax-shipment-ddp-provisioning] - A shipment file received as an email attachment starts processing the same way

```gherkin
Scenario: Successful interaction - an emailed shipment file is handed off for processing just like a dropped file
Given a shipment file arrives as an email attachment from the PRIMAX/COBAN team
When shipment-file-intake hands the shipment file to device-management-service
Then the interaction should complete successfully
And processing starts automatically with no manual step needed
And the record-by-record validation behavior matches the drop-location path
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.75

Traceability: US1-AC1, FR-001a

---

@FS-2559
## [device-management-service][FS-2541-primax-shipment-ddp-provisioning] - A shipment file with the wrong structure is rejected before any record is processed

```gherkin
Scenario: Failure or resilience behavior - a malformed shipment file is rejected with a clear reason
When shipment-file-intake hands device-management-service a shipment file that is missing required columns or has the wrong format
Then device-management-service should reject the file rather than attempt to process its records
And the rejection reason clearly names the structural problem
And no unintended side effects should occur in any involved component
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.75

Traceability: FR-003

---

@FS-2560
## [device-management-service][FS-2541-primax-shipment-ddp-provisioning] - A validated device record is submitted to DDP for provisioning

```gherkin
Scenario: Successful interaction - a record that passes validation is sent to DDP under the Holding Account tenant
Given the following fields have been confirmed on device-management-service for one device record:
  | field           | description                |
  | imei            | present and passes validation |
  | iccid           | present and passes validation |
  | gps_part_number | present and passes validation |
When device-management-service sends a provisioning request to ddp for that device
Then the interaction should complete successfully
And ddp reflects the following fields from device-management-service:
  | field  | validation_type              |
  | imei   | equals                       |
  | iccid  | equals                       |
  | tenant | equals "Holding Account"     |
And the resulting state across device-management-service and ddp is consistent
```

Automation Recommendation: Candidate

Status: Created

EMTE: 1.0

Traceability: US4-AC1, FR-015

---

@FS-2561
## [device-management-service][FS-2541-primax-shipment-ddp-provisioning] - A successfully provisioned device is assigned to the correct organization

```gherkin
Scenario: Successful interaction - a provisioned device is placed under Road Ready Advanced Telematics Organization -> System Account
Given ddp has already returned a successful provisioning outcome for a device to device-management-service
When device-management-service sends an organization-assignment request to ddp for that device
Then the interaction should complete successfully
And ddp reflects the following fields from device-management-service:
  | field        | validation_type                                      |
  | organization | equals "Road Ready Advanced Telematics Organization" |
  | account      | equals "System Account"                              |
And the resulting state across device-management-service and ddp is consistent
```

Automation Recommendation: Candidate

Status: Created

EMTE: 1.0

Traceability: US5-AC1, FR-018

---

@FS-2562
## [device-management-service][FS-2541-primax-shipment-ddp-provisioning] - A device that fails provisioning is never sent for organization assignment

```gherkin
Scenario: Failure or resilience behavior - a provisioning failure stops the device before assignment is attempted
When device-management-service sends a provisioning request to ddp and ddp returns a failure outcome for that device
Then device-management-service should log the provisioning failure with its specific reason
And device-management-service should not send an organization-assignment request to ddp for that device
And no unintended side effects should occur in any involved component
```

Automation Recommendation: Candidate

Status: Created

EMTE: 1.0

Traceability: US4-AC3, US5-AC2, FR-017, EC-5

---

@FS-2563
## [device-management-service][FS-2541-primax-shipment-ddp-provisioning] - A device that fails organization assignment is logged with its own reason

```gherkin
Scenario: Failure or resilience behavior - an assignment failure is recorded even though provisioning already succeeded
Given ddp has already returned a successful provisioning outcome for a device to device-management-service
When device-management-service sends an organization-assignment request to ddp and ddp returns a failure outcome
Then device-management-service should log the assignment failure with its specific reason
And no unintended side effects should occur in any involved component
```

Automation Recommendation: Candidate

Status: Created

EMTE: 1.0

Traceability: US5-AC3, FR-019, EC-5

---

@FS-2564
## [device-management-service][FS-2541-primax-shipment-ddp-provisioning] - A record whose device already succeeded in an earlier shipment is flagged as a duplicate

```gherkin
Scenario: Successful interaction - checking a record against earlier shipment outcomes catches a true duplicate
Given a device with the same IMEI or ICCID was already successfully provisioned and assigned in an earlier shipment
When device-management-service checks the incoming record against earlier shipment outcomes
Then the interaction should complete successfully
And the incoming record is flagged as a duplicate failure instead of being sent to ddp for provisioning
And the resulting state across the involved components remains consistent
```

Automation Recommendation: Candidate

Status: Created

EMTE: 1.0

Traceability: US1-AC5, FR-006, EC-1, EC-2

---

@FS-2565
## [device-management-service][FS-2541-primax-shipment-ddp-provisioning] - A corrected resubmission of a previously failed device is allowed to proceed

```gherkin
Scenario: Successful interaction - a device whose earlier attempt failed is not treated as a duplicate
Given a device with the same IMEI or ICCID failed validation, provisioning, or assignment in an earlier shipment
When device-management-service checks the incoming record against earlier shipment outcomes
Then the interaction should complete successfully
And the incoming record is not flagged as a duplicate
And the incoming record proceeds through validation, provisioning, and organization assignment again
```

Automation Recommendation: Candidate

Status: Created

EMTE: 1.0

Traceability: FR-006a, EC-2

---

@FS-2566
## [device-management-service][FS-2541-primax-shipment-ddp-provisioning] - Provisioning keeps working for other records while DDP is temporarily down for one

```gherkin
Scenario: Failure or resilience behavior - DDP is briefly unavailable while a record is being provisioned
When device-management-service sends a provisioning request to ddp while ddp is temporarily unavailable
Then device-management-service should log the failure with a reason that identifies DDP as unavailable
And that record appears in the failed-records reporting
And other records in the same shipment keep processing on their own, unaffected
```

Automation Recommendation: Candidate

Status: Created

EMTE: 1.25

Traceability: EC-3, FR-007

---

@FS-2567
## [device-management-service][FS-2541-primax-shipment-ddp-provisioning] - One record failing validation does not stop other records from completing

```gherkin
Scenario: Successful interaction - a failing record and a passing record are processed independently
Given a shipment file contains one record missing a required field and one record that passes validation
When device-management-service processes both records
Then the interaction should complete successfully
And the passing record continues on to ddp for provisioning and organization assignment
And the failing record is flagged as failed without affecting the passing record's outcome
```

Automation Recommendation: Candidate

Status: Created

EMTE: 1.0

Traceability: US1-AC4, FR-007, SC-002

---

@FS-2568
## [device-management-service][FS-2541-primax-shipment-ddp-provisioning] - Failed records are handed off to the reporting service to build the export

```gherkin
Scenario: Successful interaction - device-management-service sends failed-record data to px-report-service for export generation
Given device-management-service has one or more failed records for the current shipment
When device-management-service sends the failed-records data to px-report-service
Then the interaction should complete successfully
And px-report-service reflects the following fields from device-management-service for each failed record:
  | field           | validation_type |
  | imei            | equals          |
  | iccid           | equals          |
  | gps_part_number | equals          |
  | failure_reason  | not_empty       |
And px-report-service produces the export in CSV or Excel format
```

Automation Recommendation: Candidate

Status: Created

EMTE: 1.0

Traceability: US3-AC1, US3-AC2, FR-012, FR-013, FR-014

---

@FS-2569
## [device-management-service][FS-2541-primax-shipment-ddp-provisioning] - Every stage of a device's journey is recorded so it can be traced later

```gherkin
Scenario: Successful interaction - shipment receipt, provisioning, and assignment activity are all captured for audit
Given a device record has moved through validation, provisioning, and organization assignment
When device-management-service records the outcome of each stage
Then the interaction should complete successfully
And the audit record for that device includes the following details:
  | field                          | validation_type |
  | shipment file receipt          | exists          |
  | provisioning request/response  | exists          |
  | organization-assignment activity | exists        |
And the device's full outcome can be reconstructed end-to-end from these audit records
```

Automation Recommendation: Candidate

Status: Created

EMTE: 1.5

Traceability: FR-021, SC-007

---

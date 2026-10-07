Test Type: Integration

Feature: Integration - Houston customer shipment files: receive, check, deliver, record and report

Purpose:\
Check that customer shipment files from the Houston Shipment Team are received, checked, delivered to the right customer account, recorded and reported correctly across every system involved

Components:\
intake_mailbox: {It must be updated by the test reviewer}\
web_app_import_api: {It must be updated by the test reviewer}\
asset_service: {It must be updated by the test reviewer}\
asset_database: {It must be updated by the test reviewer}\
device_registry: {It must be updated by the test reviewer}\
billing: {It must be updated by the test reviewer}\
email_notifications: {It must be updated by the test reviewer}\
environment_configuration: {It must be updated by the test reviewer}

Base URLs (optional):\
web_app_import_api: {It must be updated by the test reviewer}\
asset_service: {It must be updated by the test reviewer}\
device_registry: {It must be updated by the test reviewer}\
billing: {It must be updated by the test reviewer}\
email_notifications: {It must be updated by the test reviewer}

```gherkin
Background:
Given the asset service, device registry, billing and email notifications are running
And customer shipment processing is switched on with a limit of 10000 records per file
And shipment emails go to the support recipients {support recipients}
And the PSI holding account exists and is configured for this environment
And the Road Ready holding account is configured as the account where PRIMAX devices arrive
And part numbers {Lite part number}, {Gateway part number} and {Sensor part number} are mapped to TrackRR Lite, TrackRR Gateway and a sensor type
And customers {Customer A} with customer ID {Customer A ID} and {Customer B} with customer ID {Customer B ID} each have one active main account
```

@FS-2848
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Gateway waiting in Road Ready holding moves to the customer with everything attached to it

```gherkin
Scenario: Successful interaction - a gateway already received from PRIMAX is shipped to a customer
  Given gateway {Gateway IMEI} arrived from PRIMAX and is in the Road Ready holding account with its placeholder trailer
  And asset {Attached asset} is attached to the gateway, and sensor {Loose sensor} sits in the same account unattached
  And a shipment file ships {Gateway IMEI} to {Customer A ID}
  When the asset service processes the file
  Then the gateway, its placeholder trailer and {Attached asset} now belong to {Customer A}'s main account
  And {Loose sensor} stays in the Road Ready holding account
  And the shipment record for the gateway says it was transferred from Road Ready holding to {Customer A}
  And the gateway appears in the organization transfer history
  And the gateway's registration in the device registry is unchanged
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: US1-AC4, EC-18, EC-19, FR-013, FR-022, FR-023, FR-025, FR-027, SC-010, SC-011

---

@FS-2849
## [px-asset-service][FS-2772-seon-shipment-file-automation] - New gateway not yet in Fus1on is created in the customer's account

```gherkin
Scenario: Successful interaction - a TrackRR Lite that PRIMAX never sent is created directly for the customer
  Given no device in Fus1on has IMEI {New IMEI} or ICCID {New ICCID}
  And a shipment file has a valid TrackRR Lite row with IMEI {New IMEI}, ICCID {New ICCID} and Ship To {Customer A ID}
  When the asset service processes the file
  Then the TrackRR Lite is created in {Customer A}'s main account with the same placeholder trailer an AS500 file would create
  And the device is registered successfully in the device registry
  And the shipment record for the device says it was created
  And the run reports 1 succeeded
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: US1-AC5, EC-17, FR-013a, SC-010

---

@FS-2850
## [px-asset-service][FS-2772-seon-shipment-file-automation] - New BLE sensor is created inactive and not attached to anything

```gherkin
Scenario: Successful interaction - a sensor not yet in Fus1on is created for the customer
  Given no device in Fus1on has Sensor ID {New Sensor ID}
  And a shipment file has a sensor row with Sensor ID {New Sensor ID}, no IMEI, no ICCID and Ship To {Customer A ID}
  When the asset service processes the file
  Then the sensor is created as inactive and is visible to {Customer A}
  And the sensor is not attached to any gateway or asset
  And the row is not rejected for having no gateway
  And the shipment record for the sensor says it was created
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: US1-AC5, US2-AC3, FR-006a, FR-013a, SC-010

---

@FS-2851
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Gateway that can only be partly moved is not moved at all and the file keeps going

```gherkin
Scenario: Failure or resilience behavior - part of the gateway's group leaves the holding account during processing
  Given gateway {Gateway IMEI} is in the Road Ready holding account with its placeholder trailer
  And while the file is being processed, one item attached to the gateway is moved out of the holding account
  And the same file has another valid row after the gateway's row
  When the asset service processes the file
  Then the gateway's row fails with code "TRANSFER_FAILED" and a message starting "Device could not be transferred:"
  And nothing in the gateway's group has changed account
  And no shipment or transfer history is written for the gateway
  And the next row in the file is still processed successfully
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: EC-14, FR-010, FR-011, FR-022

---

@FS-2852
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Two files shipping the same gateway at the same time move it only once

```gherkin
Scenario: Failure or resilience behavior - two submissions race for the same holding-account gateway
  Given gateway {Gateway IMEI} is in the Road Ready holding account
  And file 1 ships it to {Customer A ID} and file 2 ships it to {Customer B ID} with a different Sales Order Number
  When file 1 arrives by email and file 2 arrives through the web app at the same time
  Then the gateway ends up in exactly one customer's account
  And only one shipment record says it was transferred
  And the other file's row fails with "DEVICE_NOT_TRANSFERABLE"
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: EC-2, FR-007, FR-022, SC-003

---

@FS-2853
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Two files creating the same new device at the same time create it only once

```gherkin
Scenario: Failure or resilience behavior - two submissions race to create the same device
  Given no device in Fus1on has IMEI {New IMEI}
  And two files each ship {New IMEI} to {Customer A ID}
  When both files are processed at the same time
  Then exactly one device with IMEI {New IMEI} exists in Fus1on
  And only one shipment record says it was created
  And the other file reports the row as skipped or as a duplicate, never as a second device
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: FR-007, SC-003

---

@FS-2854
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Billing is told about transferred devices once per batch

```gherkin
Scenario: Successful interaction - billing is notified of the devices moved in a batch
  Given one batch of a file moves {N} gateways from Road Ready holding to {Customer A} and {M} gateways from PSI holding to {Customer B}
  When the batch is saved
  Then billing receives one transfer notification for the batch
  And the notification lists, for each "from account to account" pair, the devices that moved between them
  And no device is listed twice
  And the devices' registrations in the device registry are unchanged
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: US1-AC10, FR-024, FR-027, SC-011

---

@FS-2855
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Billing being unavailable never fails the shipment

```gherkin
Scenario Outline: Interaction variation matrix - billing does not accept the transfer notification
  Given a file moves gateway {Gateway IMEI} from Road Ready holding to {Customer A}
  When the asset service notifies billing and billing <billing problem>
  Then the asset service tries <tries> time(s) in total
  And the gateway's row still counts as succeeded and the gateway stays with {Customer A}
  And the failure is logged with the run number only, and the billing failure counter goes up by 1
  And the run finishes as "Completed"

Examples:
  | billing problem                   | tries |
  | times out every time              | 3     |
  | returns a server error every time | 3     |
  | rejects the request (4xx)         | 1     |
```

Automation Recommendation: Candidate

Status: Created

EMTE: 1.0

Traceability: FR-024, SC-011

---

@FS-2856
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Device the registry refuses is not kept and the row fails

```gherkin
Scenario Outline: Interaction variation matrix - the device registry refuses a new device
  Given a shipment file has a valid row for new gateway {New IMEI}
  When the asset service registers the device and the device registry <registry answer>
  Then the row fails with code "PROVISIONING_FAILED" and message "Device could not be created: {reason}. Resend the record to retry."
  And no device or placeholder trailer for {New IMEI} is left in Fus1on
  And the file carries on with the next row

Examples:
  | registry answer                                     |
  | returns an error status                             |
  | does not answer in time                             |
  | returns an empty answer                             |
  | returns an error other than "DEVICE_ALREADY_EXISTS" |
```

Automation Recommendation: Candidate

Status: Created

EMTE: 1.5

Traceability: FR-010, FR-030

---

@FS-2857
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Registry answer "already exists" counts as a successful registration

```gherkin
Scenario: Successful interaction - the device registry already holds the device
  Given a shipment file has a valid row for gateway {New IMEI}, which is not in Fus1on
  And the device registry already holds {New IMEI}
  When the asset service registers the device and the registry answers "DEVICE_ALREADY_EXISTS"
  Then the gateway is created in the customer's account with its placeholder trailer
  And the row counts as succeeded and is not failed with "PROVISIONING_FAILED"
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: FR-030

---

@FS-2858
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Device already registered for the customer is not registered a second time

```gherkin
Scenario: Successful interaction - Fus1on's own records show the registry already accepted the device
  Given gateway {Gateway IMEI} is not in Fus1on
  And Fus1on's registration history shows the registry already accepted it for {Customer A}'s tenant
  And a shipment file ships {Gateway IMEI} to {Customer A ID}
  When the asset service processes the file
  Then no new registration request is sent to the device registry
  And the gateway is created in {Customer A}'s account and the row counts as succeeded
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: FR-030

---

@FS-2859
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Old registry history does not block re-creating a device that was rolled back

```gherkin
Scenario: Failure or resilience behavior - registry history exists for a device that is not in Fus1on
  Given the registry history has an entry for gateway {Gateway IMEI}, but the device itself is not in Fus1on
  And a shipment file has a valid row for {Gateway IMEI}
  When the asset service processes the file
  Then the row is not treated as a duplicate or as already received
  And the gateway is created again in the customer's account
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: FR-030

---

@FS-2860
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Files emailed to the intake mailbox go to the right processing by their column headers

```gherkin
Scenario Outline: Interaction variation matrix - the shared mailbox routes each file by its header
  Given an approved sender emails the intake mailbox a file with <file header>
  When the mailbox hands the file to the asset service
  Then the file is handled by <processing>
  And <result>

Examples:
  | file header                                                      | processing                    | result |
  | the 12 FS-2772 columns, in any order                             | customer shipment processing  | every row is checked |
  | the 10 AS500 columns                                             | the existing AS500 processing | the result is exactly what AS500 gave before this change |
  | the 10 AS500 columns plus an extra Sensor ID column              | the existing AS500 processing | the file is not rejected as a wrong layout |
  | the PRIMAX columns                                               | PRIMAX processing             | each device is recorded as received from the manufacturer |
  | the old FS-2430 11 columns                                       | the existing AS500 processing | the whole file is rejected and support is emailed, as AS500 does today |
  | Sensor ID and Bill To Customer ID but no Agreement Number column | customer shipment processing  | the whole file fails with "The file is missing the required column: Agreement Number" and support is emailed |
```

Automation Recommendation: Candidate

Status: Created

EMTE: 1.5

Traceability: US1-AC1, US1-AC8, US1-AC9, EC-3, EC-4, FR-002, FR-003, FR-021

---

@FS-2861
## [px-asset-service][FS-2772-seon-shipment-file-automation] - One email with an AS500 file and an FS-2772 file is handled as two separate runs

```gherkin
Scenario: Successful interaction - two attachments on one email
  Given an approved sender emails one message with an AS500 file and an FS-2772 file attached
  When the mailbox hands both files to the asset service
  Then two separate runs are created, one per file
  And the AS500 file goes to AS500 processing and the FS-2772 file goes to customer shipment processing
  And support receives one email per run
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: EC-5, FR-003

---

@FS-2862
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Emails from untrusted senders are dropped without a run or a notification

```gherkin
Scenario Outline: Failure or resilience behavior - the mailbox refuses the message
  Given an FS-2772 file is emailed to the intake mailbox by <sender>
  When the mailbox checks the message
  Then the file never reaches the asset service and no run is created
  And no notification email is sent
  And the refused message is counted so it can be monitored

Examples:
  | sender                                                       |
  | someone not on the approved sender list                      |
  | an approved address that fails email authentication          |
  | an approved sender whose message is flagged as virus or spam |
```

Automation Recommendation: Do Not Automate

Status: Created

EMTE: 1.0

Traceability: FR-001

---

@FS-2863
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Each run records who submitted it

```gherkin
Scenario: Successful interaction - mailbox and web app runs are attributed correctly
  Given one file is emailed to the intake mailbox and another is uploaded in the web app by super-admin {Super Admin}
  When the asset service processes both
  Then the emailed run shows it came from the mailbox and was submitted by the system
  And the uploaded run shows it came from the web app, was submitted by {Super Admin}, and keeps contact email {Contact Email}
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: FR-001

---

@FS-2864
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Uploading in the web app gives the same results as emailing the file

```gherkin
Scenario: Successful interaction - web app upload is passed to the asset service and processed the same way
  Given super-admin {Super Admin} uploads a 12-column shipment file with {Good rows} valid and {Bad rows} invalid rows and contact email {Contact Email}
  When the web app passes the file to the asset service
  Then the asset service receives all 12 values of every row exactly as typed, including the customer IDs
  And the run is recorded as a customer shipment
  And every row gets the same result it would get if the same file were emailed
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: FR-001, FR-002

---

@FS-2865
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Emailed file with more than 10000 rows is rejected whole

```gherkin
Scenario: Failure or resilience behavior - mailbox file over the record limit
  Given a shipment file with 10001 rows is emailed to the intake mailbox
  When the asset service reads the file
  Then no row is checked and no device is created or moved
  And the run is marked "Failed" with counts 0 total, 0 succeeded, 0 skipped, 0 failed
  And the reason is "The file contains 10001 records, more than the limit of 10000."
  And support receives one email stating the failure and the reason, with no error file attached
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: US1-AC7, US3-AC4, FR-014, FR-020

---

@FS-2866
## [px-asset-service][FS-2772-seon-shipment-file-automation] - File with exactly 10000 rows is processed in full

```gherkin
Scenario: Successful interaction - a file at the record limit
  Given a shipment file with exactly 10000 rows is emailed to the intake mailbox
  When the asset service processes it
  Then all 10000 rows are checked in a single run
  And succeeded plus skipped plus failed adds up to 10000
  And the run finishes and support receives exactly one email
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: US1-AC6, FR-014, SC-002

---

@FS-2867
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Record limit can be changed in configuration without a new build

```gherkin
Scenario: Successful interaction - changing the record limit
  Given the record limit is changed to {New limit} in the environment configuration and the asset service is restarted
  When a shipment file with {New limit} + 1 rows is emailed
  Then the run fails with "The file contains {New limit + 1} records, more than the limit of {New limit}."
  And no code change or new build was needed
```

Automation Recommendation: Do Not Automate

Status: Created

EMTE: 0.5

Traceability: FR-014

---

@FS-2868
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Emailed file is refused when shipment processing or the PSI holding setup is not available

```gherkin
Scenario Outline: Interaction variation matrix - processing refused because of environment setup
  Given <setup problem> and the asset service has been restarted
  When a valid shipment file is emailed to the intake mailbox
  Then no row is checked
  And the run is marked "Failed" with the reason "<reason>"
  And support receives exactly one email stating the reason

Examples:
  | setup problem                                           | reason |
  | customer shipment processing is switched off            | V2 shipment processing is not enabled in this environment. |
  | the PSI holding organization is not configured          | The PSI holding account is not configured in this environment. |
  | the PSI holding organization's main account is inactive | The PSI holding account is not usable in this environment. |
```

Automation Recommendation: Candidate

Status: Created

EMTE: 1.0

Traceability: FR-026, SC-005

---

@FS-2869
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Emailed file with only a header row still produces a run and an email

```gherkin
Scenario: Successful interaction - header-only mailbox file
  Given a shipment file that contains only the 12 column headers is emailed to the intake mailbox
  When the asset service processes it
  Then a run is recorded with 0 total, 0 succeeded, 0 skipped and 0 failed
  And support receives one email for the run
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: EC-16, FR-020

---

@FS-2870
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Device type comes only from the part-number mapping

```gherkin
Scenario Outline: Interaction variation matrix - part number decides the device type
  Given <mapping setup>
  When the asset service checks a shipment row with Part Number <part number>
  Then <result>

Examples:
  | mapping setup                                       | part number            | result |
  | the standard mapping                                | {Lite part number}     | the row is treated as a gateway, so IMEI and ICCID are both required |
  | the standard mapping                                | {Gateway part number}  | the row is treated as a gateway, so IMEI and ICCID are both required |
  | the standard mapping                                | {Sensor part number}   | the row is treated as a sensor, so Sensor ID or IMEI is required |
  | the standard mapping                                | {Unmapped part number} | the row fails with "No asset type key mapping found for part number {Unmapped part number}." and the file carries on |
  | the standard mapping                                | blank                  | the row fails with "No Part Number found." |
  | a new mapping row for {New part number} as a sensor | {New part number}      | the row is accepted as a sensor without any code change |
```

Automation Recommendation: Candidate

Status: Created

EMTE: 1.5

Traceability: US1-AC2, US1-AC3, FR-004, FR-005

---

@FS-2871
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Gateway IMEI and ICCID are checked exactly as AS500 checks them

```gherkin
Scenario Outline: Interaction variation matrix - gateway identifier checks
  Given a <device type> row with IMEI <IMEI> and ICCID <ICCID>
  When the asset service checks the row using the same IMEI and ICCID rules AS500 uses
  Then <result>

Examples:
  | device type     | IMEI                       | ICCID                                   | result |
  | TrackRR Lite    | blank                      | a valid 19-digit ICCID                  | fails with "No IMEI found." |
  | TrackRR Gateway | 14 digits                  | a valid 19-digit ICCID                  | fails with "Invalid IMEI." |
  | TrackRR Gateway | 15 characters with letters | a valid 19-digit ICCID                  | fails with "Invalid IMEI." |
  | TrackRR Gateway | a valid 15-digit IMEI      | blank                                   | fails with "No ICCID found." |
  | TrackRR Gateway | a valid 15-digit IMEI      | 18 digits                               | fails with "Invalid ICCID." |
  | TrackRR Gateway | a valid 15-digit IMEI      | a valid 20-digit ICCID                  | accepted |
  | TrackRR Lite    | a valid 15-digit IMEI      | a valid 19-digit ICCID, plus a Sensor ID | accepted; the Sensor ID is ignored |
```

Automation Recommendation: Candidate

Status: Created

EMTE: 1.5

Traceability: US2-AC2, EC-7, FR-004, FR-006, SC-004

---

@FS-2872
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Changing the IMEI rule changes AS500 and customer shipments together

```gherkin
Scenario: Successful interaction - one shared IMEI rule for both file types
  Given the IMEI rule is changed to {New IMEI rule} in the environment configuration and the asset service is restarted
  When an AS500 file and an FS-2772 file each contain a gateway with IMEI {IMEI valid only under the new rule}
  Then both files apply the new rule
  And both give the same accept or reject result for that IMEI
```

Automation Recommendation: Do Not Automate

Status: Created

EMTE: 0.5

Traceability: FR-006

---

@FS-2873
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Sensor rows need a Sensor ID or an IMEI

```gherkin
Scenario Outline: Interaction variation matrix - sensor identifier checks
  Given a sensor row with Sensor ID <Sensor ID>, IMEI <IMEI> and ICCID <ICCID>
  When the asset service checks the row
  Then <result>

Examples:
  | Sensor ID                       | IMEI                  | ICCID            | result |
  | blank                           | blank                 | blank            | fails with "A sensor requires a Sensor ID or an IMEI." |
  | {New Sensor ID}                 | blank                 | blank            | accepted |
  | blank                           | a valid 15-digit IMEI | blank            | accepted |
  | blank                           | 14 digits             | blank            | fails with "Invalid IMEI." |
  | {New Sensor ID}                 | blank                 | contains letters | accepted; a sensor's ICCID is not format-checked |
  | longer than the maximum allowed | blank                 | blank            | fails with "Sensor ID exceeds the maximum length of {max} characters." |
```

Automation Recommendation: Candidate

Status: Created

EMTE: 1.5

Traceability: US2-AC1, US2-AC3, EC-6, EC-8, FR-006a, SC-004

---

@FS-2874
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Order numbers and Shipping Date are checked

```gherkin
Scenario Outline: Interaction variation matrix - order fields and Shipping Date
  Given an otherwise valid gateway row with <field> set to <value>
  When the asset service checks the row
  Then <result>

Examples:
  | field                   | value       | result |
  | Sales Order Number      | blank       | fails with "No Sales Order Number found." |
  | Sales Order Number      | only spaces | fails with "No Sales Order Number found." |
  | Agreement Number        | blank       | fails with "No Agreement Number found." |
  | Shipping Date           | blank       | fails with "No Shipping Date found." |
  | Shipping Date           | 2026-02-30  | fails with "Invalid Shipping Date." |
  | Shipping Date           | 15/03/2026  | fails with "Invalid Shipping Date." |
  | Shipping Date           | 2026-03-15  | accepted and stored as typed |
  | Shipping Date           | 03/15/2026  | accepted and stored as typed |
  | Shipping Date           | 3/15/26     | accepted and stored as typed |
  | Sales Order Line Number | blank       | accepted |
  | Part Description        | blank       | accepted |
  | Shipment Number         | blank       | accepted |
```

Automation Recommendation: Candidate

Status: Created

EMTE: 1.5

Traceability: US2-AC10, US2-AC12, EC-20, EC-21, EC-22, FR-008, FR-008a, SC-004

---

@FS-2875
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Customer IDs decide which customer gets the device

```gherkin
Scenario Outline: Interaction variation matrix - Bill To and Ship To customer IDs
  Given an otherwise valid row with Bill To <Bill To> and Ship To <Ship To>
  When the asset service looks up the customers
  Then <result>

Examples:
  | Bill To         | Ship To                              | result |
  | blank           | blank                                | fails with "A Bill To Customer ID or Ship To Customer ID is required." |
  | {Customer B ID} | {Customer A ID}                      | delivered to {Customer A} (Ship To wins) |
  | {Customer B ID} | blank                                | delivered to {Customer B} (Bill To is used when Ship To is blank) |
  | blank           | {Customer A ID}                      | delivered to {Customer A} |
  | {Customer B ID} | {Unknown ID}                         | fails with "Ship To Customer ID {Unknown ID} does not match a known organization." |
  | {Unknown ID}    | {Customer A ID}                      | fails with "Bill To Customer ID {Unknown ID} does not match a known organization." |
  | blank           | {Inactive customer ID}               | fails with "Customer ID {Inactive customer ID} belongs to an inactive account." |
  | blank           | {Customer ID with two main accounts} | fails with "Customer ID {Customer ID with two main accounts} matches more than one master account; contact support." |
```

Automation Recommendation: Candidate

Status: Created

EMTE: 1.5

Traceability: US2-AC9, EC-11, EC-12, FR-008, FR-012, FR-013, SC-004

---

@FS-2876
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Row with several problems reports all of them, in order

```gherkin
Scenario Outline: Interaction variation matrix - several failures on one row
  Given a shipment row with <problems>
  When the asset service checks the row
  Then the row fails once, listing the error codes "<error codes>" in that order
  And every matching error message is listed in the same order, separated by ";"

Examples:
  | problems                                                         | error codes |
  | a gateway part number, no IMEI, no ICCID and no Agreement Number | MISSING_IMEI;MISSING_ICCID;MISSING_AGREEMENT_NUMBER |
  | an unmapped part number, no IMEI and no Shipping Date            | UNKNOWN_PART_NUMBER;MISSING_SHIPPING_DATE |
```

Automation Recommendation: Candidate

Status: Created

EMTE: 1.0

Traceability: US2-AC11, EC-13, FR-009

---

@FS-2877
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Row that disagrees with the device Fus1on already has is rejected

```gherkin
Scenario Outline: Interaction variation matrix - file details conflict with the existing device
  Given Fus1on already has <existing device>
  And a shipment row has <row details>
  When the asset service matches the row to Fus1on's devices
  Then the row fails with "<message>"
  And no device is moved or created

Examples:
  | existing device                                                        | row details                                              | message |
  | gateway {Gateway IMEI} with ICCID {Stored ICCID} in Road Ready holding | IMEI {Gateway IMEI} with a different ICCID {Other ICCID} | ICCID {Other ICCID} does not match the ICCID recorded for this device. |
  | TrackRR Lite {Lite IMEI} in Road Ready holding                         | IMEI {Lite IMEI} with the TrackRR Gateway part number    | Part number {Gateway part number} does not match this device's type. |
  | one sensor with Sensor ID {Sensor ID X} and another with IMEI {IMEI Y} | Sensor ID {Sensor ID X} and IMEI {IMEI Y}                | More than one device in Fus1on matches this record. |
```

Automation Recommendation: Candidate

Status: Created

EMTE: 1.0

Traceability: US2-AC6, EC-9, FR-007

---

@FS-2878
## [px-asset-service][FS-2772-seon-shipment-file-automation] - New device is refused if one of its identifiers already belongs to another device

```gherkin
Scenario Outline: Interaction variation matrix - identifiers must be unique across the platform
  Given Fus1on already has <existing device>
  And a shipment row for a new device has <row details>
  When the asset service checks the row
  Then the row fails with "<message>"
  And no device is created

Examples:
  | existing device                                        | row details                                              | message |
  | a gateway created by AS500 with ICCID {ICCID X}        | a new gateway with ICCID {ICCID X}                       | Duplicate ICCID detected. |
  | a gateway with IMEI {IMEI X}                           | a new sensor with IMEI {IMEI X}                          | Duplicate IMEI detected. |
  | a manually created sensor with Sensor ID {Sensor ID X} | a new sensor with Sensor ID {Sensor ID X} and a new IMEI | Duplicate Sensor ID detected. |
  | a sensor with ICCID {ICCID Y}                          | a new sensor with ICCID {ICCID Y}                        | Duplicate ICCID detected. |
  | a deleted gateway that had IMEI {IMEI Z}               | a new gateway with IMEI {IMEI Z}                         | Duplicate IMEI detected. |
```

Automation Recommendation: Candidate

Status: Created

EMTE: 1.5

Traceability: US2-AC7, FR-007, SC-003

---

@FS-2879
## [px-asset-service][FS-2772-seon-shipment-file-automation] - When a file lists the same device twice, the first good row wins

```gherkin
Scenario Outline: Interaction variation matrix - duplicate rows inside one file
  Given a shipment file has <first row> followed by <later row>
  When the asset service processes the file
  Then <result>

Examples:
  | first row                                                | later row                                       | result |
  | a valid gateway row with IMEI {IMEI X}                   | a valid sensor row with IMEI {IMEI X}           | the first is delivered; the later fails with "Duplicate IMEI detected." |
  | a valid sensor row with Sensor ID {Sensor ID X}          | a valid sensor row with Sensor ID {Sensor ID X} | the first is delivered; the later fails with "Duplicate Sensor ID detected." |
  | a gateway row with IMEI {IMEI X} and no Agreement Number | a valid gateway row with IMEI {IMEI X}          | the first fails; the later is delivered |
```

Automation Recommendation: Candidate

Status: Created

EMTE: 1.0

Traceability: US2-AC8, FR-007

---

@FS-2880
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Device sitting in a customer's account cannot be shipped to another customer

```gherkin
Scenario Outline: Interaction variation matrix - device is not in an account it may be shipped from
  Given gateway {Gateway IMEI} is <where the device is>
  And a shipment row ships {Gateway IMEI} to {Customer B ID}
  When the asset service processes the row
  Then the row fails with "This device cannot be shipped from its current account (installed, moved since its shipment, not received from the manufacturer, or named by a different shipment)."
  And the gateway and everything attached to it stay where they are

Examples:
  | where the device is |
  | in {Customer A}'s account, created there by an AS500 file |
  | in {Customer A}'s account from an FS-2772 shipment, and now installed on a real asset |
  | in {Customer A}'s account from an FS-2772 shipment, and moved by an organization transfer since |
  | in {Customer A}'s account from an FS-2772 shipment with Sales Order Number {SO 1}, while the row has {SO 2} |
  | in {Customer A}'s account from an FS-2772 shipment with Shipment Number {Shipment 1}, while the row has {Shipment 2} |
  | in the Road Ready holding account but never received from a manufacturer file |
```

Automation Recommendation: Candidate

Status: Created

EMTE: 1.5

Traceability: US2-AC4, US6-AC5, FR-023

---

@FS-2881
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Devices cannot be shipped to the Road Ready holding account

```gherkin
Scenario: Failure or resilience behavior - row names the Road Ready holding organization as the customer
  Given a shipment row whose Ship To customer ID belongs to the Road Ready holding organization
  When the asset service processes the row
  Then the row fails with "Devices cannot be shipped to the Road Ready holding account."
  And no device is moved or created
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: FR-023

---

@FS-2882
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Device the customer already has is skipped, not failed

```gherkin
Scenario: Successful interaction - the device was already delivered to this customer
  Given gateway {Gateway IMEI} is already in one of {Customer A}'s accounts
  And a shipment row ships it to {Customer A ID} with a different Part Description
  When the asset service processes the file
  Then the row is counted as skipped, not failed
  And nothing about the gateway changes, including its Part Description
  And the row does not appear in the error file
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: US2-AC5, FR-028

---

@FS-2883
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Device sent to the wrong customer is corrected by resending the same shipment

```gherkin
Scenario Outline: Interaction variation matrix - correcting a wrong-customer shipment
  Given gateway {Gateway IMEI} was shipped to {Customer A} by mistake with Sales Order Number <original SO> and Shipment Number <original shipment>
  And the gateway has not been installed or moved since
  When a corrected row ships it to {Customer B ID} with Sales Order Number <row SO> and Shipment Number <row shipment>
  Then <result>

Examples:
  | original SO | original shipment | row SO     | row shipment | result |
  | SO-100      | SH-1              | SO-100     | SH-1         | the gateway moves to {Customer B}, the move is recorded as a re-delivery, and billing is notified |
  | SO-100      | SH-1              | " so-100 " | "sh-1"       | re-delivered; spaces and upper/lower case are ignored |
  | SO-100      | blank             | SO-100     | blank        | re-delivered; a blank Shipment Number matches only a blank one |
  | SO-100      | blank             | SO-100     | SH-1         | fails with "DEVICE_NOT_TRANSFERABLE" |
  | SO-100      | SH-1              | SO-200     | SH-1         | fails with "DEVICE_NOT_TRANSFERABLE" |
```

Automation Recommendation: Candidate

Status: Created

EMTE: 1.5

Traceability: US6-AC4, US6-AC5, FR-023, FR-024, SC-013

---

@FS-2884
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Correction stops if the device is installed while it is being processed

```gherkin
Scenario: Failure or resilience behavior - the device is installed during a correction
  Given gateway {Gateway IMEI} qualifies to be corrected from {Customer A} to {Customer B}
  And while the correction is processing, the gateway is installed on a real asset
  When the asset service tries to move it
  Then the row fails with "TRANSFER_FAILED" or "DEVICE_NOT_TRANSFERABLE"
  And the gateway, its trailer and the real asset all stay with {Customer A}
  And no re-delivery is recorded
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: FR-022, FR-023

---

@FS-2885
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Resending an older file does not pull back a device PSI has already forwarded

```gherkin
Scenario: Failure or resilience behavior - stale file resent after a PSI forward
  Given gateway {Gateway IMEI} was shipped to PSI holding by file 1 with Sales Order Number {SO 1}
  And PSI then forwarded it to {Customer A} with file 2 and Sales Order Number {SO 2}
  When file 1 is resent unchanged
  Then the gateway's row fails with "DEVICE_NOT_TRANSFERABLE"
  And the gateway stays with {Customer A}
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: EC-1, FR-023

---

@FS-2886
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Shipment to PSI lands in the PSI holding account

```gherkin
Scenario Outline: Interaction variation matrix - devices shipped to PSI
  Given <device>
  And a shipment row names it with the PSI holding organization's customer ID in Bill To and Ship To
  When the asset service processes the file
  Then the device is in the PSI holding account
  And the shipment record says it was <how>

Examples:
  | device                                                                | how |
  | gateway {Gateway IMEI} is in Road Ready holding, received from PRIMAX | transferred |
  | gateway {New IMEI} is not yet in Fus1on                               | created |
  | sensor {New Sensor ID} is not yet in Fus1on                           | created |
```

Automation Recommendation: Candidate

Status: Created

EMTE: 1.0

Traceability: US5-AC1, FR-013, FR-026

---

@FS-2887
## [px-asset-service][FS-2772-seon-shipment-file-automation] - PSI can forward a device on to its own customer

```gherkin
Scenario: Successful interaction - shipping out of the PSI holding account
  Given gateway {Gateway IMEI} is in the PSI holding account
  And a shipment row ships it to {Customer A ID}
  When the asset service processes the file
  Then the gateway and everything attached to it are now in {Customer A}'s account
  And the shipment record says it was transferred from PSI holding
  And billing is notified of the move
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: US5-AC2, FR-023, FR-024

---

@FS-2888
## [px-asset-service][FS-2772-seon-shipment-file-automation] - PSI holding account is set up in every environment

```gherkin
Scenario: Successful interaction - PSI holding setup per environment
  Given the feature is deployed to {Environment}
  When the asset service reads the PSI holding organization from the environment configuration
  Then that organization exists in {Environment}
  And it has exactly one active main account
```

Automation Recommendation: Do Not Automate

Status: Created

EMTE: 0.5

Traceability: US5-AC3, FR-026

---

@FS-2889
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Resending a file unchanged changes nothing and reports no failures

```gherkin
Scenario: Successful interaction - safe resend of a processed file
  Given file 1 was processed once and delivered {Delivered} devices with no failures
  When file 1 is sent again unchanged, by email or through the web app
  Then the new run reports {Delivered} skipped and 0 failed
  And no device is created or moved
  And the email has no error file attached
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: US6-AC1, FR-028, SC-003, SC-013

---

@FS-2890
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Resending after fixing failed rows delivers the fixed rows and skips the rest

```gherkin
Scenario: Successful interaction - resend after correcting failed rows
  Given file 1 delivered {Good} rows and failed {Bad} rows
  And {Fixed} of the failed rows are corrected and the whole file is sent again
  When the asset service processes it
  Then the corrected rows are delivered
  And the rows delivered the first time are counted as skipped
  And the error file lists only the {Bad} - {Fixed} rows that still fail
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: US6-AC2, EC-10, FR-028

---

@FS-2891
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Run that keeps failing is marked failed and support is told to resend

```gherkin
Scenario: Failure or resilience behavior - automatic retries run out on a customer shipment run
  Given a customer shipment run keeps hitting a temporary error after {Processed} rows were saved
  When all automatic retries are used up
  Then the run is marked "Failed" with an end time
  And support receives one email saying "The run could not be completed; resend the file to finish the remaining records."
  And resending the file delivers the remaining rows and skips the {Processed} already handled
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: US6-AC3, FR-029, SC-005

---

@FS-2892
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Run interrupted part-way picks up without doubling anything

```gherkin
Scenario: Failure or resilience behavior - processing is interrupted and retried
  Given a run of {Total} rows is interrupted after {Saved} rows were saved
  When the run is retried automatically
  Then no device is created or moved twice
  And each row is counted once, so succeeded plus skipped plus failed equals {Total}
  And billing is notified again for any transfer whose notification may have been lost
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: FR-024, SC-002, SC-003

---

@FS-2893
## [px-asset-service][FS-2772-seon-shipment-file-automation] - PRIMAX file records devices as received and skips them when resent

```gherkin
Scenario: Successful interaction - PRIMAX receipts and resend
  Given a PRIMAX file with {PRIMAX devices} devices is emailed to the intake mailbox
  When it is processed, and then the same file is sent again after a partial failure
  Then each device from the first run is recorded as received from the manufacturer into Road Ready holding
  And neither run records any customer shipment
  And the second run skips devices already received and receives only the rest
  And the PRIMAX email shows the skipped count, and its total includes the skipped devices
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: US6-AC6, FR-017, FR-021, FR-025, FR-028, SC-012

---

@FS-2894
## [px-asset-service][FS-2772-seon-shipment-file-automation] - PRIMAX run that keeps failing is marked failed and support is told

```gherkin
Scenario: Failure or resilience behavior - automatic retries run out on a PRIMAX run
  Given a PRIMAX run fails on every automatic retry
  When all retries are used up
  Then the run is marked "Failed" with an end time
  And support receives exactly one email for the run
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: FR-021, FR-029, SC-005

---

@FS-2895
## [px-asset-service][FS-2772-seon-shipment-file-automation] - AS500 files give exactly the same results as before this change

```gherkin
Scenario: Successful interaction - AS500 regression check
  Given the results of {AS500 regression files} were recorded before the FS-2772 change was deployed
  When the same files are emailed to the intake mailbox after the change
  Then the checks, created devices, shipment records, run details and emails are identical to the recorded results
  And the AS500 runs are not labelled as customer shipments or manufacturer receipts
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: US1-AC8, FR-021, SC-009

---

@FS-2896
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Shipment record keeps every value billing and reporting need

```gherkin
Scenario: Successful interaction - shipment record contents in the database
  Given a shipment row for gateway {Gateway IMEI} with all 12 columns filled in is delivered to {Customer A}
  When the row is saved
  Then the database shipment record for the gateway holds:
    | field                                                   | validation_type                |
    | destination organization                                | equals {Customer A}            |
    | Bill To and Ship To organizations                       | equals the looked-up customers |
    | IMEI, ICCID, Sensor ID                                  | equals the values in the file  |
    | Sales Order Number, Line Number, Shipment Number        | equals the values in the file  |
    | Part Number, Part Description, Shipping Date, Agreement | equals the values in the file  |
    | customer name                                           | is empty                       |
  And the shipment record and the transfer history entry have the same timestamp
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: FR-024a, FR-025, SC-012

---

@FS-2897
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Run is recorded in the database before any row is processed

```gherkin
Scenario: Successful interaction - run start is recorded
  Given shipment file {File name} arrives by email or through the web app
  When the asset service starts processing it
  Then the database has a run record named "Filename: {File name}" with a start time
  And the start time is earlier than every shipment record and failed row saved for the run
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: US4-AC1, FR-016

---

@FS-2898
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Finished run shows counts that add up and the right status

```gherkin
Scenario: Successful interaction - run totals are recorded
  Given a file with {Succeeded} rows to deliver, {Skipped} rows already delivered and {Failed} invalid rows
  When the asset service finishes the run
  Then the database run record shows:
    | field     | validation_type                           |
    | end time  | not_empty                                 |
    | total     | equals {Succeeded} + {Skipped} + {Failed} |
    | succeeded | equals {Succeeded}                        |
    | skipped   | equals {Skipped}                          |
    | failed    | equals {Failed}                           |
    | status    | equals Completed with errors              |
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: US4-AC2, FR-016, FR-028, SC-007

---

@FS-2899
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Run that stopped part-way never looks like it completed

```gherkin
Scenario: Failure or resilience behavior - an abnormal stop is visible in the run record
  Given a run stops part-way because of a system failure and is no longer processing
  When an operator looks up the run in the database
  Then the run has a start time and is either marked "Failed" or has no end time
  And it is not marked "Completed" or "Completed with errors"
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: US4-AC3, FR-016, SC-007

---

@FS-2900
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Failed rows and their reasons can be looked up without the email

```gherkin
Scenario: Successful interaction - failed rows are kept in the database
  Given an emailed run had {Failed} failed rows, one of which had an extra column {Extra column}
  When an operator looks up the run's failed rows in the database
  Then exactly {Failed} rows are found
  And each one shows:
    | field          | validation_type                                      |
    | original row   | equals the row as received, including {Extra column} |
    | error codes    | equals every code, separated by ";"                  |
    | error messages | equals every message, separated by ";"               |
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: US4-AC4, FR-015, FR-016, SC-007

---

@FS-2901
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Shipment data never appears in application logs

```gherkin
Scenario: Failure or resilience behavior - no file contents in logs or traces
  Given a file with valid and invalid rows containing easy-to-spot values {Marker IMEI}, {Marker ICCID} and {Marker Sensor ID}
  When the asset service processes the file
  Then no log line or trace contains {Marker IMEI}, {Marker ICCID}, {Marker Sensor ID} or any error message text
  And the rejection metric is labelled only with error codes
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: FR-016

---

@FS-2902
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Clean run sends one email with the full counts and no attachment

```gherkin
Scenario: Successful interaction - email for a run with no failures
  Given an emailed shipment run finishes with every row delivered or skipped
  When the asset service sends the run email
  Then support receives exactly one email with subject "Shipment Intake Notification - run {Run number} completed"
  And the email shows:
    | field                                            | validation_type          |
    | file name                                        | equals {File name}       |
    | processing reference                             | equals {Run number}      |
    | processed at                                     | not_empty                |
    | status                                           | equals Completed         |
    | total, succeeded, skipped, failed                | equals the run's counts  |
    | how many were transferred, re-delivered, created | equals the run's results |
  And there is no attachment, and the person who sent the file is not emailed
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: US3-AC1, US3-AC3, FR-017, FR-018, FR-019, SC-005, SC-006

---

@FS-2903
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Run with failures sends the error file listing exactly the failed rows

```gherkin
Scenario: Successful interaction - error file attached to the email
  Given an emailed file with its columns in a different order and one extra column has {Failed} failed rows
  When the asset service sends the run email
  Then the subject ends with "completed with errors" and the email has the attachment "shipment-{Run number}-errors.csv"
  And the attachment has a header row and exactly {Failed} rows, in file order
  And its first 12 columns are the standard FS-2772 columns in the standard order, with values exactly as received
  And its last 3 columns are Error Code, Error Description and Processing Timestamp
  And the extra column is not included
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: US3-AC2, US3-AC5, FR-015, FR-018, SC-006

---

@FS-2904
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Error file cannot run spreadsheet formulas

```gherkin
Scenario Outline: Interaction variation matrix - values that look like spreadsheet formulas
  Given a failed row whose Part Description is "<value>"
  When the error file is attached to the run email
  Then the Part Description cell is prefixed so it cannot run as a formula when opened in a spreadsheet
  And every other value in the row is exactly as received

Examples:
  | value       |
  | =SUM(A1:A2) |
  | +1          |
  | -1          |
  | @cmd        |
```

Automation Recommendation: Candidate

Status: Created

EMTE: 1.5

Traceability: FR-015

---

@FS-2905
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Web app uploads also email the uploader's contact address

```gherkin
Scenario: Successful interaction - who receives the run email
  Given one file is uploaded in the web app with contact email {Contact Email} and another is emailed by {Sender}
  When both runs finish
  Then the web app run's email goes to {support recipients} and {Contact Email}
  And the emailed run's email goes to {support recipients} only, never to {Sender}
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: US3-AC1, FR-019

---

@FS-2906
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Email recipients and error messages change through configuration and a restart

```gherkin
Scenario Outline: Interaction variation matrix - configuration controls the email
  Given <configuration change> in the environment configuration for {Environment}
  When the asset service is restarted and a run with a failed sensor row finishes
  Then <result>
  And no code change or new build was needed

Examples:
  | configuration change                                                              | result |
  | the support recipients are changed to {New recipients}                            | the email goes to {New recipients} |
  | the sensor error message is changed to "Sensor rows need a Sensor ID or an IMEI." | the error file shows "Sensor rows need a Sensor ID or an IMEI." |
  | the sensor error message is set to blank                                          | the error file shows the default "A sensor requires a Sensor ID or an IMEI." |
  | the same changes are made but the service is not restarted                        | the old recipients and messages are still used |
```

Automation Recommendation: Do Not Automate

Status: Created

EMTE: 1.5

Traceability: US3-AC6, FR-015, FR-019, SC-008

---

@FS-2907
## [px-asset-service][FS-2772-seon-shipment-file-automation] - If the email cannot be sent, the run's results are still saved

```gherkin
Scenario Outline: Failure or resilience behavior - the run email fails
  Given <email problem>
  When a customer shipment run finishes
  Then the failure is logged with the run number only
  And the run's status, times, counts and failed rows are still saved

Examples:
  | email problem                          |
  | the email notification service is down |
  | no support recipients are configured   |
```

Automation Recommendation: Candidate

Status: Created

EMTE: 1.0

Traceability: EC-15, FR-016, FR-019

---

@FS-2908
## [px-asset-service][FS-2772-seon-shipment-file-automation] - Database upgrade works on a database that already holds shipment data

```gherkin
Scenario: Successful interaction - database changes applied over existing data
  Given the database already holds AS500, PRIMAX and old FS-2430 runs, shipment records and failed rows
  When the FS-2772 database upgrade is applied
  Then the upgrade completes and all of its new checks pass
  And existing data is unchanged, with the new fields empty and old shipment records read as "created"
  And AS500 files still process successfully afterwards
```

Automation Recommendation: Candidate

Status: Created

EMTE: 0.5

Traceability: FR-021, SC-009

---

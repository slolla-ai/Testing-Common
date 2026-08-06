Test Type: Component UI

Feature: Bulk Job Submission, Progress, Notification & Cancellation - Command History View

Purpose:\
Validate that the DMS web UI correctly submits bulk device/firmware jobs, surfaces job status and live progress, delivers completion notifications, supports cancellation, and exposes per-device outcome detail on the command-history view, per FS-1865.

Base URLs (optional):\
app_ui: {It must be updated by the test reviewer}

Component Location:\
microservice: dms-web-app

```gherkin
Background:
Given app_ui page is accessible
And page loads without errors
And the DMS user is authenticated with permissions to submit commands/firmware to their authorized devices
And the DMS user has navigated to the command/firmware submission or command-history screen

```

## [dms-web-app][FS-1865-dms-bulk-command-queuing] - Bulk submission above today's 2000-device cap is accepted with a job reference

```gherkin
Scenario: DMS user submits a bulk command well above today's per-request cap and receives immediate acknowledgement
Given user navigates to {bulk-command-submission-page}
And user has selected {5000} valid devices for a single command
When user submits the bulk command
Then the submission is accepted without any prompt to split the selection into smaller submissions
And the command-history view displays a new job entry with a unique job reference and an initial status of "{Pending}"
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: US1-AC1, US1-AC2, FR-002, SC-001, SC-002

---

## [dms-web-app][FS-1865-dms-bulk-command-queuing] - Submission above the configured job ceiling is rejected with a clear message

```gherkin
Scenario: DMS user submits a job larger than the maximum supported job size
Given user navigates to {bulk-command-submission-page}
And user has selected a number of devices exceeding the configured maximum job size of {10,000}
When user submits the bulk command
Then a validation message is displayed with text "{message stating the maximum supported job size and how to proceed}"
And the submission is not accepted and no job entry is created in the command-history view
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: US1-AC3, EC-1, FR-003

---

## [dms-web-app][FS-1865-dms-bulk-command-queuing] - Live progress counts are visible on an in-progress bulk job

```gherkin
Scenario: DMS user views live progress counts for a running job
Given a bulk job {job_reference} is in progress and spans multiple batches
When user expands the job entry with {data-testid="job-history-row"} in the command-history view
Then the expanded view displays current counts for pending, succeeded, failed, and invalid devices
And the displayed counts refresh automatically without any user action
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: US3-AC1, FR-011

---

## [dms-web-app][FS-1865-dms-bulk-command-queuing] - Progress advances automatically between batches without a manual trigger

```gherkin
Scenario: DMS user observes a running job advance through processing without initiating any batch-release action
Given a bulk job {job_reference} is in progress with more devices still pending than have reached a terminal outcome
When user views the expanded job entry over time without performing any action
Then the command-history view presents no control for the DMS user to manually release the next set of devices
And the progress counts for succeeded, failed, invalid, and timed-out devices increase over time until the job reaches a terminal state, with no DMS user action between batches
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: US2-AC1, US2-AC2

---

## [dms-web-app][FS-1865-dms-bulk-command-queuing] - Job status indicator reflects each lifecycle state

```gherkin
Scenario Outline: DMS user views a job's status indicator for each lifecycle state
Given a bulk job {job_reference} is in {job_status} state
When user views the job entry in the command-history view
Then the job entry displays a status indicator with text "{job_status}"

Examples:
| job_status |
| Pending    |
| Validating |
| Processing |
| Completed  |
| Cancelled  |
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: FR-002, FR-010, FR-018

---

## [dms-web-app][FS-1865-dms-bulk-command-queuing] - Completion notification is delivered and retrievable after the submitter has logged out

```gherkin
Scenario: Submitter logs back in after a job completes while they were logged out
Given a bulk job {job_reference} reaches a terminal state while the submitting DMS user is logged out
When the DMS user logs back into app_ui
Then a persisted in-app notification is visible summarizing the job's final outcome with totals by result
And the job's result remains retrievable from the command-history view
```

Automation Recommendation: Do Not Automate

Status: approved

EMTE: {It must be updated by the test reviewer}

Traceability: US3-AC2, US3-AC3, EC-7, FR-012, SC-005

---

## [dms-web-app][FS-1865-dms-bulk-command-queuing] - Cancellation control on an in-progress job stops it and retains partial results

```gherkin
Scenario: DMS user cancels an in-flight bulk job
Given a bulk job {job_reference} is in a non-terminal state
When the DMS user selects the cancel control with {data-testid="job-cancel-button"} on the job entry
Then the job entry's status indicator updates to "{Cancelled}"
And the expanded view retains and displays the partial counts for devices that already reached a terminal outcome
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: EC-9, FR-018

---

## [dms-web-app][FS-1865-dms-bulk-command-queuing] - A job with every device invalid completes immediately with a clear "nothing dispatched" outcome

```gherkin
Scenario: All targeted devices fail validation for a submitted job
Given a bulk job {job_reference} was submitted where every targeted device fails validation
When validation of the job completes
Then the job entry's status indicator updates to "{Completed}" without any batch ever being dispatched
And the completion notification and job detail state "{nothing dispatched - all invalid}"
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: EC-2

---

## [dms-web-app][FS-1865-dms-bulk-command-queuing] - Per-device outcome breakdown is available for a completed job

```gherkin
Scenario: DMS user opens a completed job's detail to review per-device results
Given a bulk job {job_reference} has reached a "{Completed}" state
When the DMS user opens the job's detail view
Then a per-device breakdown is displayed listing each targeted device's individual result of succeeded, failed, invalid, or timed out
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: US5-AC1, SC-007

---

## [dms-web-app][FS-1865-dms-bulk-command-queuing] - Reason or category is shown for a failed or invalid device

```gherkin
Scenario: DMS user inspects a non-succeeded device for follow-up context
Given the per-device breakdown for job {job_reference} includes a device with a result of "{failed}" or "{invalid}"
When the DMS user inspects that device's entry
Then a reason or category is displayed alongside the device's result to support follow-up
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: US5-AC2

---

## [dms-web-app][FS-1865-dms-bulk-command-queuing] - Device unsupported by the requested command or firmware is reported invalid without failing the job

```gherkin
Scenario: A targeted device does not support the requested command or firmware
Given a completed job {job_reference} targeted a device for which the requested command or firmware does not apply
When the DMS user inspects that device's entry in the per-device breakdown
Then the device is shown with a result of "{invalid}" and a reason/category of "{unsupported}"
And the job entry's overall status indicator is unaffected by this device's outcome
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: EC-5, FR-015

---

## [dms-web-app][FS-1865-dms-bulk-command-queuing] - Live progress counts always reconcile to the job's total targeted device count

```gherkin
Scenario: DMS user verifies displayed counts account for every targeted device
Given a bulk job {job_reference} is in progress
When the DMS user views its live progress counts
Then the sum of the displayed pending, succeeded, failed, invalid, timed-out, and cancelled counts equals the job's total targeted device count
```

Automation Recommendation: Do Not Automate

Status: Approved 

EMTE: {It must be updated by the test reviewer}

Traceability: FR-011

---

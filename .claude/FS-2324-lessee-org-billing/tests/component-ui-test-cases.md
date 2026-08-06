Test Type: Component UI

Feature: Leased Asset Upload - Lessee Organization Selection and Upload Results Display

Purpose:\
Validate the px-web-app Leased Asset upload page's Lessee Organization selection control, its upload-gating
behavior, and its upload-results display (telemetry fields and success/failure rendering) for
lessor-to-lessee leasing (FS-2324)

Component Location:
microservice: px-web-app

```gherkin
Background:
Given the Leased Asset page is accessible
And the user is authenticated as a Lessor with the Upload Leased Assets permission
```

## [px-web-app][FS-2324-lessee-org-billing] - Leased Asset page lists only the Lessor's authorized Lessee Organizations

```gherkin
Scenario: Authorized Lessee Organizations are displayed as a selectable list
  Given the Lessor is authorized to lease assets to one or more Lessee Organizations
  When the Leased Asset page loads
  Then every Lessee Organization the Lessor is authorized to lease assets to is displayed as a selectable list
  And no Lessee Organization outside the Lessor's authorization is displayed
```

Automation Recommendation: Do Not Automate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: US1-AC1, FR-001, SC-001

---

## [px-web-app][FS-2324-lessee-org-billing] - No selectable Lessee Organizations are shown when the Lessor has none authorized

```gherkin
Scenario: Zero authorized Lessee Organizations blocks selection and upload
  Given the Lessor has zero authorized Lessee Organizations
  When the Leased Asset page loads
  Then no selectable Lessee Organization is displayed
  And the upload action is prevented, consistent with the required-selection rule
```

Automation Recommendation: Do Not Automate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: EC-1, FR-002, FR-003

---

## [px-web-app][FS-2324-lessee-org-billing] - Upload is gated on whether a Lessee Organization is selected

```gherkin
Scenario Outline: Upload proceeds only when a Lessee Organization is selected
  Given the Lessor is on the Leased Asset page with a leased asset file ready to upload
  And the Lessee Organization selection is {selection_state}
  When the Lessor attempts to upload the leased asset file
  Then the outcome is {expected_outcome}

Examples:
  | selection_state    | expected_outcome                                                                                  |
  | not selected       | the upload is prevented and a validation message indicates a Lessee Organization must be selected |
  | selected           | the upload proceeds                                                                                |
```

Automation Recommendation: Do Not Automate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: US1-AC2, FR-003, SC-002

---

## [px-web-app][FS-2324-lessee-org-billing] - Lessee Organization selection control allows exactly one selection

```gherkin
Scenario: Selection control does not offer multi-select
  Given the Lessee Organization list is displayed with more than one authorized organization
  When the Lessor selects a Lessee Organization
  Then the selection control shows exactly one Lessee Organization as selected
  And the control does not offer a way to select more than one Lessee Organization at the same time
```

Automation Recommendation: Do Not Automate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: US1-AC3, FR-002

---

## [px-web-app][FS-2324-lessee-org-billing] - Changing the selected Lessee Organization updates the displayed selection

```gherkin
Scenario: Selection control reflects a changed choice before upload
  Given the Lessor has already selected a Lessee Organization on the Leased Asset page
  When the Lessor selects a different Lessee Organization from the list
  Then the selection control displays only the newly chosen Lessee Organization as selected
  And the previously selected Lessee Organization is no longer shown as selected
```

Automation Recommendation: Do Not Automate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: US1-AC3, FR-002

---

## [px-web-app][FS-2324-lessee-org-billing] - Successful upload results display live device telemetry per record

```gherkin
Scenario: Success section shows Last Communication Date and MCU Battery Level
  Given a leased asset record has passed validation for the selected Lessee Organization
  And the record's matched asset has a device with retrievable live telemetry
  When the upload results are displayed
  Then the success section shows that record's VIN and Trailer Name
  And the success section shows that record's Last Communication Date
  And the success section shows that record's MCU Battery Level
```

Automation Recommendation: Do Not Automate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: US4-AC1, FR-012

---

## [px-web-app][FS-2324-lessee-org-billing] - Missing device telemetry shows blank fields without marking the record as failed

```gherkin
Scenario: Success section shows blank telemetry instead of a broken or failed row
  Given a leased asset record has passed validation for the selected Lessee Organization
  And the record's matched asset has no device attached, or its live telemetry cannot be retrieved
  When the upload results are displayed
  Then the record still appears in the success section
  And its Last Communication Date and MCU Battery Level are shown blank
```

Automation Recommendation: Do Not Automate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: US4-AC2, EC-6, FR-013, SC-006

---

## [px-web-app][FS-2324-lessee-org-billing] - A record matched to an asset leased to a different Lessee Organization is shown as failed

```gherkin
Scenario: Cross-organization match is rendered in the existing failure results, not the success section
  Given a leased asset record's VIN and Trailer Name match an asset already leased to a Lessee Organization other than the one selected for this upload
  When the upload results are displayed
  Then the record appears in the existing failure/exception results section
  And the record does not appear in the success section
```

Automation Recommendation: Do Not Automate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: US2-AC3, EC-5

---

## [px-web-app][FS-2324-lessee-org-billing] - Leased Asset page access control is unchanged by this feature

```gherkin
Scenario: A user without the required permission is still denied access
  Given a user does not hold the Upload Leased Assets permission
  When the user attempts to access the Leased Asset page
  Then access is denied exactly as it was before this feature
```

Automation Recommendation: Do Not Automate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: US5-AC1, FR-008, SC-004

---

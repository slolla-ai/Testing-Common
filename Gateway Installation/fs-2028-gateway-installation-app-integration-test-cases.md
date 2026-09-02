Test Type: Integration

Feature: Integration - Installer Service to Organization Authorization Domain Interaction

Purpose:\
Validate that the installer authorization domain correctly resolves organization access and role-based gateway-install permission before allowing installer features to proceed.

Base URLs:\
Installer Service (px-user-service): {It must be updated by the test reviewer}\
Organization Authorization Domain: {It must be updated by the test reviewer}

```gherkin
Background:
Given px-user-service is operational
And an installer account with the Installation role exists
And the Organization Authorization Service holds organization-access records for the installer
```

## [px-user-service][FS-2028] - Single-organization access resolves installer permissions

```gherkin
Scenario: Successful interaction - single-organization access resolves installer permissions
  Given the installer's account is associated with exactly one organization
  And the installer's role has the gateway-install permission granted
  When the installer service requests organization access resolution from the authorization domain for the installer
  Then the authorization domain should return exactly one authorized organization
  And the installer should be granted access to installer features without requiring an organization-selection step
  And the resolution outcome should reflect the installer's granted gateway-install permission
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC1

---

## [px-user-service][FS-2028] - Multiple-organization access returns selectable list

```gherkin
Scenario: Successful interaction - multiple-organization access returns selectable list
  Given the installer's account is associated with more than one organization
  And the installer's role has the gateway-install permission granted
  When the installer service requests organization access resolution from the authorization domain for the installer
  Then the authorization domain should return the full list of organizations the installer is authorized to access
  And no single organization should be auto-selected on the installer's behalf
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC1

---

## [px-user-service][FS-2028] - Installer role without gateway-install permission is denied access

```gherkin
Scenario: Failure or resilience behavior - installer role without gateway-install permission is denied access
  Given the installer's role does not have the gateway-install permission granted
  When the installer service requests organization access resolution from the authorization domain for the installer
  Then the authorization domain should deny access to installer features
  And no organization list should be returned to the installer service
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC1

---

## [px-user-service][FS-2028] - Revoked organization access is rejected internally before proceeding

```gherkin
Scenario: Failure or resilience behavior - revoked organization access is rejected internally before proceeding
  Given the installer previously selected an organization for which access has since been revoked
  When the installer service re-validates organization access against the authorization domain before proceeding
  Then the authorization domain should determine the installer no longer has access to the selected organization
  And the installer service should reject the operation internally without proceeding to gateway scan
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC10-dup

---

Feature: Integration - Installation Service to Asset Repository Interaction

Purpose:\
Validate that installation records, asset property updates, and notes are correctly persisted and scope-confirmed against the asset repository, including required-field and duplicate-association enforcement.

Base URLs:\
Installation Service (px-asset-service): {It must be updated by the test reviewer}\
Asset Repository / Database: {It must be updated by the test reviewer}

```gherkin
Background:
Given px-asset-service is operational
And an in-progress installation record exists for a scanned gateway and selected organization
And the Asset Management Service holds the associated asset record
```

## [px-asset-service][FS-2028] - Asset properties retrieved and pre-populated from persisted record

```gherkin
Scenario: Successful interaction - asset properties retrieved and pre-populated from persisted record
  Given a scanned gateway is associated with an existing asset record in the Asset Management Service
  When the installation service requests the associated asset properties for the current installation
  Then the asset repository should return the persisted asset property values
  And the installation service should pre-populate the installation record fields from the returned values
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC4

---

## [px-asset-service][FS-2028] - Updated asset properties saved with required-field validation passing

```gherkin
Scenario: Successful interaction - updated asset properties saved with required-field validation passing
  Given the installer has entered updated values for all required asset property fields
  When the installation service saves the updated asset properties to the asset repository
  Then the asset repository should persist the updated property values against the installation record
  And the required-field validation at the domain layer should pass without error
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC5

---

## [px-asset-service][FS-2028] - Installation notes persisted with the installation record

```gherkin
Scenario: Successful interaction - installation notes persisted with the installation record
  Given the installer has entered free-text notes for the current installation
  When the installation service saves the notes to the installation record
  Then the notes should be persisted and associated with the correct installation record identifier
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC8

---

## [px-asset-service][FS-2028] - Save rejected when required asset property fields are blank

```gherkin
Scenario: Failure or resilience behavior - save rejected when required asset property fields are blank
  Given the installer has left one or more required asset property fields blank
  When the installation service attempts to save the asset properties to the asset repository
  Then the repo/domain layer should reject the save operation
  And the installation record should retain its previously persisted values unchanged
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC17

---

## [px-asset-service][FS-2028] - Duplicate gateway-to-asset association rejected by the repository

```gherkin
Scenario: Failure or resilience behavior - duplicate gateway-to-asset association rejected by the repository
  Given the scanned gateway is already linked to a different asset record in the asset repository
  When the installation service attempts to associate the same gateway with the current asset record
  Then the repo layer should detect the existing association
  And the association attempt should be rejected without altering the existing asset-gateway link
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC18

---

Feature: Integration - Gateway Assignment Domain to Audit Log Repository Interaction

Purpose:\
Validate that confirming a gateway swap consistently updates gateway assignment state and writes a complete audit history across the gateway-assignment and audit-log persistence boundaries.

Base URLs:\
Gateway Assignment Domain (px-asset-service): {It must be updated by the test reviewer}\
Audit Log Repository: {It must be updated by the test reviewer}

```gherkin
Background:
Given px-asset-service is operational
And an installation record exists with an active gateway assignment
And the audit log repository is available to record gateway-assignment changes
```

## [px-asset-service][FS-2028] - Gateway swap confirmation updates assignment and writes complete audit history

```gherkin
Scenario: Successful interaction - gateway swap confirmation updates assignment and writes complete audit history
  Given an installation record has an active gateway assignment
  And a replacement gateway has been scanned for the swap
  When the installer confirms the gateway swap
  Then the existing gateway assignment should be marked removed
  And the replacement gateway should be associated with the asset in the same orchestrated operation
  And a complete audit history entry should be persisted with installer ID, timestamp, and organization context
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC9, AC10

---

## [px-asset-service][FS-2028] - Swap orchestration failure leaves gateway assignment state consistent

```gherkin
Scenario: Failure or resilience behavior - swap orchestration failure leaves gateway assignment state consistent
  Given an installation record has an active gateway assignment
  And a replacement gateway has been scanned for the swap
  When the audit-log write step fails partway through the gateway swap orchestration
  Then the gateway assignment change should not be partially committed
  And the existing gateway assignment should remain in its prior consistent state
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC9, AC10

---

## [px-asset-service][FS-2028] - Audit history captures full installer and organization context on swap

```gherkin
Scenario: Successful interaction - audit history captures full installer and organization context on swap
  Given a gateway swap has been confirmed for an installation
  When the audit history entry for the swap is persisted
  Then the entry should record the installer ID, timestamp, and organization context alongside the removed and assigned gateway identifiers
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC9, AC10

---

Feature: Integration - Installation Service to S3 Photo Storage Adapter Interaction

Purpose:\
Validate that installation photo bytes are correctly stored via the S3Service adapter and linked to the persisted installation record, including replace and delete operations.

Base URLs:\
Installation Service (px-asset-service): {It must be updated by the test reviewer}\
S3 Photo Storage Adapter: {It must be updated by the test reviewer}

```gherkin
Background:
Given px-asset-service is operational
And an installation record exists for the current installation session
And the S3Service adapter is configured with a valid installation-photos bucket
```

## [px-asset-service][FS-2028] - Photo bytes stored via S3Service and linked to installation record

```gherkin
Scenario: Successful interaction - photo bytes stored via S3Service and linked to installation record
  Given the installer has captured a photo for the current installation
  When the installation service stores the photo through the S3Service adapter
  Then the photo bytes should be stored in the configured S3 bucket
  And the installation record should be linked to the stored photo's reference
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC6, AC7

---

## [px-asset-service][FS-2028] - Replacing an existing photo updates the stored object and link

```gherkin
Scenario: Successful interaction - replacing an existing photo updates the stored object and link
  Given the installation record already has a photo linked from a prior upload
  When the installer replaces the photo
  Then the S3Service adapter should store the new photo bytes
  And the installation record's photo link should be updated to reference the new photo, no longer the prior one
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC7

---

## [px-asset-service][FS-2028] - Deleting a photo removes both the stored object and its link

```gherkin
Scenario: Successful interaction - deleting a photo removes both the stored object and its link
  Given the installation record has a photo linked from a prior upload
  When the installer deletes the photo
  Then the S3Service adapter should remove the corresponding stored object
  And the installation record should no longer reference the deleted photo
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC7

---

## [px-asset-service][FS-2028] - S3 adapter upload failure leaves no orphaned photo link

```gherkin
Scenario: Failure or resilience behavior - S3 adapter upload failure leaves no orphaned photo link
  Given the installer has captured a photo for the current installation
  When the S3Service adapter encounters a transient storage failure during upload
  Then the installation record should not be linked to a photo reference
  And the failure should be handled without leaving an orphaned or broken link on the installation record
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC6, AC7

---

Feature: Integration - Installation Completion Orchestrator to Persistence Layer Interaction

Purpose:\
Validate that completing an installation orchestrates asset, photo, notes, and gateway-assignment persistence with status update as one consistent operation, including idempotency on retried submissions.

Base URLs:\
Installation Completion Orchestrator (px-asset-service): {It must be updated by the test reviewer}\
Persistence Layer (asset, photo, notes, gateway-assignment repositories): {It must be updated by the test reviewer}

```gherkin
Background:
Given px-asset-service is operational
And an installation record exists with pending asset changes, photos, and notes
And the gateway assignment for the installation has been determined
```

## [px-asset-service][FS-2028] - Completing installation orchestrates all sub-operations and sets status Completed

```gherkin
Scenario: Successful interaction - completing installation orchestrates all sub-operations and sets status Completed
  Given an installation record has pending asset changes, photos, and notes, and a determined gateway assignment
  When the installer completes the installation
  Then the asset changes should be saved
  And the photos should be stored
  And the notes should be saved
  And the gateway assignment should be updated
  And the installation status should be set to Completed as one orchestrated operation
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC11

---

## [px-asset-service][FS-2028] - Retried completion submission after dropped connection does not duplicate the installation record

```gherkin
Scenario: Failure or resilience behavior - retried completion submission after dropped connection does not duplicate the installation record
  Given an installation completion submission was sent but the connection dropped before a response was received
  When the installer retries the completion submission for the same installation
  Then only one installation record should exist for that installation
  And the installation status should be set to Completed exactly once
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC20

---

## [px-asset-service][FS-2028] - Partial orchestration failure does not mark installation Completed

```gherkin
Scenario: Failure or resilience behavior - partial orchestration failure does not mark installation Completed
  Given an installation record has pending asset changes, photos, and notes, and a determined gateway assignment
  When the gateway-assignment update step fails during installation completion
  Then the installation status should not be set to Completed
  And the sub-operations that succeeded before the failure should not leave the installation record in an inconsistent status
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC11

---

Feature: Integration - Device Validation Domain to Gateway Registry Repository Interaction

Purpose:\
Validate that device number format validation and gateway-registry lookups are correctly enforced at the domain layer before installation can proceed.

Base URLs:\
Device Validation Domain (px-asset-service): {It must be updated by the test reviewer}\
Gateway Device Registry Repository (MCU/TrackRR): {It must be updated by the test reviewer}

```gherkin
Background:
Given px-asset-service is operational
And the Gateway Device Registry (MCU/TrackRR) is reachable
And a gateway device number has been scanned for the current installation
```

## [px-asset-service][FS-2028] - Well-formed edited device number passes format validation

```gherkin
Scenario: Successful interaction - well-formed edited device number passes format validation
  Given the installer has edited the scanned device number
  When the domain layer validates the edited device number against device-number-format standards
  Then the validation should pass
  And the edited device number should be accepted for the installation record
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC3

---

## [px-asset-service][FS-2028] - Device number format validation outcomes across malformed variants

```gherkin
Scenario Outline: Interaction variation matrix - device number format validation outcomes
  When the domain layer validates an edited device number of {input_variant}
  Then {expected interaction outcome} should occur

Examples:
| input_variant | expected interaction outcome |
| correct length and character set | validation passes and the value is accepted |
| too few characters | validation fails and the edit is rejected |
| too many characters | validation fails and the edit is rejected |
| disallowed characters present | validation fails and the edit is rejected |
| empty value | validation fails and the edit is rejected |
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC3

---

## [px-asset-service][FS-2028] - Unregistered gateway device logs a failed-lookup event for audit

```gherkin
Scenario: Failure or resilience behavior - unregistered gateway device logs a failed-lookup event for audit
  Given a scanned gateway device number is not found in the Gateway Device Registry
  When the domain layer performs the registry lookup for the scanned device
  Then the lookup should be reported as failed to the installation service
  And a failed-lookup event should be logged for audit purposes
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC8-dup

---

## [px-asset-service][FS-2028] - Gateway with an existing active assignment blocks installation

```gherkin
Scenario: Failure or resilience behavior - gateway with an existing active assignment blocks installation
  Given a scanned gateway already has an existing active assignment recorded in the repository
  When the domain layer performs the registry/assignment lookup for the scanned gateway
  Then the domain layer should detect the existing active assignment
  And installation should not be allowed to proceed with this gateway
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC9-dup

---

## [px-asset-service][FS-2028] - Scanned gateway organization mismatch is rejected before installation proceeds

```gherkin
Scenario: Failure or resilience behavior - scanned gateway organization mismatch is rejected before installation proceeds
  Given the scanned gateway's registered organization does not match the installer's selected organization
  When the domain layer confirms the scanned gateway's organization against the selected organization
  Then the domain layer should reject the operation
  And installation should not be allowed to proceed for this gateway under the selected organization
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC11-dup

---

Test Type: Component API

Feature: px-web-app-api - Gateway Installation, Asset Update, and Installation Documentation BFF endpoints behavior

Purpose:\
Validate the px-web-app-api BFF endpoints that support the installer gateway installation workflow — organization scaffold retrieval, gateway number validation (format, registry, assignment, and organization authorization), asset property retrieval and update, photo upload, gateway swap validation and confirmation, and installation completion (idempotent) — correctly handle valid and invalid request scenarios, each endpoint in isolation.

Base URLs:\
px-web-app-api: {It must be updated by the test reviewer}

Payloads (optional):\
gatewayValidatePayload: {payload_file_reference}\
assetPropertiesUpdatePayload: {payload_file_reference}\
photoUploadPayload: {payload_file_reference}\
gatewaySwapValidatePayload: {payload_file_reference}\
gatewaySwapConfirmPayload: {payload_file_reference}\
completeInstallationPayload: {payload_file_reference}

```gherkin
Background:
Given px-web-app-api is available and reachable
And a valid installer authentication session exists for the request unless the scenario states otherwise
And an authorized organization context has been established for the installer unless the scenario states otherwise
```

## [px-web-app-api][FS-2028] - Organization scaffold returns all authorized organizations when installer has access to multiple

```gherkin
Scenario: Multiple authorized organizations are returned by the scaffold endpoint
  Given the installer is authorized for {multipleOrgCount} organizations
  When px-web-app-api sends GET request to {ORG_SCAFFOLD_PATH}
  Then px-web-app-api responds with status 200
  And response body contains:
    | field                | expected_value | validation_type |
    | organizations        | —               | not_empty       |
    | organizations        | {multipleOrgCount} | equals       |
    | autoSelected         | false           | equals          |
  And response header "Content-Type" equals "application/json"
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC1

---

## [px-web-app-api][FS-2028] - Organization scaffold auto-selects the single authorized organization

```gherkin
Scenario: Single authorized organization is auto-selected by the scaffold endpoint
  Given the installer is authorized for exactly one organization
  When px-web-app-api sends GET request to {ORG_SCAFFOLD_PATH}
  Then px-web-app-api responds with status 200
  And response body contains:
    | field         | expected_value | validation_type |
    | organizations | 1               | equals          |
    | autoSelected  | true            | equals          |
    | organizationId | —              | not_empty       |
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC1

---

## [px-web-app-api][FS-2028] - Gateway validate accepts a correctly formatted, registered, unassigned, org-authorized gateway number

```gherkin
Scenario: Valid gateway number passes format, registry, assignment, and organization authorization checks
  Given {gatewayNumber} conforms to the device number format standard
  And {gatewayNumber} exists in the Device Registry
  And {gatewayNumber} is not currently assigned to another active asset or organization
  And {gatewayNumber} belongs to the installer's selected organization
  When px-web-app-api sends POST request to {GATEWAY_VALIDATE_PATH} with {gatewayValidatePayload}
  Then px-web-app-api responds with status 200
  And response body contains:
    | field         | expected_value | validation_type |
    | gatewayNumber | {gatewayNumber} | equals          |
    | valid         | true            | equals          |
  And response header "Content-Type" equals "application/json"
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC2, AC3

---

## [px-web-app-api][FS-2028] - Gateway validate rejects an edited gateway number that fails format validation

```gherkin
Scenario: Edited gateway number failing server-side format validation is rejected
  Given the installer has edited the scanned gateway number to {invalidGatewayNumber}
  When px-web-app-api sends POST request to {GATEWAY_VALIDATE_PATH} with {gatewayValidatePayload}
  Then px-web-app-api responds with status 400
  And response body contains:
    | field   | expected_value                                                        | validation_type |
    | error   | Invalid gateway number scanned. Please rescan or enter a valid gateway number. | equals |
  And no unintended side effects should occur
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC3, AC12

---

## [px-web-app-api][FS-2028] - Gateway validate format validation matrix

```gherkin
Scenario Outline: Gateway number format validation across invalid input variants
  When px-web-app-api sends POST request to {GATEWAY_VALIDATE_PATH} with <gatewayNumberVariant>
  Then px-web-app-api responds with status <HTTPCODE>
  And response body contains:
    | field | expected_value     | validation_type |
    | error | <expectedError>    | equals          |

Examples:
  | gatewayNumberVariant       | HTTPCODE | expectedError                                                                 |
  | {tooShortGatewayNumber}    | 400      | Invalid gateway number scanned. Please rescan or enter a valid gateway number. |
  | {tooLongGatewayNumber}     | 400      | Invalid gateway number scanned. Please rescan or enter a valid gateway number. |
  | {invalidCharsGatewayNumber}| 400      | Invalid gateway number scanned. Please rescan or enter a valid gateway number. |
  | {emptyGatewayNumber}       | 400      | Invalid gateway number scanned. Please rescan or enter a valid gateway number. |
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC3, AC12

---

## [px-web-app-api][FS-2028] - Gateway validate rejects a gateway number not found in the Device Registry

```gherkin
Scenario: Gateway number not present in the Device Registry is rejected
  Given {gatewayNumber} is correctly formatted but does not exist in the Device Registry
  When px-web-app-api sends POST request to {GATEWAY_VALIDATE_PATH} with {gatewayValidatePayload}
  Then px-web-app-api responds with status 404
  And response body contains:
    | field | expected_value              | validation_type |
    | error | Gateway device not found.   | equals           |
  And no unintended side effects should occur
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC8

---

## [px-web-app-api][FS-2028] - Gateway validate rejects a gateway number already assigned to another active asset or organization

```gherkin
Scenario: Gateway already assigned to another active asset is rejected
  Given {gatewayNumber} is registered and correctly formatted
  And {gatewayNumber} is currently assigned to another active asset in a different organization
  When px-web-app-api sends POST request to {GATEWAY_VALIDATE_PATH} with {gatewayValidatePayload}
  Then px-web-app-api responds with status 409
  And response body contains:
    | field | expected_value                                             | validation_type |
    | error | This gateway is already assigned and cannot be installed.  | equals          |
  And no unintended side effects should occur
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC9

---

## [px-web-app-api][FS-2028] - Gateway validate rejects the request when the installer no longer has access to the selected organization

```gherkin
Scenario: Installer without access to the selected organization is rejected on validate
  Given the installer's authorization for the selected organization has been revoked
  When px-web-app-api sends POST request to {GATEWAY_VALIDATE_PATH} with {gatewayValidatePayload}
  Then px-web-app-api responds with status 403
  And response body contains:
    | field | expected_value                                    | validation_type |
    | error | You do not have access to this organization.       | equals          |
  And no unintended side effects should occur
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC10

---

## [px-web-app-api][FS-2028] - Gateway validate rejects a gateway number belonging to a different organization

```gherkin
Scenario: Gateway number registered to a different organization than the selected one is rejected
  Given {gatewayNumber} is registered and correctly formatted
  And {gatewayNumber} belongs to an organization other than the installer's selected organization
  When px-web-app-api sends POST request to {GATEWAY_VALIDATE_PATH} with {gatewayValidatePayload}
  Then px-web-app-api responds with status 403
  And response body contains:
    | field | expected_value                                                     | validation_type |
    | error | The scanned gateway is not authorized for the selected organization. | equals         |
  And no unintended side effects should occur
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC11

---

## [px-web-app-api][FS-2028] - Gateway validate rejects an expired installer session

```gherkin
Scenario: Expired installer session is rejected when attempting to validate a gateway
  Given the installer's session has expired due to inactivity
  When px-web-app-api sends POST request to {GATEWAY_VALIDATE_PATH} with {gatewayValidatePayload}
  Then px-web-app-api responds with status 401
  And response body contains:
    | field | expected_value                                     | validation_type |
    | error | Your session has expired. Please sign in again.    | equals          |
  And no unintended side effects should occur
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC19

---

## [px-web-app-api][FS-2028] - Gateway validate returns a generic error on unexpected system failure

```gherkin
Scenario: Unhandled failure during gateway validation returns a generic error without technical detail
  Given an unhandled dependency failure occurs while processing the validate request
  When px-web-app-api sends POST request to {GATEWAY_VALIDATE_PATH} with {gatewayValidatePayload}
  Then px-web-app-api responds with status 500
  And response body contains:
    | field | expected_value                                                          | validation_type |
    | error | An unexpected error occurred. Please try again or contact support.     | equals           |
  And response body does not contain internal technical details or stack traces
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC21

---

## [px-web-app-api][FS-2028] - Asset properties retrieval returns pre-populated existing asset information

```gherkin
Scenario: Existing asset information is retrieved and pre-populated after Continue
  Given an asset record already exists for {gatewayNumber}
  When px-web-app-api sends GET request to {ASSET_PROPERTIES_PATH}
  Then px-web-app-api responds with status 200
  And response body contains:
    | field          | expected_value | validation_type |
    | assetId        | —               | not_empty       |
    | assetProperties | —              | not_empty       |
  And response header "Content-Type" equals "application/json"
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC4

---

## [px-web-app-api][FS-2028] - Asset properties retrieval reports no associated asset record

```gherkin
Scenario: No associated asset record exists for the scanned gateway
  Given no asset record is associated with {gatewayNumber}
  When px-web-app-api sends GET request to {ASSET_PROPERTIES_PATH}
  Then px-web-app-api responds with status 404
  And response body contains:
    | field | expected_value                        | validation_type |
    | error | No asset record found for this gateway. | equals         |
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC12

---

## [px-web-app-api][FS-2028] - Asset properties retrieval fails gracefully when the Asset Management Service is unavailable

```gherkin
Scenario: Asset Management Service unavailability returns an error with no partial data
  Given the upstream Asset Management Service is unavailable
  When px-web-app-api sends GET request to {ASSET_PROPERTIES_PATH}
  Then px-web-app-api responds with status 503
  And response body contains:
    | field | expected_value                                          | validation_type |
    | error | Unable to retrieve asset information. Please try again. | equals           |
  And response body contains:
    | field           | expected_value | validation_type |
    | assetProperties | —               | not_present      |
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC13

---

## [px-web-app-api][FS-2028] - Asset properties save persists a valid update

```gherkin
Scenario: Valid asset property field update is saved successfully
  Given all required asset property fields are present and valid in {assetPropertiesUpdatePayload}
  When px-web-app-api sends PUT request to {ASSET_PROPERTIES_PATH} with {assetPropertiesUpdatePayload}
  Then px-web-app-api responds with status 200
  And response body contains:
    | field   | expected_value | validation_type |
    | assetId | —               | not_empty       |
    | saved   | true            | equals          |
  And response header "Content-Type" equals "application/json"
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC5

---

## [px-web-app-api][FS-2028] - Asset properties save rejects a request with a missing or invalid required field

```gherkin
Scenario: Missing or invalid required asset property field prevents save
  Given {assetPropertiesUpdatePayload} is missing a required field
  When px-web-app-api sends PUT request to {ASSET_PROPERTIES_PATH} with {assetPropertiesUpdatePayload}
  Then px-web-app-api responds with status 400
  And response body contains:
    | field           | expected_value        | validation_type |
    | fieldErrors     | —                      | not_empty       |
    | fieldErrors.field | {requiredFieldName} | equals           |
  And no unintended side effects should occur
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC5, AC17

---

## [px-web-app-api][FS-2028] - Asset properties save field-level validation matrix

```gherkin
Scenario Outline: Required field validation across invalid input variants on save
  When px-web-app-api sends PUT request to {ASSET_PROPERTIES_PATH} with <fieldVariant>
  Then px-web-app-api responds with status <HTTPCODE>
  And response body contains:
    | field       | expected_value  | validation_type |
    | fieldErrors | <expectedField> | contains         |

Examples:
  | fieldVariant                          | HTTPCODE | expectedField          |
  | {requiredField} left blank            | 400      | {requiredField}        |
  | {requiredField} with invalid type      | 400      | {requiredField}        |
  | {requiredField} out of allowed range   | 400      | {requiredField}        |
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC17

---

## [px-web-app-api][FS-2028] - Asset properties save rejects a gateway already associated with another asset

```gherkin
Scenario: Gateway already linked to another asset is rejected on save
  Given {gatewayNumber} in {assetPropertiesUpdatePayload} is already associated with a different asset record
  When px-web-app-api sends PUT request to {ASSET_PROPERTIES_PATH} with {assetPropertiesUpdatePayload}
  Then px-web-app-api responds with status 409
  And response body contains:
    | field | expected_value                                              | validation_type |
    | error | Gateway is already associated with another asset.           | equals          |
  And no unintended side effects should occur
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC18

---

## [px-web-app-api][FS-2028] - Asset properties save rejects an expired installer session

```gherkin
Scenario: Expired installer session is rejected when attempting to save asset properties
  Given the installer's session has expired due to inactivity
  When px-web-app-api sends PUT request to {ASSET_PROPERTIES_PATH} with {assetPropertiesUpdatePayload}
  Then px-web-app-api responds with status 401
  And response body contains:
    | field | expected_value                                  | validation_type |
    | error | Your session has expired. Please sign in again. | equals          |
  And no unintended side effects should occur
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC19

---

## [px-web-app-api][FS-2028] - Asset properties save returns a generic error on unexpected system failure

```gherkin
Scenario: Unhandled failure during asset properties save returns a generic error without technical detail
  Given an unhandled dependency failure occurs while processing the save request
  When px-web-app-api sends PUT request to {ASSET_PROPERTIES_PATH} with {assetPropertiesUpdatePayload}
  Then px-web-app-api responds with status 500
  And response body contains:
    | field | expected_value                                                      | validation_type |
    | error | An unexpected error occurred. Please try again or contact support. | equals           |
  And response body does not contain internal technical details or stack traces
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC21

---

## [px-web-app-api][FS-2028] - Photo upload accepts supported image formats

```gherkin
Scenario Outline: Supported photo file formats are uploaded successfully
  When px-web-app-api sends POST request to {PHOTO_UPLOAD_PATH} with <photoFormatVariant>
  Then px-web-app-api responds with status 200
  And response body contains:
    | field        | expected_value | validation_type |
    | uploadStatus | success         | equals          |
    | photoId      | —               | not_empty       |

Examples:
  | photoFormatVariant        |
  | {validJpgPhotoPayload}    |
  | {validJpegPhotoPayload}   |
  | {validPngPhotoPayload}    |
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC6, AC7

---

## [px-web-app-api][FS-2028] - Photo upload rejects an unsupported file format

```gherkin
Scenario: Unsupported photo file format is rejected
  Given {unsupportedFormatPhotoPayload} is not JPG, JPEG, or PNG
  When px-web-app-api sends POST request to {PHOTO_UPLOAD_PATH} with {unsupportedFormatPhotoPayload}
  Then px-web-app-api responds with status 400
  And response body contains:
    | field | expected_value                                                | validation_type |
    | error | Unsupported file format or file exceeds allowed size.        | equals           |
  And no unintended side effects should occur
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC15

---

## [px-web-app-api][FS-2028] - Photo upload rejects a file exceeding the maximum configured size

```gherkin
Scenario: Photo exceeding the maximum configured file size is rejected
  Given {oversizedPhotoPayload} exceeds the configured maximum file size
  When px-web-app-api sends POST request to {PHOTO_UPLOAD_PATH} with {oversizedPhotoPayload}
  Then px-web-app-api responds with status 400
  And response body contains:
    | field | expected_value                                          | validation_type |
    | error | Unsupported file format or file exceeds allowed size.  | equals           |
  And no unintended side effects should occur
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC7, AC15

---

## [px-web-app-api][FS-2028] - Photo upload failure returns an error with no partial data

```gherkin
Scenario: Photo storage failure returns an error without partial data
  Given the upstream photo storage dependency fails to process {photoUploadPayload}
  When px-web-app-api sends POST request to {PHOTO_UPLOAD_PATH} with {photoUploadPayload}
  Then px-web-app-api responds with status 502
  And response body contains:
    | field | expected_value                            | validation_type |
    | error | Unable to upload photo. Please try again. | equals          |
  And response body contains:
    | field   | expected_value | validation_type |
    | photoId | —               | not_present      |
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC14

---

## [px-web-app-api][FS-2028] - Photo delete removes a previously uploaded photo before submission

```gherkin
Scenario: Previously uploaded photo is deleted before installation submission
  Given {photoId} was previously uploaded and not yet submitted
  When px-web-app-api sends DELETE request to {PHOTO_PATH}
  Then px-web-app-api responds with status 200
  And response body contains:
    | field   | expected_value | validation_type |
    | deleted | true            | equals          |
    | photoId | {photoId}       | equals          |
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC7

---

## [px-web-app-api][FS-2028] - Gateway swap validate accepts a valid, available replacement gateway number

```gherkin
Scenario: Valid replacement gateway number is accepted for swap
  Given {replacementGatewayNumber} conforms to the device number format standard
  And {replacementGatewayNumber} is registered and available for assignment
  When px-web-app-api sends POST request to {GATEWAY_SWAP_VALIDATE_PATH} with {gatewaySwapValidatePayload}
  Then px-web-app-api responds with status 200
  And response body contains:
    | field                    | expected_value             | validation_type |
    | valid                    | true                        | equals          |
    | existingGatewayNumber    | —                           | not_empty       |
    | existingAssignmentDetails | —                          | not_empty       |
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC9

---

## [px-web-app-api][FS-2028] - Gateway swap validate rejects an invalid or unavailable replacement gateway number

```gherkin
Scenario: Invalid or unavailable replacement gateway number is rejected for swap
  Given {replacementGatewayNumber} fails format validation or is otherwise unavailable for assignment
  When px-web-app-api sends POST request to {GATEWAY_SWAP_VALIDATE_PATH} with {gatewaySwapValidatePayload}
  Then px-web-app-api responds with status 400
  And response body contains:
    | field | expected_value                             | validation_type |
    | error | Selected gateway cannot be used for swap.  | equals           |
  And no unintended side effects should occur
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC16

---

## [px-web-app-api][FS-2028] - Gateway swap confirm marks the existing gateway removed and associates the replacement

```gherkin
Scenario: Confirmed gateway swap updates assignment and audit history
  Given the replacement gateway number was previously validated as available
  When px-web-app-api sends POST request to {GATEWAY_SWAP_CONFIRM_PATH} with {gatewaySwapConfirmPayload}
  Then px-web-app-api responds with status 200
  And response body contains:
    | field                  | expected_value | validation_type |
    | existingGatewayStatus  | removed         | equals          |
    | replacementGatewayNumber | —             | not_empty       |
    | auditHistoryUpdated    | true            | equals          |
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC9, AC10

---

## [px-web-app-api][FS-2028] - Gateway swap confirm rejects an expired installer session

```gherkin
Scenario: Expired installer session is rejected when confirming a gateway swap
  Given the installer's session has expired due to inactivity
  When px-web-app-api sends POST request to {GATEWAY_SWAP_CONFIRM_PATH} with {gatewaySwapConfirmPayload}
  Then px-web-app-api responds with status 401
  And response body contains:
    | field | expected_value                                  | validation_type |
    | error | Your session has expired. Please sign in again. | equals          |
  And no unintended side effects should occur
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC19

---

## [px-web-app-api][FS-2028] - Gateway swap confirm returns a generic error on unexpected system failure

```gherkin
Scenario: Unhandled failure during gateway swap confirmation returns a generic error without technical detail
  Given an unhandled dependency failure occurs while processing the swap confirmation
  When px-web-app-api sends POST request to {GATEWAY_SWAP_CONFIRM_PATH} with {gatewaySwapConfirmPayload}
  Then px-web-app-api responds with status 500
  And response body contains:
    | field | expected_value                                                      | validation_type |
    | error | An unexpected error occurred. Please try again or contact support. | equals           |
  And response body does not contain internal technical details or stack traces
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC21

---

## [px-web-app-api][FS-2028] - Complete installation persists all installation data and returns confirmation

```gherkin
Scenario: Completing installation saves asset changes, photos, notes, and gateway assignment, and returns confirmation
  Given valid asset property changes, uploaded photos, installation notes, and a validated gateway assignment exist for this installation
  When px-web-app-api sends POST request to {COMPLETE_INSTALLATION_PATH} with {completeInstallationPayload}
  Then px-web-app-api responds with status 200
  And response body contains:
    | field                | expected_value | validation_type |
    | installationStatus   | Completed       | equals          |
    | confirmationId       | —               | not_empty       |
    | notesSaved           | true            | equals          |
    | photosStored         | true            | equals          |
    | gatewayAssignmentUpdated | true         | equals          |
  And response header "Content-Type" equals "application/json"
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC8, AC11

---

## [px-web-app-api][FS-2028] - Complete installation is idempotent on retried submission after connectivity loss

```gherkin
Scenario: Retried completion submission after connectivity loss does not create a duplicate installation record
  Given {completeInstallationPayload} was already submitted once and acknowledged with {confirmationId}
  When px-web-app-api sends POST request to {COMPLETE_INSTALLATION_PATH} again with the same {completeInstallationPayload}
  Then px-web-app-api responds with status 200
  And response body contains:
    | field          | expected_value    | validation_type |
    | confirmationId | {confirmationId}  | equals          |
  And no duplicate installation record is created
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC20

---

## [px-web-app-api][FS-2028] - Complete installation rejects an expired installer session

```gherkin
Scenario: Expired installer session is rejected when attempting to complete installation
  Given the installer's session has expired due to inactivity
  When px-web-app-api sends POST request to {COMPLETE_INSTALLATION_PATH} with {completeInstallationPayload}
  Then px-web-app-api responds with status 401
  And response body contains:
    | field | expected_value                                  | validation_type |
    | error | Your session has expired. Please sign in again. | equals          |
  And no unintended side effects should occur
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC19

---

## [px-web-app-api][FS-2028] - Complete installation returns a generic error on unexpected system failure

```gherkin
Scenario: Unhandled failure during installation completion returns a generic error without technical detail
  Given an unhandled dependency failure occurs while processing the completion request
  When px-web-app-api sends POST request to {COMPLETE_INSTALLATION_PATH} with {completeInstallationPayload}
  Then px-web-app-api responds with status 500
  And response body contains:
    | field | expected_value                                                      | validation_type |
    | error | An unexpected error occurred. Please try again or contact support. | equals           |
  And response body does not contain internal technical details or stack traces
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC21

---

## [px-web-app-api][FS-2028] - Road Ready validation endpoint returns the sensor-health verdict for an organization-scoped asset

```gherkin
Scenario: Road Ready sensor-health verdict is retrieved for the asset associated with the scanned gateway
  Given an asset record exists for {gatewayNumber} within the installer's authorized organization
  When px-web-app-api sends GET request to {ROAD_READY_VALIDATION_PATH}
  Then px-web-app-api responds with status 200
  And response body contains:
    | field   | expected_value | validation_type |
    | verdict | —               | not_empty       |
  And response header "Content-Type" equals "application/json"
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC4

---

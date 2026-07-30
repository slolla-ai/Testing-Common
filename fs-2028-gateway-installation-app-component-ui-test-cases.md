Test Type: Component UI

Feature: Gateway Installation App - Organization Selection, Gateway Scan, Asset Properties, Photo Management, Notes, and Gateway Swap UI

Purpose:\
Validate the px-web-app installer UI provides correct feedback, validation, and behavior across the organization selection, gateway scan, asset properties, installation photo and notes, gateway swap, and installation completion screens

Base URLs (optional):\
app_ui: {It must be updated by the test reviewer}

Component Location:
microservice: px-web-app

```gherkin
Background:
Given app_ui page is accessible
And page loads without errors
And the installer is logged into Fus1on
```

## [px-web-app][FS-2028] - Organization selection screen displays all authorized organizations for a multi-org installer

```gherkin
Scenario: Installer with access to multiple organizations must choose one before continuing
Given user navigates to {organization_selection_path}
And the installer has access to {multiple_organizations}
When the organization selection screen loads
Then the {organization_list} displays only the organizations the installer is authorized for
And the installer is required to select an {organization_item} before the flow can continue
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC1

---

## [px-web-app][FS-2028] - Single-organization installer is auto-selected and routed directly to the gateway scan screen

```gherkin
Scenario: Installer with access to only one organization skips manual selection
Given the installer has access to exactly one authorized organization
When the installer logs in
Then the organization is automatically selected without displaying an {organization_list}
And the installer is taken directly to the {gateway_scan_screen}
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC1

---

## [px-web-app][FS-2028] - Organization access revoked mid-session returns installer to organization selection with error

```gherkin
Scenario: Installer loses access to the previously selected organization
Given user navigates to {organization_selection_path}
And the installer had previously selected an organization
When the installer no longer has access to the selected organization
Then the error message is displayed with text "You do not have access to this organization."
And the installer is returned to the {organization_selection_screen}
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC10

---

## [px-web-app][FS-2028] - Scanning an MCU or TrackRR Gateway captures and displays an editable device number

```gherkin
Scenario: Installer scans a gateway device on the gateway scan screen
Given user navigates to {gateway_scan_path}
And page contains the {scan_input_field} within a selected organization
When user scans an MCU or TrackRR Gateway using {scan_input_field}
Then the scanned gateway number is displayed in {scanned_device_number_field}
And user can edit the value in {scanned_device_number_field}
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC2

---

## [px-web-app][FS-2028] - Installer edits the scanned device number before continuing

```gherkin
Scenario: Installer corrects a scanned gateway number
Given user navigates to {gateway_scan_path}
And a gateway device number has been scanned and is shown in {scanned_device_number_field}
When user edits the value in {scanned_device_number_field} to a valid gateway number
Then the updated value is retained in {scanned_device_number_field}
And the {continue_button} becomes enabled
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC3

---

## [px-web-app][FS-2028] - Manually edited device number failing format validation blocks continuation

```gherkin
Scenario: Installer enters an edited device number that does not match device number standards
Given user navigates to {gateway_scan_path}
And a gateway device number has been scanned and is shown in {scanned_device_number_field}
When user edits {scanned_device_number_field} with a value that fails device number format validation
Then a validation error message is displayed with text "{invalid_format_error_message}"
And the {continue_button} remains disabled
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC3

---

## [px-web-app][FS-2028] - Invalid gateway scan displays the exact error message and keeps installer on the scan screen

```gherkin
Scenario: Installer scans or enters a value that does not match a valid MCU or TrackRR Gateway format
Given user navigates to {gateway_scan_path}
When user scans or enters an invalid value into {scan_input_field}
Then the error message is displayed with text "Invalid gateway number scanned. Please rescan or enter a valid gateway number."
And user remains on the {gateway_scan_screen}
And the {continue_button} remains disabled until a valid gateway number is entered
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC12

---

## [px-web-app][FS-2028] - Gateway not present in Device Registry displays "Gateway device not found."

```gherkin
Scenario: Installer scans a gateway that does not exist in the Device Registry
Given user navigates to {gateway_scan_path}
When user scans a gateway number that does not exist in the Device Registry
Then the error message is displayed with text "Gateway device not found."
And user is presented with the option to rescan the device using {scan_input_field}
And user is presented with the option to manually enter a valid gateway number in {scanned_device_number_field}
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC8

---

## [px-web-app][FS-2028] - Gateway already assigned to another active asset or organization blocks continuation

```gherkin
Scenario: Installer scans a valid gateway that is already assigned elsewhere
Given user navigates to {gateway_scan_path}
When user scans a valid gateway number that is already assigned to another active asset or organization
Then the error message is displayed with text "This gateway is already assigned and cannot be installed."
And the {continue_button} does not allow the installer to continue
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC9

---

## [px-web-app][FS-2028] - Gateway belonging to a different organization is blocked from the selected organization's scan flow

```gherkin
Scenario: Installer scans a gateway that belongs to a different organization
Given user navigates to {gateway_scan_path}
And an organization has been selected
When the scanned gateway belongs to a different organization than the one selected
Then the error message is displayed with text "The scanned gateway is not authorized for the selected organization."
And continuation past the {gateway_scan_screen} is blocked
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC11

---

## [px-web-app][FS-2028] - Gateway scan result is displayed within the required response time

```gherkin
Scenario: Installer scans a gateway and expects a prompt response
Given user navigates to {gateway_scan_path}
When user scans an MCU or TrackRR Gateway using {scan_input_field}
Then the scanned device number is displayed in {scanned_device_number_field} within {2} seconds
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > NFR-1

---

## [px-web-app][FS-2028] - Valid gateway number loads the Asset Properties page with pre-populated data

```gherkin
Scenario: Installer continues from a valid gateway number to view asset properties
Given user navigates to {gateway_scan_path}
And a valid gateway number is entered in {scanned_device_number_field}
When user selects {continue_button}
Then the {asset_properties_screen} is displayed
And existing asset information is pre-populated into {asset_properties_form} when available
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC4

---

## [px-web-app][FS-2028] - No asset record found for the entered gateway displays the exact error message

```gherkin
Scenario: Installer continues with a valid gateway number that has no associated asset record
Given user navigates to {gateway_scan_path}
And a valid gateway number is entered in {scanned_device_number_field}
When no associated asset record exists for the entered gateway number
Then the error message is displayed with text "No asset record found for this gateway."
And user is presented with the option to create a new asset association where permitted
And user is presented with the option to return to the {gateway_scan_screen}
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC12

---

## [px-web-app][FS-2028] - Asset Management Service failure blocks display of partial asset data

```gherkin
Scenario: Installer continues while the Asset Management Service is unavailable
Given user navigates to {gateway_scan_path}
And a valid gateway number is entered in {scanned_device_number_field}
When user selects {continue_button} and the Asset Management Service is unavailable or returns an error
Then the error message is displayed with text "Unable to retrieve asset information. Please try again."
And no partial asset data is displayed on {asset_properties_screen}
And user is presented with the option to retry
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC13

---

## [px-web-app][FS-2028] - Asset Properties screen loads within the required time under normal conditions

```gherkin
Scenario: Installer views asset properties under normal network conditions
Given user navigates to {gateway_scan_path}
And a valid gateway number is entered in {scanned_device_number_field}
When user selects {continue_button}
Then the {asset_properties_screen} loads within {3} seconds
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > NFR-2

---

## [px-web-app][FS-2028] - Installer edits and saves asset property fields successfully

```gherkin
Scenario: Installer updates one or more asset property fields and saves
Given user navigates to {asset_properties_path}
And the {asset_properties_screen} is displayed with pre-populated data
When user updates one or more fields in {asset_properties_form} with valid values
And user selects {save_button}
Then the updated values are reflected in {asset_properties_form}
And a save confirmation is displayed to the installer
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC5

---

## [px-web-app][FS-2028] - Missing or invalid required asset property fields prevent save and highlight the offending fields

```gherkin
Scenario: Installer attempts to save asset properties with an incomplete or invalid required field
Given user navigates to {asset_properties_path}
And the {asset_properties_screen} is displayed
When user leaves a required field blank or enters invalid data into {asset_properties_form}
And user selects {save_button}
Then the invalid field(s) in {asset_properties_form} are visually highlighted
And a field-level validation message "{field_validation_error_message}" is displayed for each invalid field
And the save operation is prevented until all errors are resolved
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC5, AC17

---

## [px-web-app][FS-2028] - Saving asset properties with a gateway already linked to another asset is rejected

```gherkin
Scenario: Installer saves asset properties while the gateway is already linked to another asset record
Given user navigates to {asset_properties_path}
And the {asset_properties_screen} is displayed
When user selects {save_button} while the gateway is already linked to another asset record
Then the error message is displayed with text "Gateway is already associated with another asset."
And the save operation is rejected
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC18

---

## [px-web-app][FS-2028] - Installer captures an installation photo using the device camera

```gherkin
Scenario: Installer adds an installation photo by capturing it with the device camera
Given user navigates to {asset_properties_path}
And page contains {add_photos_button} on the {asset_properties_screen}
When user selects {add_photos_button} and captures a photo using {camera_capture_option}
Then the captured photo appears as a {photo_thumbnail} in the photo list
And the {photo_upload_status} indicator shows the upload result for the captured photo
```

Automation Recommendation: Do Not Automate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC6

---

## [px-web-app][FS-2028] - Installer uploads an existing photo from the device

```gherkin
Scenario: Installer adds an installation photo by uploading an existing file
Given user navigates to {asset_properties_path}
And page contains {add_photos_button} on the {asset_properties_screen}
When user selects {add_photos_button} and uploads an existing photo using {upload_photo_option}
Then the uploaded photo appears as a {photo_thumbnail} in the photo list
And the {photo_upload_status} indicator shows the upload result for the uploaded photo
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC6

---

## [px-web-app][FS-2028] - Installer uploads multiple installation photos across supported subjects

```gherkin
Scenario Outline: Installer adds multiple photos documenting different installation subjects
Given user navigates to {asset_properties_path}
And page is in {initial_state}
When user uploads a photo of {input_variant} using {add_photos_button}
Then {expected_outcome} should occur

Examples:
| initial_state | input_variant | expected_outcome |
| no photos uploaded | the installed gateway | a {photo_thumbnail} for the installed gateway is added to the photo list |
| one photo uploaded | the mounting location | a second {photo_thumbnail} for the mounting location is added alongside the existing photo |
| two photos uploaded | the wiring connection | a third {photo_thumbnail} for the wiring connection is added alongside the existing photos |
| three photos uploaded | the vehicle dashboard | a fourth {photo_thumbnail} for the vehicle dashboard is added alongside the existing photos |
| four photos uploaded | the asset identification label | a fifth {photo_thumbnail} for the asset identification label is added alongside the existing photos |
| five photos uploaded | additional installation evidence | a sixth {photo_thumbnail} for additional installation evidence is added alongside the existing photos |
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC6

---

## [px-web-app][FS-2028] - Uploading an unsupported or oversized photo file displays the exact error message

```gherkin
Scenario: Installer selects a photo file that is an unsupported type or exceeds the allowed size
Given user navigates to {asset_properties_path}
And page contains {add_photos_button} on the {asset_properties_screen}
When user selects a photo file that is not JPG/JPEG/PNG or that exceeds the configured maximum file size
Then the error message is displayed with text "Unsupported file format or file exceeds allowed size."
And no partial photo data is displayed in the photo list
And user is presented with the option to retry
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC15

---

## [px-web-app][FS-2028] - Photo upload failure displays the exact error message and does not show partial data

```gherkin
Scenario: Installer selects a valid photo but the upload operation fails
Given user navigates to {asset_properties_path}
And page contains {add_photos_button} on the {asset_properties_screen}
When user selects a valid photo to upload and the upload fails
Then the error message is displayed with text "Unable to upload photo. Please try again."
And no partial photo data is displayed in the photo list
And user is presented with the option to retry
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC14

---

## [px-web-app][FS-2028] - Uploaded installation photos are displayed as thumbnails for review

```gherkin
Scenario: Installer reviews previously uploaded installation photos
Given user navigates to {asset_properties_path}
And one or more installation photos have been uploaded
When the installer views the photo list on {asset_properties_screen}
Then each uploaded photo is displayed as a {photo_thumbnail}
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC7

---

## [px-web-app][FS-2028] - Installer previews an uploaded installation photo

```gherkin
Scenario: Installer opens a preview of an uploaded photo before submission
Given user navigates to {asset_properties_path}
And installation photos are displayed as {photo_thumbnail} entries
When user selects a {photo_thumbnail} and chooses {photo_preview_button}
Then an enlarged preview of the selected photo is displayed to the installer
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC7

---

## [px-web-app][FS-2028] - Installer deletes an uploaded installation photo before submission

```gherkin
Scenario: Installer removes a previously uploaded photo
Given user navigates to {asset_properties_path}
And installation photos are displayed as {photo_thumbnail} entries
When user selects a {photo_thumbnail} and chooses {photo_delete_button}
Then the selected {photo_thumbnail} is removed from the photo list
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC7

---

## [px-web-app][FS-2028] - Installer replaces an uploaded installation photo before submission

```gherkin
Scenario: Installer swaps a previously uploaded photo for a new one
Given user navigates to {asset_properties_path}
And installation photos are displayed as {photo_thumbnail} entries
When user selects a {photo_thumbnail} and chooses {photo_replace_button} to upload a new photo
Then the original {photo_thumbnail} is replaced by the newly uploaded photo in the photo list
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC7

---

## [px-web-app][FS-2028] - Installer enters free-form installation notes

```gherkin
Scenario: Installer records free-form notes about the installation
Given user navigates to {asset_properties_path}
And page contains {installation_notes_field} on the installation details view
When user enters text such as "Gateway mounted behind dashboard." into {installation_notes_field}
Then the entered text is retained in {installation_notes_field}
And the notes are associated with the current installation record
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC8

---

## [px-web-app][FS-2028] - Selecting Swap Gateway initiates the gateway swap workflow

```gherkin
Scenario: Installer identifies that an existing gateway needs replacement
Given user navigates to {asset_properties_path}
And the asset has an assigned gateway
When user selects {swap_gateway_button}
Then the gateway swap workflow screen is displayed to the installer
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC9

---

## [px-web-app][FS-2028] - Gateway swap workflow displays the currently assigned gateway with assignment details

```gherkin
Scenario: Installer views the currently assigned gateway at the start of a swap
Given user navigates to {asset_properties_path}
And the asset already has an assigned gateway
When user selects {swap_gateway_button}
Then the {current_gateway_details_panel} displays the currently assigned gateway number and its assignment details
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC10

---

## [px-web-app][FS-2028] - Replacement gateway scanned during a swap is validated before confirmation

```gherkin
Scenario: Installer scans or enters a replacement gateway during the swap workflow
Given user navigates to {asset_properties_path}
And the gateway swap workflow is displaying {current_gateway_details_panel}
When user scans or enters the device id of a replacement MCU or TrackRR Gateway into {replacement_gateway_scan_input}
Then the replacement gateway number is displayed as validated
And the {confirm_swap_button} becomes enabled
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC10

---

## [px-web-app][FS-2028] - Confirming a gateway swap displays confirmation and updates the displayed gateway

```gherkin
Scenario: Installer confirms the gateway swap
Given user navigates to {asset_properties_path}
And a validated replacement gateway number is entered in {replacement_gateway_scan_input}
When user selects {confirm_swap_button}
Then a swap confirmation message is displayed to the installer
And {current_gateway_details_panel} updates to display the replacement gateway number
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC10

---

## [px-web-app][FS-2028] - Invalid or unavailable replacement gateway during swap displays the exact error message

```gherkin
Scenario: Installer attempts to swap in a gateway that is invalid or unavailable
Given user navigates to {asset_properties_path}
And the gateway swap workflow is displaying {current_gateway_details_panel}
When user scans or enters a replacement gateway that is invalid or unavailable
Then the error message is displayed with text "Selected gateway cannot be used for swap."
And no partial swap data is displayed
And user is presented with the option to retry
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC16

---

## [px-web-app][FS-2028] - Completing the installation displays a confirmation message

```gherkin
Scenario: Installer completes the installation after all required information is entered
Given user navigates to {asset_properties_path}
And all required asset, photo, and note information has been entered
When user selects {complete_installation_button}
Then a confirmation message is displayed to the installer
And the installation status displayed on screen shows {completed_status_label}
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC11

---

## [px-web-app][FS-2028] - Session timeout during continue or save redirects installer to login with the exact message

```gherkin
Scenario: Installer's session expires while attempting to continue or save
Given user navigates to {asset_properties_path}
And the installer has been inactive for the configured session timeout period
When user attempts to select {continue_button} or {save_button}
Then the error message is displayed with text "Your session has expired. Please sign in again."
And user is redirected to the {login_screen}
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC19

---

## [px-web-app][FS-2028] - Network connectivity loss during scan or save displays the exact error message

```gherkin
Scenario: Installer loses network connectivity while performing a scan or save operation
Given user navigates to {gateway_scan_path}
When network connectivity is lost while user performs a scan or save operation
Then the error message is displayed with text "Network connection unavailable. Check your connection and try again."
And user is presented with the option to retry without triggering a duplicate transaction
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC20

---

## [px-web-app][FS-2028] - Unexpected application error displays the generic exact error message

```gherkin
Scenario: An unexpected application error occurs during an installer operation
Given user navigates to {asset_properties_path}
When an unexpected application error occurs and the operation cannot be completed
Then the error message is displayed with text "An unexpected error occurred. Please try again or contact support."
```

Automation Recommendation: Candidate

Status: Open

EMTE: {It must be updated by the test reviewer}

Traceability: FS-2028 > AC21

---

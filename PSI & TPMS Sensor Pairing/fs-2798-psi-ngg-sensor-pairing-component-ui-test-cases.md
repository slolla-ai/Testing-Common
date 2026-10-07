Test Type: Component UI

Feature: DMS Commands Screens - The New Tire Sensor Pairing Command

Purpose:\
Check how the DMS web app shows the new tire sensor pairing command, named "T1 - TPMS Configure (TrackRR)". Only the system sends this command, when PSI asks to pair tire sensors to a TrackRR gateway. Operators must not be able to find it in the commands list, send it themselves, edit it or delete it. They must still be able to see each pairing that was sent, and cancel or resend it, the same way they can for any other sent command. The spec says pairing status is not shown anywhere else in the web apps, so these screens are the only UI to test.

Base URLs (optional):\
app_ui: {It must be updated by the test reviewer}

Component Location:\
microservice: dms-web-app

```gherkin
Background:
Given the DMS web app opens without errors
And the tester is signed in as an operator who can view, send, cancel and resend commands
And tire sensor pairing is switched on in this environment
And a TrackRR test gateway {gateway_imei} is registered and available
```

@FS-2923
## [dms-web-app][FS-2798-psi-ngg-sensor-pairing] - The pairing command is not listed in the commands list

```gherkin
Scenario: Operator searches the commands list and does not find the pairing command
Given the operator opens the Commands page at {commands_page}
When the operator searches the list for "TPMS Configure"
Then no command named "T1 - TPMS Configure (TrackRR)" is shown
And the existing Firmware Ready command is not shown either, just as before
```

Automation Recommendation: Manual

Status: Created

EMTE: 0.5

Traceability: FR-009a

---

@FS-2924
## [dms-web-app][FS-2798-psi-ngg-sensor-pairing] - The pairing command cannot be sent by hand

```gherkin
Scenario: Operator cannot pick the pairing command when sending a command
Given the operator opens the Send Command screen at {send_command_page} for gateway {gateway_imei}
When the operator opens the command picker and types "TPMS Configure"
Then "T1 - TPMS Configure (TrackRR)" is not offered
And the operator has no way to send the pairing command to the gateway by hand
```

Automation Recommendation: Manual

Status: Created

EMTE: 0.5

Traceability: FR-009a

---

@FS-2925
## [dms-web-app][FS-2798-psi-ngg-sensor-pairing] - The pairing command cannot be edited or deleted

```gherkin
Scenario: Operator finds no Edit or Delete option for the pairing command
Given the operator opens the Commands page at {commands_page}
When the operator looks for a way to open, edit or delete "T1 - TPMS Configure (TrackRR)"
Then no Edit button {edit_button_id} is shown for it
And no Delete button {delete_button_id} is shown for it
And the command cannot be opened for editing from any screen
```

Automation Recommendation: Manual

Status: Created

EMTE: 0.5

Traceability: FR-009a

---

@FS-2926
## [dms-web-app][FS-2798-psi-ngg-sensor-pairing] - A pairing sent by PSI shows up once in the gateway's command history

```gherkin
Scenario: Operator sees the pairing in the gateway's sent command history
Given PSI has sent a pairing request for gateway {gateway_imei}, and the system accepted it with request number {request_id}
When the operator opens the gateway's sent command history at {command_history_page}
Then exactly one new row is shown for this pairing
And the row shows these details:
  | field          | what to check                           |
  | command name   | shows "T1 - TPMS Configure (TrackRR)"   |
  | device         | shows {gateway_imei}                    |
  | command number | shows {request_id}                      |
  | status         | is shown                                |
  | sent time      | is shown                                |
```

Automation Recommendation: Manual

Status: Created

EMTE: 0.5

Traceability: US1-AC1, FR-008c, FR-009a, FR-018

---

@FS-2927
## [dms-web-app][FS-2798-psi-ngg-sensor-pairing] - The pairing details match what PSI sent

```gherkin
Scenario: Operator opens a sent pairing and sees exactly the tire layout PSI asked for
Given PSI has sent a pairing for gateway {gateway_imei} with 8 tires, 2 axles and sensors on tires 1, 2 and 5
And one of those sensor IDs was typed in lower case as "8fb179"
When the operator opens the details {details_view_id} of that pairing in the command history
Then the details show these values:
  | field                     | what to check                                         |
  | number of tires           | 8                                                     |
  | number of axles           | 2                                                     |
  | sensor ID for each tire   | 70 slots; tires 1, 2 and 5 have the sensor IDs sent; all other slots are empty |
  | axle for each tire        | 70 slots; tires 1, 2 and 5 have the axles sent; all other slots are 0          |
  | tire group for each tire  | 70 slots; tires 1, 2 and 5 have the groups sent; all other slots are 0         |
  | "start pairing" trigger   | is included                                           |
  | message ID                | is included                                           |
And the sensor ID sent as "8fb179" is shown in capitals as "8FB179"
```

Automation Recommendation: Manual

Status: Created

EMTE: 0.5

Traceability: US1-AC1, FR-005, FR-008c, FR-009c, FR-018

---

@FS-2928
## [dms-web-app][FS-2798-psi-ngg-sensor-pairing] - The pairing's status in history changes as it progresses

```gherkin
Scenario Outline: Operator sees the right status for the pairing at each stage
Given a pairing command was sent to gateway {gateway_imei}
And the pairing is in this situation: {situation}
When the operator opens the gateway's sent command history at {command_history_page}
Then the pairing row shows the status {status_shown}
And the Cancel button {cancel_button_id} is {cancel_button}

Examples:
| situation                                                          | status_shown | cancel_button                                |
| sent, but the gateway has not answered yet                         | Queued       | available                                    |
| the gateway did not answer for about 2 days, so it was sent again  | Queued       | available                                    |
| the gateway accepted it                                            | Completed    | {not available - confirm with test reviewer} |
| the gateway rejected it                                            | Failed       | {not available - confirm with test reviewer} |
| the system gave up resending it                                    | Expired      | {not available - confirm with test reviewer} |
| PSI sent a newer pairing for the same gateway before it was answered | Cancelled  | {not available - confirm with test reviewer} |
```

Automation Recommendation: Manual

Status: Created

EMTE: 1.0

Traceability: US2-AC1, US2-AC2, US2-AC4, US3-AC1, FR-009a, FR-010, FR-011

---

@FS-2929
## [dms-web-app][FS-2798-psi-ngg-sensor-pairing] - Operator cancels a pairing that is still waiting

```gherkin
Scenario: Operator cancels a waiting pairing from the command history
Given PSI has sent a pairing for gateway {gateway_imei} while the gateway is switched off
And the operator opens the gateway's sent command history at {command_history_page}
And the pairing row shows "Queued"
When the operator clicks Cancel {cancel_button_id} on that row and confirms
Then the row changes to "Cancelled" within {N} seconds
And the Cancel button is no longer available on that row
```

Automation Recommendation: Manual

Status: Created

EMTE: 0.5

Traceability: US2-AC3, FR-009a, FR-011

---

@FS-2930
## [dms-web-app][FS-2798-psi-ngg-sensor-pairing] - Operator resends a pairing and the same layout goes out again

```gherkin
Scenario: Resending a pairing sends that same pairing's layout again
Given a pairing with request number {request_id} was sent to gateway {gateway_imei}
And the operator opens the gateway's sent command history at {command_history_page}
When the operator clicks Resend {resend_button_id} on that row and confirms
Then the history shows the pairing sent again to the gateway
And its details show the same tires, axles, sensor IDs and tire groups as request {request_id}
And nothing from any other pairing is mixed into it
```

Automation Recommendation: Manual

Status: Created

EMTE: 1.0

Traceability: FR-009a, FR-008

---

@FS-2931
## [dms-web-app][FS-2798-psi-ngg-sensor-pairing] - A newer pairing replaces an older one that was still waiting

```gherkin
Scenario: History shows the older pairing cancelled and the newer one waiting
Given gateway {gateway_imei} is switched off
And PSI has sent pairing A (request {request_id_a}), which shows "Queued" in the history
When PSI sends pairing B (request {request_id_b}) for the same gateway
And the operator refreshes the gateway's command history
Then pairing A shows "Cancelled"
And pairing B shows "Queued"
And after about 2 more days, the history shows no new attempt to send pairing A
```

Automation Recommendation: Manual

Status: Created

EMTE: 1.0

Traceability: US3-AC1, US3-AC3, FR-013, SC-009

---

@FS-2932
## [dms-web-app][FS-2798-psi-ngg-sensor-pairing] - A pairing request that was refused never appears in the history

```gherkin
Scenario Outline: A refused pairing request adds nothing to the command history
Given the operator opens the gateway's sent command history at {command_history_page} and notes how many pairing rows there are
When PSI sends a pairing for gateway {gateway_imei} that is refused because {reason}
And the operator refreshes the history
Then no new pairing row is shown

Examples:
| reason                                              |
| a sensor ID starts with "0x"                        |
| the same tire is listed twice                       |
| the same sensor ID is on two tires                  |
| a sensor has tire group 0                           |
| a sensor is on an axle higher than the axle count   |
| the number of tires is missing                      |
| tire sensor pairing is switched off here            |
| the caller is not allowed to pair sensors           |
```

Automation Recommendation: Manual

Status: Created

EMTE: 0.75

Traceability: US5-AC1, US5-AC2, US5-AC3, US5-AC4, US5-AC5, FR-003, FR-019, FR-021, SC-005

---

@FS-2933
## [dms-web-app][FS-2798-psi-ngg-sensor-pairing] - The Firmware Ready command looks the same as before

```gherkin
Scenario: Firmware Ready only changes where it stores its message ID
Given a Firmware Ready command was sent to gateway {gateway_imei} after this release
And the operator opens the gateway's sent command history at {command_history_page}
When the operator opens the details {details_view_id} of that Firmware Ready command
Then the message ID is shown in field 104 instead of field 100
And field 1210 still shows "[02]"
And the command's name, status and Cancel/Resend buttons look and work the same as before this release
```

Automation Recommendation: Manual

Status: Created

EMTE: 0.5

Traceability: FR-009c, SC-010

---

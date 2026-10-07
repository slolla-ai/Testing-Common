Test Type: Integration

Feature: Integration - PSI Pairs Tire Sensors to TrackRR Gateways Through the Platform

Purpose:\
Check that when PSI (the tire pressure partner) asks the platform to pair tire sensors to a TrackRR gateway, the platform sends the gateway the full tire layout in one command, and then tells PSI once whether it worked. Also check that bad requests are stopped before anything reaches a gateway, that PSI can look up a request's status, and that the existing MCU pairing and Firmware Ready behaviour still work as before.

Components:\
PSI test client: plays the part of PSI's FAST system. It sends pairing requests and status lookups, using a login token that has the "pair tire sensors" permission (pair:tpms-sensors)\
Device Management Service (DMS): checks each request, sends the pairing command to the gateway, and tells PSI the result\
Asset Service: tells DMS what kind of device an IMEI belongs to, and which trailer it is on\
Device Delivery Service (DDP): carries commands from DMS to the gateway\
TrackRR test gateway: a real gateway, with console access so the tester can read back its tire settings\
Device reply path (message-processor-lambda): brings the gateway's "accepted" or "rejected" reply back to DMS\
PSI reply receiver: a test stand-in for PSI that records every result message the platform sends\
DMS database and logs: hold the command history, the result messages sent to PSI, and the audit records

Base URLs (optional):\
Device Management Service: {It must be updated by the test reviewer}\
Asset Service: {It must be updated by the test reviewer}\
Device Delivery Service: {It must be updated by the test reviewer}\
PSI reply receiver: {It must be updated by the test reviewer}

```gherkin
Background:
Given all the services listed above are running
And tire sensor pairing is switched on in this environment
And the PSI test client has a valid login token with the "pair tire sensors" permission
And a TrackRR test gateway {gateway_imei} is registered, connected, installed on trailer {trailer_id} named {trailer_name}, and the tester can read its settings from its console
And the PSI reply receiver is running and records every message it gets
```

@FS-2934
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - Pairing 8 sensors puts exactly those 8 sensors on the gateway

```gherkin
Scenario: Successful interaction - 8 sensors reach the gateway in one command
Given PSI prepares a pairing for gateway {gateway_imei} with:
  | field           | description                                         |
  | number of tires | 8                                                   |
  | number of axles | 2                                                   |
  | sensors         | 8 sensors on tires 1 to 8, each with axle and group |
When PSI sends the pairing
Then the platform replies "Pairing request accepted." with a request number and the gateway IMEI
And the gateway receives exactly one command holding the whole layout and the "start pairing" trigger
And once the gateway accepts it, its console shows 8 tires, 2 axles, the 8 sensors on tires 1 to 8, and slots 9 to 70 empty
```

Automation Recommendation: Manual

Status: Created

EMTE: 1.0

Traceability: US1-AC1, FR-002, FR-007, FR-008, FR-008c, FR-009c

---

@FS-2935
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - PSI gets one "Success" message when the gateway accepts

```gherkin
Scenario: Successful interaction - gateway accepts and PSI is told once
Given PSI's pairing for gateway {gateway_imei} was accepted with request number {request_id}
When the gateway replies that it accepted the command
Then the command shows "Completed" in the DMS command history
And within 2 minutes the PSI reply receiver gets exactly one message with:
  | field             | what to check          |
  | status            | "Success"              |
  | message ID        | {request_id}           |
  | gateway IMEI      | {gateway_imei}         |
  | trailer ID        | {trailer_id}           |
  | trailer name      | {trailer_name}         |
  | sensor ID         | empty                  |
  | location          | empty                  |
  | date and time     | filled in              |
```

Automation Recommendation: Manual

Status: Created

EMTE: 0.5

Traceability: US1-AC2, FR-010, FR-011, FR-012, SC-002

---

@FS-2936
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - Swapping one sensor changes only that tire

```gherkin
Scenario: Successful interaction - new sensor on tire 3, everything else the same
Given gateway {gateway_imei} already has sensors on tires 1 to 8
When PSI sends the same full layout again but with a different sensor on tire 3
And the gateway accepts it
Then the gateway console shows the new sensor on tire 3
And tires 1, 2 and 4 to 8 are exactly as they were
And PSI gets one "Success" message for the new request
```

Automation Recommendation: Manual

Status: Created

EMTE: 1.0

Traceability: US1-AC3, FR-008

---

@FS-2937
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - A tire left out of the request is cleared on the gateway

```gherkin
Scenario: Successful interaction - leaving out tire 5 empties it
Given gateway {gateway_imei} already has sensors on tires 1 to 8
When PSI sends a layout of 8 tires that lists tires 1 to 4 and 6 to 8 only
And the gateway accepts it
Then tire 5 is sent to the gateway as empty
And the gateway console shows tire 5 empty and the other tires as sent
And the platform did not copy anything from the gateway's earlier layout
```

Automation Recommendation: Manual

Status: Created

EMTE: 1.0

Traceability: US1-AC4, FR-008, FR-008c

---

@FS-2938
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - The maximum of 70 sensors is delivered complete

```gherkin
Scenario: Successful interaction - 70 sensors, the most allowed
Given PSI prepares a pairing for gateway {gateway_imei} with 70 tires, 24 axles and 70 sensors with 6-character IDs
When PSI sends the pairing
Then the platform accepts it
And the command sent to the gateway is no bigger than 2048 bytes
And once the gateway accepts it, its console shows all 70 sensors exactly as sent
And the gateway's pairing status goes back to "idle/succeeded" when it finishes
```

Automation Recommendation: Manual

Status: Created

EMTE: 1.0

Traceability: US1-AC5, FR-003, SC-004

---

@FS-2939
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - PSI's result depends only on the gateway's reply to the command

```gherkin
Scenario: Successful interaction - no other gateway data is needed
Given PSI's pairing {request_id} for gateway {gateway_imei} was accepted
And the gateway sends no tire readings or other reports afterwards
When the gateway replies that it accepted the command
Then PSI still gets one "Success" message for {request_id}
```

Automation Recommendation: Manual

Status: Created

EMTE: 0.5

Traceability: US1-AC6, FR-010, FR-016

---

@FS-2940
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - A gateway not yet on a trailer can be paired at the factory

```gherkin
Scenario: Successful interaction - factory pairing with no trailer
Given gateway {factory_imei} is registered but not installed on any trailer
When PSI sends a valid pairing for {factory_imei}
Then the platform accepts it, just as for an installed gateway
And once the gateway accepts it, PSI gets "Success" with the gateway IMEI and an empty trailer ID and trailer name
And looking up the request shows no trailer
```

Automation Recommendation: Manual

Status: Created

EMTE: 0.5

Traceability: US1-AC7, FR-006a, FR-010, FR-012, SC-001

---

@FS-2941
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - All three TrackRR models can be paired

```gherkin
Scenario Outline: Interaction variation matrix - each TrackRR model
When PSI sends a valid pairing for a registered {model} gateway {model_imei}
Then the platform accepts it and sends one pairing command to that gateway
And the platform never replies "device information is missing or incomplete"

Examples:
| model         |
| TrackRR       |
| TrackRR Cargo |
| TrackRR Solar |
```

Automation Recommendation: Manual

Status: Created

EMTE: 0.75

Traceability: FR-006, SC-001

---

@FS-2942
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - PSI gets "Unsuccess" when the gateway rejects the pairing

```gherkin
Scenario: Failure or resilience behavior - gateway rejects the command
Given PSI's pairing {request_id} for gateway {gateway_imei} was accepted
When the gateway replies that it rejected the command
Then the command shows "Failed" in the DMS command history
And PSI gets exactly one "Unsuccess" message for {request_id}
And the message gives no reason for the failure
```

Automation Recommendation: Manual

Status: Created

EMTE: 0.5

Traceability: US2-AC1, FR-011, FR-012

---

@FS-2943
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - An unanswered pairing is sent again and PSI is not told yet

```gherkin
Scenario: Failure or resilience behavior - gateway is off for one delivery window (about 2 days)
Given gateway {gateway_imei} is switched off
And PSI's pairing {request_id} was accepted and sent
When one delivery window passes with no reply (about 47 hours, or a shorter time set up for testing)
Then the platform sends the same pairing to the gateway again
And the command still shows "Queued"
And PSI has received nothing yet for {request_id}
And looking up {request_id} shows "in progress" with no result yet
```

Automation Recommendation: Manual

Status: Created

EMTE: 1.0

Traceability: US2-AC2, FR-010, FR-011

---

@FS-2944
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - A gateway that answers late still gives a normal "Success"

```gherkin
Scenario: Successful interaction - gateway comes back online after being resent
Given pairing {request_id} for gateway {gateway_imei} was sent again at least once while the gateway was off
When the gateway is switched on and accepts the command
Then PSI gets exactly one "Success" message for {request_id}
And the gateway console shows the layout from {request_id}
```

Automation Recommendation: Manual

Status: Created

EMTE: 1.0

Traceability: US2-AC5, FR-010, FR-011

---

@FS-2945
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - An operator cancelling the pairing gives PSI "Unsuccess"

```gherkin
Scenario: Failure or resilience behavior - operator cancels a waiting pairing in DMS
Given PSI's pairing {request_id} for switched-off gateway {gateway_imei} was accepted
When an operator cancels that pairing from the DMS command history
Then the command shows "Cancelled"
And PSI gets exactly one "Unsuccess" message for {request_id}
And looking up {request_id} shows "cancelled"
```

Automation Recommendation: Manual

Status: Created

EMTE: 0.5

Traceability: US2-AC3, FR-011, FR-022

---

@FS-2946
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - When the platform gives up resending, PSI gets "Unsuccess"

```gherkin
Scenario: Failure or resilience behavior - the pairing expires
Given the test environment is set up to stop resending after a short time
And PSI's pairing {request_id} was accepted for a gateway that never answers
When the platform stops resending and marks the command "Expired"
Then within 10 minutes PSI gets exactly one "Unsuccess" message for {request_id}
And looking up {request_id} shows "failed", with the command status "Expired"
```

Automation Recommendation: Manual

Status: Created

EMTE: 1.0

Traceability: US2-AC4, FR-010, FR-011, SC-002

---

@FS-2947
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - A new pairing replaces an older one that is still waiting

```gherkin
Scenario: Successful interaction - pairing B replaces waiting pairing A
Given gateway {gateway_imei} is switched off
And PSI has sent pairing A and got request number {request_id_a}
When PSI sends pairing B for the same gateway, which differs from A only on tire 3
Then the platform accepts B and its reply says it replaced request {request_id_a}
And pairing A is marked "Cancelled" before pairing B is sent
And PSI gets exactly one "Unsuccess" message for {request_id_a}
```

Automation Recommendation: Manual

Status: Created

EMTE: 0.5

Traceability: US3-AC1, FR-004, FR-011, FR-013, SC-009

---

@FS-2948
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - After a replacement the gateway ends up with the newer layout

```gherkin
Scenario: Successful interaction - gateway holds exactly pairing B
Given pairing B (request {request_id_b}) replaced pairing A for gateway {gateway_imei}
When the gateway is switched on and accepts pairing B
Then the gateway console shows exactly pairing B, including B's sensor on tire 3
And PSI gets one "Success" message for {request_id_b}
And if a late reply for pairing A arrives, A stays "Cancelled" and PSI gets no second message for A
```

Automation Recommendation: Manual

Status: Created

EMTE: 1.0

Traceability: US3-AC2, FR-013, FR-014, SC-009, EC-6

---

@FS-2949
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - A replaced pairing is never sent again

```gherkin
Scenario: Failure or resilience behavior - old pairing stays stopped
Given pairing A was replaced while the gateway had not answered
When one or more delivery windows (about 2 days each) pass with the gateway still off
Then pairing A is not sent to the gateway again
And only pairing B is sent again
```

Automation Recommendation: Manual

Status: Created

EMTE: 1.0

Traceability: US3-AC3, FR-013, SC-009

---

@FS-2950
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - Sending the same pairing twice counts as two requests

```gherkin
Scenario: Successful interaction - PSI repeats a pairing after a timeout
Given gateway {gateway_imei} is switched off
And PSI has sent pairing A and got request number {request_id_1}
When PSI sends exactly the same pairing again
Then the platform accepts it with a new request number {request_id_2} and says it replaced {request_id_1}
And PSI gets "Unsuccess" for {request_id_1}
And once the gateway accepts, PSI gets "Success" for {request_id_2} and the gateway console shows pairing A
```

Automation Recommendation: Manual

Status: Created

EMTE: 1.0

Traceability: EC-5, FR-013

---

@FS-2951
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - "Unpair all" removes every sensor from the gateway

```gherkin
Scenario: Successful interaction - 0 tires and no sensors
Given gateway {gateway_imei} has sensors on tires 1 to 8
When PSI sends a pairing with 0 tires, 0 axles and an empty sensor list
Then the platform accepts it
And the gateway is sent 0 tires with every one of the 70 slots empty, plus the "start pairing" trigger
And once the gateway accepts, its console shows no tires in use and every slot cleared
And PSI gets exactly one result message for the request
```

Automation Recommendation: Manual

Status: Created

EMTE: 1.0

Traceability: US4-AC1, FR-008b, FR-008c

---

@FS-2952
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - Mistakes in the request are refused and nothing is sent to any gateway

```gherkin
Scenario Outline: Interaction variation matrix - bad request is refused before sending
When PSI sends a pairing for gateway {gateway_imei} with this mistake: {mistake}
Then the platform refuses it with status 400 and the reason code {reason_code}
And the refusal message points to {what_is_named}
And no request number is given
And nothing is sent to any gateway, and nothing is added to the DMS command history

Examples:
| mistake                                       | reason_code             | what_is_named                     |
| sensor ID "0x8FB179" (has a 0x prefix)        | INVALID_SENSOR_ID       | the sensor                        |
| sensor ID "8FB1790" (7 characters, too long)  | INVALID_SENSOR_ID       | the sensor                        |
| sensor ID "8FG179" (G is not allowed)         | INVALID_SENSOR_ID       | the sensor                        |
| tire 3 listed twice                           | DUPLICATE_POSITION      | tire 3                            |
| sensor "8FB179" on both tire 2 and tire 6     | DUPLICATE_SENSOR_ID     | the sensor and tires 2 and 6      |
| 71 tires                                      | COUNT_OUT_OF_RANGE      | number of tires                   |
| 25 axles                                      | COUNT_OUT_OF_RANGE      | number of axles                   |
| 8 tires but a sensor on tire 9                | POSITION_OUT_OF_RANGE   | the tire                          |
| 0 tires but one sensor listed                 | POSITION_OUT_OF_RANGE   | the tire                          |
| 2 axles but a sensor on axle 3                | AXLE_OUT_OF_RANGE       | the axle                          |
| a sensor on axle 0                            | AXLE_OUT_OF_RANGE       | the axle                          |
| a sensor in tire group 0                      | TIRE_GROUP_OUT_OF_RANGE | the tire group                    |
| a sensor in tire group 11                     | TIRE_GROUP_OUT_OF_RANGE | the tire group                    |
| number of tires left out                      | MISSING_FIELD           | number of tires                   |
| number of axles left out                      | MISSING_FIELD           | number of axles                   |
| sensor list left out                          | MISSING_FIELD           | sensor list                       |
| a sensor with no sensor ID                    | MISSING_FIELD           | sensor ID and which tire          |
| a sensor with no axle                         | MISSING_FIELD           | axle and which tire               |
| a sensor with no tire group                   | MISSING_FIELD           | tire group and which tire         |
| IMEI with 14 digits instead of 15             | INVALID_IMEI            | the IMEI                          |
```

Automation Recommendation: Manual

Status: Created

EMTE: 0.75

Traceability: US5-AC1, US5-AC2, US5-AC3, US5-AC4, US5-AC5, FR-003, SC-005

---

@FS-2953
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - Devices that are not TrackRR gateways are refused

```gherkin
Scenario Outline: Interaction variation matrix - wrong or unknown device
Given the Asset Service shows IMEI {target_imei} as {device}
When PSI sends a valid pairing for {target_imei}
Then the platform refuses it with status {status} and the reason code {reason_code}
And the refusal message says {message}
And nothing is sent to any gateway

Examples:
| device                        | status | reason_code              | message                                                        |
| not known to the platform     | 404    | GATEWAY_NOT_REGISTERED   | the gateway is not registered                                  |
| a TrackRR Lite (AS500)        | 422    | TRACKRR_LITE_UNSUPPORTED | TrackRR Lite does not support tire sensors                     |
| an MCU                        | 422    | MCU_USE_LOCATION_SET     | it is not a TrackRR, and to use the existing MCU pairing request |
| any other kind of device      | 422    | NOT_A_TRACKRR            | it is not a TrackRR                                            |
```

Automation Recommendation: Manual

Status: Created

EMTE: 0.75

Traceability: US5-AC6, US5-AC7, US5-AC8, FR-006, SC-005

---

@FS-2954
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - A gateway the delivery service cannot reach is refused

```gherkin
Scenario: Failure or resilience behavior - the command cannot be delivered
Given TrackRR gateway {unreachable_imei} is registered in the platform but not set up in the Device Delivery Service
When PSI sends a valid pairing for {unreachable_imei}
Then the platform refuses it with status 502 and the reason code "DISPATCH_FAILED"
And the platform never says the request was accepted
And PSI gets no result message afterwards for this request
```

Automation Recommendation: Manual

Status: Created

EMTE: 0.5

Traceability: FR-007

---

@FS-2955
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - Gateways on old firmware are refused when the version is known

```gherkin
Scenario Outline: Interaction variation matrix - gateway firmware version
Given the platform shows gateway {gateway_imei} with firmware {firmware}
When PSI sends a valid pairing for {gateway_imei}
Then {result}

Examples:
| firmware                                | result                                                       |
| known, and older than build ffad85ee    | the platform refuses it with a reason, and nothing is sent   |
| not known                               | the platform accepts it and sends the pairing                |
| known, build 4a5c7657 or newer          | the platform accepts it and sends the pairing                |
```

Automation Recommendation: Manual

Status: Created

EMTE: 0.75

Traceability: EC-11

---

@FS-2956
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - Lower-case sensor IDs and gaps between tires are handled

```gherkin
Scenario: Successful interaction - lower-case ID and gaps in the layout
Given PSI prepares a pairing for gateway {gateway_imei} with 8 tires and sensors on tires 1, 2 and 5
And the sensor on tire 1 is typed in lower case as "8fb179"
When PSI sends the pairing and the gateway accepts it
Then the gateway receives the sensor ID in capitals as "8FB179"
And tires 3, 4, 6, 7 and 8 are sent empty, with 8 tires in use
And the gateway console shows 8 tires in use with sensors only on tires 1, 2 and 5
```

Automation Recommendation: Manual

Status: Created

EMTE: 1.0

Traceability: EC-8, EC-9, FR-005, FR-008c

---

@FS-2957
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - A sensor moved from another gateway is accepted and the other gateway is left alone

```gherkin
Scenario: Successful interaction - sensor moved between trailers
Given sensor "8FB179" was earlier paired to another gateway {other_imei}
When PSI sends a pairing for gateway {gateway_imei} that includes sensor "8FB179"
Then the platform accepts it and sends it to {gateway_imei}
And nothing is sent to {other_imei}
And the console of {other_imei} shows its layout unchanged
```

Automation Recommendation: Manual

Status: Created

EMTE: 1.0

Traceability: EC-7

---

@FS-2958
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - Sensors set up by hand on the gateway are overwritten

```gherkin
Scenario: Successful interaction - PSI's layout replaces a hand-made change
Given a technician added a sensor on tire 9 of gateway {gateway_imei} through its console
When PSI sends a layout of 8 tires with sensors on tires 1 to 8
And the gateway accepts it
Then the gateway console shows tire 9 cleared and only the 8 sensors PSI sent
And the platform did not read the gateway's settings before sending
```

Automation Recommendation: Manual

Status: Created

EMTE: 1.0

Traceability: EC-4, FR-008

---

@FS-2959
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - A request after a failed one is sent exactly as given

```gherkin
Scenario: Successful interaction - an earlier failure does not affect the next pairing
Given pairing {request_id_1} for gateway {gateway_imei} failed because the gateway rejected it
When PSI sends a new valid pairing for {gateway_imei}
Then the reply says it replaced nothing
And the gateway receives exactly the new layout, with nothing taken from {request_id_1}
```

Automation Recommendation: Manual

Status: Created

EMTE: 0.5

Traceability: EC-3, FR-008

---

@FS-2960
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - The result shows the trailer the gateway was on when PSI asked

```gherkin
Scenario: Successful interaction - gateway moved to another trailer before it answered
Given PSI's pairing {request_id} was accepted while gateway {gateway_imei} was on trailer {trailer_id}
And the gateway is then moved to trailer {new_trailer_id} before it answers
When the gateway accepts the command
Then PSI's result message for {request_id} shows trailer {trailer_id} and its name
And looking up {request_id} also shows trailer {trailer_id}
```

Automation Recommendation: Manual

Status: Created

EMTE: 0.5

Traceability: EC-10, FR-012, FR-018

---

@FS-2961
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - PSI gets only one result even if the gateway replies more than once

```gherkin
Scenario Outline: Interaction variation matrix - repeated or simultaneous replies
Given PSI's pairing {request_id} for gateway {gateway_imei} was accepted
When the gateway's "accepted" reply {reply_pattern}
Then PSI gets exactly one result message for {request_id}
And the platform records the result as delivered to PSI only once

Examples:
| reply_pattern                                              |
| arrives twice                                              |
| is handled by two copies of the platform at the same time  |
| is followed later by a "rejected" reply for the same command |
```

Automation Recommendation: Manual

Status: Created

EMTE: 0.75

Traceability: EC-1, FR-014, SC-003

---

@FS-2962
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - If PSI cannot be reached, the platform tries 3 times and keeps the result

```gherkin
Scenario: Failure or resilience behavior - PSI's receiver is down
Given the PSI reply receiver is set to answer every message with an error (HTTP 503)
When the gateway accepts pairing {request_id}
Then the platform tries to send PSI the result 3 times: the 2nd try about 30 seconds after the 1st, and the 3rd about 60 seconds after the 2nd
And each failed try is logged as a warning, and one error is logged after the last try
And the platform records the result as "could not be delivered", with 3 tries and the time of the last try
And the command still shows "Completed"
And looking up {request_id} shows "accepted", result "success", and that delivery to PSI failed
```

Automation Recommendation: Manual

Status: Created

EMTE: 1.0

Traceability: EC-2, US6-AC2, FR-015, FR-018, FR-022, SC-008

---

@FS-2963
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - Looking up a request shows where it stands

```gherkin
Scenario Outline: Interaction variation matrix - status lookup at each stage
Given pairing {request_id} for gateway {gateway_imei} is {situation}
When PSI looks up request {request_id}
Then the lookup shows the gateway IMEI, the state {state}, the result {result} and whether PSI was told: {psi_told}
And looking it up does not change anything

Examples:
| situation                                    | state       | result       | psi_told     |
| sent, waiting for the gateway                | in progress | none yet     | not yet      |
| accepted, and PSI was told                   | accepted    | success      | yes          |
| rejected by the gateway                      | failed      | unsuccessful | yes          |
| expired                                      | failed      | unsuccessful | yes          |
| cancelled by an operator                     | cancelled   | unsuccessful | yes          |
| replaced by a newer pairing                  | cancelled   | unsuccessful | yes          |
```

Automation Recommendation: Manual

Status: Created

EMTE: 1.0

Traceability: US6-AC1, US6-AC2, US6-AC3, FR-022

---

@FS-2964
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - The lookup reveals nothing for unknown requests or callers without permission

```gherkin
Scenario Outline: Interaction variation matrix - lookup is refused
When a caller {caller} looks up {lookup_id}
Then {result}

Examples:
| caller                                       | lookup_id                              | result                                                        |
| with the pairing permission                  | a request number that does not exist   | refused with status 404 "REQUEST_NOT_FOUND" and no other data |
| with the pairing permission                  | the number of a non-pairing command    | refused with status 404 "REQUEST_NOT_FOUND" and no other data |
| whose login lacks the pairing permission     | a real pairing request number          | refused with HTTP 403 and no request data                     |
| with no login token                          | a real pairing request number          | refused with HTTP 401 and no request data                     |
```

Automation Recommendation: Manual

Status: Created

EMTE: 0.75

Traceability: US6-AC4, FR-021, FR-022

---

@FS-2965
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - Callers without the pairing permission are stopped before anything happens

```gherkin
Scenario Outline: Failure or resilience behavior - caller not allowed to pair
When a caller {caller} sends a valid pairing for gateway {gateway_imei}
Then the platform refuses it with HTTP {http_status}
And the platform does not look up the gateway
And nothing is sent to any gateway

Examples:
| caller                                   | http_status |
| whose login lacks the pairing permission | 403         |
| with no login token                      | 401         |
| with an invalid login token              | 401         |
```

Automation Recommendation: Manual

Status: Created

EMTE: 0.75

Traceability: EC-12, FR-021

---

@FS-2966
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - With pairing switched off, requests are refused

```gherkin
Scenario: Failure or resilience behavior - feature switched off in this environment
Given tire sensor pairing is switched off in this environment
When PSI sends a valid pairing for gateway {gateway_imei}
Then the platform refuses it with status 503, reason code "PAIRING_DISABLED", and a message saying TrackRR pairing is not available here
And nothing is sent to any gateway
```

Automation Recommendation: Manual

Status: Created

EMTE: 0.5

Traceability: EC-13, FR-019

---

@FS-2967
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - The old MCU pairing request tells PSI to use the TrackRR request

```gherkin
Scenario: Failure or resilience behavior - MCU request sent for a TrackRR trailer
Given trailer {trailer_id} has a TrackRR gateway
When PSI sends the existing MCU pairing request for trailer {trailer_id}
Then the platform still refuses it
And the refusal message tells PSI to use the TrackRR pairing request instead
And nothing is sent to any gateway
```

Automation Recommendation: Manual

Status: Created

EMTE: 0.5

Traceability: EC-14, FR-020

---

@FS-2968
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - MCU pairing works exactly as before

```gherkin
Scenario: Successful interaction - MCU pairing is not affected
Given an MCU test gateway is installed on trailer {mcu_trailer_id}
When PSI sends the existing MCU pairing request for one sensor, with the same fields and login as today
And the MCU gateway confirms the pairing
Then PSI's reply and result message have the same fields, values and timing as before this release
And the MCU result message has no gateway IMEI field
```

Automation Recommendation: Manual

Status: Created

EMTE: 0.5

Traceability: FR-001, FR-020, FR-021, SC-006

---

@FS-2969
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - The gateway's reply to Firmware Ready is matched to the right command

```gherkin
Scenario: Successful interaction - Firmware Ready now carries its message ID in field 104
Given a TrackRR test gateway is waiting for a firmware update
When DMS sends it the Firmware Ready command
Then the command carries the message ID in field 104, field 1210 set to "[02]", and no field 100
And the gateway's reply repeats that message ID in field 104
And DMS matches the reply to the correct Firmware Ready command
```

Automation Recommendation: Manual

Status: Created

EMTE: 0.5

Traceability: FR-009c, SC-010

---

@FS-2970
## [device-management-service][FS-2798-psi-ngg-sensor-pairing] - Everything is recorded for audit, and PSI's password never appears

```gherkin
Scenario: Successful interaction - check the audit records and logs after testing
Given during testing one pairing was accepted, one was refused, and one result message to PSI needed a retry
When the tester checks the DMS command history, the stored result messages and the DMS logs from the test run
Then the accepted pairing's record shows the layout sent, the gateway's answer, the gateway, and its trailer and organization at the time
And the refused pairing is logged with its reason
And every try to send a result to PSI is logged, with the number of tries and the last try recorded
And the stored copy of each result message shows the PSI key as "***REDACTED***"
And searching all records and logs finds PSI's shared key zero times
```

Automation Recommendation: Manual

Status: Created

EMTE: 1.0

Traceability: FR-018, SC-007

---

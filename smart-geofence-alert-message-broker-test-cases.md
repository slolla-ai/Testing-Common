Test Type: Message Broker

Feature: Message Broker - Smart Geofence Crossing Notification Queuing

Purpose:
Validate that a notification message is queued for every Smart Geofence boundary crossing, with correct payload content and schedule-window suppression behavior.

Automation Recommendation: automatable

Background:
Given a message broker (SQS) is operational
And px-alert-rules-engine is configured as the producer and px-notification-service as the consumer for crossing notifications
And a Smart Geofence configuration has one or more notification recipients and a defined schedule window
And required test data (in-scope trailer with a known alert state) is available

---

Scenario: Successful message flow - crossing with active alerts queues a notification with full alert detail
Given an in-scope trailer with one or more active alerts crosses the Smart Geofence boundary within the configured schedule window
When the crossing event is processed by px-alert-rules-engine
Then a SmartGeofenceCrossingPayload message should be published to the notification queue
And the message should be consumed by px-notification-service
And the message should contain the trailer identifier, crossing direction, geofence name, and the union of all individual active alert details (type, category, trigger)
And each configured recipient should receive the notification
Automation Recommendation: automatable
Traceability: US4-AC1, FR-009

---

Scenario: Successful message flow - zero-alert crossing still queues a notification with a clean indicator
Given an in-scope trailer with zero active alerts crosses the Smart Geofence boundary within the configured schedule window
When the crossing event is processed by px-alert-rules-engine
Then a SmartGeofenceCrossingPayload message should be published to the notification queue
And the message should contain the trailer identifier, crossing direction, geofence name, and an explicit indicator that no active alerts are present
And the expected business outcome (recipient notified of a clean crossing) should occur
Automation Recommendation: automatable
Traceability: US4-AC2, FR-009

---

Scenario: Message failure or resilience behavior - crossing outside the configured schedule window suppresses the notification
Given a crossing event occurs outside the Smart Geofence's configured schedule window
When px-alert-rules-engine evaluates the crossing for notification
Then no notification message should be published to the queue at that time
And the notification should be delivered at the next scheduled window instead, consistent with existing geofence alert behavior
Automation Recommendation: automatable
Traceability: US4-AC3

---

Scenario: Message failure or resilience behavior - notification queuing failure does not block snapshot persistence
Given the notification queue is unavailable or rejects the publish attempt
When a Smart Geofence boundary crossing is processed
Then the crossing snapshot should still be persisted successfully
And the notification failure should be logged
And no unintended side effects should occur to subsequent crossing processing
Automation Recommendation: automatable
Traceability: FR-006, FR-007, SC-006

---

Scenario Outline: Message variation matrix - notification payload by alert state
When a message is published with "<payload_variant>"
Then "<expected outcome>" should occur

Examples:
| payload_variant | expected outcome |
| activeAlertCount=0 | notification includes clean indicator, no alert detail entries |
| activeAlertCount=1 | notification includes exactly one alert detail (type, category, trigger) |
| activeAlertCount>1 across multiple referenced configurations | notification includes the deduplicated union of alert details |

Automation Recommendation: automatable
Traceability: US4-AC1, US4-AC2, EC-2, FR-009

---

Scenario: Configured recipients receive and can read the crossing notification in their actual delivery channel
Given a Smart Geofence has one or more configured recipients with real delivery addresses in a staging environment
When a trailer crosses the boundary with and without active alerts across two separate crossings
Then each recipient receives a legible notification for both crossings in their actual inbox or channel
And no crossing is skipped due to zero-alert status
Automation Recommendation: manual
Traceability: US4-AC1, US4-AC2, SC-007

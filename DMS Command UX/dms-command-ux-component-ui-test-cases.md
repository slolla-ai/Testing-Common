Test Type: Component UI

Feature: Component UI - DMS Command UX Behavior

Purpose:
Validate that the DMS command list and command detail UI display current command status, metadata, filtering, sorting, pagination, refresh behavior, and failed/stale state treatment.

Automation Recommendation: manual

Background:
Given the DMS command list page is loaded
And the system contains commands in statuses pending, in progress, successful, failed, and stale

Scenario: Display command status and metadata in the command list
Given the DMS command list page has loaded
When the user inspects the visible command rows
Then each visible row displays the expected status label and metadata fields
And status labels match the current command state
Automation Recommendation: manual
Traceability: US1-AC1

Scenario: Filter and sort behavior updates the visible command list
Given the command list contains commands across multiple statuses
When the user applies a status filter
And the user changes the sort order
Then the list shows only commands matching the selected status
And the visible rows are ordered according to the selected sort
Automation Recommendation: manual
Traceability: US1-AC2

Scenario: Pagination preserves filters and sort order
Given the command list contains more commands than fit on one page
When the user navigates to the next page
Then the list updates to display the next page of command rows
And the selected status filter and sort order remain applied
Automation Recommendation: manual
Traceability: US1-AC3

Scenario: Command detail displays current status and metadata
Given a command is selected from the list
When the user opens the command detail page
Then the detail page displays the command's current status
And the page shows the command metadata fields correctly
Automation Recommendation: manual
Traceability: US2-AC1

Scenario: Refresh updates command status in the UI
Given a command status has changed in the backend
When the user refreshes the command list or detail page
Then the UI reflects the updated command status
Automation Recommendation: manual
Traceability: US2-AC2

Scenario: Failed or stale commands show the correct UX treatment
Given a command has failed or stale status
When the user views the command in the list and detail pages
Then the UI displays the correct failed or stale indicator
And the command is not shown as active or successful
Automation Recommendation: manual
Traceability: US3-AC1

Scenario Outline: Filter and sort state variations
Given the command list contains commands in <initial_state>
When the user applies <filter>
And the user applies <sort_action>
Then the list should display <expected_outcome>
Automation Recommendation: manual
Traceability: US1-AC2

Examples:
| initial_state | filter         | sort_action                | expected_outcome |
| all statuses  | status = failed | sort by date descending    | only failed commands appear in newest-first order |
| all statuses  | status = pending | sort by command name ascending | only pending commands appear in alphabetical order |

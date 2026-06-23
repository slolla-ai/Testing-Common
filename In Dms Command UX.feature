Feature: DMS Command UX
  Verify the Device Management Service command user experience for command status, metadata, filtering, sorting, pagination, refresh, and failed/stale handling.

  Scenario: Display command status and metadata in the command list
    Given the DMS command list page is loaded
    When the user inspects the visible command rows
    Then each row displays the command status label and metadata fields
    And the status label matches the command's current status

  Scenario: Filter and sort behavior updates the visible command list
    Given the command list contains commands across multiple statuses
    When the user applies a status filter
    And the user changes the sort order
    Then the list updates to show only commands matching the selected status
    And the rows are ordered according to the selected sort

  Scenario: Paginated navigation preserves filters and sort order
    Given the command list contains more commands than fit on one page
    When the user navigates to the next page
    Then the command list updates to the next page of results
    And the selected status filter and sort order remain applied

  Scenario: Command detail displays current status and metadata
    Given the user selects a command from the list
    When the user opens the command detail page
    Then the detail page displays the command's current status
    And the metadata fields are shown correctly

  Scenario: Refresh updates command status in the UI
    Given a command status has changed in the backend
    When the user refreshes the command list or detail view
    Then the UI reflects the updated command status

  Scenario: Failed or stale commands show the correct UX treatment
    Given a command has failed or stale status
    When the user views the command in the list and detail pages
    Then the UI shows the appropriate failed or stale indicator
    And the command is not displayed as active or successful

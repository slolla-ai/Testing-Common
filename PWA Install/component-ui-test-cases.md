Test Type: Component UI

Feature: Download (PWA Install) Sidebar Entry, Guidance Dialog & Update Prompt - Install, Standalone Branding, and Update Notification UI

Purpose:\
Validate the px-web-app sidebar "Download" entry, its install-guidance dialog, the in-app "update available" prompt, and standalone-launch branding provide correct, accessible, platform-appropriate feedback and behavior for PWA installability (FS-2066)

Component Location:
microservice: px-web-app

```gherkin
Background:
Given the px-web-app is served over HTTPS
And the PWA installability feature flag and the sidebar Download-entry flag are enabled for the current environment
And the user is authenticated in px-web-app
```

## [px-web-app][FS-2066-web-app-pwa-install] - Download entry appears unaided on a cold authenticated Chromium load

```gherkin
Scenario: Sidebar Download entry appears without a reload on Chromium
  Given the user opens px-web-app in a Chromium browser (Chrome/Edge) on a cold authenticated load
  And the browser has not yet rendered the sidebar when the install-eligibility event fires
  When the app finishes loading
  Then the sidebar {Download} entry (accessible name "Download Fus1on") is visible below the Feedback entry
  And the entry appears without the user having to reload the page
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: US1-AC1, FR-003a, SC-001, SC-007

---

## [px-web-app][FS-2066-web-app-pwa-install] - Activating Download entry on Chromium triggers the native install prompt

```gherkin
Scenario: Download entry triggers the browser install prompt on Chromium
  Given the app is installable on a Chromium browser and not yet installed
  And the sidebar {Download} entry is visible
  When the user activates the {Download} entry
  Then the browser's native install prompt is triggered
  And the user can complete installation from that prompt
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: US1-AC2, FR-003a, SC-002

---

## [px-web-app][FS-2066-web-app-pwa-install] - Download entry opens Add-to-Home-Screen guidance on Safari iOS/iPadOS

```gherkin
Scenario: Download entry shows iOS/iPadOS install guidance dialog
  Given the user opens px-web-app in Safari on iOS/iPadOS
  And the app is not yet installed
  When the user activates the {Download} entry
  Then a guidance dialog opens with the steps "Share → Add to Home Screen"
  And the dialog remains on screen until the user dismisses it
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: US1-AC3, EC-1, FR-003a

---

## [px-web-app][FS-2066-web-app-pwa-install] - Download entry opens Add-to-Dock guidance on macOS Safari with version caveat

```gherkin
Scenario: Download entry shows macOS Safari install guidance dialog
  Given the user opens px-web-app in Safari on macOS
  And the app is not yet installed
  When the user activates the {Download} entry
  Then a guidance dialog opens with the steps "File → Add to Dock"
  And the dialog states that Add to Dock requires Safari 17 (macOS Sonoma) or later
  And the dialog remains on screen until the user dismisses it
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: US1-AC3, EC-1, FR-003a

---

## [px-web-app][FS-2066-web-app-pwa-install] - iOS guidance text does not assume the Share control is in the browser toolbar

```gherkin
Scenario: iOS guidance copy is toolbar-layout agnostic
  Given the user opens px-web-app in any iOS browser (not necessarily Safari's own toolbar layout)
  When the user activates the {Download} entry
  Then the guidance dialog's Share → Add to Home Screen instructions do not assume the Share control's toolbar position
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: EC-1, FR-003a

---

## [px-web-app][FS-2066-web-app-pwa-install] - Guidance dialog opens on Chromium once the single-use install prompt is spent

```gherkin
Scenario: Download entry falls back to guidance after the Chromium prompt is consumed
  Given the app is installable on Chromium
  And the browser's single-use install prompt has already been consumed
  When the user activates the {Download} entry
  Then the guidance dialog opens pointing at the browser's own install control (address-bar icon on desktop, overflow menu on Android)
  And the activation does not do nothing
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: US1-AC3a, EC-8, SC-007

---

## [px-web-app][FS-2066-web-app-pwa-install] - Guidance dialog persists until explicitly dismissed

```gherkin
Scenario: Guidance dialog is persistent, not a transient toast
  Given the guidance dialog is open after activating the {Download} entry
  When the user does not interact with the dialog for an extended period
  Then the dialog remains visible on screen
  And it only closes when the user explicitly dismisses it
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: FR-003a

---

## [px-web-app][FS-2066-web-app-pwa-install] - Repeated activation of Download entry does not stack duplicate dialogs

```gherkin
Scenario: Multiple activations reuse a single dialog instance
  Given the guidance dialog is already open after activating the {Download} entry
  When the user activates the {Download} entry again without closing the dialog
  Then no second/duplicate guidance dialog is stacked on top of the first
  And exactly one dialog instance remains visible
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: FR-003a

---

## [px-web-app][FS-2066-web-app-pwa-install] - Download entry and any open guidance dialog disappear once installation completes

```gherkin
Scenario: Successful install hides the Download entry and closes the dialog
  Given the guidance dialog or native install prompt is available from the {Download} entry
  When the user completes installation on any supported browser
  Then a Fus1on app icon/entry is added to the device launcher
  And the sidebar {Download} entry is no longer shown
  And any open guidance dialog is closed
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: US1-AC4, EC-3

---

## [px-web-app][FS-2066-web-app-pwa-install] - Open guidance dialog closes when the app becomes installed via another window

```gherkin
Scenario: Cross-window install closes an already-open guidance dialog
  Given the guidance dialog is open in one browser window/tab
  When the app becomes installed via a different window/tab
  Then the open guidance dialog closes rather than continuing to instruct the user to install what they already have
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: EC-3

---

## [px-web-app][FS-2066-web-app-pwa-install] - Download entry is not shown when the app is already running standalone

```gherkin
Scenario: Standalone launch suppresses the Download entry
  Given the app is already running in standalone/installed mode
  When the sidebar renders
  Then the {Download} entry is not shown
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: EC-3, SC-007

---

## [px-web-app][FS-2066-web-app-pwa-install] - Download entry is absent and the app remains usable on unsupported browsers

```gherkin
Scenario: Genuinely unsupported browsers show no install affordance
  Given the user opens px-web-app on a browser that supports neither a programmatic install prompt nor standalone installation
  When the app loads
  Then the sidebar {Download} entry is not shown
  And the app remains fully usable in the normal browser tab with no degradation
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: US1-AC6, EC-2, SC-006

---

## [px-web-app][FS-2066-web-app-pwa-install] - Dismissing the native Chromium install prompt keeps the Download entry available

```gherkin
Scenario: Declining the native prompt does not permanently hide the entry
  Given the app is installable on Chromium and not yet installed
  When the user dismisses the browser's native install prompt without installing
  Then the sidebar {Download} entry remains available for the user to try again later
```

Automation Recommendation: Do Not Automate

Status: Approve

EMTE: {It must be updated by the test reviewer}

Traceability: EC-8

---

## [px-web-app][FS-2066-web-app-pwa-install] - Download entry activation never results in a no-op when the native prompt is unusable

```gherkin
Scenario: Refused/unusable install prompt falls back to guidance
  Given the browser refuses to display its native install prompt (e.g. another prompt is already open)
  When the user activates the {Download} entry
  Then the activation falls back to showing the guidance dialog
  And the activation never results in no visible response
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: EC-9

---

## [px-web-app][FS-2066-web-app-pwa-install] - App remains fully usable in a normal browser tab prior to installation

```gherkin
Scenario: Installability is additive, not required, for normal use
  Given the app is not yet installed
  When the user opens and uses px-web-app in a normal browser tab
  Then every existing feature continues to work exactly as it does today
  And installation is never a precondition for using the app
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: US1-AC5, FR-004

---

## [px-web-app][FS-2066-web-app-pwa-install] - Standalone window opens without browser tab/address-bar chrome

```gherkin
Scenario: Installed app launches chromeless
  Given the app is installed on a supported browser
  When the user launches it from the device icon
  Then it opens in a standalone window without browser tab or address-bar chrome
```

Automation Recommendation: Do Not Automate

Status: Approved
EMTE: {It must be updated by the test reviewer}

Traceability: US2-AC1, FR-003

---

## [px-web-app][FS-2066-web-app-pwa-install] - Standalone window is identified by the Fus1on name and icon in the OS

```gherkin
Scenario: Task switcher/dock shows Fus1on branding
  Given the standalone window is open
  When the OS shows the app in a task switcher/dock
  Then it is identified by the name "Fus1on"
  And it displays the Fus1on icon
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: US2-AC2, FR-002, FR-002a, FR-003

---

## [px-web-app][FS-2066-web-app-pwa-install] - Standalone window theming matches the app's visual identity

```gherkin
Scenario: Title/status bar color reflects Fus1on branding
  Given the standalone window is open
  When the app renders
  Then the window theming (title/status bar color) matches the app's own defined theme color
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: US2-AC3, FR-002

---

## [px-web-app][FS-2066-web-app-pwa-install] - "Update available" prompt is shown with reload and close controls

```gherkin
Scenario: In-app update prompt appears when a new version is deployed
  Given the user has an open session in px-web-app (browser or installed)
  When a newer app version becomes available
  Then an in-app "update available" prompt is shown
  And the prompt offers a reload action and a close control
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: US4-AC1, FR-008, SC-005

---

## [px-web-app][FS-2066-web-app-pwa-install] - Accepting the update prompt reloads into the new version

```gherkin
Scenario: Reload action applies the new version immediately
  Given the "update available" prompt is shown
  When the user accepts the prompt's reload action
  Then the app reloads into the new version
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: US4-AC2, FR-008, SC-005

---

## [px-web-app][FS-2066-web-app-pwa-install] - Closing the update prompt dismisses the notification only, without declining the update

```gherkin
Scenario: Close control does not defer or decline the update
  Given the "update available" prompt is shown
  When the user activates the close control instead of reloading
  Then the notification is dismissed without declining the update
  And the pending version is applied on the next in-app navigation
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: US4-AC3, EC-5, EC-6, FR-008, SC-005

---

## [px-web-app][FS-2066-web-app-pwa-install] - Download entry meets accessibility requirements

```gherkin
Scenario: Download entry is keyboard operable with a screen-reader label
  Given the sidebar {Download} entry is visible
  When the user navigates to it using only the keyboard
  Then the entry receives visible focus
  And it can be activated with the keyboard
  And it exposes the accessible name "Download Fus1on" to assistive technology
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: FR-012, SC-008

---

## [px-web-app][FS-2066-web-app-pwa-install] - Guidance dialog meets accessibility requirements

```gherkin
Scenario: Guidance dialog is keyboard operable with screen-reader labeling
  Given the guidance dialog is open
  When the user navigates and dismisses it using only the keyboard
  Then all interactive elements in the dialog receive visible focus
  And the dialog and its controls expose screen-reader-accessible labels
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: FR-012, SC-008

---

## [px-web-app][FS-2066-web-app-pwa-install] - "Update available" prompt meets accessibility requirements

```gherkin
Scenario: Update prompt is keyboard operable with screen-reader labeling
  Given the "update available" prompt is shown
  When the user navigates its reload and close controls using only the keyboard
  Then both controls receive visible focus
  And both controls expose screen-reader-accessible labels
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: FR-012, SC-008

---

## [px-web-app][FS-2066-web-app-pwa-install] - No Download entry or update prompt is shown when installability is disabled

```gherkin
Scenario: Per-environment toggle suppresses all install/update UI
  Given the installability feature flag is disabled for the current environment
  When the user loads px-web-app
  Then no sidebar {Download} entry is shown
  And no "update available" prompt is ever shown
```

Automation Recommendation: Do Not Automate

Status: Approved

EMTE: {It must be updated by the test reviewer}

Traceability: FR-010, SC-009

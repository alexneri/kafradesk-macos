# Task 05: Preferences and Persistence

## Goal
Persist user preferences such as selected character, window position, and always-on-top.

## Scope
- Store preferences in `UserDefaults` or a simple SwiftData model.
- Restore the mascot window position and selection on launch.
- Expose a minimal preferences UI for toggles.

## Implementation Steps
1. Define a `Preferences` model with fields for character ID, last window position, and always-on-top.
2. Load preferences at launch and apply them in `AppState` and `MascotWindowController`.
3. Add a lightweight preferences view (modal sheet or popover) with basic toggles.
4. Save preference updates immediately on change.

## Acceptance Criteria
- The app restores the last selected character and position on relaunch.
- Always-on-top preference persists across sessions.
- Preferences can be adjusted without restarting the app.

## Notes/Dependencies
- Depends on Task 03 for window behavior.

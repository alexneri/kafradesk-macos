# Task 10: Notifications and About Window

## Goal
Add the legacy-style blurb notification and a simple About dialog.

## Scope
- Create a small floating blurb window for short messages.
- Add an About dialog with app name, version, and credits.
- Trigger blurbs for key actions (for example, file added).

## Implementation Steps
1. Implement a `BlurbWindowController` using a lightweight borderless window.
2. Create a SwiftUI blurb view with text, optional icon, and auto-dismiss behavior.
3. Add an About view accessible from the status bar menu.
4. Hook blurb triggers into storage and memo actions.

## Acceptance Criteria
- A blurb window appears briefly and dismisses itself.
- About dialog shows app name, version, and basic credits.
- Blurbs can be triggered programmatically from services.

## Notes/Dependencies
- Depends on Task 06 for menu access and Task 08 for storage triggers.

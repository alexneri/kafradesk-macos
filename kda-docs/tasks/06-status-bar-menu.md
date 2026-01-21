# Task 06: Status Bar Menu and Commands

## Goal
Provide a status bar menu for core commands and visibility control.

## Scope
- Add an `NSStatusItem` with a menu.
- Include actions for show/hide, character selection, preferences, and quit.
- Keep menu state in sync with `AppState`.

## Implementation Steps
1. Create a `StatusBarController` that owns an `NSStatusItem` and `NSMenu`.
2. Add menu items: Show/Hide, Character submenu, Preferences, About, Quit.
3. Bind menu state to `AppState` so selections update immediately.
4. Ensure menu actions operate on the mascot window host.

## Acceptance Criteria
- Status bar icon is visible when the app runs.
- Menu commands toggle visibility and switch characters reliably.
- Menu reflects the current character selection.

## Notes/Dependencies
- Depends on Tasks 03 and 05 for window control and settings.

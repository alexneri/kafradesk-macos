# Task 03: Mascot Window Host

## Goal
Create a borderless, transparent mascot window that can float above the desktop and be dragged.

## Scope
- Add an AppKit-backed window host for the mascot.
- Support transparent background and optional always-on-top behavior.
- Provide basic drag-to-move behavior for the mascot window.

## Implementation Steps
1. Implement a `MascotWindowController` that creates an `NSPanel` or borderless `NSWindow`.
2. Configure the window to be non-opaque, clear background, and without title bar or shadow.
3. Attach a `NSHostingView` to host the SwiftUI mascot view.
4. Add drag handling to move the window, storing updated position in `AppState`.

## Acceptance Criteria
- The mascot window appears without a title bar and with a transparent background.
- The window can be dragged freely on screen.
- Always-on-top can be toggled without restarting the app.

## Notes/Dependencies
- Depends on `AppState` and shared paths from Task 01.

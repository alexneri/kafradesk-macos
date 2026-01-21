# Task 01: App Foundation and Shared Services

## Goal
Establish the macOS app foundation with shared services, stable paths, and app state wiring.

## Scope
- Define shared services for file paths and basic logging.
- Create required app folders on first launch.
- Centralize app state for window visibility and selection.

## Implementation Steps
1. Add a `Core` folder under `Kafra Desktop Assistant/Kafra Desktop Assistant/` for shared services.
2. Implement `AppPaths` using `FileManager` and `URL` to resolve `Application Support/Kafra Desktop Assistant/` and its `Storage` subfolder.
3. Add an `AppState` class to track window visibility and the active character.
4. Wire `AppState` into `Kafra_Desktop_AssistantApp.swift` as a shared environment object.

## Acceptance Criteria
- App launches cleanly and creates the storage folder on first run.
- Shared paths resolve consistently across app restarts.
- Core services are centralized and not duplicated in feature code.

## Notes/Dependencies
- Use `kda-docs/reference/forms-reference.md` for the legacy `Storage` folder behavior.

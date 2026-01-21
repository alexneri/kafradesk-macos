# Task 07: Memo Feature (SwiftData)

## Goal
Implement memo creation, listing, and editing similar to the legacy memo popup.

## Scope
- Define a SwiftData model for memos with timestamp and content.
- Build a memo list and editor view.
- Persist and update memos locally.

## Implementation Steps
1. Create a `Memo` model with fields for `id`, `createdAt`, `updatedAt`, and `body`.
2. Build a memo list view with sorting by timestamp.
3. Add a memo editor sheet or window with save and delete actions.
4. Wire memo views into the status bar menu or a toolbar action.

## Acceptance Criteria
- Users can create, edit, and delete memos.
- Memos persist across app restarts.
- UI shows memo timestamps in a readable format.

## Notes/Dependencies
- Align memo UX with `kda-docs/reference/forms-reference.md`.

# Task 04: Mascot Rendering and Animation

## Goal
Render the character artwork cleanly and add simple animation support (blink or idle).

## Scope
- Display character images at native resolution.
- Apply alpha masking for non-rectangular shapes.
- Support a lightweight animation loop for blink frames.

## Implementation Steps
1. Create a `MascotView` that renders the current character image from the catalog.
2. Ensure the image uses its alpha channel for transparent edges.
3. Add optional animation data (for example, a small JSON or plist with frame rectangles or named images).
4. Drive animation with a `Timer` or `TimelineView`, keeping CPU usage minimal.

## Acceptance Criteria
- Character artwork renders with clean transparency edges.
- At least one character supports a simple blink animation.
- Animation can be disabled for accessibility or low power modes.

## Notes/Dependencies
- Depends on asset catalog and metadata from Task 02.
- Legacy behavior details live in `kda-docs/reference/forms-reference.md`.

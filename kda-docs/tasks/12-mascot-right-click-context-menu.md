# Feature Plan: Task 12 - Mascot Right-Click Context Menu

**Date:** 2026-02-25  
**Feature Type:** Enhancement  
**Status:** Proposed

---

## DISCOVER

### Problem Statement

#### Summary
Users can currently access app actions only through the status bar icon menu. Right-clicking the desktop mascot does not provide the same interaction surface.

#### Background
The app already has a complete command menu in the status bar (`StatusBarController`). The mascot is rendered in a borderless `NSPanel` and supports drag/drop, but there is no right-click context menu on the mascot surface. This forces unnecessary pointer travel to the menu bar for common actions.

#### User Impact

| User Segment | Current Pain | Desired Outcome |
|---|---|---|
| Keyboard/mouse desktop users | Must move cursor to top bar for every command | Right-click mascot to access commands in place |
| Users with hidden auto-collapse menu bar | Extra step to reveal/access menu bar | Reliable desktop-level command access |
| Frequent character switchers | Repeated status-bar interactions | Character/edition switching directly on mascot |

### Discovery Research

#### Current State Analysis

- What exists:
  - Status bar menu with full app commands and dynamic character/edition state.
  - Mascot borderless floating window with drag movement and drop handling.
  - App-level action methods in `AppDelegate` for windows, visibility, and quit.
- What's missing:
  - Secondary-click interaction on mascot view/window.
  - Reusable menu presentation API from existing status bar menu logic.
- Regression boundaries:
  - Left-click drag behavior must remain intact.
  - Existing topbar menu behavior must remain unchanged.

### Code Investigation Summary

#### 1) Files Searched

| Path | Search Terms | Findings |
|---|---|---|
| `Kafra Desktop Assistant/Kafra Desktop Assistant/Windows/StatusBarController.swift` | `NSMenu`, `NSStatusItem`, `show/hide`, `selectCharacter`, `selectEdition` | Full menu construction and command handlers found |
| `Kafra Desktop Assistant/Kafra Desktop Assistant/Views/MascotView.swift` | `right click`, `contextMenu`, `onDrop`, gesture handling | No context menu; only render, blink, and drop handling |
| `Kafra Desktop Assistant/Kafra Desktop Assistant/Windows/MascotWindowController.swift` | `NSPanel`, `isMovableByWindowBackground`, hosting view setup | Borderless panel hosting mascot view; no right-click handling |
| `Kafra Desktop Assistant/Kafra Desktop Assistant/AppDelegate.swift` | `showPreferences`, `showMemos`, `showStorage`, `showAbout`, `quit` | Existing app actions are already centralized |
| `kda-docs/tasks/06-status-bar-menu.md` | menu requirements | Confirms current behavior is status-bar-centric |

#### 2) Relevant Code Locations

- `StatusBarController` builds and binds full command menu: `StatusBarController.swift:54-102`, `StatusBarController.swift:128-146`.
- Menu actions already implemented and routed through closures: `StatusBarController.swift:148-189`.
- Mascot view currently has no context menu surface: `MascotView.swift:18-54`.
- Mascot window creates borderless `NSPanel` and hosting view: `MascotWindowController.swift:18-47`.
- Action endpoints exist in app delegate and can be reused without new business logic: `AppDelegate.swift:117-160`.

#### 3) Existing Patterns

- UI command handling uses closure injection from `AppDelegate` into controllers.
- `NSMenu` state is kept synchronized with `AppState` via Combine subscribers.
- Window controllers encapsulate window lifecycle and display behavior.
- No automated test target currently exists; validation is manual.

#### 4) Search Log

- `rg -n "status bar|statusbar|NSStatusItem|menu|NSMenu|right.?click|context menu|mascot|window" -S "Kafra Desktop Assistant/Kafra Desktop Assistant"`
- `rg --files "Kafra Desktop Assistant/Kafra Desktop Assistant" | rg -i "app|menu|status|mascot|window|viewmodel|controller|delegate|scene"`
- `nl -ba "Kafra Desktop Assistant/Kafra Desktop Assistant/Windows/StatusBarController.swift"`
- `nl -ba "Kafra Desktop Assistant/Kafra Desktop Assistant/Views/MascotView.swift"`
- `nl -ba "Kafra Desktop Assistant/Kafra Desktop Assistant/Windows/MascotWindowController.swift"`
- `nl -ba "Kafra Desktop Assistant/Kafra Desktop Assistant/AppDelegate.swift"`
- `find . -maxdepth 4 \( -name '*Tests*' -o -name '*.xctest' -o -name '*.test.*' -o -name '*.spec.*' \)`

**Investigation confidence:** High (multiple relevant source files with clear integration points).

---

## DEFINE

### Scope Definition

#### In Scope

- Add secondary-click (right-click) interaction on mascot window content.
- Show the app command menu from mascot right-click.
- Reuse existing menu commands and state (show/hide, edition, character, windows, quit).
- Keep menu state accurate at open time.
- Preserve current topbar-icon menu flow.

#### Out of Scope

- Menu redesign or command set expansion.
- Gesture customizations beyond standard secondary click.
- New settings/preferences for context menu behavior.
- Automated UI test framework introduction.

#### Constraints

- Must not break drag movement and drop handling on mascot.
- Must preserve `NSApplication` accessory behavior.
- Must keep logic maintainable (avoid duplicate command implementations).

### Feature Objectives

| Objective | Metric | Target |
|---|---|---|
| Reduce command access friction | User can invoke menu from mascot directly | 100% of manual test runs |
| Maintain parity with status bar menu | Same menu sections/actions available | 100% parity |
| Avoid behavior regressions | Drag/drop and status menu still function | 0 regressions in manual checklist |
| Keep interaction responsive | Context menu appears after secondary click | <150ms on local run |

### Solution Approach (Recommended)

Use AppKit-level context menu presentation on mascot hosting view while reusing status bar menu construction.

#### Why this approach

- Reuses existing `NSMenu` command wiring and dynamic state.
- Prevents menu drift between status bar and mascot surfaces.
- Minimizes business-logic changes and preserves current architecture.

### Information Architecture

#### Files to Update

| File | Change Type | Planned Change |
|---|---|---|
| `Kafra Desktop Assistant/Kafra Desktop Assistant/Windows/StatusBarController.swift` | Refactor | Extract menu construction into reusable API (`buildMenu` + `makeContextMenu`/equivalent) |
| `Kafra Desktop Assistant/Kafra Desktop Assistant/Windows/MascotWindowController.swift` | Feature | Install right-click handling and show context menu via provider closure |
| `Kafra Desktop Assistant/Kafra Desktop Assistant/AppDelegate.swift` | Wiring | Inject menu provider from status bar controller into mascot window controller |

#### Files to Create

| File | Purpose |
|---|---|
| `Kafra Desktop Assistant/Kafra Desktop Assistant/Windows/MascotHostingView.swift` (optional but recommended) | Subclass `NSHostingView<MascotView>` to intercept `rightMouseDown` and pop context menu cleanly |

#### Interaction Flow

1. User right-clicks mascot.
2. Hosting view captures `rightMouseDown`.
3. Window controller requests a fresh menu instance/provider.
4. AppKit pops menu at cursor location.
5. Existing actions execute via current `StatusBarController` wiring.

### Acceptance Criteria

- [ ] Right-clicking the mascot opens a context menu on desktop.
- [ ] Context menu includes Show/Hide Mascot, Edition, Character, Preferences, Memos, Storage, About, and Quit.
- [ ] Menu selection updates `AppState` and window behavior exactly like status bar menu actions.
- [ ] Edition and character checkmark state is accurate when menu opens.
- [ ] Left-click drag movement still works as before.
- [ ] File drop on mascot still works as before.
- [ ] Status bar icon menu behavior remains unchanged.

---

## DELIVER

### Implementation Phases

#### Phase 1: Menu Reuse Refactor

| Task | Status |
|---|---|
| Extract reusable menu construction path in `StatusBarController` | [ ] |
| Ensure menu state refresh occurs immediately before display | [ ] |

#### Phase 2: Mascot Right-Click Integration

| Task | Status |
|---|---|
| Add right-click handler on mascot hosting view/window | [ ] |
| Wire context menu provider from `AppDelegate` | [ ] |
| Present menu using `NSMenu.popUpContextMenu` | [ ] |

#### Phase 3: Validation and Hardening

| Task | Status |
|---|---|
| Manual regression test: drag mascot | [ ] |
| Manual regression test: drop files onto mascot | [ ] |
| Manual regression test: each menu command from mascot | [ ] |
| Manual regression test: status bar menu still works | [ ] |

### Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Drag behavior conflict with right-click handling | Medium | Capture only secondary-click path; leave left-click path unchanged |
| Menu state stale at popup time | Medium | Rebuild/sync menu state just before each popup |
| Strong reference cycle via provider closures | Low | Use `[weak self]` closures in `AppDelegate` wiring |

### Quality Gates

- [ ] Debug build succeeds (`xcodebuild ... -configuration Debug build`).
- [ ] Manual checklist completed for mascot menu and regressions.
- [ ] No accessibility regressions on existing menu actions.

### Delivery Checklist

- [ ] Code changes merged for context menu support.
- [ ] Task document updated with implementation notes (if deviations occur).
- [ ] Optional: update `kda-docs/tasks/implementation-timeline.md` to include Task 12.

---

## Notes

- This feature is an enhancement to Task 06 behavior (status bar menu) and should reuse its command logic rather than introducing parallel command implementations.
- No new persistence or data model changes are required.

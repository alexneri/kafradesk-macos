# Kafra Desktop Assistant (macOS)

Kafra Desktop Assistant is a macOS SwiftUI app that ports the original Windows Kafra Desktop Assistant into a modern, native experience. The repository includes the current macOS implementation, legacy assets, and reference materials for porting behaviors and features.

## Repository Layout

- `Kafra Desktop Assistant/` — Xcode project and SwiftUI source code for the macOS app.
- `Kafra Desktop Assistant/Kafra Desktop Assistant/` — Main target with views, models, and assets.
- `KDA-Data/` — Legacy asset files from the original Windows release.
- `kafra-desktop-assistant-legacycode/` — Original Windows codebase for reference.
- `kda-docs/` — Architecture, security, migration, and task documentation.
- `_bmad/` — BMad Method configuration and workflow tooling.

## Requirements

- macOS with Xcode installed
- SwiftUI-compatible toolchain

## Build

```bash
# Open in Xcode
open "Kafra Desktop Assistant/Kafra Desktop Assistant.xcodeproj"

# Build from CLI (Debug)
xcodebuild -project "Kafra Desktop Assistant/Kafra Desktop Assistant.xcodeproj" \
           -scheme "Kafra Desktop Assistant" \
           -configuration Debug \
           build

# Build from CLI (Release)
xcodebuild -project "Kafra Desktop Assistant/Kafra Desktop Assistant.xcodeproj" \
           -scheme "Kafra Desktop Assistant" \
           -configuration Release \
           build
```

## Run

- Open the Xcode project and select a macOS destination.
- Use **Cmd+R** for Debug or **Cmd+Ctrl+R** for Release.

## Test

```bash
# Run tests (once test target exists)
xcodebuild -project "Kafra Desktop Assistant/Kafra Desktop Assistant.xcodeproj" \
           -scheme "Kafra Desktop Assistant" \
           test
```

## Documentation

- Architecture: `kda-docs/explanation/architecture.md`
- Security: `kda-docs/explanation/security.md`
- Migration overview: `kda-docs/migration/overview.md`
- Task roadmap: `kda-docs/tasks/TASK-REVIEW-SUMMARY.md`

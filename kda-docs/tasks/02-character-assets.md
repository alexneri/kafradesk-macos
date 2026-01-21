# Task 02: Import Character Assets and Metadata

## Goal
Bring the legacy character art into the macOS project and define a clean metadata catalog for it.

## Scope
- Convert legacy bitmap assets to modern formats.
- Organize assets in `Assets.xcassets` by character and edition.
- Create a metadata source for character IDs, names, and sprite files.

## Implementation Steps
1. Decide which sets to include from `KDA-Data/Original Data/Bitmaps` and `KDA-Data/Sakura Edition Data/Bitmaps`.
2. Convert `.bmp` files to `.png` while preserving alpha, then import them into `Assets.xcassets`.
3. Create a `CharacterCatalog.json` (or `.plist`) describing character ID, display name, edition, and image asset name.
4. Add a `CharacterAsset` model and loader that reads the catalog and resolves image assets by name.

## Acceptance Criteria
- The app can load a list of characters with names and images.
- A SwiftUI preview can render at least one character from the catalog.
- Asset names are consistent across editions.

## Notes/Dependencies
- Character name IDs and ordering live in `kda-docs/reference/forms-reference.md`.

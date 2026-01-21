# Character Edition Strategy

## Overview

The legacy Windows application comes in two editions, each featuring a different set of Kafra characters with distinct artwork. This document outlines the strategic options for handling these editions in the macOS port and recommends an implementation approach.

## Legacy Editions

### Original Edition (`KDA-Data/Original Data/`)
- **Character Count:** 7 Kafra characters
- **Art Style:** Classic Ragnarok Online sprites
- **Bitmaps:** 7 files (kafra1.bmp through kafra7.bmp)
- **Regions:** 7 pre-compiled region files (.rgn format)
- **Animation:** Static sprites only
- **Historical Context:** First release, shipped in 2004

### Sakura Edition (`KDA-Data/Sakura Edition Data/`)
- **Character Count:** 7 Kafra characters (+ alternate poses)
- **Art Style:** Enhanced sprites with Sakura theme
- **Bitmaps:** 15 files including blink animations
- **Regions:** Matching region files for all poses
- **Animation:** Supports blink frames
- **Historical Context:** Special release, added 2005

---

## Strategic Options

### Option A: Unified App with Runtime Switching ⭐ **RECOMMENDED**

**Description:**  
Single application bundle that includes both editions, allowing users to switch between Original and Sakura character sets via preferences.

**Implementation:**

```swift
// Character catalog structure
struct CharacterCatalog {
    enum Edition: String, Codable, CaseIterable {
        case original = "Original"
        case sakura = "Sakura"
        
        var displayName: String { rawValue }
    }
    
    struct Character: Identifiable {
        let id: String
        let name: String
        let edition: Edition
        let imageName: String
        let blinkImageName: String?  // For animated editions
    }
    
    static let allCharacters: [Character] = [
        // Original Edition
        Character(id: "orig_1", name: "Kafra Leilah", 
                 edition: .original, imageName: "kafra1", blinkImageName: nil),
        Character(id: "orig_2", name: "Kafra Jasmine", 
                 edition: .original, imageName: "kafra2", blinkImageName: nil),
        // ... more original characters
        
        // Sakura Edition
        Character(id: "sakura_1", name: "Kafra Leilah", 
                 edition: .sakura, imageName: "kafra1_sakura", blinkImageName: "kafra1_sakura_blink"),
        Character(id: "sakura_2", name: "Kafra Jasmine", 
                 edition: .sakura, imageName: "kafra2_sakura", blinkImageName: "kafra2_sakura_blink"),
        // ... more sakura characters
    ]
    
    static func characters(for edition: Edition) -> [Character] {
        allCharacters.filter { $0.edition == edition }
    }
}

// Preferences
class AppPreferences {
    @AppStorage("selectedEdition") var selectedEdition: CharacterCatalog.Edition = .original
    @AppStorage("selectedCharacterID") var selectedCharacterID: String = "orig_1"
}
```

**Preferences UI:**

```swift
struct EditionPreferencesView: View {
    @AppStorage("selectedEdition") private var selectedEdition: CharacterCatalog.Edition = .original
    
    var body: some View {
        Form {
            Section("Character Edition") {
                Picker("Edition", selection: $selectedEdition) {
                    ForEach(CharacterCatalog.Edition.allCases, id: \.self) { edition in
                        Text(edition.displayName).tag(edition)
                    }
                }
                .pickerStyle(.segmented)
                
                Text("Switch between Original (2004) and Sakura (2005) character artwork.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

**Pros:**
- ✅ **User Choice:** Users get both editions without downloading separately
- ✅ **Easy Switching:** Change edition anytime via preferences
- ✅ **Single Codebase:** No duplication of logic
- ✅ **Complete Collection:** Preserves entire legacy library
- ✅ **Future-Proof:** Easy to add more editions later
- ✅ **Better Value:** More content for users

**Cons:**
- ❌ **Larger Bundle:** ~2x asset size (~10-15 MB vs 5-7 MB)
- ❌ **Slightly Complex:** Need edition-aware character loading
- ❌ **Testing:** Must test both edition switching paths

**App Bundle Size Impact:**
- Original Edition Only: ~5-7 MB
- Sakura Edition Only: ~5-7 MB  
- **Both Editions: ~10-15 MB** (still tiny by modern standards)

**Distribution:**
- Single DMG installer
- Simpler update mechanism
- Single App Store listing (if published)

---

### Option B: Separate App Bundles

**Description:**  
Ship two distinct applications: "Kafra Desktop (Original)" and "Kafra Desktop (Sakura)"

**Implementation:**

```swift
// Two separate Xcode targets
Target: Kafra Desktop Original
  - Assets: Original Edition only
  - Bundle ID: moe.sei.kafra-desktop-original
  - Display Name: Kafra Desktop (Original)

Target: Kafra Desktop Sakura
  - Assets: Sakura Edition only
  - Bundle ID: moe.sei.kafra-desktop-sakura
  - Display Name: Kafra Desktop (Sakura)
```

**Pros:**
- ✅ **Smaller Individual Bundles:** ~5-7 MB each
- ✅ **Simple Implementation:** No edition switching logic
- ✅ **User Choice at Install:** Pick preferred edition
- ✅ **Can Run Both:** Different bundle IDs allow simultaneous use

**Cons:**
- ❌ **Duplicate Maintenance:** Two builds to test and release
- ❌ **Separate Updates:** Users must update each app independently
- ❌ **Code Duplication:** Shared logic must be synced
- ❌ **Distribution Complexity:** Two DMGs or one fat DMG
- ❌ **Poor User Experience:** Can't switch without reinstalling
- ❌ **App Store Issues:** Two separate listings or complicated choice

---

### Option C: Original Edition Only (Defer Sakura)

**Description:**  
Ship only the Original edition initially, add Sakura in a future update.

**Implementation:**

```swift
// Phase 1 (v1.0): Original Edition
- Include only Original characters
- Edition selection disabled/hidden

// Phase 2 (v1.1): Add Sakura Edition
- Add Sakura assets
- Enable edition switching
- Release as free update
```

**Pros:**
- ✅ **Faster Initial Release:** Less asset preparation
- ✅ **Smaller v1.0 Bundle:** ~5-7 MB
- ✅ **Simpler v1.0 Testing:** One edition to validate
- ✅ **Controlled Rollout:** Gauge interest before full port

**Cons:**
- ❌ **Incomplete Migration:** Half the legacy content missing
- ❌ **Disappointed Users:** Sakura fans must wait
- ❌ **Rework Required:** Must retrofit edition system later
- ❌ **Delayed Value:** Not delivering full legacy experience

---

### Option D: Sakura Edition Only

**Description:**  
Ship only Sakura edition (more polished, has animations).

**Pros:**
- ✅ **Best Artwork:** Sakura edition is more refined
- ✅ **Animation Support:** Blink frames included
- ✅ **Smaller Bundle:** ~5-7 MB

**Cons:**
- ❌ **Alienates Original Fans:** Some prefer classic sprites
- ❌ **Incomplete Legacy:** Leaves out historical content
- ❌ **Poor Preservation:** Doesn't honor full original app

---

## Recommendation: **Option A** (Unified App)

### Rationale

1. **Complete Legacy Preservation**  
   The macOS port should honor the complete legacy by including all character artwork from both editions.

2. **Bundle Size is Negligible**  
   Modern Macs have abundant storage. A 15 MB app vs 7 MB app makes no practical difference to users.

3. **Superior User Experience**  
   Users appreciate having choices. Switching editions via preferences is more elegant than downloading separate apps.

4. **Future-Proof Architecture**  
   The edition system makes it easy to add community-created character packs or themed editions later.

5. **Single Distribution Channel**  
   One DMG, one App Store listing, one set of release notes, one update stream.

6. **Development Efficiency**  
   While slightly more complex than single-edition, it's far more maintainable than separate app bundles.

---

## Implementation Plan for Option A

### Phase 1: Asset Preparation (Task 02)

1. **Convert Original Edition**
   ```bash
   # Convert all Original bitmaps to PNG
   for i in {1..7}; do
       convert Original\ Data/Bitmaps/kafra${i}.bmp \
               -transparent magenta \
               Assets.xcassets/Characters/Original/kafra${i}_orig.imageset/kafra${i}_orig.png
   done
   ```

2. **Convert Sakura Edition**
   ```bash
   # Convert Sakura bitmaps (base + blink)
   convert Sakura\ Edition\ Data/Bitmaps/kafra1.bmp \
           -transparent magenta \
           Assets.xcassets/Characters/Sakura/kafra1_sakura.imageset/kafra1_sakura.png
           
   convert Sakura\ Edition\ Data/Bitmaps/kafra1_blink.bmp \
           -transparent magenta \
           Assets.xcassets/Characters/Sakura/kafra1_sakura_blink.imageset/kafra1_sakura_blink.png
   ```

3. **Asset Organization**
   ```
   Assets.xcassets/
   ├── Characters/
   │   ├── Original/
   │   │   ├── kafra1_orig.imageset/
   │   │   ├── kafra2_orig.imageset/
   │   │   └── ... (7 characters)
   │   └── Sakura/
   │       ├── kafra1_sakura.imageset/
   │       ├── kafra1_sakura_blink.imageset/
   │       └── ... (7 base + 7 blink)
   ```

### Phase 2: Metadata Catalog (Task 02)

Create `CharacterCatalog.json`:

```json
{
  "editions": [
    {
      "id": "original",
      "name": "Original Edition",
      "year": 2004,
      "characters": [
        {
          "id": "orig_1",
          "name": "Kafra Leilah",
          "imageName": "kafra1_orig",
          "blinkImageName": null
        },
        {
          "id": "orig_2",
          "name": "Kafra Jasmine",
          "imageName": "kafra2_orig",
          "blinkImageName": null
        }
        // ... more original characters
      ]
    },
    {
      "id": "sakura",
      "name": "Sakura Edition",
      "year": 2005,
      "characters": [
        {
          "id": "sakura_1",
          "name": "Kafra Leilah",
          "imageName": "kafra1_sakura",
          "blinkImageName": "kafra1_sakura_blink"
        },
        {
          "id": "sakura_2",
          "name": "Kafra Jasmine",
          "imageName": "kafra2_sakura",
          "blinkImageName": "kafra2_sakura_blink"
        }
        // ... more sakura characters
      ]
    }
  ]
}
```

### Phase 3: Edition Switcher UI (Task 05)

Add edition picker to preferences:

```swift
struct PreferencesView: View {
    @AppStorage("selectedEdition") private var selectedEdition = "original"
    @AppStorage("selectedCharacterID") private var selectedCharacterID = "orig_1"
    
    var body: some View {
        Form {
            Section("Edition") {
                Picker("Character Set", selection: $selectedEdition) {
                    Text("Original (2004)").tag("original")
                    Text("Sakura (2005)").tag("sakura")
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedEdition) { _ in
                    // Reset to first character of new edition
                    selectedCharacterID = CharacterCatalog.characters(for: selectedEdition).first?.id ?? "orig_1"
                }
            }
            
            Section("Character") {
                // Show only characters from selected edition
                Picker("Select Character", selection: $selectedCharacterID) {
                    ForEach(CharacterCatalog.characters(for: selectedEdition)) { character in
                        Text(character.name).tag(character.id)
                    }
                }
            }
        }
    }
}
```

### Phase 4: Character Loading (Task 04)

```swift
class MascotController: ObservableObject {
    @Published var currentCharacter: CharacterCatalog.Character
    
    init() {
        let prefs = AppPreferences.shared
        self.currentCharacter = CharacterCatalog.character(id: prefs.selectedCharacterID) 
                              ?? CharacterCatalog.defaultCharacter
    }
    
    var characterImage: NSImage? {
        NSImage(named: currentCharacter.imageName)
    }
    
    var blinkImage: NSImage? {
        guard let blinkName = currentCharacter.blinkImageName else { return nil }
        return NSImage(named: blinkName)
    }
}
```

---

## Testing Strategy

### Edition Switching Tests
- [ ] Switch from Original to Sakura → Character updates immediately
- [ ] Switch from Sakura to Original → Character updates immediately
- [ ] Selected character persists across app restarts
- [ ] Edition preference persists across app restarts
- [ ] Invalid character ID falls back to default
- [ ] All Original characters load correctly
- [ ] All Sakura characters load correctly
- [ ] Sakura blink animations work
- [ ] Original characters (no animation) don't crash

### Edge Cases
- [ ] Corrupt preferences → Falls back to defaults
- [ ] Missing image asset → Shows placeholder
- [ ] Switching edition mid-animation → Graceful transition
- [ ] Multiple rapid edition switches → No crashes

---

## Future Enhancements (Post v1.0)

### Community Editions
With the edition system in place, future versions could support:
- Custom character packs imported by users
- Holiday-themed editions (Halloween, Christmas)
- Anime crossover characters (with proper licensing)
- User-created character sprites

### Edition Marketplace
- Browse downloadable character packs
- Rate and share custom editions
- Auto-update edition catalogs

---

## Bundle Size Comparison

| Configuration | Estimated Size | % Increase |
|--------------|----------------|------------|
| **Original Only** | 6 MB | Baseline |
| **Sakura Only** | 7 MB | +17% (animations) |
| **Both Editions** | 12 MB | +100% |
| **With Future Packs** | 20-30 MB | +233-400% |

**Note:** Even at 30 MB with multiple editions, this remains tiny by modern app standards (Xcode: 40 GB, Chrome: 250 MB).

---

## Decision Matrix

| Criteria | Option A (Unified) | Option B (Separate) | Option C (Orig Only) | Option D (Sakura Only) |
|----------|-------------------|---------------------|---------------------|------------------------|
| User Choice | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐ | ⭐ |
| Ease of Maintenance | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Legacy Completeness | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| Bundle Size | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Time to Ship | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **TOTAL** | **21** | **18** | **18** | **18** |

**Winner: Option A (Unified App with Both Editions)** ⭐

---

## Implementation Priority

Update **Task 02** acceptance criteria to reflect this decision:

```markdown
## Acceptance Criteria (Updated)
- The app can load characters from both Original and Sakura editions
- A SwiftUI preview can render at least one character from each edition
- Character catalog includes edition metadata
- Asset names clearly indicate edition (e.g., `kafra1_orig`, `kafra1_sakura`)
- Sakura edition blink frames are present and correctly linked
- Total asset bundle size is documented and reasonable (<20 MB)
```

---

**Document Version:** 1.0  
**Last Updated:** 2026-01-20  
**Decision Status:** RECOMMENDED (Pending approval)

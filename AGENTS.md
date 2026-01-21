# Repository Guidelines

## Project Structure & Module Organization

### Directory Layout
- `Kafra Desktop Assistant/` contains the macOS app Xcode project and Swift sources.
- `Kafra Desktop Assistant/Kafra Desktop Assistant/` is the main target: SwiftUI views, SwiftData models, and `Assets.xcassets`.
- `KDA-Data/` holds legacy asset files (cursors, bitmaps, regions) from the original Windows release.
- `kafra-desktop-assistant-legacycode/` contains the original Windows codebase for reference when porting behaviors.
- `kda-docs/` provides architectural, security, and migration documentation for the legacy app and porting context.
- `_bmad/` contains the BMad Method modules, workflows, and agent definitions used for structured planning and documentation.

### Module Organization Principles
- Group related functionality together (e.g., `Core/`, `Features/`, `Services/`)
- Use clear, descriptive file and folder names
- One class/model per file for maintainability
- Separate concerns: Models, Views, Controllers, Services
- Follow Swift package conventions for module boundaries

---

## Build, Test, and Development Commands

### Building
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

### Running
- Run the app from Xcode with the selected macOS destination and the play button.
- Use `Cmd+R` for debug run, `Cmd+Ctrl+R` for release run

### Testing
```bash
# Run tests (once test target exists)
xcodebuild -project "Kafra Desktop Assistant/Kafra Desktop Assistant.xcodeproj" \
           -scheme "Kafra Desktop Assistant" \
           test

# Run specific test
xcodebuild -project "Kafra Desktop Assistant/Kafra Desktop Assistant.xcodeproj" \
           -scheme "Kafra Desktop Assistant" \
           -only-testing:Kafra_Desktop_Assistant_Tests/FeatureNameTests \
           test
```

---

## Coding Style & Naming Conventions

### Swift Formatting
- Use Xcode defaults for Swift formatting (4-space indentation, trailing braces on the same line)
- Types and SwiftUI views use `UpperCamelCase`
- Properties, functions, and variables use `lowerCamelCase`
- Constants use `lowerCamelCase` (Swift convention, not SCREAMING_SNAKE_CASE)
- Enum cases use `lowerCamelCase`

### Imports Checklist
- `import Combine` in any file declaring `ObservableObject` or `@Published`
- `import os` in any file calling `Logger` / `AppLogger`

### Naming Guidelines
- **Descriptive, Intention-Revealing Names:**
  ```swift
  // Good
  func calculateMonthlyRevenue(for customer: Customer) -> Decimal
  var unprocessedPaymentQueue: [Payment]
  
  // Bad
  func calc(for c: Customer) -> Decimal
  var q: [Payment]
  ```

- **One Responsibility Per Function:**
  ```swift
  // Good: Small, focused functions
  func validateEmail(_ email: String) -> Bool { }
  func sendWelcomeEmail(to user: User) throws { }
  
  // Bad: Function doing too much
  func validateAndSendEmail(_ email: String, user: User) throws { }
  ```

- **Avoid Abbreviations:**
  ```swift
  // Good
  var characterConfiguration: CharacterConfig
  var storageDirectory: URL
  
  // Bad
  var charCfg: CharacterConfig
  var strgDir: URL
  ```

### SwiftData Models
- Keep SwiftData models in their own files (e.g., `Item.swift`, `Memo.swift`)
- Use `@Model` macro for persistence types
- Keep models in `Models/` folder
- Document relationships and constraints

```swift
// Example: Memo.swift
import Foundation
import SwiftData

@Model
final class Memo {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var content: String
    
    init(content: String) {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.content = content
    }
}
```

---

## Code Quality Principles

### Clean Code Foundation

1. **Readability First**
   - Code should read like well-written prose
   - Write self-documenting code that explains the "what" and "why"
   - Prefer explicit over implicit behavior
   - Use meaningful names that reveal intent

2. **Single Responsibility Principle (SRP)**
   - Each function/class should do one thing well
   - Functions should be small and focused (typically 10-30 lines)
   - Classes should have a single reason to change
   - High cohesion, low coupling

3. **DRY (Don't Repeat Yourself)**
   - Eliminate code duplication
   - Extract common functionality into reusable functions/protocols
   - Use configuration for repeated constants
   - Implement proper abstractions for shared behavior

4. **SOLID Principles**
   - **S**ingle Responsibility: One reason to change
   - **O**pen/Closed: Open for extension, closed for modification
   - **L**iskov Substitution: Subtypes must be substitutable for base types
   - **I**nterface Segregation: Clients shouldn't depend on unused interfaces (protocols in Swift)
   - **D**ependency Inversion: Depend on abstractions, not concretions

### Domain-Driven Design (DDD) Guidance

When applicable to feature complexity:

1. **Start with the Domain**
   - Use ubiquitous language: Name classes, properties, and methods to match domain concepts
   - Align code structure with business subdomains
   - Document domain boundaries and integration contracts

2. **Model Integrity**
   - Define entities with clear identity (use `Identifiable`)
   - Use value types (structs) for immutable domain concepts
   - Keep aggregate boundaries small
   - Enforce invariants at the model level

3. **Strategic Consistency**
   - Align tactical patterns (e.g., repositories, services) with strategic vision
   - Adopt patterns only when they solve domain complexity
   - Document domain discoveries in `kda-docs/`

### Error Handling

```swift
// Use Swift's error handling mechanisms
enum StorageError: LocalizedError {
    case pathTraversal(String)
    case invalidPath(String)
    case accessDenied(String)
    
    var errorDescription: String? {
        switch self {
        case .pathTraversal(let msg): return "Path Traversal: \(msg)"
        case .invalidPath(let msg): return "Invalid Path: \(msg)"
        case .accessDenied(let msg): return "Access Denied: \(msg)"
        }
    }
}

// Provide meaningful error messages
func openFile(_ url: URL) throws {
    guard FileManager.default.fileExists(atPath: url.path) else {
        throw StorageError.invalidPath("File does not exist: \(url.lastPathComponent)")
    }
    // ... implementation
}

// Handle errors gracefully
do {
    try openFile(fileURL)
} catch let error as StorageError {
    logger.error("Storage operation failed: \(error.localizedDescription)")
    showErrorAlert(message: error.localizedDescription)
} catch {
    logger.error("Unexpected error: \(error)")
    showErrorAlert(message: "An unexpected error occurred")
}
```

### Function Design

```swift
// Keep functions small and focused
func validateCharacterSelection(_ characterID: String) -> Bool {
    CharacterCatalog.character(id: characterID) != nil
}

// Use descriptive parameter names
func moveFile(from sourceURL: URL, to destinationURL: URL) throws {
    try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
}

// Return meaningful values
func loadCharacter(id: String) -> Character? {
    // Returns nil if not found (clear semantics)
    return CharacterCatalog.character(id: id)
}

// Include documentation for public APIs
/// Validates that the given file path is within the storage directory bounds.
/// - Parameter url: The file URL to validate
/// - Throws: `StorageError.pathTraversal` if path escapes storage directory
/// - Returns: The canonical URL within storage bounds
func validatePath(_ url: URL) throws -> URL {
    // Implementation...
}
```

---

## Security Guidelines

### Input Validation
```swift
// ALWAYS validate external input
func handleDroppedFile(_ url: URL) throws {
    // 1. Validate path is within bounds
    try validatePath(url)
    
    // 2. Check file type
    try validateFileType(url)
    
    // 3. Sanitize filename
    let sanitizedName = sanitizeFileName(url.lastPathComponent)
    
    // 4. Proceed with validated data
    // ...
}
```

### Path Security
```swift
// Prevent directory traversal
func sanitizeFileName(_ name: String) -> String {
    var sanitized = name
    sanitized = sanitized.replacingOccurrences(of: "/", with: "-")
    sanitized = sanitized.replacingOccurrences(of: "\\", with: "-")
    sanitized = sanitized.replacingOccurrences(of: "..", with: "")
    return sanitized
}

// Validate paths stay within bounds
func validatePath(_ url: URL) throws {
    let canonicalURL = url.standardizedFileURL
    let storageURL = AppPaths.storageDirectory.standardizedFileURL
    
    guard canonicalURL.path.hasPrefix(storageURL.path) else {
        throw StorageError.pathTraversal("Path outside storage directory")
    }
}
```

### Safe File Operations
```swift
// Always use FileManager with error handling
let fileManager = FileManager.default

do {
    try fileManager.copyItem(at: sourceURL, to: destURL)
    logger.info("File copied successfully")
} catch {
    logger.error("Copy failed: \(error)")
    throw StorageError.accessDenied("Cannot copy file: \(error.localizedDescription)")
}
```

### Audit Logging
```swift
// Log security-relevant operations
func logFileOperation(operation: String, file: URL, success: Bool) {
    let timestamp = ISO8601DateFormatter().string(from: Date())
    let entry = "\(timestamp) | \(operation) | \(file.lastPathComponent) | \(success ? "✓" : "✗")"
    // Write to audit log...
}
```

---

## Testing Guidelines

### Test Organization
- No automated tests are present yet
- When adding tests, use XCTest under a new `Kafra Desktop Assistant Tests/` target
- Name test files like `FeatureNameTests.swift`
- Organize tests by feature/module

### Test Structure
```swift
import XCTest
@testable import Kafra_Desktop_Assistant

final class MemoServiceTests: XCTestCase {
    var sut: MemoService!
    var mockDatabase: MockModelContext!
    
    override func setUp() {
        super.setUp()
        mockDatabase = MockModelContext()
        sut = MemoService(context: mockDatabase)
    }
    
    override func tearDown() {
        sut = nil
        mockDatabase = nil
        super.tearDown()
    }
    
    // MARK: - Happy Path Tests
    
    func testCreateMemo_ValidContent_SavesSuccessfully() throws {
        // Given
        let content = "Test memo content"
        
        // When
        let memo = try sut.createMemo(content: content)
        
        // Then
        XCTAssertEqual(memo.content, content)
        XCTAssertNotNil(memo.id)
        XCTAssertEqual(mockDatabase.insertedObjects.count, 1)
    }
    
    // MARK: - Edge Case Tests
    
    func testCreateMemo_EmptyContent_ThrowsError() {
        // Given
        let emptyContent = ""
        
        // When/Then
        XCTAssertThrowsError(try sut.createMemo(content: emptyContent)) { error in
            XCTAssertEqual(error as? MemoError, MemoError.emptyContent)
        }
    }
    
    // MARK: - Security Tests
    
    func testValidatePath_PathTraversal_ThrowsError() {
        // Given
        let maliciousPath = URL(fileURLWithPath: "../../etc/passwd")
        
        // When/Then
        XCTAssertThrowsError(try sut.validatePath(maliciousPath)) { error in
            guard case StorageError.pathTraversal = error else {
                XCTFail("Wrong error type")
                return
            }
        }
    }
}
```

### Testing Strategy
- **Unit Tests:** Test individual functions/methods in isolation
- **Integration Tests:** Test component interactions (e.g., SwiftData + Services)
- **Security Tests:** Validate input sanitization and access controls
- **Performance Tests:** Verify animation frame rates, memory usage

### Test Coverage Goals
- Aim for 80%+ code coverage
- 100% coverage for security-critical code (file operations, path validation)
- Test edge cases and error conditions
- Include performance benchmarks for critical paths

---

## Commit & Pull Request Guidelines

### Commit Messages
- Use short, plain-language messages (e.g., "Add memo creation feature")
- Keep messages concise and imperative mood
- Format: `<verb> <what>` (e.g., "Fix path traversal vulnerability")
- Use conventional commits for clarity:
  - `feat:` New feature
  - `fix:` Bug fix
  - `docs:` Documentation only
  - `refactor:` Code restructuring
  - `test:` Adding tests
  - `security:` Security improvements

### Pull Request Requirements
- Include a brief summary of changes
- Add testing notes (or "not run" if untested)
- Include screenshots for UI changes
- Link related documentation updates in `kda-docs/`
- Reference issue numbers (e.g., "Fixes #42")
- Ensure all tests pass
- Run SwiftLint and fix warnings

### Code Review Checklist
- [ ] Code follows Swift style guidelines
- [ ] Functions are small and focused (<50 lines)
- [ ] Security validations present for file operations
- [ ] Error handling is comprehensive
- [ ] Tests added for new functionality
- [ ] Documentation updated (if architecture changes)
- [ ] No hardcoded secrets or credentials
- [ ] Performance acceptable (no obvious bottlenecks)

---

## BMad Method Usage

### Core Configuration
- Core configuration lives in `_bmad/core/config.yaml`
- Generated artifacts should go to `_bmad-output/` (see `output_folder`)
- Use `_bmad/bmm/data/documentation-standards.md` as the style baseline when producing docs

### Best Practices
- Prefer updating BMad configs or module data over editing generated outputs by hand
- If you add BMad workflows or agents, register them in `_bmad/_config/` manifests to keep discovery consistent
- Link BMad outputs to relevant `kda-docs/` sections
- Version control BMad configs, not generated artifacts

---

## Documentation Standards

### Where to Document
- **Architecture decisions:** `kda-docs/explanation/architecture.md`
- **Security considerations:** `kda-docs/explanation/security.md`
- **API reference:** `kda-docs/reference/`
- **Migration guides:** `kda-docs/migration/`
- **Implementation tasks:** `kda-docs/tasks/`

### Documentation Style
- Follow Diataxis framework (Tutorials, How-To, Reference, Explanation)
- Use clear headings and section markers
- Include code examples for complex concepts
- Provide rationale for architectural decisions
- Document known issues and workarounds
- Keep docs up-to-date with code changes

### In-Code Documentation
```swift
// Use /// for public API documentation
/// Validates that the given file path is within the storage directory bounds.
///
/// This function prevents path traversal attacks by ensuring all file operations
/// remain within the designated storage directory.
///
/// - Parameter url: The file URL to validate
/// - Throws: `StorageError.pathTraversal` if path escapes storage directory
/// - Returns: The canonical URL within storage bounds
///
/// - Note: This is a security-critical function. All file operations MUST call this.
public func validatePath(_ url: URL) throws -> URL {
    // Implementation...
}

// Use // for implementation notes
// Check for symbolic links (security risk)
let resolvedURL = url.resolvingSymlinksInPath()
```

---

## Performance Guidelines

### Optimization Priorities
1. **Correctness First:** Never sacrifice correctness for speed
2. **Profile Before Optimizing:** Use Instruments to find actual bottlenecks
3. **Lazy Loading:** Load resources on-demand, not at startup
4. **Efficient Rendering:** Use SwiftUI performance best practices
5. **Memory Management:** Avoid retain cycles, use weak references appropriately

### Performance Targets (from Task 04)
- **Idle RAM usage:** < 50 MB
- **CPU usage (idle):** < 1%
- **CPU usage (animating):** < 5%
- **Launch time:** < 2 seconds
- **UI responsiveness:** 60 FPS minimum

### SwiftUI Performance
```swift
// Use @State and @Binding appropriately
@State private var characterIndex: Int = 0  // View-local state
@Binding var selectedCharacter: Character   // Passed from parent

// Avoid expensive computations in body
var body: some View {
    // Bad: Recomputes every render
    let processedData = expensiveComputation(data)
    
    // Good: Cache with computed property or @State
    Text(cachedProcessedData)
}

// Use lazy loading for lists
List {
    ForEach(items) { item in
        LazyVStack {  // Loads only visible items
            ItemRow(item: item)
        }
    }
}
```

---

## Accessibility Requirements

### Minimum Standards
- All interactive elements must have accessibility labels
- Support keyboard navigation
- Respect system font sizes (Dynamic Type)
- Provide sufficient color contrast
- Include VoiceOver hints for complex interactions

### Implementation
```swift
// Button with accessibility
Button("Save Memo") {
    saveMemo()
}
.accessibilityLabel("Save Memo")
.accessibilityHint("Saves the current memo to your collection")
.keyboardShortcut("s", modifiers: .command)

// Custom view with accessibility
Image("kafra_character")
    .accessibilityLabel("Kafra character mascot")
    .accessibilityHint("Drag to move the mascot around your screen")
    .accessibilityAddTraits(.isImage)
```

---

## Continuous Integration / Deployment

### Pre-Commit Checks (Future)
- [ ] SwiftLint passes with no warnings
- [ ] All tests pass
- [ ] Build succeeds for Debug and Release
- [ ] Code coverage meets threshold (80%)

### Release Process
1. Update version in `Info.plist`
2. Update `CHANGELOG.md`
3. Run full test suite
4. Build Release configuration
5. Code sign with Developer ID
6. Notarize with Apple
7. Create DMG installer (see Task 11)
8. Test on clean macOS system
9. Tag release in git
10. Upload to distribution platform

---

## Security-Critical Code Guidelines

For file operations, user input handling, and system integration, apply heightened scrutiny:

### Input Validation Checklist
- [ ] All external input validated before use
- [ ] File paths checked for traversal attempts
- [ ] File types whitelisted, not blacklisted
- [ ] Size limits enforced
- [ ] Null bytes and control characters stripped
- [ ] User confirmation required for dangerous operations

### File Operation Checklist
- [ ] All paths validated with `validatePath()`
- [ ] Operations stay within storage directory
- [ ] Symbolic links resolved or rejected
- [ ] Error handling covers all failure modes
- [ ] Operations logged for audit trail
- [ ] User permissions checked before access

### Security Review Required For
- All file system operations
- User input processing
- External data parsing
- Privilege escalation (e.g., autorun setup)
- Cryptographic operations (if any)
- Network requests (if added)

---

## Quick Reference

### Essential Reading (New Developers)
1. **Start here:** `kda-docs/explanation/architecture.md` — System context
2. **Security:** `kda-docs/explanation/security.md` — Risk considerations
3. **Tasks:** `kda-docs/tasks/TASK-REVIEW-SUMMARY.md` — Implementation roadmap
4. **Migration:** `kda-docs/migration/overview.md` — Windows to macOS porting

### Code Templates

**New Feature Service:**
```swift
// Services/FeatureNameService.swift
import Foundation

final class FeatureNameService {
    // MARK: - Properties
    private let dependency: DependencyType
    
    // MARK: - Initialization
    init(dependency: DependencyType) {
        self.dependency = dependency
    }
    
    // MARK: - Public Methods
    func performAction() throws {
        // Implementation
    }
}
```

**New SwiftData Model:**
```swift
// Models/ModelName.swift
import Foundation
import SwiftData

@Model
final class ModelName {
    var id: UUID
    var createdAt: Date
    
    init() {
        self.id = UUID()
        self.createdAt = Date()
    }
}
```

**New SwiftUI View:**
```swift
// Views/FeatureName/ViewName.swift
import SwiftUI

struct ViewName: View {
    // MARK: - State
    @State private var localState: String = ""
    
    // MARK: - Body
    var body: some View {
        VStack {
            // View content
        }
    }
}

// MARK: - Preview
#Preview {
    ViewName()
}
```

---

## Troubleshooting

### Common Issues

**Build fails with "Cannot find type"**
- Ensure proper import statements
- Check target membership of files
- Clean build folder: `Cmd+Shift+K`

**Build fails with ObservableObject/@Published errors or "missing import of Combine"**
- Add `import Combine` to any file declaring `ObservableObject` or `@Published`
- SwiftUI no longer re-exports Combine in newer toolchains

**Build fails with Logger/AppLogger errors or "missing import of os"**
- Add `import os` to any file that calls `Logger` methods

**SwiftData crashes on launch**
- Check model schema changes
- Verify ModelContainer configuration
- Consider migration if schema changed

**Performance issues**
- Profile with Instruments (Time Profiler)
- Check for retain cycles (Leaks instrument)
- Verify view updates are minimal

**Code signing fails**
- Verify Apple Developer account is active
- Check certificate expiration
- Ensure provisioning profile is current

---

**Document Version:** 2.0  
**Last Updated:** 2026-01-21  
**Maintained By:** DevContext Team

**Key Changes from v1.0:**
- Added comprehensive coding standards and principles
- Included security guidelines and checklists
- Expanded testing strategy and examples
- Added performance targets and optimization guidance
- Included accessibility requirements
- Enhanced with DDD and SOLID principles
- Added code templates and troubleshooting section

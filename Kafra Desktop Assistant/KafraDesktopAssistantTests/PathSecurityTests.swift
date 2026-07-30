import XCTest
@testable import Kafra_Desktop_Assistant

final class PathSecurityTests: XCTestCase {

    // MARK: - sanitizeFileName

    func testStripsPathSeparators() {
        XCTAssertEqual(PathSecurity.sanitizeFileName("a/b\\c.txt"), "a-b-c.txt")
    }

    func testStripsControlCharactersAndNul() {
        let input = "na\u{0007}me\u{0000}.txt"
        let out = PathSecurity.sanitizeFileName(input)
        XCTAssertEqual(out, "name.txt")
    }

    func testTrimsLeadingDotsToBlockHiddenFiles() {
        XCTAssertEqual(PathSecurity.sanitizeFileName("...secret"), "secret")
        XCTAssertEqual(PathSecurity.sanitizeFileName(".env"), "env")
    }

    func testCollapsesWhitespaceRuns() {
        XCTAssertEqual(PathSecurity.sanitizeFileName("a    b   c.txt"), "a b c.txt")
    }

    func testTrimsSurroundingSpaces() {
        XCTAssertEqual(PathSecurity.sanitizeFileName("   hello.txt   "), "hello.txt")
    }

    func testEnforcesByteLengthCeilingPreservingExtension() {
        let longBase = String(repeating: "x", count: 400)
        let out = PathSecurity.sanitizeFileName(longBase + ".txt")
        XCTAssertLessThanOrEqual(out.utf8.count, 255)
        XCTAssertTrue(out.hasSuffix(".txt"))
    }

    // MARK: - containmentViolation

    private var storage: URL {
        URL(fileURLWithPath: "/tmp/kda-storage-root", isDirectory: true)
    }

    func testAllowsFileDirectlyInsideStorage() {
        let url = storage.appendingPathComponent("note.txt")
        XCTAssertNil(PathSecurity.containmentViolation(for: url, within: storage))
    }

    func testAllowsNestedDescendant() {
        let url = storage.appendingPathComponent("sub/dir/note.txt")
        XCTAssertNil(PathSecurity.containmentViolation(for: url, within: storage))
    }

    func testAllowsStorageRootItself() {
        XCTAssertNil(PathSecurity.containmentViolation(for: storage, within: storage))
    }

    func testRejectsSiblingOutsideStorage() {
        let url = URL(fileURLWithPath: "/tmp/kda-storage-root-evil/note.txt")
        XCTAssertEqual(PathSecurity.containmentViolation(for: url, within: storage), .outside)
    }

    func testRejectsParentEscape() {
        let url = URL(fileURLWithPath: "/tmp/other/note.txt")
        XCTAssertEqual(PathSecurity.containmentViolation(for: url, within: storage), .outside)
    }
}

final class FileOpenSafetyTests: XCTestCase {
    func testSafeTypes() {
        XCTAssertEqual(FileOpenSafety.assess(URL(fileURLWithPath: "/x/a.pdf")), .safe)
        XCTAssertEqual(FileOpenSafety.assess(URL(fileURLWithPath: "/x/a.PNG")), .safe)
    }

    func testDangerousTypes() {
        XCTAssertEqual(FileOpenSafety.assess(URL(fileURLWithPath: "/x/a.sh")), .dangerous)
        XCTAssertEqual(FileOpenSafety.assess(URL(fileURLWithPath: "/x/a.app")), .dangerous)
    }

    func testUnknownTypeIsCaution() {
        XCTAssertEqual(FileOpenSafety.assess(URL(fileURLWithPath: "/x/a.xyz")), .caution)
    }
}

final class DropValidatorTypeTests: XCTestCase {
    func testForbiddenExtensionThrows() {
        let url = URL(fileURLWithPath: "/x/evil.command")
        XCTAssertThrowsError(try DropValidator.validateFileType(url))
    }

    func testOrdinaryExtensionPasses() {
        let url = URL(fileURLWithPath: "/x/photo.jpg")
        XCTAssertNoThrow(try DropValidator.validateFileType(url))
    }
}

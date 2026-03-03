import XCTest
@testable import DooCore

final class VersionTests: XCTestCase {
    func testVersionMatchesSemver() {
        let semver = #/^\d+\.\d+\.\d+$/#
        XCTAssertNotNil(dooVersion.firstMatch(of: semver), "dooVersion '\(dooVersion)' is not a valid semver string")
    }
}

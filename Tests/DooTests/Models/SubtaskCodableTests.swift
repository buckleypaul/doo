import Foundation
import XCTest
@testable import DooKit

final class SubtaskCodableTests: XCTestCase {

    func testRoundTripEncodeDecode() throws {
        let subtask = Subtask(title: "Do the thing", completed: true)
        let data = try JSONEncoder().encode(subtask)
        let decoded = try JSONDecoder().decode(Subtask.self, from: data)
        XCTAssertEqual(decoded.id, subtask.id)
        XCTAssertEqual(decoded.title, "Do the thing")
        XCTAssertTrue(decoded.completed)
    }

    func testDefaultCompletedIsFalse() {
        let subtask = Subtask(title: "New subtask")
        XCTAssertFalse(subtask.completed)
    }

    func testEquatable() {
        let id = UUID()
        let a = Subtask(id: id, title: "Same", completed: false)
        let b = Subtask(id: id, title: "Same", completed: false)
        XCTAssertEqual(a, b)

        let c = Subtask(id: id, title: "Same", completed: true)
        XCTAssertNotEqual(a, c)
    }
}

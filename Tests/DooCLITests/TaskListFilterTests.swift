import Foundation
import XCTest
@testable import DooCLILib
@testable import DooCore

final class TaskListFilterTests: XCTestCase {

    // MARK: - Helpers

    /// Parse a TaskListCommand from CLI-style arguments and call buildFilterState().
    private func makeFilterState(args: [String]) throws -> FilterState {
        let cmd = try TaskListCommand.parse(args)
        return try cmd.buildFilterState()
    }

    // MARK: - Tests

    func testExactPriority() throws {
        let state = try makeFilterState(args: ["--priority", "3"])
        XCTAssertEqual(state.selectedPriorities, [3])
    }

    func testMinPriorityAlone() throws {
        let state = try makeFilterState(args: ["--min-priority", "2"])
        XCTAssertEqual(state.selectedPriorities, Set(2...5))
    }

    func testMaxPriorityAlone() throws {
        let state = try makeFilterState(args: ["--max-priority", "3"])
        XCTAssertEqual(state.selectedPriorities, Set(1...3))
    }

    func testMinAndMaxPriority() throws {
        let state = try makeFilterState(args: ["--min-priority", "2", "--max-priority", "4"])
        XCTAssertEqual(state.selectedPriorities, Set(2...4))
    }

    func testNoPriorityFlagsProducesEmptySet() throws {
        let state = try makeFilterState(args: [])
        XCTAssertEqual(state.selectedPriorities, [])
    }

    func testInvertedRangeThrows() {
        XCTAssertThrowsError(
            try makeFilterState(args: ["--min-priority", "5", "--max-priority", "1"])
        ) { error in
            XCTAssertNotNil(error)
        }
    }

    func testPriorityOutOfRangeLowThrows() {
        XCTAssertThrowsError(try makeFilterState(args: ["--priority", "0"]))
    }

    func testPriorityOutOfRangeHighThrows() {
        XCTAssertThrowsError(try makeFilterState(args: ["--priority", "6"]))
    }

    func testMinPriorityOutOfRangeThrows() {
        XCTAssertThrowsError(try makeFilterState(args: ["--min-priority", "0"]))
    }

    func testMaxPriorityOutOfRangeThrows() {
        XCTAssertThrowsError(try makeFilterState(args: ["--max-priority", "6"]))
    }

    func testStatusFilter() throws {
        let state = try makeFilterState(args: ["--status", "backlog"])
        XCTAssertEqual(state.selectedStatuses, [.backlog])
    }

    func testMultipleStatusFilters() throws {
        let state = try makeFilterState(args: ["--status", "backlog", "--status", "inprogress"])
        XCTAssertEqual(state.selectedStatuses, [.backlog, .inProgress])
    }

    func testInvalidStatusThrows() {
        XCTAssertThrowsError(try makeFilterState(args: ["--status", "bogus"]))
    }

    func testNoStatusFlagsProducesEmptySet() throws {
        let state = try makeFilterState(args: [])
        XCTAssertEqual(state.selectedStatuses, [])
    }
}

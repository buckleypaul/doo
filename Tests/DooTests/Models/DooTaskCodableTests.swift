import Foundation
import XCTest
@testable import DooKit

final class DooTaskCodableTests: XCTestCase {

    private func roundTrip(_ task: DooTask) throws -> DooTask {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(task)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(DooTask.self, from: data)
    }

    func testRoundTripWithAllFields() throws {
        let task = sampleTask(
            title: "Test",
            description: "A description",
            notes: "Some notes",
            priority: 1,
            tags: ["work", "urgent"],
            dueDate: dateOnly("2026-06-15"),
            dateCompleted: Date()
        )
        let decoded = try roundTrip(task)
        XCTAssertEqual(decoded.id, task.id)
        XCTAssertEqual(decoded.title, task.title)
        XCTAssertEqual(decoded.description, task.description)
        XCTAssertEqual(decoded.notes, task.notes)
        XCTAssertEqual(decoded.priority, task.priority)
        XCTAssertEqual(decoded.tags, task.tags)
        XCTAssertEqual(decoded.dueDate, task.dueDate)
        XCTAssertNotNil(decoded.dateCompleted)
    }

    func testRoundTripMinimalFields() throws {
        let task = sampleTask(title: "Minimal")
        let decoded = try roundTrip(task)
        XCTAssertEqual(decoded.title, "Minimal")
        XCTAssertNil(decoded.description)
        XCTAssertNil(decoded.notes)
        XCTAssertEqual(decoded.priority, 2)
        XCTAssertTrue(decoded.tags.isEmpty)
        XCTAssertNil(decoded.dueDate)
        XCTAssertNil(decoded.dateCompleted)
    }

    func testDueDateEncodesAsDateOnlyString() throws {
        let task = sampleTask(title: "Due", dueDate: dateOnly("2026-03-10"))
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(task)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let dueDateValue = json["dueDate"] as? String
        XCTAssertEqual(dueDateValue, "2026-03-10")
    }

    func testDueDateNilOmitsKey() throws {
        let task = sampleTask(title: "No due", dueDate: nil)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(task)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        // encodeIfPresent with nil omits the key entirely
        let hasDueDate = json.keys.contains("dueDate")
        XCTAssertFalse(hasDueDate || json["dueDate"] is NSNull,
            "dueDate should be absent or null when nil")
    }

    func testDateAddedEncodesAsISO8601() throws {
        let task = sampleTask(title: "Added", dateAdded: iso8601("2026-03-01T10:00:00Z"))
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(task)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let dateAddedValue = json["dateAdded"] as? String
        XCTAssertTrue(dateAddedValue?.contains("2026-03-01") == true)
    }

    func testDecodeFromExternalJSON() throws {
        let json = """
        {
            "id": "550E8400-E29B-41D4-A716-446655440000",
            "title": "Buy milk",
            "priority": 2,
            "tags": ["grocery"],
            "dueDate": "2026-03-10",
            "dateAdded": "2026-03-01T10:00:00Z",
            "dateCompleted": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let task = try decoder.decode(DooTask.self, from: json)

        XCTAssertEqual(task.title, "Buy milk")
        XCTAssertEqual(task.priority, 2)
        XCTAssertEqual(task.tags, ["grocery"])
        XCTAssertEqual(task.dueDate, dateOnly("2026-03-10"))
        XCTAssertNil(task.dateCompleted)
    }

    func testDecodeWithMissingOptionalFieldsUsesDefaults() throws {
        let json = """
        {
            "id": "550E8400-E29B-41D4-A716-446655440000",
            "title": "Minimal task",
            "dateAdded": "2026-03-01T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let task = try decoder.decode(DooTask.self, from: json)

        XCTAssertEqual(task.priority, 2)
        XCTAssertTrue(task.tags.isEmpty)
        XCTAssertNil(task.description)
        XCTAssertNil(task.notes)
    }

    func testDecodeLegacyPriorityClampedToTwo() throws {
        let json = """
        {
            "id": "550E8400-E29B-41D4-A716-446655440000",
            "title": "Old task",
            "priority": 5,
            "dateAdded": "2026-03-01T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let task = try decoder.decode(DooTask.self, from: json)

        XCTAssertEqual(task.priority, 2)
    }

    func testTaskFileRoundTrip() throws {
        let tasks = [
            sampleTask(title: "First"),
            sampleTask(title: "Second", priority: 1),
        ]
        let taskFile = TaskFile(tasks: tasks)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(taskFile)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(TaskFile.self, from: data)

        XCTAssertEqual(decoded.tasks.count, 2)
        XCTAssertEqual(decoded.tasks[0].title, "First")
        XCTAssertEqual(decoded.tasks[1].title, "Second")
        XCTAssertEqual(decoded.tasks[1].priority, 1)
    }

    func testDueDateSortKeyReturnsDueDateWhenSet() {
        let due = dateOnly("2026-06-01")
        let task = sampleTask(title: "T", dueDate: due)
        XCTAssertEqual(task.dueDateSortKey, due)
    }

    func testDueDateSortKeyReturnsDistantFutureWhenNil() {
        let task = sampleTask(title: "T", dueDate: nil)
        XCTAssertEqual(task.dueDateSortKey, .distantFuture)
    }

    func testDateCompletedSortKeyReturnsDateCompletedWhenSet() {
        let completed = iso8601("2026-03-01T10:00:00Z")
        let task = sampleTask(title: "T", dateCompleted: completed)
        XCTAssertEqual(task.dateCompletedSortKey, completed)
    }

    func testDateCompletedSortKeyReturnsDistantPastWhenNil() {
        let task = sampleTask(title: "T", dateCompleted: nil)
        XCTAssertEqual(task.dateCompletedSortKey, .distantPast)
    }
}

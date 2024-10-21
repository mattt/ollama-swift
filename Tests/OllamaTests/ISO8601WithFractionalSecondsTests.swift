import XCTest

@testable import Ollama

let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
    return decoder
}()

let utcCalendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

final class JSONDecoderExtensionsTests: XCTestCase {
    func testDecodeISO8601WithFractionalSeconds() throws {
        let json = #""2023-04-15T12:30:45.123Z""#
        let result = try decoder.decode(Date.self, from: json.data(using: .utf8)!)

        let components = utcCalendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second, .nanosecond], from: result)

        XCTAssertEqual(components.year, 2023)
        XCTAssertEqual(components.month, 4)
        XCTAssertEqual(components.day, 15)
        XCTAssertEqual(components.hour, 12)
        XCTAssertEqual(components.minute, 30)
        XCTAssertEqual(components.second, 45)
        XCTAssertEqual(components.nanosecond!, 123_000_000, accuracy: 100)
    }

    func testDecodeISO8601WithoutFractionalSeconds() throws {
        let json = #""2023-04-15T12:30:45Z""#
        let result = try decoder.decode(Date.self, from: json.data(using: .utf8)!)

        let components = utcCalendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second, .nanosecond], from: result)

        XCTAssertEqual(components.year, 2023)
        XCTAssertEqual(components.month, 4)
        XCTAssertEqual(components.day, 15)
        XCTAssertEqual(components.hour, 12)
        XCTAssertEqual(components.minute, 30)
        XCTAssertEqual(components.second, 45)
        XCTAssertEqual(components.nanosecond, 0)
    }

    func testDecodeInvalidDate() {
        let json = #""invalid""#
        XCTAssertThrowsError(try decoder.decode(Date.self, from: json.data(using: .utf8)!)) {
            error in
            guard case DecodingError.dataCorrupted(let context) = error else {
                XCTFail("Expected DecodingError.dataCorrupted, got \(error)")
                return
            }
            XCTAssertEqual(context.debugDescription, "Invalid date: invalid")
        }
    }
}

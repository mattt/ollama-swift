import Foundation
import Testing

struct ISO8601WithFractionalSecondsTests {
    struct TestContainer: Codable {
        let date: Date
    }
    
    let calendar: Calendar
    let decoder: JSONDecoder
    let encoder: JSONEncoder

    init() {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        calendar = utc

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    @Test
    func testDecodingISO8601WithFractionalSeconds() throws {
        let json = #"{"date": "2023-01-01T12:34:56.789Z"}"#
        let container = try decoder.decode(TestContainer.self, from: json.data(using: .utf8)!)

        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second, .nanosecond], from: container.date)

        #expect(components.year == 2023)
        #expect(components.month == 1)
        #expect(components.day == 1)
        #expect(components.hour == 12)
        #expect(components.minute == 34)
        #expect(components.second == 56)
        #expect(abs((components.nanosecond ?? 0) - 789_000_000) < 1_000)
    }

    @Test
    func testDecodingISO8601WithoutFractionalSeconds() throws {
        let json = #"{"date": "2023-04-15T12:30:45Z"}"#
        let container = try decoder.decode(TestContainer.self, from: json.data(using: .utf8)!)

        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second, .nanosecond], from: container.date)

        #expect(components.year == 2023)
        #expect(components.month == 4)
        #expect(components.day == 15)
        #expect(components.hour == 12)
        #expect(components.minute == 30)
        #expect(components.second == 45)
        #expect(components.nanosecond == 0)
    }

    @Test
    func testDecodeInvalidDate() throws {
        let json = #""invalid""#

        do {
            _ = try decoder.decode(Date.self, from: json.data(using: .utf8)!)
            Issue.record("Expected DecodingError.dataCorrupted")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.debugDescription == "Invalid date: invalid")
        } catch {
            Issue.record("Expected DecodingError.dataCorrupted, got \(error)")
        }
    }
}

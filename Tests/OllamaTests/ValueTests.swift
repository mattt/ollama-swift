import XCTest

@testable import Ollama

final class ValueTests: XCTestCase {
    func testBoolConversion() {
        // Strict mode
        XCTAssertEqual(Bool(Value.bool(true)), true)
        XCTAssertEqual(Bool(Value.bool(false)), false)
        XCTAssertNil(Bool(Value.int(1)))
        XCTAssertNil(Bool(Value.string("true")))

        // Non-strict mode - numbers
        XCTAssertEqual(Bool(Value.int(1), strict: false), true)
        XCTAssertEqual(Bool(Value.int(0), strict: false), false)
        XCTAssertNil(Bool(Value.int(2), strict: false))

        XCTAssertEqual(Bool(Value.double(1.0), strict: false), true)
        XCTAssertEqual(Bool(Value.double(0.0), strict: false), false)
        XCTAssertNil(Bool(Value.double(0.5), strict: false))

        // Non-strict mode - lowercase strings only
        XCTAssertEqual(Bool(Value.string("true"), strict: false), true)
        XCTAssertEqual(Bool(Value.string("t"), strict: false), true)
        XCTAssertEqual(Bool(Value.string("yes"), strict: false), true)
        XCTAssertEqual(Bool(Value.string("y"), strict: false), true)
        XCTAssertEqual(Bool(Value.string("on"), strict: false), true)
        XCTAssertEqual(Bool(Value.string("1"), strict: false), true)

        XCTAssertEqual(Bool(Value.string("false"), strict: false), false)
        XCTAssertEqual(Bool(Value.string("f"), strict: false), false)
        XCTAssertEqual(Bool(Value.string("no"), strict: false), false)
        XCTAssertEqual(Bool(Value.string("n"), strict: false), false)
        XCTAssertEqual(Bool(Value.string("off"), strict: false), false)
        XCTAssertEqual(Bool(Value.string("0"), strict: false), false)

        // Non-strict mode - uppercase should fail
        XCTAssertNil(Bool(Value.string("TRUE"), strict: false))
        XCTAssertNil(Bool(Value.string("YES"), strict: false))
        XCTAssertNil(Bool(Value.string("False"), strict: false))
        XCTAssertNil(Bool(Value.string("No"), strict: false))
    }

    func testIntConversions() throws {
        // Strict mode
        XCTAssertEqual(Int(Value.int(42), strict: true), 42)
        XCTAssertNil(Int(Value.double(42.0), strict: true))
        XCTAssertNil(Int(Value.string("42"), strict: true))

        // Non-strict mode
        XCTAssertEqual(Int(Value.double(42.0), strict: false), 42)
        XCTAssertNil(Int(Value.double(42.5), strict: false))
        XCTAssertEqual(Int(Value.string("42"), strict: false), 42)
        XCTAssertNil(Int(Value.string("42.5"), strict: false))
        XCTAssertNil(Int(Value.string("invalid"), strict: false))
    }

    func testDoubleConversions() throws {
        // Strict mode
        XCTAssertEqual(Double(Value.double(42.5), strict: true), 42.5)
        XCTAssertEqual(Double(Value.int(42), strict: true), 42.0)
        XCTAssertNil(Double(Value.string("42.5"), strict: true))

        // Non-strict mode
        XCTAssertEqual(Double(Value.string("42.5"), strict: false), 42.5)
        XCTAssertEqual(Double(Value.string("42"), strict: false), 42.0)
        XCTAssertNil(Double(Value.string("invalid"), strict: false))
    }

    func testStringConversions() throws {
        // Strict mode
        XCTAssertEqual(String(Value.string("hello"), strict: true), "hello")
        XCTAssertNil(String(Value.int(42), strict: true))
        XCTAssertNil(String(Value.double(42.5), strict: true))
        XCTAssertNil(String(Value.bool(true), strict: true))

        // Non-strict mode
        XCTAssertEqual(String(Value.int(42), strict: false), "42")
        XCTAssertEqual(String(Value.double(42.5), strict: false), "42.5")
        XCTAssertEqual(String(Value.bool(true), strict: false), "true")
        XCTAssertEqual(String(Value.bool(false), strict: false), "false")
    }

    func testEdgeCases() throws {
        // Test null values
        XCTAssertNil(Bool(Value.null))
        XCTAssertNil(Int(Value.null))
        XCTAssertNil(Double(Value.null))
        XCTAssertNil(String(Value.null))

        // Test array values
        XCTAssertNil(Bool(Value.array([.bool(true)])))
        XCTAssertNil(Int(Value.array([.int(42)])))
        XCTAssertNil(Double(Value.array([.double(42.5)])))
        XCTAssertNil(String(Value.array([.string("hello")])))

        // Test object values
        XCTAssertNil(Bool(Value.object(["key": .bool(true)])))
        XCTAssertNil(Int(Value.object(["key": .int(42)])))
        XCTAssertNil(Double(Value.object(["key": .double(42.5)])))
        XCTAssertNil(String(Value.object(["key": .string("hello")])))
    }
}

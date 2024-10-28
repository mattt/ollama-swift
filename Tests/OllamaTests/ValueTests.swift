import Testing

@testable import Ollama

struct ValueTests {
    @Suite("Bool value conversions")
    struct BoolTests {
        @Test("Bool conversion in strict mode")
        func strict() {
            let cases = [
                (Value.bool(true), true),
                (Value.bool(false), false),
                (Value.int(1), nil),
                (Value.string("true"), nil),
            ]

            for (value, expected) in cases {
                #expect(Bool(value) == expected)
            }
        }

        @Suite("Bool conversion in non-strict mode")
        struct NonStrict {
            @Test("Bool conversion from numbers")
            func numbers() {
                let cases = [
                    (Value.int(1), true),
                    (Value.int(0), false),
                    (Value.int(2), nil),
                    (Value.double(1.0), true),
                    (Value.double(0.0), false),
                    (Value.double(0.5), nil),
                ]

                for (value, expected) in cases {
                    #expect(Bool(value, strict: false) == expected)
                }
            }

            @Test("Bool conversion from strings")
            func strings() {
                let cases = [
                    // True cases
                    (Value.string("true"), true),
                    (Value.string("t"), true),
                    (Value.string("yes"), true),
                    (Value.string("y"), true),
                    (Value.string("on"), true),
                    (Value.string("1"), true),

                    // False cases
                    (Value.string("false"), false),
                    (Value.string("f"), false),
                    (Value.string("no"), false),
                    (Value.string("n"), false),
                    (Value.string("off"), false),
                    (Value.string("0"), false),

                    // Nil cases
                    (Value.string("TRUE"), nil),
                    (Value.string("YES"), nil),
                    (Value.string("False"), nil),
                    (Value.string("No"), nil),
                    (Value.string("invalid"), nil),
                ]

                for (value, expected) in cases {
                    #expect(Bool(value, strict: false) == expected)
                }
            }
        }
    }

    @Suite("Int value conversions")
    struct IntTests {
        @Test("Int conversion in strict mode")
        func strict() {
            let cases = [
                (Value.int(42), 42),
                (Value.double(42.0), nil),
                (Value.string("42"), nil),
            ]

            for (value, expected) in cases {
                #expect(Int(value, strict: true) == expected)
            }
        }

        @Test("Int conversion in non-strict mode")
        func nonStrict() {
            let cases = [
                (Value.double(42.0), 42),
                (Value.double(42.5), nil),
                (Value.string("42"), 42),
                (Value.string("42.5"), nil),
                (Value.string("invalid"), nil),
            ]

            for (value, expected) in cases {
                #expect(Int(value, strict: false) == expected)
            }
        }
    }

    @Suite("Double value conversions")
    struct DoubleTests {
        @Test("Double conversion in strict mode")
        func strict() {
            let cases = [
                (Value.double(42.5), 42.5),
                (Value.int(42), 42.0),
                (Value.string("42.5"), nil),
            ]

            for (value, expected) in cases {
                #expect(Double(value, strict: true) == expected)
            }
        }

        @Test("Double conversion in non-strict mode")
        func nonStrict() {
            let cases = [
                (Value.string("42.5"), 42.5),
                (Value.string("42"), 42.0),
                (Value.string("invalid"), nil),
            ]

            for (value, expected) in cases {
                #expect(Double(value, strict: false) == expected)
            }
        }
    }

    @Suite("String value conversions")
    struct StringTests {
        @Test("String conversion in strict mode")
        func strict() {
            let cases = [
                (Value.string("hello"), "hello"),
                (Value.int(42), nil),
                (Value.double(42.5), nil),
                (Value.bool(true), nil),
            ]

            for (value, expected) in cases {
                #expect(String(value, strict: true) == expected)
            }
        }

        @Test("String conversion in non-strict mode")
        func nonStrict() {
            let cases = [
                (Value.int(42), "42"),
                (Value.double(42.5), "42.5"),
                (Value.bool(true), "true"),
                (Value.bool(false), "false"),
            ]

            for (value, expected) in cases {
                #expect(String(value, strict: false) == expected)
            }
        }
    }

    @Test("Null value conversions")
    func nullValues() {
        #expect(Bool(Value.null) == nil)
        #expect(Int(Value.null) == nil)
        #expect(Double(Value.null) == nil)
        #expect(String(Value.null) == nil)
    }

    @Test("Array value conversions")
    func arrayValues() {
        let array = Value.array([.bool(true)])
        #expect(Bool(array) == nil)
        #expect(Int(array) == nil)
        #expect(Double(array) == nil)
        #expect(String(array) == nil)
    }

    @Test("Object value conversions")
    func objectValues() {
        let object = Value.object(["key": .bool(true)])
        #expect(Bool(object) == nil)
        #expect(Int(object) == nil)
        #expect(Double(object) == nil)
        #expect(String(object) == nil)
    }
}

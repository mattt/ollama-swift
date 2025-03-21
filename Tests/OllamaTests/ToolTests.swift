import Foundation
import Testing

@testable import Ollama

@Suite
struct ToolTests {
    @Test
    func verifyToolSchema() throws {
        guard case let .object(schema) = hexColorTool.schemaValue else {
            Issue.record("Schema is not an object")
            return
        }

        // Verify basic schema structure
        #expect(schema["type"]?.stringValue == "function")

        guard let function = schema["function"]?.objectValue else {
            Issue.record("Missing or invalid function object in schema")
            return
        }

        #expect(function["name"]?.stringValue == "rgb_to_hex")
        #expect(function["description"]?.stringValue != nil)

        guard let parameters = function["parameters"]?.objectValue else {
            Issue.record("Missing or invalid parameters in schema")
            return
        }

        #expect(parameters["type"]?.stringValue == "object")

        guard let properties = parameters["properties"]?.objectValue else {
            Issue.record("Missing or invalid properties in parameters")
            return
        }
        #expect(properties.count == 3, "Expected 3 parameters, got \(properties.count)")

        // Check required parameter definitions and constraints
        for (key, value) in properties {
            guard let paramObj = value.objectValue else {
                Issue.record("Missing parameter object for \(key)")
                continue
            }

            #expect(paramObj["type"]?.stringValue == "number", "Invalid type for \(key)")
            #expect(paramObj["description"]?.stringValue != nil, "Missing description for \(key)")
            #expect(paramObj["minimum"]?.doubleValue == 0, "Invalid minimum for \(key)")
            #expect(paramObj["maximum"]?.doubleValue == 1, "Invalid maximum for \(key)")
        }

        #expect(
            parameters["required"]?.arrayValue == ["red", "green", "blue"],
            "Expected 3 required parameters, got \(parameters["required"]?.arrayValue ?? [])"
        )
    }

    @Test
    func testInputSerialization() throws {
        let input = HexColorInput(red: 0.5, green: 0.7, blue: 0.9)

        // Test JSON encoding
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(input)

        // Test JSON decoding
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(HexColorInput.self, from: encoded)

        // Verify roundtrip
        #expect(decoded.red == input.red)
        #expect(decoded.green == input.green)
        #expect(decoded.blue == input.blue)
    }

    @Test
    func testColorConversion() async throws {
        // Test various color combinations
        let testCases = [
            (red: 1.0, green: 0.0, blue: 0.0, expected: "#FF0000"),  // Red
            (red: 0.0, green: 1.0, blue: 0.0, expected: "#00FF00"),  // Green
            (red: 0.0, green: 0.0, blue: 1.0, expected: "#0000FF"),  // Blue
            (red: 0.0, green: 0.0, blue: 0.0, expected: "#000000"),  // Black
            (red: 1.0, green: 1.0, blue: 1.0, expected: "#FFFFFF"),  // White
            (red: 0.5, green: 0.5, blue: 0.5, expected: "#808080"),  // Gray
        ]

        for testCase in testCases {
            let input = HexColorInput(
                red: testCase.red,
                green: testCase.green,
                blue: testCase.blue
            )
            let result = try await hexColorTool(input)
            #expect(result == testCase.expected, "Failed conversion for \(testCase)")
        }
    }

    @Test
    func testBackwardsCompatibilityWithFullSchema() throws {
        // Define a simple struct for testing
        struct TestInput: Codable {
            let query: String
        }
        
        // Create a tool using the old style (full schema in parameters)
        let oldStyleTool = Tool(
            name: "test_tool",
            description: "A test tool",
            parameters: [
                "type": .string("object"),
                "properties": .object([
                    "query": .object([
                        "type": .string("string"),
                        "description": .string("The search query"),
                    ])
                ]),
                "required": .array([.string("query")]),
            ]
        ) { (input: TestInput) async throws -> String in
            return "result"
        }

        // Create the same tool using the new style
        let newStyleTool = Tool(
            name: "test_tool",
            description: "A test tool",
            parameters: [
                "query": .object([
                    "type": .string("string"),
                    "description": .string("The search query"),
                ])
            ],
            required: ["query"]
        ) { (input: TestInput) async throws -> String in
            return "result"
        }

        // Verify both tools generate the same schema
        guard case let .object(oldSchema) = oldStyleTool.schemaValue,
            case let .object(newSchema) = newStyleTool.schemaValue,
            let oldFunction = oldSchema["function"]?.objectValue,
            let newFunction = newSchema["function"]?.objectValue,
            let oldParameters = oldFunction["parameters"]?.objectValue,
            let newParameters = newFunction["parameters"]?.objectValue,
            let oldProperties = oldParameters["properties"]?.objectValue,
            let newProperties = newParameters["properties"]?.objectValue,
            let oldRequired = oldParameters["required"]?.arrayValue,
            let newRequired = newParameters["required"]?.arrayValue
        else {
            Issue.record("Invalid schema structure")
            return
        }

        // Compare the properties
        #expect(oldProperties.count == newProperties.count)
        #expect(
            oldProperties["query"]?.objectValue?["type"]
                == newProperties["query"]?.objectValue?["type"])
        #expect(
            oldProperties["query"]?.objectValue?["description"]
                == newProperties["query"]?.objectValue?["description"])

        // Compare the required fields
        #expect(oldRequired.count == newRequired.count)
        #expect(oldRequired[0] == newRequired[0])
    }

    @Test
    func testBackwardsCompatibilityWithRequiredField() throws {
        // Define a simple struct for testing
        struct TestInput: Codable {
            let query: String
        }

        // Create a tool with a full schema but no explicit required parameter
        let toolWithImplicitRequired = Tool(
            name: "test_tool",
            description: "A test tool",
            parameters: [
                "type": .string("object"),
                "properties": .object([
                    "query": .object([
                        "type": .string("string"),
                        "description": .string("The search query"),
                    ])
                ]),
                "required": .array([.string("query")]),
            ]
        ) { (input: TestInput) async throws -> String in
            return "result"
        }

        // Create a tool with a full schema and an explicit required parameter (which should override)
        let toolWithExplicitRequired = Tool(
            name: "test_tool",
            description: "A test tool",
            parameters: [
                "type": .string("object"),
                "properties": .object([
                    "query": .object([
                        "type": .string("string"),
                        "description": .string("The search query"),
                    ])
                ]),
                "required": .array([.string("query")]),  // This should be ignored
            ],
            required: ["differentField"]  // This should take precedence
        ) { (input: TestInput) async throws -> String in
            return "result"
        }

        // Verify the required fields are correctly handled
        guard case let .object(implicitSchema) = toolWithImplicitRequired.schemaValue,
            case let .object(explicitSchema) = toolWithExplicitRequired.schemaValue,
            let implicitFunction = implicitSchema["function"]?.objectValue,
            let explicitFunction = explicitSchema["function"]?.objectValue,
            let implicitParameters = implicitFunction["parameters"]?.objectValue,
            let explicitParameters = explicitFunction["parameters"]?.objectValue,
            let implicitRequired = implicitParameters["required"]?.arrayValue,
            let explicitRequired = explicitParameters["required"]?.arrayValue
        else {
            Issue.record("Invalid schema structure")
            return
        }

        // For implicit required from schema, we should see "query"
        #expect(implicitRequired.count == 1)
        #expect(implicitRequired[0].stringValue == "query")

        // For explicit required parameter, we should see "differentField"
        #expect(explicitRequired.count == 1)
        #expect(explicitRequired[0].stringValue == "differentField")
    }
}

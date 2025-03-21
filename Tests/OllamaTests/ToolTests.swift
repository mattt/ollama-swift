import Foundation
import JSONSchema
import Testing

@testable import Ollama

@Suite
struct ToolTests {
    @Test
    func usage() async throws {
        let input = HexColorInput(red: 1.0, green: 0.0, blue: 0.0)
        let result = try await hexColorTool(input)
        #expect(result == "#FF0000")
    }

    @Test
    func verifyToolSchema() throws {
        #expect(hexColorTool.name == "rgb_to_hex")
        #expect(hexColorTool.description != nil)

        // Verify basic schema structure
        let schema = hexColorTool.inputSchema

        // Convert the schema to a dictionary to access its properties
        let schemaDict =
            try JSONSerialization.jsonObject(
                with: JSONEncoder().encode(schema)
            ) as? [String: Any]

        guard let schemaDict = schemaDict,
            schemaDict["type"] as? String == "object",
            let properties = schemaDict["properties"] as? [String: Any],
            let required = schemaDict["required"] as? [String]
        else {
            Issue.record("Schema is not a valid object schema")
            return
        }

        #expect(properties.count == 3)
        #expect(required == ["red", "green", "blue"])

        // Check the properties
        for key in ["red", "green", "blue"] {
            guard let prop = properties[key] as? [String: Any],
                prop["type"] as? String == "number",
                let min = prop["minimum"] as? Double,
                let max = prop["maximum"] as? Double,
                let desc = prop["description"] as? String
            else {
                Issue.record("Missing or invalid parameter object for \(key)")
                continue
            }

            #expect(!desc.isEmpty, "Missing description for \(key)")
            #expect(min == 0, "Invalid minimum for \(key)")
            #expect(max == 1, "Invalid maximum for \(key)")
        }
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
}

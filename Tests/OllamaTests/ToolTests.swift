import Foundation
import Testing

@testable import Ollama

struct HexColorInput: Codable {
    let red: Double
    let green: Double
    let blue: Double
}

let hexColorTool = Tool<HexColorInput, String>(
    name: "rgb_to_hex",
    description: """
        Converts RGB components to a hexadecimal color string.

        The input is a JSON object with three floating-point numbers
        representing the red, green, and blue components of a color.
        The output is a string representing the color in hexadecimal format.
        """,
    parameters: [
        "type": "object",
        "properties": [
            "red": [
                "type": "number",
                "description": "The red component of the color",
                "minimum": 0.0,
                "maximum": 1.0,
            ],
            "green": [
                "type": "number",
                "description": "The green component of the color",
                "minimum": 0.0,
                "maximum": 1.0,
            ],
            "blue": [
                "type": "number",
                "description": "The blue component of the color",
                "minimum": 0.0,
                "maximum": 1.0,
            ],
        ],
        "required": ["red", "green", "blue"],
    ]
) { (input) async throws -> String in
    let r = Int(round(input.red * 255))
    let g = Int(round(input.green * 255))
    let b = Int(round(input.blue * 255))
    return String(
        format: "#%02X%02X%02X",
        min(max(r, 0), 255),
        min(max(g, 0), 255),
        min(max(b, 0), 255)
    )
}

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
        let schema = hexColorTool.schema

        // Verify basic schema structure
        #expect(schema["name"]?.stringValue == "rgb_to_hex")
        #expect(schema["description"]?.stringValue != nil)

        guard let parameters = schema["parameters"]?.objectValue else {
            #expect(Bool(false), "Missing or invalid parameters in schema")
            return
        }

        #expect(parameters["type"]?.stringValue == "object")

        guard let properties = parameters["properties"]?.objectValue else {
            #expect(Bool(false), "Missing or invalid properties in parameters")
            return
        }
        #expect(properties.count == 3, "Expected 3 parameters, got \(properties.count)")

        // Check required parameter definitions and constraints
        for (key, value) in properties {
            guard let paramObj = value.objectValue else {
                #expect(Bool(false), "Missing parameter object for \(key)")
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
}

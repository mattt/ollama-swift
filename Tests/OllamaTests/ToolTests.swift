import Ollama
import Testing

/// Get the current weather for a given location
/// - Parameter location: The location to get the weather for
@Tool
func getCurrentWeather(in location: String) -> String {
    return "Sunny and 72°F"
}

struct WeatherToolTests {
    @Test func usage() {
        #expect(getCurrentWeather(in: "Cupertino, CA") == "Sunny and 72°F")

        let weatherResult = try? Tool_getCurrentWeather.call(location: "Cupertino, CA")
        #expect(weatherResult == "Sunny and 72°F")
    }

    @Test func schema() {
        let weatherSchema = Tool_getCurrentWeather.schema
        #expect(weatherSchema["name"]?.stringValue == "getCurrentWeather")
        #expect(
            weatherSchema["description"]?.stringValue
                == "Get the current weather for a given location")

        if let parameters = weatherSchema["parameters"]?.objectValue {
            #expect(parameters["location"]?.objectValue?["type"]?.stringValue == "string")
            #expect(
                parameters["location"]?.objectValue?["description"]?.stringValue
                    == "The location to get the weather for")
        }
    }
}

/// Add two numbers together
/// - Parameter x: The first number
/// - Parameter y: The second number
@Tool
func add(x: Int, y: Int) -> Int {
    return x + y
}

struct AddToolTests {
    @Test func usage() {
        let sumResult = try? Tool_add.call(x: 1, y: 2)
        #expect(sumResult == 3)
    }

    @Test func schema() {
        let addSchema = Tool_add.schema
        #expect(addSchema["name"]?.stringValue == "add")
        #expect(addSchema["description"]?.stringValue == "Add two numbers together")

        if let parameters = addSchema["parameters"]?.objectValue {
            #expect(parameters["x"]?.objectValue?["type"]?.stringValue == "number")
            #expect(parameters["x"]?.objectValue?["description"]?.stringValue == "The first number")

            #expect(parameters["y"]?.objectValue?["type"]?.stringValue == "number")
            #expect(
                parameters["y"]?.objectValue?["description"]?.stringValue == "The second number")
        }
    }
}

enum HexColorTool: Tool {
    struct Input: Codable {
        let red: Double
        let green: Double
        let blue: Double
    }
    typealias Output = String

    static var schema: [String: Value] {
        [
            "name": "rgb_to_hex",
            "description": "Convert RGB components to a hexadecimal color string",
            "parameters": [
                "red": ["type": "number"],
                "green": ["type": "number"],
                "blue": ["type": "number"],
            ],
        ]
    }

    static func call(red: Double, green: Double, blue: Double) throws -> Output {
        let r = min(max(Int(red * 255), 0), 255)
        let g = min(max(Int(green * 255), 0), 255)
        let b = min(max(Int(blue * 255), 0), 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

struct HexColorToolTests {
    @Test func usage() {
        let result = try? HexColorTool.call(red: 1.0, green: 0.0, blue: 0.0)
        #expect(result == "#FF0000")
    }
}

import Ollama
import Testing

/// Get the current weather for a given location
/// - Parameter location: The location to get the weather for
@Tool
func getCurrentWeather(in location: String) -> String {
    return "Sunny and 72°F"
}

/// Add two numbers together
/// - Parameter x: The first number
/// - Parameter y: The second number
@Tool
func add(x: Int, y: Int) -> Int {
    return x + y
}

struct ToolTests {
    @Test func exampleUsage() {
        #expect(getCurrentWeather(in: "Cupertino, CA") == "Sunny and 72°F")

        let sumResult = try? Tool_add.call(x: 1, y: 2)
        #expect(sumResult == 3)

        let weatherResult = try? Tool_getCurrentWeather.call(location: "Cupertino, CA")
        #expect(weatherResult == "Sunny and 72°F")
    }

    @Test func schemaCheck() {
        let weatherSchema = Tool_getCurrentWeather.schema
        #expect(weatherSchema["name"]?.stringValue == "getCurrentWeather")
        #expect(
            weatherSchema["description"]?.stringValue
                == "Get the current weather for a given location")

         if let parameters = weatherSchema["parameters"]?.objectValue {
             #expect(parameters["location"]?.objectValue?["type"]?.stringValue == "string")
             #expect(parameters["location"]?.objectValue?["description"]?.stringValue == "The location to get the weather for")
         }

        let sumSchema = Tool_add.schema
        #expect(sumSchema["name"]?.stringValue == "add")
        #expect(sumSchema["description"]?.stringValue == "Add two numbers together")

         if let parameters = weatherSchema["parameters"]?.objectValue {
             #expect(parameters["x"]?.objectValue?["type"]?.stringValue == "number")
             #expect(parameters["x"]?.objectValue?["description"]?.stringValue == "The first number")

             #expect(parameters["y"]?.objectValue?["type"]?.stringValue == "number")
             #expect(parameters["y"]?.objectValue?["description"]?.stringValue == "The second number")
         }
    }
}

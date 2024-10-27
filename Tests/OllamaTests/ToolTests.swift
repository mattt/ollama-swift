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
        assert(getCurrentWeather(in: "Cupertino, CA") == "Sunny and 72°F")
        
        let sumResult = try? Tool_add.call(x: 1, y: 2)
        assert(sumResult == 3)
        
        let weatherResult = try? Tool_getCurrentWeather.call(location: "Cupertino, CA")
        assert(weatherResult == "Sunny and 72°F")
    }

    @Test func schemaCheck() {
        let weatherSchema = Tool_getCurrentWeather.schema
        assert(weatherSchema["name"]?.stringValue == "getCurrentWeather")
        assert(weatherSchema["description"]?.stringValue == "Get the current weather for a given location")
        
        // Uncomment and update these assertions once the Value type is properly defined
        // if let parameters = weatherSchema["parameters"] as? [String: [String: String]] {
        //     assert(parameters["location"]?["type"] == "String")
        //     assert(parameters["location"]?["description"] == "The location to get the weather for")
        // }

        let sumSchema = Tool_add.schema
        assert(sumSchema["name"]?.stringValue == "add")
        assert(sumSchema["description"]?.stringValue == "Add two numbers together")
        
        // Uncomment and update these assertions once the Value type is properly defined
        // if let parameters = sumSchema["parameters"] as? [String: [String: String]] {
        //     assert(parameters["x"]?["type"] == "Int")
        //     assert(parameters["x"]?["description"] == "The first number")
        //     assert(parameters["y"]?["type"] == "Int")
        //     assert(parameters["y"]?["description"] == "The second number")
        // }
    }
}

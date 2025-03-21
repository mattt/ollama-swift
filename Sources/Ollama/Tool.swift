/// Protocol defining the requirements for a tool that can be used with Ollama
public protocol ToolProtocol: Sendable {
    /// The JSON Schema describing the tool's interface
    var schema: any (Codable & Sendable) { get }
}

/// A type representing a tool that can be used with Ollama.
///
/// Tools allow models to perform complex tasks
/// or interact with the outside world by calling functions, APIs,
/// or other services.
///
/// Tools can be provided to Ollama models that support tool calling
/// (like Llama 3.1, Mistral Nemo, etc.) to extend their capabilities.
public struct Tool<Input: Codable, Output: Codable>: ToolProtocol {
    /// A JSON Schema for the tool.
    ///
    /// Models use the schema to understand when and how to use the tool.
    /// The schema includes the tool's name, description, and parameter specifications.
    ///
    /// - Example:
    /// ```swift
    /// var schema: [String: Value] {
    ///     [
    ///         "type: "function",
    ///         "function": [
    ///             "name": "get_current_weather",
    ///             "description": "Get the current weather for a location",
    ///             "parameters": [
    ///                 "type": "object",
    ///                 "properties": [
    ///                     "location": [
    ///                         "type": "string",
    ///                         "description": "The location to get the weather for, e.g. San Francisco, CA"
    ///                     ],
    ///                     "format": [
    ///                         "type": "string",
    ///                         "description": "The format to return the weather in, e.g. 'celsius' or 'fahrenheit'",
    ///                         "enum": ["celsius", "fahrenheit"]
    ///                     ]
    ///                 ],
    ///                 "required": ["location", "format"]
    ///             ]
    ///         ]
    ///     ]
    /// }
    /// ```
    public var schema: any (Codable & Sendable) { schemaValue }
    private(set) var schemaValue: Value

    /// The tool's implementation.
    ///
    /// This is the function that will be called when the tool is called.
    ///
    /// - Parameter input: The input parameters for the tool
    /// - Returns: The output of the tool operation
    /// - Throws: Any errors that occur during tool execution
    /// - SeeAlso: `callAsFunction(_:)`
    private let implementation: @Sendable (Input) async throws -> Output

    /// Creates a new tool with the given schema and implementation.
    ///
    /// - Parameters:
    ///   - schema: The JSON schema describing the tool's interface
    ///   - implementation: The function that implements the tool's behavior
    public init(
        schema: [String: Value],
        implementation: @Sendable @escaping (Input) async throws -> Output
    ) {
        self.schemaValue = Value.object([
            "type": .string("function"),
            "function": .object(schema),
        ])
        self.implementation = implementation
    }

    /// Creates a new tool with the given name, description, and implementation.
    ///
    /// - Parameters:
    ///   - name: The name of the tool
    ///   - description: A description of what the tool does
    ///   - parameters: A JSON Schema for the tool's parameters
    ///   - required: The required parameters of the tool.
    ///               If not provided, all parameters are optional.
    ///   - implementation: The function that implements the tool's behavior
    /// - Returns: A new Tool instance
    /// - Example:
    /// ```swift
    /// let weatherTool = Tool(
    ///     name: "get_current_weather",
    ///     description: "Get the current weather for a location",
    ///     parameters: [
    ///         "type": "object",
    ///         "properties": [
    ///             "location": [
    ///                 "type": "string",
    ///                 "description": "The location to get the weather for"
    ///             ]
    ///         ],
    ///         "required": ["location"]
    ///     ]
    /// ) { (input: WeatherInput) async throws -> WeatherOutput in
    ///     // Implementation here
    /// }
    /// ```
    public init(
        name: String,
        description: String,
        parameters: [String: Value],
        required: [String] = [],
        implementation: @Sendable @escaping (Input) async throws -> Output
    ) {
        var propertiesObject: [String: Value] = parameters
        var requiredParams = required

        // Check if the user passed a full schema and extract properties and required fields
        if case .string("object") = parameters["type"],
            case .object(let props) = parameters["properties"]
        {

            #if DEBUG
                print(
                    "Warning: You're passing a full JSON schema to the 'parameters' argument. "
                        + "This usage is deprecated. Pass only the properties object instead.")
            #endif

            propertiesObject = props

            // If required field exists in the parameters and no required array was explicitly passed
            if required.isEmpty,
                case .array(let reqArray) = parameters["required"]
            {
                requiredParams = reqArray.compactMap { value in
                    if case .string(let str) = value {
                        return str
                    }
                    return nil
                }
            }
        }

        self.init(
            schema: [
                "name": .string(name),
                "description": .string(description),
                "parameters": .object([
                    "type": .string("object"),
                    "properties": .object(propertiesObject),
                    "required": .array(requiredParams.map { .string($0) }),
                ]),
            ],
            implementation: implementation
        )
    }

    /// Calls the tool with the given input.
    ///
    /// - Parameter input: The input parameters for the tool
    /// - Returns: The output of the tool operation
    /// - Throws: Any errors that occur during tool execution
    public func callAsFunction(_ input: Input) async throws -> Output {
        try await implementation(input)
    }
}

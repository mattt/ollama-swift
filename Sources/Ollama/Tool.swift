/// Protocol defining the requirements for a tool that can be used with Ollama
public protocol ToolProtocol {
    /// The JSON Schema describing the tool's interface
    var schema: [String: Value] { get }
}

/// A type representing a tool that can be used with Ollama.
///
/// Tools allow models to perform complex tasks
/// or interact with the outside world by calling functions, APIs,
/// or other services.
///
/// Tools can be provided to Ollama models that support tool calling
/// (like Llama 3.1, Mistral Nemo, etc.) to extend their capabilities.
public struct Tool<Input: Codable, Output: Codable>: ToolProtocol, Sendable {
    /// A JSON Schema for the tool.
    ///
    /// Models use the schema to understand when and how to use the tool.
    /// The schema includes the tool's name, description, and parameter specifications.
    ///
    /// - Example:
    /// ```swift
    /// var schema: [String: Value] {
    ///     [
    ///         "name": "get_current_weather",
    ///         "description": "Get the current weather for a location",
    ///         "parameters": [
    ///             "type": "object",
    ///             "properties": [
    ///                 "location": [
    ///                     "type": "string",
    ///                     "description": "The location to get the weather for, e.g. San Francisco, CA"
    ///                 ],
    ///                 "format": [
    ///                     "type": "string",
    ///                     "description": "The format to return the weather in, e.g. 'celsius' or 'fahrenheit'",
    ///                     "enum": ["celsius", "fahrenheit"]
    ///                 ]
    ///             ],
    ///             "required": ["location", "format"]
    ///         ]
    ///     ]
    /// }
    /// ```
    public let schema: [String: Value]

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
        self.schema = schema
        self.implementation = implementation
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

/// Creates a new tool with the given name, description, and implementation.
///
/// - Parameters:
///   - name: The name of the tool
///   - description: A description of what the tool does
///   - parameters: A JSON Schema for the tool's parameters
///   - implementation: The function that implements the tool's behavior
/// - Returns: A new Tool instance
/// - Example:
/// ```swift
/// let tool = tool(
///     name: "get_current_weather",
///     description: "Get the current weather for a location",
///     parameters: [
///         "type": "object",
///         "properties": [
///             "location": [
///                 "type": "string",
///                 "description": "The location to get the weather for, e.g. San Francisco, CA"
///             ],
///             "format": [
///                 "type": "string",
///                 "description": "The format to return the weather in, e.g. 'celsius' or 'fahrenheit'",
///                 "enum": ["celsius", "fahrenheit"]
///             ]
///         ],
///         "required": ["location", "format"]
///     ],
///     implementation: { input in
///         // ...
///     }
/// )
/// ```
public func tool<Input: Codable, Output: Codable>(
    name: String,
    description: String,
    parameters: [String: Value],
    _ implementation: @Sendable @escaping (Input) async throws -> Output
) -> Tool<Input, Output> {
    Tool(
        schema: [
            "name": .string(name),
            "description": .string(description),
            "parameters": .object(parameters),
        ],
        implementation: implementation
    )
}

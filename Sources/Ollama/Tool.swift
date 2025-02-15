/// A protocol for tools that can be used with Ollama.
///
/// Tools allow models to perform complex tasks
/// or interact with the outside world by calling functions, APIs,
/// or other services.
///
/// Tools can be provided to Ollama models that support tool calling
/// (like Llama 3.1, Mistral Nemo, etc.) to extend their capabilities.
public protocol Tool {
    /// The input type for the tool.
    associatedtype Input: Codable

    /// The output type for the tool.
    associatedtype Output: Codable

    /// A JSON Schema for the tool.
    ///
    /// Models use the schema to understand when and how to use the tool.
    /// The schema should include the tool's
    /// name, description, and parameter specifications.
    ///
    /// - Example:
    /// ```swift
    /// static var schema: [String: Value] {
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
    static var schema: [String: Value] { get }

    /// Calls the tool with the given input.
    ///
    /// - Parameter input: The input parameters for the tool,
    ///                    matching the schema specification.
    /// - Returns: The output of the tool operation.
    /// - Throws: Any errors that occur during tool execution.
    static func call(_ input: Input) async throws -> Output
}

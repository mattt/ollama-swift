import Foundation

/// Macro that transforms functions and types into Tools
@attached(peer, names: prefixed(Tool_))
public macro Tool() = #externalMacro(module: "OllamaMacro", type: "ToolMacro")

public protocol Tool {
    associatedtype Input: Codable
    associatedtype Output: Codable

    static var schema: [String: Value] { get }
}

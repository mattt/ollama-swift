import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct OllamaToolPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ToolMacro.self
    ]
}

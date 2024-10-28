import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum Error: Swift.Error {
    case unsupportedDeclaration
}

public struct ToolMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
            throw Error.unsupportedDeclaration
        }

        let toolName = "Tool_" + funcDecl.name.text

        let inputType = generateInputType(
            from: funcDecl.signature.parameterClause,
            toolName: toolName
        )

        let description = extractDescription(from: funcDecl)
        let parameterDescriptions = extractParameterDescriptions(from: funcDecl)

        let tool = """
            enum \(toolName): Tool {
                \(inputType)
                typealias Output = \(funcDecl.signature.returnClause?.type.description ?? "Void")
                
                static var schema: [String: Value] {
                    [
                        "name": "\(funcDecl.name.text)",
                        "description": "\(description)",
                        "parameters": \(generateParametersDictionary(from: funcDecl.signature.parameterClause, descriptions: parameterDescriptions))
                    ]
                }

                static func call(_ input: Input) async throws -> Output {
                    \(generateFunctionCall(funcDecl: funcDecl))
                }
            }
            """

        let toolDecl: DeclSyntax = "\(raw: tool)"
        return [toolDecl]
    }

    private static func generateInputType(
        from parameters: FunctionParameterClauseSyntax,
        toolName: String
    ) -> String {
        if parameters.parameters.count == 1 {
            let param = parameters.parameters.first!
            return "typealias Input = \(param.type)"
        }

        let structFields = parameters.parameters.map { param in
            "let \(param.firstName.text): \(param.type)"
        }.joined(separator: "\n        ")

        let inputStruct = """
            struct Input: Codable {
                    \(structFields)
                }
            """

        return inputStruct
    }

    private static func mapSwiftTypeToJSON(_ swiftType: String) -> String {
        switch swiftType {
        case "String":
            return "string"
        case "Int", "Double", "Float":
            return "number"
        case "Bool":
            return "boolean"
        case let type where type.hasPrefix("["):
            return "array"
        case let type where type.hasPrefix("Dictionary"):
            return "object"
        default:
            // For custom types, default to object
            return "object"
        }
    }

    private static func generateParametersDictionary(
        from parameters: FunctionParameterClauseSyntax, descriptions: [String: String]
    ) -> String {
        let parameterEntries = parameters.parameters.map { param in
            let paramName = getParameterName(param: param, descriptions: descriptions)
            let swiftType = param.type.description
            let jsonType = mapSwiftTypeToJSON(swiftType)

            if let description = descriptions[paramName] {
                return """
                                    "\(paramName)": [
                                        "type": "\(jsonType)",
                                        "description": "\(description)"
                                    ]
                    """
            } else {
                return """
                                    "\(paramName)": [
                                        "type": "\(jsonType)"
                                    ]
                    """
            }
        }.joined(separator: ",\n")

        return "[\n\(parameterEntries)\n            ]"
    }

    private static func generateFunctionCall(funcDecl: FunctionDeclSyntax) -> String {
        let params = funcDecl.signature.parameterClause.parameters
        let arguments = params.map { param in
            if params.count == 1 {
                // For single parameter, input is the parameter value directly
                return "\(param.firstName.trimmed): input"
            } else {
                // For multiple parameters, input is a struct with properties
                return "\(param.firstName.trimmed): input.\(param.firstName.text)"
            }
        }.joined(separator: ", ")

        // Handle async and throws modifiers
        let isAsync = funcDecl.signature.effectSpecifiers?.asyncSpecifier != nil
        let isThrows = funcDecl.signature.effectSpecifiers?.throwsSpecifier != nil

        let awaitPrefix = isAsync ? "await " : ""
        let tryPrefix = isThrows ? "try " : ""

        return "\(tryPrefix)\(awaitPrefix)\(funcDecl.name.text)(\(arguments))"
    }

    private static func extractDescription(from funcDecl: FunctionDeclSyntax) -> String {
        if let docComment = funcDecl.leadingTrivia.compactMap({ trivia in
            if case .docLineComment(let comment) = trivia { return comment }
            return nil
        }).first {
            return String(docComment.dropFirst(3).trimmingCharacters(in: .whitespaces))
        }
        return "Calls the \(funcDecl.name.text) function"
    }

    private static func extractParameterDescriptions(from funcDecl: FunctionDeclSyntax) -> [String:
        String]
    {
        var descriptions: [String: String] = [:]
        var inParametersBlock = false

        let docComments = funcDecl.leadingTrivia.compactMap({ trivia in
            if case .docLineComment(let comment) = trivia { return comment }
            return nil
        })

        for comment in docComments {
            let trimmed = comment.dropFirst(3).trimmingCharacters(in: .whitespaces)

            // Check for Parameters block start
            if trimmed == "- Parameters:" {
                inParametersBlock = true
                continue
            }

            // Check for other directive that would end Parameters block
            if trimmed.starts(with: "- ") && !trimmed.starts(with: "- Parameter") {
                inParametersBlock = false
                continue
            }

            if inParametersBlock {
                // Handle nested parameter format
                // Expected format: "  - paramName: description"
                if trimmed.starts(with: "  - ") {
                    let paramContent = trimmed.dropFirst(4).trimmingCharacters(in: .whitespaces)
                    let parts = paramContent.split(separator: ":", maxSplits: 1)
                    if parts.count == 2 {
                        let paramName = String(parts[0]).trimmingCharacters(in: .whitespaces)
                        let description = String(parts[1]).trimmingCharacters(in: .whitespaces)
                        descriptions[paramName] = description
                    }
                }
            } else if trimmed.starts(with: "- Parameter") {
                // Handle single parameter format
                // Expected format: "- Parameter paramName: description"
                let parameterContent = trimmed.dropFirst("- Parameter".count).trimmingCharacters(
                    in: .whitespaces)
                let parts = parameterContent.split(separator: ":", maxSplits: 1)
                if parts.count == 2 {
                    let paramName = String(parts[0]).trimmingCharacters(in: .whitespaces)
                    let description = String(parts[1]).trimmingCharacters(in: .whitespaces)
                    descriptions[paramName] = description
                }
            }
        }
        return descriptions
    }

    private static func getParameterName(
        param: FunctionParameterSyntax, descriptions: [String: String]
    ) -> String {
        // Check if the parameter is documented
        if let documentedName = descriptions.keys.first(where: { key in
            key == param.firstName.text || key == param.secondName?.text
        }) {
            return documentedName
        }
        // Otherwise use second name if available, falling back to first name
        return param.secondName?.text ?? param.firstName.text
    }
}

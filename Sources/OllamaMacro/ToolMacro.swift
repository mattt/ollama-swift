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

                static func call(\(generateCallParameters(from: funcDecl.signature.parameterClause))) throws -> Output {
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

    private static func generateCallParameters(from parameters: FunctionParameterClauseSyntax)
        -> String
    {
        return parameters.parameters.map { param in
            let paramName = param.secondName?.text ?? param.firstName.text
            return "\(paramName): \(param.type)"
        }.joined(separator: ", ")
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
            let paramName = param.secondName?.text ?? param.firstName.text
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
            let argName = param.secondName?.text ?? param.firstName.text
            return "\(param.firstName.trimmed): \(argName)"
        }.joined(separator: ", ")

        return "\(funcDecl.name.text)(\(arguments))"
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
        let docComments = funcDecl.leadingTrivia.compactMap({ trivia in
            if case .docLineComment(let comment) = trivia { return comment }
            return nil
        })
        for comment in docComments {
            let trimmed = comment.dropFirst(3).trimmingCharacters(in: .whitespaces)
            if trimmed.starts(with: "- Parameter") {
                let parts = trimmed.dropFirst(12).split(separator: ":", maxSplits: 1)
                if parts.count == 2 {
                    let paramName = parts[0].trimmingCharacters(in: .whitespaces)
                    let description = parts[1].trimmingCharacters(in: .whitespaces)
                    descriptions[paramName] = description
                }
            }
        }
        return descriptions
    }
}

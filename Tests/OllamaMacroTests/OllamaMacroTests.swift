import OllamaMacro
import SwiftSyntaxMacros
import Testing

struct ToolTests {
    let testMacros: [String: Macro.Type] = [
        "Tool": ToolMacro.self
    ]

    @Test func basicFunctionTransformation() {
        assertMacroExpansion(
            """
            @Tool
            func getCurrentWeather(in location: String) -> String {
                "Sunny and 72°F"
            }
            """,
            expandedSource: """
                func getCurrentWeather(in location: String) -> String {
                    "Sunny and 72°F"
                }

                enum Tool_getCurrentWeather: Tool {
                    typealias Input = String
                    typealias Output = String

                    static var schema: [String: Value] {
                        [
                            "name": "getCurrentWeather",
                            "description": "Calls the getCurrentWeather function",
                            "parameters": [
                                "location": [
                                    "type": "String"
                                ]
                            ]
                        ]
                    }

                    static func call(location: String) throws -> Output {
                        getCurrentWeather(in: location)
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test func multipleParameterFunction() {
        assertMacroExpansion(
            """
            @Tool
            func greet(firstName: String, lastName: String) -> String {
                "Hello, \\(firstName) \\(lastName)!"
            }
            """,
            expandedSource: """
                func greet(firstName: String, lastName: String) -> String {
                    "Hello, \\(firstName) \\(lastName)!"
                }

                enum Tool_greet: Tool {
                    struct Input: Codable {
                        let firstName: String
                        let lastName: String
                    }
                    typealias Output = String

                    static var schema: [String: Value] {
                        [
                            "name": "greet",
                            "description": "Calls the greet function",
                            "parameters": [
                                "firstName": [
                                    "type": "String"
                                ],
                                "lastName": [
                                    "type": "String"
                                ]
                            ]
                        ]
                    }

                    static func call(firstName: String, lastName: String) throws -> Output {
                        greet(firstName: firstName, lastName: lastName)
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test func customToolName() {
        assertMacroExpansion(
            """
            @Tool
            func hello(name: String) -> String {
                "Hello, \\(name)!"
            }
            """,
            expandedSource: """
                func hello(name: String) -> String {
                    "Hello, \\(name)!"
                }

                enum Tool_hello: Tool {
                    typealias Input = String
                    typealias Output = String

                    static var schema: [String: Value] {
                        [
                            "name": "hello",
                            "description": "Calls the hello function",
                            "parameters": [
                                "name": [
                                    "type": "String"
                                ]
                            ]
                        ]
                    }

                    static func call(name: String) throws -> Output {
                        hello(name: name)
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test func voidReturnType() {
        assertMacroExpansion(
            """
            @Tool
            func log(message: String) {
                print(message)
            }
            """,
            expandedSource: """
                func log(message: String) {
                    print(message)
                }

                enum Tool_log: Tool {
                    typealias Input = String
                    typealias Output = Void

                    static var schema: [String: Value] {
                        [
                            "name": "log",
                            "description": "Calls the log function",
                            "parameters": [
                                "message": [
                                    "type": "String"
                                ]
                            ]
                        ]
                    }

                    static func call(message: String) throws -> Output {
                        log(message: message)
                    }
                }
                """,
            macros: testMacros
        )
    }
}

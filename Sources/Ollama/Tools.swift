import Foundation

extension Chat {
    
    /// A tool provided to the LLM
    public struct Tool {
        /// The definition included in the API calls
        let definition: ToolDefinition
        /// The action to be run when this tool is called on by the AI
        let action: ([String: Value]) -> Value
        
        /// A parameter passed into the function
        public struct ToolParameter {
            /// The type of parameter object
            public enum ParameterType: String {
                /// Represents the  integer json type
                case integer
                /// Represents the string json type
                case string
            }
            
            /// The name of this parameter
            let name: String
            /// The human readable description of what the parameter does.
            let description: String
            /// The object type of this parameter
            let parameterType: ParameterType
            /// Is this parameter required
            let required: Bool
        }
        
        /// Creates a function tool to be used by the LLM
        /// - Parameters:
        ///   - name: The name of the function
        ///   - description: The human readable description of what the function does
        ///   - parameters: The parameter summary of the parameters the function takes
        ///   - action: The action which should be run
        public init(
            name: String,
            description: String,
            parameters: [ToolParameter],
            action: @escaping ([String : Value]) -> Value
        ) {
            var parametersDefinitions: [String : Value] = [:]
            parametersDefinitions["type"] = .string("object")
            
            var properties: [String : Value] = [:]
            var requiredParameters: [String] = []
            
            for parameter in parameters {
                let property: [String: Value] = [
                    "type": .string(parameter.parameterType.rawValue),
                    "description": .string(parameter.description)
                ]
                properties[parameter.name] = .object(property)
                
                if parameter.required {
                    requiredParameters.append(parameter.name)
                }
            }
            parametersDefinitions["properties"] = .object(properties)
            parametersDefinitions["required"] = .array(requiredParameters.map({ .string($0) }))
            
            self.definition = ToolDefinition(type: .function, function: ToolDefinition.FunctionDefinition(
                name: name,
                description: description,
                parameters: parametersDefinitions
            ))
            
            self.action = action
        }
        
        /// Creates a function tool to be used by the LLM
        /// - Parameters:
        ///   - name: The name of the function
        ///   - description: The human readable description of what the function does
        ///   - parameters: The raw parameter's the function takes
        ///   - action: The action which should be run
        public init(
            name: String,
            description: String,
            parameters: [String : Value],
            action: @escaping ([String : Value]) -> Value
        ) {
            self.definition = ToolDefinition(type: .function, function: ToolDefinition.FunctionDefinition(
                name: name,
                description: description,
                parameters: parameters
            ))
            
            self.action = action
        }
    }
    
    /// The information about the tool given provided to the AI assistant.
    public struct ToolDefinition: Hashable, Codable {
        /// The role of the message sender.
        public enum ToolType: String, Hashable, CaseIterable, Codable {
            /// Represents a tool which provides a function to the LLM
            case function
        }
        /// The type of tool
        let type: ToolType
        
        /// Information about the function
        struct FunctionDefinition: Hashable, Codable {
            /// The name of the function
            let name: String
            /// The human readable description of what the function does
            let description: String
            /// The parameter's the function takes
            let parameters: [String: Value]
        }
        /// The function this tool provides
        let function: FunctionDefinition
    }
    
}

import Foundation

extension Chat {
    
    /// A tool provided to the LLM
    public struct Tool {
        /// The definition included in the API calls
        public let definition: ToolDefinition
        /// The action to be run when this tool is called on by the AI
        public let action: ([String: Value]) -> Value
        
        /// A parameter passed into the function
        public struct ToolParameter {
            /// The type of parameter object
            public enum ParameterType: String {
                /// Represents the number json type
                case number
                /// Represents the boolean json type
                case boolean
                /// Represents the string json type
                case string
                /// Represents the object json type
                case object
                /// Represents the array json type
                case array
                /// Represents the null json type
                case null
            }
            
            /// The name of this parameter
            public let name: String
            
            /// The human readable description of what the parameter does.
            public let description: String
            
            /// The object type of this parameter
            public let parameterType: ParameterType
            
            /// Is this parameter required
            public let required: Bool
			
			/// Create a tool parameter description to be passed to the LLM
			/// - Parameters:
			///   - name: The name of this parameter
			///   - description: The human readable description of what the parameter does
			///   - parameterType: The object type of this parameter
			///   - required: Is this parameter required
            public init(name: String, description: String, parameterType: ParameterType, required: Bool) {
                self.name = name
                self.description = description
                self.parameterType = parameterType
                self.required = required
            }
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
        
        /// Creates a function tool to be used by the LLM
        /// - Parameters:
        ///   - definition: The definition included in the API calls
        ///   - action: The closure to be called to run this action
        init(definition: ToolDefinition, action: @escaping ([String : Value]) -> Value) {
            self.definition = definition
            self.action = action
        }
    }
    
    /// The information about the tool given provided to the AI assistant.
    public struct ToolDefinition: Hashable, Codable {
        /// Create a tool definition for the LLM
        /// - Parameters:
        ///   - type: What type of tool is this
        ///   - function: The function definition which should be sent to the LLM
        public init(type: Chat.ToolDefinition.ToolType, function: Chat.ToolDefinition.FunctionDefinition) {
            self.type = type
            self.function = function
        }
        
        /// The role of the message sender.
        public enum ToolType: String, Hashable, CaseIterable, Codable {
            /// Represents a tool which provides a function to the LLM
            case function
        }
        /// The type of tool
        public let type: ToolType
        
        /// Information about the function
       public struct FunctionDefinition: Hashable, Codable {
           /// The name of the function
           public let name: String
           /// The human readable description of what the function does
           public let description: String
           /// The parameter's the function takes
           public let parameters: [String: Value]
		   
		   /// Create a function definition to be passed to the LLM
		   /// - Parameters:
		   ///   - name: The name of the function.
		   ///   - description: The human readable description of what the function does.
		   ///   - parameters: The parameter's the function takes in.
           public init(name: String, description: String, parameters: [String : Value]) {
               self.name = name
               self.description = description
               self.parameters = parameters
           }
        }
        /// The function this tool provides
        public let function: FunctionDefinition
    }
    
}

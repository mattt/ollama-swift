import struct Foundation.Data
import struct Foundation.Date
import struct Foundation.TimeInterval

/// Namespace for chat-related types and functionality.
public enum Chat {
    /// Represents a message in a chat conversation.
    public struct Message: Hashable, Codable {
        /// The role of the message sender.
        public enum Role: String, Hashable, CaseIterable, Codable {
            /// Represents a message from the user.
            case user
            /// Represents a system message.
            case system
            /// Represents a message from the AI assistant.
            case assistant
            /// Represents a user tool responding to a function call by the AI assistant.
            case tool
        }

        /// The role of the message sender.
        public let role: Role

        /// The content of the message.
        public let content: String

        /// Optional array of image data associated with the message.
        public let images: [Data]?
        
        /// The function call information
        public struct ToolCall: Hashable, Codable {
            /// The function being called
            public struct ToolFunction: Hashable, Codable {
                /// The name of the function being called
                let name: String
                /// The arguments being passed to the function
                let arguments: [String: Value]
            }
            /// The function being called
            let function: ToolFunction
        }
        
        /// Optional array of tool calls the model is asking for in order to create it's reply message..
        public let tool_calls: [ToolCall]?
        
        /// Creates a new chat message.
        ///
        /// - Parameters:
        ///   - role: The role of the message sender.
        ///   - content: The content of the message.
        ///   - images: Optional array of image data associated with the message.
        public init(
            role: Role,
            content: String,
            images: [Data]? = nil,
            toolCalls: [ToolCall]? = nil
        ) {
            self.role = role
            self.content = content
            self.images = images
            self.tool_calls = toolCalls
        }

        /// Creates a user message.
        ///
        /// - Parameters:
        ///   - content: The content of the message.
        ///   - images: Optional array of image data associated with the message.
        /// - Returns: A new `Message` instance with the user role.
        public static func user(
            _ content: String,
            images: [Data]? = nil
        ) -> Message {
            return Message(role: .user, content: content, images: images)
        }

        /// Creates a system message.
        ///
        /// - Parameters:
        ///   - content: The content of the message.
        ///   - images: Optional array of image data associated with the message.
        /// - Returns: A new `Message` instance with the system role.
        public static func system(
            _ content: String,
            images: [Data]? = nil
        ) -> Message {
            return Message(role: .system, content: content, images: images)
        }

        /// Creates an assistant message.
        ///
        /// - Parameters:
        ///   - content: The content of the message.
        ///   - images: Optional array of image data associated with the message.
        /// - Returns: A new `Message` instance with the assistant role.
        public static func assistant(
            _ content: String,
            images: [Data]? = nil
        ) -> Message {
            return Message(role: .assistant, content: content, images: images)
        }
        
        /// Creates a tool message back to the assistant.
        /// - Parameters:
        ///   - content: The content of the message
        ///   - images: Optional array of image data associated with the message
        /// - Returns: A new `Message` instance with the tool role
        public static func tool(
            _ content: String,
            images: [Data]? = nil
        ) -> Message {
            return Message(role: .tool, content: content, images: images)
        }
    }
}

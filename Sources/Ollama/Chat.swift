import struct Foundation.Data
import struct Foundation.Date
import struct Foundation.TimeInterval

/// Namespace for chat-related types and functionality.
public enum Chat {
    /// Represents a message in a chat conversation.
    public struct Message: Hashable, Sendable {
        /// The role of the message sender.
        public enum Role: String, Hashable, CaseIterable, Codable, Sendable {
            /// A system message.
            case system

            /// A message from the user.
            case user

            /// A message from the AI assistant.
            case assistant

            /// The result of calling a tool.
            case tool
        }

        /// Represents a function call made by a tool
        public struct ToolCall: Hashable, Codable, Sendable {
            /// Represents the function details for a tool call
            public struct Function: Hashable, Codable, Sendable {
                /// The name of the function
                public let name: String

                /// The arguments passed to the function
                public let arguments: [String: Value]

                public init(name: String, arguments: [String: Value]) {
                    self.name = name
                    self.arguments = arguments
                }
            }

            /// The function to be called
            public let function: Function

            public init(function: Function) {
                self.function = function
            }
        }

        /// The role of the message sender.
        public let role: Role

        /// The content of the message.
        public let content: String

        /// Optional array of image data associated with the message.
        public let images: [Data]?

        /// Optional array of tool calls associated with the message
        public let toolCalls: [ToolCall]?

        /// Creates a new chat message.
        ///
        /// - Parameters:
        ///   - role: The role of the message sender.
        ///   - content: The content of the message.
        ///   - images: Optional array of image data associated with the message.
        ///   - toolCalls: Optional array of tool calls associated with the message.
        private init(
            role: Role,
            content: String,
            images: [Data]? = nil,
            toolCalls: [ToolCall]? = nil
        ) {
            self.role = role
            self.content = content
            self.images = images
            self.toolCalls = toolCalls
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
            return Message(
                role: .system,
                content: content,
                images: images
            )
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
            return Message(
                role: .user,
                content: content,
                images: images
            )
        }

        /// Creates an assistant message.
        ///
        /// - Parameters:
        ///   - content: The content of the message.
        ///   - images: Optional array of image data associated with the message.
        ///   - toolCalls: Optional array of tool calls associated with the message.
        /// - Returns: A new `Message` instance with the assistant role.
        public static func assistant(
            _ content: String,
            images: [Data]? = nil,
            toolCalls: [ToolCall]? = nil
        ) -> Message {
            return Message(
                role: .assistant,
                content: content,
                images: images,
                toolCalls: toolCalls
            )
        }

        /// Creates a tool message.
        ///
        /// - Parameters:
        ///   - content: The content of the message.
        /// - Returns: A new `Message` instance with the tool role.
        public static func tool(
            _ content: String
        ) -> Message {
            return Message(role: .tool, content: content)
        }
    }
}

// MARK: - Codable
extension Chat.Message: Codable {
    private enum CodingKeys: String, CodingKey {
        case role
        case content
        case images
        case toolCalls = "tool_calls"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(role, forKey: .role)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(images, forKey: .images)
        try container.encodeIfPresent(toolCalls, forKey: .toolCalls)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        role = try container.decode(Role.self, forKey: .role)
        content = try container.decode(String.self, forKey: .content)
        images = try container.decodeIfPresent([Data].self, forKey: .images)
        toolCalls = try container.decodeIfPresent([ToolCall].self, forKey: .toolCalls)
    }
}

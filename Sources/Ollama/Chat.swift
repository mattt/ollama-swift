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
        }

        /// The role of the message sender.
        public let role: Role

        /// The content of the message.
        public let content: String

        /// Optional array of image data associated with the message.
        public let images: [Data]?

        /// Creates a new chat message.
        ///
        /// - Parameters:
        ///   - role: The role of the message sender.
        ///   - content: The content of the message.
        ///   - images: Optional array of image data associated with the message.
        public init(
            role: Role,
            content: String,
            images: [Data]? = nil
        ) {
            self.role = role
            self.content = content
            self.images = images
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
    }
}

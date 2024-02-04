import struct Foundation.Data
import struct Foundation.Date
import struct Foundation.TimeInterval

public enum Chat {
    public struct Message: Hashable, Codable {
        public enum Role: String, Hashable, CaseIterable, Codable {
            case user
            case system
            case assistant
        }
        
        public let role: Role
        public let content: String
        public let images: [Data]?
        
        public init(role: Role, 
                    content: String,
                    images: [Data]? = nil)
        {
            self.role = role
            self.content = content
            self.images = images
        }
        
        static func user(_ content: String,
                         images: [Data]? = nil) -> Message
        {
            return Message(role: .user, content: content, images: images)
        }
        
        static func system(_ content: String,
                           images: [Data]? = nil) -> Message
        {
            return Message(role: .system, content: content, images: images)
        }
        
        static func assistant(_ content: String,
                              images: [Data]? = nil) -> Message
        {
            return Message(role: .assistant, content: content, images: images)
        }
    }

    public struct Response: Hashable {
        public let model: Model.ID
        public let createdAt: Date
        public let message: Message
        public let done: Bool

        public let totalDuration: TimeInterval?
        public let loadDuration: TimeInterval?
        public let promptEvalCount: Int?
        public let promptEvalDuration: TimeInterval?
        public let evalCount: Int?
        public let evalDuration: TimeInterval?
    }
}

// MARK: - Codable

extension Chat.Response: Codable {
    enum CodingKeys: String, CodingKey {
        case model
        case createdAt = "created_at"
        case message
        case done
        case totalDuration = "total_duration"
        case loadDuration = "load_duration"
        case promptEvalCount = "prompt_eval_count"
        case promptEvalDuration = "prompt_eval_duration"
        case evalCount = "eval_count"
        case evalDuration = "eval_duration"
    }
}

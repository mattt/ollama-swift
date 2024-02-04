import struct Foundation.Date
import class Foundation.ISO8601DateFormatter

public struct Model: Hashable, Identifiable {
    public struct Details: Hashable {
        public let format: String
        public let family: String
        public let families: [String]?
        public let parameterSize: String
        public let quantizationLevel: String
    }

    public typealias ID = String

    public var id: ID {
        return name
    }

    public let name: ID
    public let size: Int
    public let digest: String
    public let details: Details
    public let modifiedAt: Date
}

// MARK: - Codable

extension Model: Codable {
    enum CodingKeys: String, CodingKey {
        case name
        case size
        case digest
        case details
        case modifiedAt = "modified_at"
    }
}

extension Model.Details: Codable {
    enum CodingKeys: String, CodingKey {
        case format
        case family
        case families
        case parameterSize = "parameter_size"
        case quantizationLevel = "quantization_level"
    }
}

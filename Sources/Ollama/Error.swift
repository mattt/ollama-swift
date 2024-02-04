import Foundation

/// An error returned by the Replicate HTTP API
public struct Error: Swift.Error, Hashable {
    /// A description of the error.
    public let detail: String
}

// MARK: - LocalizedError

extension Error: LocalizedError {
    public var errorDescription: String? {
        return self.detail
    }
}

// MARK: - CustomStringConvertible

extension Error: CustomStringConvertible {
    public var description: String {
        return self.detail
    }
}

// MARK: - Decodable

extension Error: Decodable {
    private enum CodingKeys: String, CodingKey {
        case detail
    }

    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            self.detail = try container.decode(String.self, forKey: .detail)
        } else if let container = try? decoder.singleValueContainer() {
            self.detail = try container.decode(String.self)
        } else {
            let context = DecodingError.Context(codingPath: [], debugDescription: "unable to decode error")
            throw DecodingError.dataCorrupted(context)
        }
    }
}

// MARK: - Encodable

extension Error: Encodable {}

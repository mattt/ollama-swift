import Foundation

public struct Embeddings: RawRepresentable, Hashable {
    public let rawValue: [[Double]]

    public init(rawValue: [[Double]]) {
        self.rawValue = rawValue
    }
}

// MARK: - ExpressibleByArrayLiteral

extension Embeddings: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: [Double]...) {
        self.init(rawValue: elements)
    }
}

// MARK: - Decodable

extension Embeddings: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode([[Double]].self)
    }
}

import struct Foundation.Date
import class Foundation.ISO8601DateFormatter

/// Namespace for model-related types and functionality.
public enum Model {
    /// An identifier in the form of "[namespace/]model[:tag]".
    /// This structure is used to uniquely identify models in the Ollama ecosystem.
    public struct ID: Hashable, Equatable, Comparable, RawRepresentable, CustomStringConvertible,
        ExpressibleByStringLiteral, ExpressibleByStringInterpolation, Codable, Sendable
    {
        /// The optional namespace of the model.
        /// Namespaces are used to organize models, often representing the creator or organization.
        public let namespace: String?

        /// The name of the model.
        /// This is the primary identifier for the model.
        public let model: String

        /// The optional tag (version) of the model.
        /// Tags are used to specify different versions or variations of the same model.
        public let tag: String?

        /// The raw string representation of the model identifier.
        public typealias RawValue = String

        // MARK: Equatable & Comparable

        /// Compares two `Model.ID` instances for equality.
        /// The comparison is case-insensitive.
        public static func == (lhs: Model.ID, rhs: Model.ID) -> Bool {
            return lhs.rawValue.caseInsensitiveCompare(rhs.rawValue) == .orderedSame
        }

        /// Compares two `Model.ID` instances for ordering.
        /// The comparison is case-insensitive.
        public static func < (lhs: Model.ID, rhs: Model.ID) -> Bool {
            return lhs.rawValue.caseInsensitiveCompare(rhs.rawValue) == .orderedAscending
        }

        // MARK: RawRepresentable

        /// Initializes a `Model.ID` from a raw string value.
        /// The raw value should be in the format `"[namespace/]model[:tag]"`.
        public init?(rawValue: RawValue) {
            let components = rawValue.split(separator: "/", maxSplits: 1)

            if components.count == 2 {
                self.namespace = String(components[0])
                let modelAndTag = components[1].split(separator: ":", maxSplits: 1)
                self.model = String(modelAndTag[0])
                self.tag = modelAndTag.count > 1 ? String(modelAndTag[1]) : nil
            } else {
                self.namespace = nil
                let modelAndTag = rawValue.split(separator: ":", maxSplits: 1)
                self.model = String(modelAndTag[0])
                self.tag = modelAndTag.count > 1 ? String(modelAndTag[1]) : nil
            }
        }

        /// Returns the raw string representation of the `Model.ID`.
        public var rawValue: String {
            let namespaceString = namespace.map { "\($0)/" } ?? ""
            let tagString = tag.map { ":\($0)" } ?? ""
            return "\(namespaceString)\(model)\(tagString)"
        }

        // MARK: CustomStringConvertible

        /// A textual representation of the `Model.ID`.
        public var description: String {
            return rawValue
        }

        // MARK: ExpressibleByStringLiteral

        /// Initializes a `Model.ID` from a string literal.
        public init(stringLiteral value: StringLiteralType) {
            self.init(rawValue: value)!
        }

        // MARK: ExpressibleByStringInterpolation

        /// Initializes a `Model.ID` from a string interpolation.
        public init(stringInterpolation: DefaultStringInterpolation) {
            self.init(rawValue: stringInterpolation.description)!
        }

        // MARK: Codable

        /// Decodes a `Model.ID` from a single string value.
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            guard let identifier = Model.ID(rawValue: rawValue) else {
                throw DecodingError.dataCorruptedError(
                    in: container, debugDescription: "Invalid Identifier string: \(rawValue)")
            }
            self = identifier
        }

        /// Encodes the `Model.ID` as a single string value.
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }

        // MARK: Pattern Matching

        /// Defines the pattern matching operator for `Model.ID`.
        /// This allows for partial matching based on namespace, model name, and tag.
        public static func ~= (pattern: Model.ID, value: Model.ID) -> Bool {
            if let patternNamespace = pattern.namespace, patternNamespace != value.namespace {
                return false
            }
            if pattern.model != value.model {
                return false
            }
            if let patternTag = pattern.tag, patternTag != value.tag {
                return false
            }
            return true
        }
    }

    // MARK: -

    /// Represents additional information about a model.
    public struct Details: Hashable, Codable, Sendable {
        /// The format of the model file (e.g., "gguf").
        public let format: String

        /// The primary family or architecture of the model (e.g., "llama").
        public let family: String

        /// Additional families or architectures the model belongs to, if any.
        public let families: [String]?

        /// The parameter size of the model (e.g., "7B", "13B").
        public let parameterSize: String

        /// The quantization level of the model (e.g., "Q4_0").
        public let quantizationLevel: String

        /// The parent model, if this model is derived from another.
        public let parentModel: String?

        /// Coding keys for mapping JSON keys to struct properties.
        enum CodingKeys: String, CodingKey {
            case format, family, families
            case parameterSize = "parameter_size"
            case quantizationLevel = "quantization_level"
            case parentModel = "parent_model"
        }

        /// Creates a model details object.
        /// - Parameters:
        ///   - format: The format of the model file (e.g., "gguf").
        ///   - family: The primary family or architecture of the model (e.g., "llama").
        ///   - families: Additional families or architectures the model belongs to, if any.
        ///   - parameterSize: The parameter size of the model (e.g., "7B", "13B").
        ///   - quantizationLevel: The quantization level of the model (e.g., "Q4_0").
        ///   - parentModel: The parent model, if this model is derived from another.
        public init(
            format: String,
            family: String,
            families: [String]? = nil,
            parameterSize: String,
            quantizationLevel: String,
            parentModel: String? = nil
        ) {
            self.format = format
            self.family = family
            self.families = families
            self.parameterSize = parameterSize
            self.quantizationLevel = quantizationLevel
            self.parentModel = parentModel
        }
    }

    /// Represents a capability that a model may support.
    public struct Capability: Hashable, Comparable, RawRepresentable, Sendable, Codable,
        ExpressibleByStringLiteral
    {
        public typealias RawValue = String

        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(stringLiteral value: StringLiteralType) {
            self.init(rawValue: value)
        }

        public static func < (lhs: Capability, rhs: Capability) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            self.init(rawValue: rawValue)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }

        /// The ability to generate text completions based on a prompt.
        public static let completion: Capability = "completion"

        /// The ability to use tools and function calling capabilities.
        public static let tools: Capability = "tools"

        /// The ability to insert text at a specific position in the context.
        public static let insert: Capability = "insert"

        /// The ability to process and understand visual inputs.
        public static let vision: Capability = "vision"

        /// The ability to generate embeddings for text inputs.
        public static let embedding: Capability = "embedding"

        /// The ability to provide thinking/reasoning steps in the output.
        public static let thinking: Capability = "thinking"
    }
}

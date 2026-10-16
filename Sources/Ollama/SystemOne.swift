import Foundation

/// Namespace for System One types and functionality.
///
/// System One answers choice, yes/no, and scoring questions about a shared state
/// with a model trained for decisions, such as Nimble.
/// It requires Ollama v0.35.0 or later,
/// or v0.40.5 or later for cloud models.
///
/// - SeeAlso: [System One API Documentation](https://docs.ollama.com/api/systemone)
public enum SystemOne {
    /// The content of a request's state or a question's instructions.
    ///
    /// A nonempty string,
    /// or an object or array serialized as JSON text.
    /// The content is not interpreted as chat messages or multimodal input.
    public enum Content: Hashable, Sendable {
        /// A string value.
        case string(String)

        /// An object value, keyed by string.
        case object([String: Value])

        /// An array value.
        case array([Value])
    }

    /// A question about the shared state.
    ///
    /// Each question is answered independently.
    /// Answers are not passed to later questions.
    public enum Question: Hashable, Sendable {
        /// Descriptions for the two outcomes of a yes/no question.
        ///
        /// An omitted description uses a model-specific default.
        public struct NoulCriteria: Hashable, Codable, Sendable {
            /// The description of the `true` outcome, if any.
            public let whenTrue: String?

            /// The description of the `false` outcome, if any.
            public let whenFalse: String?

            private enum CodingKeys: String, CodingKey {
                case whenTrue = "true"
                case whenFalse = "false"
            }

            /// Creates criteria for a yes/no question.
            ///
            /// - Parameters:
            ///   - whenTrue: The description of the `true` outcome, if any.
            ///   - whenFalse: The description of the `false` outcome, if any.
            public init(whenTrue: String? = nil, whenFalse: String? = nil) {
                self.whenTrue = whenTrue
                self.whenFalse = whenFalse
            }
        }

        /// A question that chooses one option from the criteria.
        ///
        /// The criteria map each option's key to its description,
        /// or to `nil` for a bare label.
        case choice(instructions: Content, criteria: [String: String?])

        /// A yes/no question.
        ///
        /// The optional criteria describe the `true` and `false` outcomes.
        case noul(instructions: Content, criteria: NoulCriteria?)

        /// A question that scores the state against ordered criteria.
        ///
        /// The criteria run from the lowest score (index 0) to the highest,
        /// and define a scale from 0 to the number of criteria minus 1.
        case score(instructions: Content, criteria: [String])

        /// Creates a yes/no question without criteria.
        ///
        /// - Parameter instructions: The instructions for the question.
        /// - Returns: A `noul` question with no criteria.
        public static func noul(instructions: Content) -> Question {
            return .noul(instructions: instructions, criteria: nil)
        }
    }

    /// The answer to a question.
    public enum Answer: Hashable, Sendable {
        /// The answer to a choice question.
        ///
        /// `choice` is the option key with the highest probability.
        /// Ties follow the model's option order.
        /// `confidence` measures how strongly the model favors one answer over the others,
        /// from 0 to 1.
        /// It is not calibrated correctness.
        case choice(choice: String, probabilities: [String: Double], confidence: Double)

        /// The answer to a yes/no question.
        ///
        /// `probability` is the probability of `true` among the `false` and `true` candidates,
        /// from 0 to 1.
        case noul(probability: Double)

        /// The answer to a scoring question.
        ///
        /// `score` is the probability-weighted average of the zero-based criterion indices.
        /// It is not rounded to a level or normalized to 0–1.
        /// `legend` maps each zero-based index, as a string, to its criterion description.
        /// `probabilities` are likewise keyed by zero-based criterion indices as strings.
        case score(
            score: Double, legend: [String: String], probabilities: [String: Double],
            confidence: Double
        )
    }
}

// MARK: - Codable

extension SystemOne.Content: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: Value].self) {
            self = .object(value)
        } else if let value = try? container.decode([Value].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Content must be a string, object, or array")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .string(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        }
    }
}

extension SystemOne.Question: Codable {
    private enum QuestionType: String, Codable {
        case choice
        case noul
        case score
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case instructions
        case criteria
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let instructions = try container.decode(SystemOne.Content.self, forKey: .instructions)

        switch try container.decode(QuestionType.self, forKey: .type) {
        case .choice:
            let criteria = try container.decode([String: String?].self, forKey: .criteria)
            self = .choice(instructions: instructions, criteria: criteria)
        case .noul:
            let criteria = try container.decodeIfPresent(NoulCriteria.self, forKey: .criteria)
            self = .noul(instructions: instructions, criteria: criteria)
        case .score:
            let criteria = try container.decode([String].self, forKey: .criteria)
            self = .score(instructions: instructions, criteria: criteria)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .choice(let instructions, let criteria):
            try container.encode(QuestionType.choice, forKey: .type)
            try container.encode(instructions, forKey: .instructions)
            try container.encode(criteria, forKey: .criteria)
        case .noul(let instructions, let criteria):
            try container.encode(QuestionType.noul, forKey: .type)
            try container.encode(instructions, forKey: .instructions)
            try container.encodeIfPresent(criteria, forKey: .criteria)
        case .score(let instructions, let criteria):
            try container.encode(QuestionType.score, forKey: .type)
            try container.encode(instructions, forKey: .instructions)
            try container.encode(criteria, forKey: .criteria)
        }
    }
}

extension SystemOne.Answer: Codable {
    private enum AnswerType: String, Codable {
        case choice
        case noul
        case score
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case choice
        case noul
        case score
        case legend
        case probabilities
        case confidence
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        switch try container.decode(AnswerType.self, forKey: .type) {
        case .choice:
            self = .choice(
                choice: try container.decode(String.self, forKey: .choice),
                probabilities: try container.decode([String: Double].self, forKey: .probabilities),
                confidence: try container.decode(Double.self, forKey: .confidence)
            )
        case .noul:
            self = .noul(probability: try container.decode(Double.self, forKey: .noul))
        case .score:
            self = .score(
                score: try container.decode(Double.self, forKey: .score),
                legend: try container.decode([String: String].self, forKey: .legend),
                probabilities: try container.decode([String: Double].self, forKey: .probabilities),
                confidence: try container.decode(Double.self, forKey: .confidence)
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .choice(let choice, let probabilities, let confidence):
            try container.encode(AnswerType.choice, forKey: .type)
            try container.encode(choice, forKey: .choice)
            try container.encode(probabilities, forKey: .probabilities)
            try container.encode(confidence, forKey: .confidence)
        case .noul(let probability):
            try container.encode(AnswerType.noul, forKey: .type)
            try container.encode(probability, forKey: .noul)
        case .score(let score, let legend, let probabilities, let confidence):
            try container.encode(AnswerType.score, forKey: .type)
            try container.encode(score, forKey: .score)
            try container.encode(legend, forKey: .legend)
            try container.encode(probabilities, forKey: .probabilities)
            try container.encode(confidence, forKey: .confidence)
        }
    }
}

// MARK: - ExpressibleByStringLiteral

extension SystemOne.Content: ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
    public init(stringLiteral value: StringLiteralType) {
        self = .string(value)
    }

    public init(stringInterpolation: DefaultStringInterpolation) {
        self = .string(stringInterpolation.description)
    }
}

// MARK: - ExpressibleByArrayLiteral

extension SystemOne.Content: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Value...) {
        self = .array(elements)
    }
}

// MARK: - ExpressibleByDictionaryLiteral

extension SystemOne.Content: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, Value)...) {
        var dictionary: [String: Value] = [:]
        for (key, value) in elements {
            dictionary[key] = value
        }
        self = .object(dictionary)
    }
}

import Foundation
import Testing

@testable import Ollama

@Suite
struct SystemOneTests {
    private func encode<T: Encodable>(_ value: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return String(decoding: try encoder.encode(value), as: UTF8.self)
    }

    @Test
    func choiceQuestionEncoding() throws {
        let question = SystemOne.Question.choice(
            instructions: "Which label fits this ticket?",
            criteria: [
                "billing": "Payments and refunds",
                "bug": "Software errors",
                "account": nil,
            ]
        )

        #expect(
            try encode(question)
                == #"{"criteria":{"account":null,"billing":"Payments and refunds","bug":"Software errors"},"instructions":"Which label fits this ticket?","type":"choice"}"#
        )
    }

    @Test
    func noulQuestionEncoding() throws {
        let question = SystemOne.Question.noul(
            instructions: "Is the customer requesting a refund?"
        )

        #expect(
            try encode(question)
                == #"{"instructions":"Is the customer requesting a refund?","type":"noul"}"#
        )
    }

    @Test
    func noulQuestionWithCriteriaEncoding() throws {
        let question = SystemOne.Question.noul(
            instructions: "Is the customer requesting a refund?",
            criteria: .init(
                whenTrue: "The customer requests a refund",
                whenFalse: "No refund is requested"
            )
        )

        #expect(
            try encode(question)
                == #"{"criteria":{"false":"No refund is requested","true":"The customer requests a refund"},"instructions":"Is the customer requesting a refund?","type":"noul"}"#
        )
    }

    @Test
    func scoreQuestionEncoding() throws {
        let question = SystemOne.Question.score(
            instructions: "How urgently does this ticket need a response?",
            criteria: [
                "Routine: no time pressure",
                "Soon: a customer is inconvenienced",
                "Immediate: a critical service is unavailable",
            ]
        )

        #expect(
            try encode(question)
                == #"{"criteria":["Routine: no time pressure","Soon: a customer is inconvenienced","Immediate: a critical service is unavailable"],"instructions":"How urgently does this ticket need a response?","type":"score"}"#
        )
    }

    @Test
    func contentEncoding() throws {
        #expect(try encode(SystemOne.Content.string("State")) == #""State""#)
        #expect(
            try encode(SystemOne.Content.object(["ticket": "I was charged twice."]))
                == #"{"ticket":"I was charged twice."}"#
        )
        #expect(try encode(SystemOne.Content.array(["a", "b"])) == #"["a","b"]"#)

        let literal: SystemOne.Content = "State"
        #expect(try encode(literal) == #""State""#)
    }

    @Test
    func questionsRoundTrip() throws {
        let questions: [String: SystemOne.Question] = [
            "label": .choice(
                instructions: "Which label fits this ticket?",
                criteria: ["billing": "Payments and refunds", "bug": nil]
            ),
            "refund": .noul(instructions: "Is the customer requesting a refund?"),
            "urgency": .score(
                instructions: "How urgent is this?",
                criteria: ["Routine", "Soon", "Immediate"]
            ),
        ]

        let data = try JSONEncoder().encode(questions)
        let decoded = try JSONDecoder().decode([String: SystemOne.Question].self, from: data)

        #expect(decoded == questions)
    }

    @Test
    func requestValueEncoding() throws {
        // The client builds its request body through `Value`,
        // so the round trip through `Value` must preserve the wire format.
        let questions: [String: SystemOne.Question] = [
            "label": .choice(
                instructions: "Which label fits this ticket?",
                criteria: ["billing": "Payments and refunds", "bug": nil]
            ),
            "refund": .noul(instructions: "Is the customer requesting a refund?"),
        ]

        #expect(
            try encode(Value(questions))
                == #"{"label":{"criteria":{"billing":"Payments and refunds","bug":null},"instructions":"Which label fits this ticket?","type":"choice"},"refund":{"instructions":"Is the customer requesting a refund?","type":"noul"}}"#
        )

        let state: SystemOne.Content = ["ticket": "I was charged twice."]
        #expect(try encode(Value(state)) == #"{"ticket":"I was charged twice."}"#)
    }

    @Test
    func choiceResponseDecoding() throws {
        let json = #"""
            {
              "model": "nimble",
              "answers": {
                "label": {
                  "type": "choice",
                  "choice": "bug",
                  "probabilities": {"billing": 0.0125, "bug": 0.9781, "account": 0.0093},
                  "confidence": 0.8906
                }
              },
              "usage": {"input_tokens": 174, "output_tokens": 1}
            }
            """#

        let response = try JSONDecoder().decode(
            Client.SystemOneResponse.self, from: Data(json.utf8))

        #expect(response.model == "nimble")
        #expect(response.usage.inputTokens == 174)
        #expect(response.usage.outputTokens == 1)
        #expect(
            response.answers["label"]
                == .choice(
                    choice: "bug",
                    probabilities: ["billing": 0.0125, "bug": 0.9781, "account": 0.0093],
                    confidence: 0.8906
                )
        )
    }

    @Test
    func noulAndScoreResponseDecoding() throws {
        let json = #"""
            {
              "model": "nimble",
              "answers": {
                "refund": {"type": "noul", "noul": 0.9989},
                "urgency": {
                  "type": "score",
                  "score": 0.8308,
                  "legend": {"0": "Routine", "1": "Soon", "2": "Immediate"},
                  "probabilities": {"0": 0.25, "1": 0.6692, "2": 0.0808},
                  "confidence": 0.1234
                }
              },
              "usage": {"input_tokens": 200, "output_tokens": 2}
            }
            """#

        let response = try JSONDecoder().decode(
            Client.SystemOneResponse.self, from: Data(json.utf8))

        #expect(response.answers["refund"] == .noul(probability: 0.9989))
        #expect(
            response.answers["urgency"]
                == .score(
                    score: 0.8308,
                    legend: ["0": "Routine", "1": "Soon", "2": "Immediate"],
                    probabilities: ["0": 0.25, "1": 0.6692, "2": 0.0808],
                    confidence: 0.1234
                )
        )
    }

    @Test
    func unknownAnswerTypeFailsDecoding() {
        let json = #"{"type":"unknown"}"#

        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(SystemOne.Answer.self, from: Data(json.utf8))
        }
    }
}

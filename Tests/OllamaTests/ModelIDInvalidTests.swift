import Foundation
import Testing

@testable import Ollama

@Suite
struct ModelIDInvalidTests {
    @Test(arguments: ["", ":", "namespace/:"])
    func missingModelFailsInitialization(rawValue: String) {
        #expect(Model.ID(rawValue: rawValue) == nil)
    }

    @Test(arguments: ["", ":", "namespace/:"])
    func missingModelFailsDecoding(rawValue: String) throws {
        let data = try JSONEncoder().encode(rawValue)
        do {
            _ = try JSONDecoder().decode(Model.ID.self, from: data)
            Issue.record("Expected invalid model ID to fail decoding")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.debugDescription == "Invalid Identifier string: \(rawValue)")
        }
    }

    @Test(arguments: ["llama3:8b", "mistral", "namespace/model:tag", "/", "namespace/model:"])
    func acceptedModelIDsKeepTheirRepresentation(rawValue: String) throws {
        let identifier = try #require(Model.ID(rawValue: rawValue))
        let expected = rawValue == "namespace/model:" ? "namespace/model" : rawValue
        #expect(identifier.rawValue == expected)
        let encoded = try JSONEncoder().encode(identifier)
        #expect(try JSONDecoder().decode(String.self, from: encoded) == expected)
        #expect(try JSONDecoder().decode(Model.ID.self, from: encoded).rawValue == expected)
    }
}

import Foundation
import Testing

@testable import Ollama

@Suite
struct ResponseUsageTests {
    let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
        return decoder
    }()

    @Test
    func generateResponseDecodesPromptEvalCachedCount() throws {
        let json = """
            {"model":"llama3.2","created_at":"2025-01-01T00:00:00.000Z","response":"","done":true,"prompt_eval_count":120,"prompt_eval_cached_count":100,"eval_count":5}
            """
        let response = try decoder.decode(Client.GenerateResponse.self, from: Data(json.utf8))
        #expect(response.promptEvalCount == 120)
        #expect(response.promptEvalCachedCount == 100)
    }

    @Test
    func chatResponseDecodesPromptEvalCachedCount() throws {
        let json = """
            {"model":"llama3.2","created_at":"2025-01-01T00:00:00.000Z","message":{"role":"assistant","content":"Hi"},"done":true,"prompt_eval_count":120,"prompt_eval_cached_count":100,"eval_count":5}
            """
        let response = try decoder.decode(Client.ChatResponse.self, from: Data(json.utf8))
        #expect(response.promptEvalCount == 120)
        #expect(response.promptEvalCachedCount == 100)
    }

    @Test
    func promptEvalCachedCountIsNilWhenMissing() throws {
        let json = """
            {"model":"llama3.2","created_at":"2025-01-01T00:00:00.000Z","message":{"role":"assistant","content":"Hi"},"done":true,"prompt_eval_count":120}
            """
        let response = try decoder.decode(Client.ChatResponse.self, from: Data(json.utf8))
        #expect(response.promptEvalCachedCount == nil)
    }
}

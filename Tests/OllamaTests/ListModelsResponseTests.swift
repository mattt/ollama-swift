import Foundation
import Testing

@testable import Ollama

@Suite
struct ListModelsResponseTests {
    private let details = """
        {"format":"gguf","family":"llama","families":["llama"],"parameter_size":"8B","quantization_level":"Q4_K_M"}
        """

    @Test
    func decodesCapabilitiesFromTags() throws {
        let json = """
            {"models":[{"name":"llama3.1:8b","model":"llama3.1:8b","modified_at":"2025-01-01T00:00:00Z","size":4920753328,"digest":"abc123","details":\(details),"capabilities":["completion","tools"]}]}
            """
        let response = try JSONDecoder().decode(
            Client.ListModelsResponse.self, from: Data(json.utf8))

        let model = try #require(response.models.first)
        #expect(model.capabilities == [.completion, .tools])
    }

    @Test
    func capabilitiesAreNilWhenMissing() throws {
        let json = """
            {"models":[{"name":"llama3.1:8b","modified_at":"2025-01-01T00:00:00Z","size":4920753328,"digest":"abc123","details":\(details)}]}
            """
        let response = try JSONDecoder().decode(
            Client.ListModelsResponse.self, from: Data(json.utf8))

        #expect(response.models.first?.capabilities == nil)
    }

    @Test
    func decodesContextLengthFromPs() throws {
        let json = """
            {"models":[{"name":"llama3.1:8b","model":"llama3.1:8b","size":5137025024,"digest":"abc123","details":\(details),"expires_at":"2025-01-01T00:05:00Z","size_vram":5137025024,"context_length":8192}]}
            """
        let response = try JSONDecoder().decode(
            Client.ListRunningModelsResponse.self, from: Data(json.utf8))

        #expect(response.models.first?.contextLength == 8192)
    }

    @Test
    func contextLengthIsNilWhenMissing() throws {
        let json = """
            {"models":[{"name":"llama3.1:8b","model":"llama3.1:8b","size":5137025024,"digest":"abc123","details":\(details),"expires_at":"2025-01-01T00:05:00Z","size_vram":5137025024}]}
            """
        let response = try JSONDecoder().decode(
            Client.ListRunningModelsResponse.self, from: Data(json.utf8))

        #expect(response.models.first?.contextLength == nil)
    }
}

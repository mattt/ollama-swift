import Testing
import XCTest

@testable import Ollama

@Suite(.serialized)
struct ClientTests {
    let ollama: Client

    init() async {
        ollama = await Client(host: Client.defaultHost)
    }

    @Test
    func testGenerateWithImage() async throws {
        // Create a transparent 1x1 pixel image
        let imageData = Data(
            base64Encoded:
                "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+ip1sAAAAASUVORK5CYII="
        )!
        let prompt = "Describe this image in detail."

        let response = try await ollama.generate(
            model: "llama3.2",
            prompt: prompt,
            images: [imageData],
            stream: false
        )

        #expect(!response.response.isEmpty)
        #expect(response.done)
        #expect(response.model == "llama3.2")
        #expect(response.createdAt != nil)
        #expect(response.totalDuration ?? 0 > 0)
        #expect(response.loadDuration ?? 0 > 0)
        #expect(response.promptEvalCount ?? 0 > 0)
    }

    @Test
    func testChatCompletion() async throws {
        let messages: [Chat.Message] = [
            .system("You are a helpful AI assistant."),
            .user("Write a haiku about llamas."),
        ]

        let response = try await ollama.chat(
            model: "llama3.2",
            messages: messages)
        #expect(!response.message.content.isEmpty)
    }

    @Test
    func testEmbed() async throws {
        let input = "This is a test sentence for embedding."
        let response = try await ollama.embed(model: "llama3.2", input: input)

        #expect(!response.embeddings.rawValue.isEmpty)
        #expect(response.totalDuration > 0)
        #expect(response.loadDuration > 0)
        #expect(response.promptEvalCount > 0)
    }

    @Test
    func testListModels() async throws {
        let response = try await ollama.listModels()

        #expect(!response.models.isEmpty)
        #expect(response.models.first != nil)
    }

    @Test
    func testListRunningModels() async throws {
        let response = try await ollama.listRunningModels()

        // This test might be flaky if no models are running
        // Consider starting a model before running this test
        #expect(response != nil)
    }

    @Test
    func testCreateShowDeleteModel() async throws {
        let base = "llama3.2"
        let name: Model.ID = "test-\(UUID().uuidString)"
        let modelfile =
            """
            FROM \(base)
            PARAMETER temperature 0.7
            """

        // Create model
        var success = try await ollama.createModel(name: name, modelfile: modelfile)
        #expect(success)

        // Show model
        let response = try await ollama.showModel(name)
        #expect(response.details.parentModel?.hasPrefix(base + ":") ?? false)

        // Delete model
        success = try await ollama.deleteModel(name)
        #expect(success)

        // Verify deletion
        do {
            _ = try await ollama.showModel(name)
            Issue.record("Model should have been deleted")
        } catch {
            // Expected error
        }
    }
}

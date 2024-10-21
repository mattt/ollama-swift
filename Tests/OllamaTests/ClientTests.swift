import XCTest

@testable import Ollama

final class ClientTests: XCTestCase {
    let ollama = Ollama.Client.default

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

        XCTAssertFalse(response.response.isEmpty)
        XCTAssertTrue(response.done)
        XCTAssertEqual(response.model, "llama3.2")
        XCTAssertNotNil(response.createdAt)
        XCTAssertGreaterThan(response.totalDuration ?? 0, 0)
        XCTAssertGreaterThan(response.loadDuration ?? 0, 0)
        XCTAssertGreaterThan(response.promptEvalCount ?? 0, 0)
    }

    func testChatCompletion() async throws {
        let messages: [Chat.Message] = [
            .system("You are a helpful AI assistant."),
            .user("Write a haiku about llamas."),
        ]

        let response = try await ollama.chat(
            model: "llama3.2",
            messages: messages)
        XCTAssertFalse(response.message.content.isEmpty)
    }

    func testEmbed() async throws {
        let input = "This is a test sentence for embedding."
        let response = try await ollama.embed(model: "llama3.2", input: input)

        XCTAssertFalse(response.embeddings.rawValue.isEmpty)
        XCTAssertGreaterThan(response.totalDuration, 0)
        XCTAssertGreaterThan(response.loadDuration, 0)
        XCTAssertGreaterThan(response.promptEvalCount, 0)
    }

    func testListModels() async throws {
        let response = try await ollama.listModels()

        XCTAssertFalse(response.models.isEmpty)
        XCTAssertNotNil(response.models.first)
    }

    func testListRunningModels() async throws {
        let response = try await ollama.listRunningModels()

        // This test might be flaky if no models are running
        // Consider starting a model before running this test
        XCTAssertNotNil(response)
    }

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
        XCTAssertTrue(success)

        // Show model
        let response = try await ollama.showModel(name)
        XCTAssertTrue(response.details.parentModel?.hasPrefix(base + ":") ?? false)

        // Delete model
        success = try await ollama.deleteModel(name)
        XCTAssertTrue(success)

        // Verify deletion
        do {
            _ = try await ollama.showModel(name)
            XCTFail("Model should have been deleted")
        } catch {
            // Expected error
        }
    }
}

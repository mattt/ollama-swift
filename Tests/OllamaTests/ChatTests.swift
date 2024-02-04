import XCTest
@testable import Ollama

final class ChatTests: XCTestCase {
    let ollama = Ollama.Client.default
    
    func testChatCompletion() async throws {
        let messages: [Chat.Message] = [
            .system("You are a helpful AI assistant."),
            .user("Write a haiku about llamas.")
        ]
        
        let response = try await ollama.chat(model: "mistral",
                                             messages: messages)
        print(response.message.content)
    }
}

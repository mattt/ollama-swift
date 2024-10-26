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

        let (_, response) = try await ollama.chat(
            model: "llama3.2",
            messages: messages)
        
        XCTAssertFalse(response.message.content.isEmpty)
    }
    
    func testChatToolCompletion() async throws {
        let tools = [
            Chat.Tool(
                name: "add",
                description: "A function that adds two numbers",
                parameters: [
                    Chat.Tool.ToolParameter(name: "x", description: "The first number", parameterType: .number, required: true),
                    Chat.Tool.ToolParameter(name: "y", description: "The second number", parameterType: .number, required: true)
                ],
                action: { (parameters: [String : Value]) in
                    guard let x: Double = parameters["x"]?.asDoubleValue,
                          let y: Double = parameters["y"]?.asDoubleValue
                    else {
                        return .null
                    }
                    
                    return .double(x + y)
                }
            )
        ]
        
        var messages: [Chat.Message] = [
            .system("You are a helpful AI assistant. Who will use a tool to help you when needed."),
            .user("What is 23 + 58 ?"),
        ]
        
        let (_, response) = try await ollama.chat(
            model: "llama3.2",
            messages: messages,
            tools: tools,
            toolApproval: nil)
        
        XCTAssertNotNil(response.message.tool_calls)
        XCTAssertTrue(response.message.content.isEmpty)
        
        // - Manually process tool call
        
        let toolCalls = response.message.tool_calls!
        let replyMessage = try await ollama.processToolCalls(toolCalls, tools: tools)
        
        messages.append(replyMessage.1)
        
        let (_, secondResponse) = try await ollama.chat(
            model: "llama3.2",
            messages: messages
        )
        
        XCTAssertFalse(secondResponse.message.content.isEmpty)
        XCTAssertTrue(secondResponse.message.content.contains("81"))
    }
    
    func testChatToolDeniedCompletion() async throws {
        let tools = [
            Chat.Tool(
                name: "current_location",
                description: "Gets the user's current location",
                parameters: [],
                action: { (parameters: [String : Value]) in
                    return "New York"
                }
            ),
            Chat.Tool(
                name: "add",
                description: "A function that adds two numbers",
                parameters: [
                    Chat.Tool.ToolParameter(name: "x", description: "The first number", parameterType: .number, required: true),
                    Chat.Tool.ToolParameter(name: "y", description: "The second number", parameterType: .number, required: true)
                ],
                action: { (parameters: [String : Value]) in
                    guard let x: Double = parameters["x"]?.asDoubleValue,
                          let y: Double = parameters["y"]?.asDoubleValue
                    else {
                        return .null
                    }
                    
                    return .double(x + y)
                }
            )
        ]
        
        // - Check rejection
        
        let messages: [Chat.Message] = [
            .system("You are a helpful AI assistant. Who will use a tool to help you when needed."),
            .user("What is the town I am in now called? What is 23 + 58 ?"),
        ]
        
        let (_, response) = try await ollama.chat(
            model: "llama3.2",
            messages: messages,
            tools: tools,
            toolApproval: { (toolCall, tool) in
                if tool.definition.function.name == "current_location" {
                    return false
                }
                
                return true
            })
        
        XCTAssertTrue(response.message.content.contains("81"))
        XCTAssertFalse(response.message.content.contains("New York"))
        
        // - Check approval
        
        let (_, approvedResponse) = try await ollama.chat(
            model: "llama3.2",
            messages: messages,
            tools: tools,
            toolApproval: { (toolCall, tool) in
                return true
            })
        
        XCTAssertTrue(approvedResponse.message.content.contains("81"))
        XCTAssertTrue(approvedResponse.message.content.contains("New York"))
    }
    
    func testChatToolAutoCompletion() async throws {
        let tools = [
            Chat.Tool(
                name: "add",
                description: "A function that adds two numbers",
                parameters: [
                    Chat.Tool.ToolParameter(name: "x", description: "The first number", parameterType: .number, required: true),
                    Chat.Tool.ToolParameter(name: "y", description: "The second number", parameterType: .number, required: true)
                ],
                action: { (parameters: [String : Value]) in
                    guard let x: Double = parameters["x"]?.asDoubleValue,
                          let y: Double = parameters["y"]?.asDoubleValue
                    else {
                        return .null
                    }
                    
                    return .double(x + y)
                }
            )
        ]
        
        let messages: [Chat.Message] = [
            .system("You are a helpful AI assistant. Who will use a tool to help you when needed."),
            .user("What is 23 + 58 ?"),
        ]
        
        let (chatMessages, response) = try await ollama.chat(
            model: "llama3.2",
            messages: messages,
            tools: tools)
        
        XCTAssertTrue(chatMessages.count == 4)
        
        XCTAssertTrue(chatMessages[0].role == .system)
        XCTAssertTrue(chatMessages[1].role == .user)
        XCTAssertTrue(chatMessages[2].role == .assistant)
        XCTAssertTrue(chatMessages[3].role == .tool)
        
        XCTAssertFalse(response.message.content.isEmpty)
        XCTAssertTrue(response.message.content.contains("81"))
    }
    
    func testChatMultiToolAutoCompletion() async throws {
        let tools = [
            Chat.Tool(
                name: "add",
                description: "A function that adds two numbers",
                parameters: [
                    Chat.Tool.ToolParameter(name: "x", description: "The first number", parameterType: .number, required: true),
                    Chat.Tool.ToolParameter(name: "y", description: "The second number", parameterType: .number, required: true)
                ],
                action: { (parameters: [String : Value]) in
                    guard let x: Double = parameters["x"]?.asDoubleValue,
                          let y: Double = parameters["y"]?.asDoubleValue
                    else {
                        return .null
                    }
                    
                    return .double(x + y)
                }
            ),
            Chat.Tool(
                name: "divide",
                description: "A function that divides two numbers",
                parameters: [
                    Chat.Tool.ToolParameter(name: "x", description: "The first number", parameterType: .number, required: true),
                    Chat.Tool.ToolParameter(name: "y", description: "The second number", parameterType: .number, required: true)
                ],
                action: { (parameters: [String : Value]) in
                    guard let x: Double = parameters["x"]?.asDoubleValue,
                          let y: Double = parameters["y"]?.asDoubleValue,
                          x.isNormal,
                          y.isNormal, !y.isZero
                    else {
                        return .null
                    }
                    
                    return .double(x / y)
                }
            )
        ]
        
        let messages: [Chat.Message] = [
            .system("You are a helpful AI assistant. Who will use a tool to help you when needed."),
            .user("What the answer to these questions: What is (23 + 58)? And what is (497 / 71) ?"),
        ]
        
        let (chatMessages, response) = try await ollama.chat(
            model: "llama3.2",
            messages: messages,
            tools: tools)
        
        XCTAssertTrue(chatMessages.count > messages.count)
        XCTAssertTrue(chatMessages.last?.role == .tool)
        
        XCTAssertFalse(response.message.content.isEmpty)
        XCTAssertTrue(response.message.content.contains("81"))
        XCTAssertTrue(response.message.content.contains("7"))
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

import Foundation
import Testing

@testable import Ollama

@Suite
struct ChatMessageTests {
    @Test
    func decodesToolCallID() throws {
        let json = """
            {
              "role": "assistant",
              "content": "",
              "tool_calls": [
                {
                  "id": "call_abc123",
                  "function": {
                    "name": "get_weather",
                    "arguments": {"city": "Paris"}
                  }
                }
              ]
            }
            """
        let message = try JSONDecoder().decode(Chat.Message.self, from: Data(json.utf8))

        let toolCall = try #require(message.toolCalls?.first)
        #expect(toolCall.id == "call_abc123")
        #expect(toolCall.function.name == "get_weather")
        #expect(toolCall.function.arguments["city"] == .string("Paris"))
    }

    @Test
    func decodesToolCallWithoutID() throws {
        let json = """
            {
              "role": "assistant",
              "content": "",
              "tool_calls": [
                {"function": {"name": "get_weather", "arguments": {}}}
              ]
            }
            """
        let message = try JSONDecoder().decode(Chat.Message.self, from: Data(json.utf8))

        let toolCall = try #require(message.toolCalls?.first)
        #expect(toolCall.id == nil)
    }

    @Test
    func encodesToolResultWithNameAndCallID() throws {
        let message = Chat.Message.tool(
            "{\"temperature\": 21}",
            toolName: "get_weather",
            toolCallID: "call_abc123"
        )

        let value = try Value(message)
        let object = try #require(value.objectValue)
        #expect(object["role"] == .string("tool"))
        #expect(object["tool_name"] == .string("get_weather"))
        #expect(object["tool_call_id"] == .string("call_abc123"))

        let decoded = try JSONDecoder().decode(
            Chat.Message.self, from: JSONEncoder().encode(message))
        #expect(decoded == message)
    }

    @Test
    func omitsToolFieldsWhenNotSet() throws {
        let value = try Value(Chat.Message.tool("ok"))
        let object = try #require(value.objectValue)
        #expect(object["tool_name"] == nil)
        #expect(object["tool_call_id"] == nil)
    }

    @Test
    func encodesAssistantToolCallID() throws {
        let message = Chat.Message.assistant(
            "",
            toolCalls: [
                .init(id: "call_1", function: .init(name: "get_weather", arguments: [:]))
            ]
        )

        let value = try Value(message)
        let toolCalls = try #require(value.objectValue?["tool_calls"]?.arrayValue)
        #expect(toolCalls.first?.objectValue?["id"] == .string("call_1"))
    }
}

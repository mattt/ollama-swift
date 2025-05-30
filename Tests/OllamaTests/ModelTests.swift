import Foundation
import Testing

@testable import Ollama

@Suite
struct ModelTests {
    @Test
    func testCapabilityInitialization() throws {
        // Test string literal initialization
        let completion: Model.Capability = "completion"
        #expect(completion.rawValue == "completion")

        // Test raw value initialization
        let tools = Model.Capability(rawValue: "tools")
        #expect(tools.rawValue == "tools")

        // Test predefined capabilities
        #expect(Model.Capability.completion.rawValue == "completion")
        #expect(Model.Capability.tools.rawValue == "tools")
        #expect(Model.Capability.insert.rawValue == "insert")
        #expect(Model.Capability.vision.rawValue == "vision")
        #expect(Model.Capability.embedding.rawValue == "embedding")
        #expect(Model.Capability.thinking.rawValue == "thinking")
    }

    @Test
    func testCapabilityComparison() throws {
        let completion: Model.Capability = "completion"
        let tools: Model.Capability = "tools"

        // Test equality
        #expect(completion == Model.Capability.completion)
        #expect(tools == Model.Capability.tools)
        #expect(completion != tools)

        // Test comparison
        #expect(completion < tools)  // "completion" < "tools" alphabetically
        #expect(tools > completion)
    }

    @Test
    func testCapabilityCoding() throws {
        let capability: Model.Capability = "completion"

        // Test encoding
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(capability)

        // Test decoding
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Model.Capability.self, from: encoded)

        // Verify roundtrip
        #expect(decoded == capability)
        #expect(decoded.rawValue == capability.rawValue)
    }

    @Test
    func testCustomCapability() throws {
        // Test creating a custom capability
        let custom: Model.Capability = "custom_feature"
        #expect(custom.rawValue == "custom_feature")

        // Test that custom capabilities work with comparison
        #expect(custom > Model.Capability.completion)  // "custom_feature" > "completion" alphabetically
        #expect(custom < Model.Capability.vision)  // "custom_feature" < "vision" alphabetically
    }

    @Test
    func testCapabilityCollection() throws {
        // Test using capabilities in collections
        let capabilities: Set<Model.Capability> = [
            .completion,
            .tools,
            .insert,
            .vision,
            .embedding,
            .thinking,
        ]

        #expect(capabilities.count == 6)
        #expect(capabilities.contains(.completion))
        #expect(capabilities.contains(.tools))
        #expect(capabilities.contains(.insert))
        #expect(capabilities.contains(.vision))
        #expect(capabilities.contains(.embedding))
        #expect(capabilities.contains(.thinking))

        // Test array sorting
        let sorted = capabilities.sorted()
        #expect(sorted[0] == .completion)
        #expect(sorted[1] == .embedding)
        #expect(sorted[2] == .insert)
        #expect(sorted[3] == .thinking)
        #expect(sorted[4] == .tools)
        #expect(sorted[5] == .vision)
    }
}

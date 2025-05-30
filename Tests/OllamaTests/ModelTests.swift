import Foundation
import Testing

@testable import Ollama

@Suite
struct ModelTests {
    @Suite
    struct IDTests {
        @Test
        func testModelIDInitialization() throws {
            // Test with real Ollama model identifiers
            
            // Full format with namespace
            guard let deepseekModel = Model.ID(rawValue: "deepseek/deepseek-r1:7b") else {
                Issue.record("Failed to create Model.ID with namespace")
                return
            }
            #expect(deepseekModel.namespace == "deepseek")
            #expect(deepseekModel.model == "deepseek-r1")
            #expect(deepseekModel.tag == "7b")
            
            // Model with tag (most common format on Ollama)
            guard let llama3Model = Model.ID(rawValue: "llama3:8b") else {
                Issue.record("Failed to create Model.ID with tag")
                return
            }
            #expect(llama3Model.namespace == nil)
            #expect(llama3Model.model == "llama3")
            #expect(llama3Model.tag == "8b")
            
            // Model without tag
            guard let mistralModel = Model.ID(rawValue: "mistral") else {
                Issue.record("Failed to create Model.ID without tag")
                return
            }
            #expect(mistralModel.namespace == nil)
            #expect(mistralModel.model == "mistral")
            #expect(mistralModel.tag == nil)
            
            // Vision model
            guard let llavaModel = Model.ID(rawValue: "llava:7b") else {
                Issue.record("Failed to create Model.ID for vision model")
                return
            }
            #expect(llavaModel.model == "llava")
            #expect(llavaModel.tag == "7b")
            
            // Embedding model
            guard let embedModel = Model.ID(rawValue: "nomic-embed-text") else {
                Issue.record("Failed to create Model.ID for embedding model")
                return
            }
            #expect(embedModel.model == "nomic-embed-text")
            #expect(embedModel.tag == nil)
        }
        
        @Test
        func testModelIDRawValue() throws {
            // Test with real Ollama models
            let qwen: Model.ID = "qwen2.5:72b"
            #expect(qwen.rawValue == "qwen2.5:72b")
            
            let gemma: Model.ID = "gemma2:27b"
            #expect(gemma.rawValue == "gemma2:27b")
            
            let codellama: Model.ID = "codellama:34b"
            #expect(codellama.rawValue == "codellama:34b")
            
            let phi4: Model.ID = "phi4:14b"
            #expect(phi4.rawValue == "phi4:14b")
        }
        
        @Test
        func testModelIDEquality() throws {
            // Test with real model names
            let llama1: Model.ID = "llama3.1:70b"
            let llama2: Model.ID = "llama3.1:70b"
            let llama3: Model.ID = "LLAMA3.1:70B"  // Different case
            let llama4: Model.ID = "llama3.2:70b"  // Different version
            
            // Test equality
            #expect(llama1 == llama2)
            #expect(llama1 == llama3)  // Case-insensitive
            #expect(llama1 != llama4)  // Different model
            
            // Test with embedding models
            let embed1: Model.ID = "mxbai-embed-large"
            let embed2: Model.ID = "MXBAI-EMBED-LARGE"
            #expect(embed1 == embed2)  // Case-insensitive
        }
        
        @Test
        func testModelIDComparison() throws {
            // Test with real Ollama models
            let codellama: Model.ID = "codellama:7b"
            let llama2: Model.ID = "llama2:7b"
            let llama3: Model.ID = "llama3:7b"
            
            // Test comparison (alphabetical)
            #expect(codellama < llama2)
            #expect(llama2 < llama3)
            #expect(codellama < llama3)
        }
        
        @Test
        func testModelIDStringLiteral() throws {
            // Real Ollama models as string literals
            let mistral: Model.ID = "mistral:7b"
            #expect(mistral.model == "mistral")
            #expect(mistral.tag == "7b")
            
            let qwq: Model.ID = "qwq:32b"
            #expect(qwq.model == "qwq")
            #expect(qwq.tag == "32b")
            
            let deepseek: Model.ID = "deepseek-v3:671b"
            #expect(deepseek.model == "deepseek-v3")
            #expect(deepseek.tag == "671b")
        }
        
        @Test
        func testModelIDStringInterpolation() throws {
            // Build model IDs dynamically
            let model = "qwen2.5-coder"
            let size = "32b"
            
            let coder: Model.ID = "\(model):\(size)"
            #expect(coder.model == "qwen2.5-coder")
            #expect(coder.tag == "32b")
        }
        
        @Test
        func testModelIDDescription() throws {
            let dolphin: Model.ID = "dolphin3:8b"
            #expect(dolphin.description == "dolphin3:8b")
            
            let vision: Model.ID = "llama3.2-vision:11b"
            #expect(vision.description == "llama3.2-vision:11b")
        }
        
        @Test
        func testModelIDCodable() throws {
            let original: Model.ID = "llava:34b"
            
            // Test encoding
            let encoder = JSONEncoder()
            let encoded = try encoder.encode(original)
            let encodedString = String(data: encoded, encoding: .utf8)!
            #expect(encodedString == "\"llava:34b\"")
            
            // Test decoding
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(Model.ID.self, from: encoded)
            #expect(decoded == original)
            #expect(decoded.model == "llava")
            #expect(decoded.tag == "34b")
            
            // Test array of models
            let models: [Model.ID] = ["llama3:8b", "mistral:7b", "gemma2:9b"]
            let encodedArray = try encoder.encode(models)
            let decodedArray = try decoder.decode([Model.ID].self, from: encodedArray)
            #expect(decodedArray.count == 3)
            #expect(decodedArray[0].model == "llama3")
            #expect(decodedArray[1].model == "mistral")
            #expect(decodedArray[2].model == "gemma2")
        }
        
        @Test
        func testModelIDPatternMatching() throws {
            let model: Model.ID = "qwen2.5:72b"
            
            // Test exact match
            let pattern1: Model.ID = "qwen2.5:72b"
            #expect(pattern1 ~= model)
            
            // Test pattern without tag (should match any tag)
            let pattern2: Model.ID = "qwen2.5"
            #expect(pattern2 ~= model)
            
            // Test non-matching patterns
            let pattern3: Model.ID = "qwen2:72b"  // Different model version
            #expect(!(pattern3 ~= model))
            
            let pattern4: Model.ID = "qwen2.5:7b"  // Different tag
            #expect(!(pattern4 ~= model))
        }
        
        @Test
        func testModelIDHashable() throws {
            // Test with popular Ollama models
            let llama3_8b: Model.ID = "llama3:8b"
            let llama3_8b_dup: Model.ID = "llama3:8b"
            let llama3_70b: Model.ID = "llama3:70b"
            
            // Test Set behavior
            var modelSet: Set<Model.ID> = []
            modelSet.insert(llama3_8b)
            modelSet.insert(llama3_8b_dup)  // Should not increase count
            modelSet.insert(llama3_70b)
            
            #expect(modelSet.count == 2)
            #expect(modelSet.contains(llama3_8b))
            #expect(modelSet.contains(llama3_70b))
            
            // Test Dictionary usage
            var modelCapabilities: [Model.ID: [Model.Capability]] = [:]
            modelCapabilities["llava:7b"] = [.vision, .completion]
            modelCapabilities["nomic-embed-text"] = [.embedding]
            modelCapabilities["qwen3:8b"] = [.tools, .thinking]
            
            #expect(modelCapabilities.count == 3)
            #expect(modelCapabilities["llava:7b"]?.contains(.vision) == true)
        }
        
        @Test
        func testModelIDEdgeCases() throws {
            // Test with model names containing special characters
            guard let hyphenated = Model.ID(rawValue: "llama-guard3:8b") else {
                Issue.record("Failed to create Model.ID with hyphenated name")
                return
            }
            #expect(hyphenated.model == "llama-guard3")
            #expect(hyphenated.tag == "8b")
            
            // Test with version numbers in model names
            guard let versioned = Model.ID(rawValue: "qwen2.5-coder:32b") else {
                Issue.record("Failed to create Model.ID with versioned name")
                return
            }
            #expect(versioned.model == "qwen2.5-coder")
            #expect(versioned.tag == "32b")
            
            // Test with unusual tag formats
            guard let complexTag = Model.ID(rawValue: "mixtral:8x7b") else {
                Issue.record("Failed to create Model.ID with complex tag")
                return
            }
            #expect(complexTag.model == "mixtral")
            #expect(complexTag.tag == "8x7b")
            
            // Test with very large parameter counts
            guard let largeModel = Model.ID(rawValue: "command-a:111b") else {
                Issue.record("Failed to create Model.ID with large parameter count")
                return
            }
            #expect(largeModel.model == "command-a")
            #expect(largeModel.tag == "111b")
        }
    }
    
    @Suite
    struct CapabilityTests {
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
}

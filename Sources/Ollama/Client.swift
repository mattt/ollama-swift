import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// An Ollama HTTP API client.
///
/// This client provides methods to interact with the Ollama API,
/// allowing you to generate text, chat, create embeddings, and manage models.
///
/// - SeeAlso: [Ollama API Documentation](https://github.com/ollama/ollama/blob/main/docs/api.md)
open class Client {
    /// The default host URL for the Ollama API.
    public static let defaultHost = URL(string: "http://localhost:11434")!

    /// A default client instance using the default host.
    public static let `default` = Client(host: Client.defaultHost)

    /// The host URL for requests made by the client.
    public let host: URL

    /// The value for the `User-Agent` header sent in requests, if any.
    public let userAgent: String?

    /// The underlying client session.
    internal(set) public var session: URLSession
	
	/// A list of tools to include in chat requests
	var tools: [Chat.Tool] = []

    /// Creates a client with the specified session, host, and user agent.
    ///
    /// - Parameters:
    ///   - session: The underlying client session. Defaults to `URLSession(configuration: .default)`.
    ///   - host: The host URL to use for requests.
    ///   - userAgent: The value for the `User-Agent` header sent in requests, if any. Defaults to `nil`.
    public init(
        session: URLSession = URLSession(configuration: .default),
        host: URL,
        userAgent: String? = nil
    ) {
        var host = host
        if !host.path.hasSuffix("/") {
            host = host.appendingPathComponent("")
        }

        self.host = host
        self.userAgent = userAgent
        self.session = session
    }

    /// Represents errors that can occur during API operations.
    public enum Error: Swift.Error, CustomStringConvertible {
        /// An error encountered while constructing the request.
        case requestError(String)

        /// An error returned by the Ollama HTTP API.
        case responseError(response: HTTPURLResponse, detail: String)

        /// An error encountered while decoding the response.
        case decodingError(response: HTTPURLResponse, detail: String)

        /// An unexpected error.
        case unexpectedError(String)

        // MARK: CustomStringConvertible

        public var description: String {
            switch self {
            case .requestError(let detail):
                return "Request error: \(detail)"
            case .responseError(let response, let detail):
                return "Response error (Status \(response.statusCode)): \(detail)"
            case .decodingError(let response, let detail):
                return "Decoding error (Status \(response.statusCode)): \(detail)"
            case .unexpectedError(let detail):
                return "Unexpected error: \(detail)"
            }
        }
    }

    private struct ErrorResponse: Decodable {
        let error: String
    }

    enum Method: String, Hashable {
        case get = "GET"
        case post = "POST"
        case delete = "DELETE"
    }

    func fetch<T: Decodable>(
        _ method: Method,
        _ path: String,
        params: [String: Value]? = nil
    )
        async throws -> T
    {
        var urlComponents = URLComponents(url: host, resolvingAgainstBaseURL: true)
        urlComponents?.path = path

        var httpBody: Data? = nil
        switch method {
        case .get:
            if let params {
                var queryItems: [URLQueryItem] = []
                for (key, value) in params {
                    queryItems.append(URLQueryItem(name: key, value: value.description))
                }
                urlComponents?.queryItems = queryItems
            }
        case .post, .delete:
            if let params {
                let encoder = JSONEncoder()
                httpBody = try encoder.encode(params)
            }
        }

        guard let url = urlComponents?.url else {
            throw Error.requestError(
                #"Unable to construct URL with host "\#(host)" and path "\#(path)""#)
        }
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = method.rawValue

        request.addValue("application/json", forHTTPHeaderField: "Accept")
        if let userAgent {
            request.addValue(userAgent, forHTTPHeaderField: "User-Agent")
        }

        if let httpBody {
            request.httpBody = httpBody
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw Error.unexpectedError("Response is not HTTPURLResponse")
        }

        switch httpResponse.statusCode {
        case 200..<300:
            if T.self == Bool.self {
                // If T is Bool, we return true for successful response
                return true as! T
            } else if data.isEmpty {
                throw Error.responseError(response: httpResponse, detail: "Empty response body")
            } else {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds

                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw Error.decodingError(
                        response: httpResponse,
                        detail: "Error decoding response: \(error.localizedDescription)"
                    )
                }
            }
        default:
            if T.self == Bool.self {
                // If T is Bool, we return false for unsuccessful response
                return false as! T
            }

            if let errorDetail = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw Error.responseError(response: httpResponse, detail: errorDetail.error)
            }

            if let string = String(data: data, encoding: .utf8) {
                throw Error.responseError(response: httpResponse, detail: string)
            }

            throw Error.responseError(response: httpResponse, detail: "Invalid response")
        }
    }
}

// MARK: - Generate

extension Client {
    public struct GenerateResponse: Hashable, Decodable {
        public let model: Model.ID
        public let createdAt: Date
        public let response: String
        public let done: Bool
        public let context: [Int]?
        public let totalDuration: TimeInterval?
        public let loadDuration: TimeInterval?
        public let promptEvalCount: Int?
        public let promptEvalDuration: TimeInterval?
        public let evalCount: Int?
        public let evalDuration: TimeInterval?

        enum CodingKeys: String, CodingKey {
            case model
            case createdAt = "created_at"
            case response
            case done
            case context
            case totalDuration = "total_duration"
            case loadDuration = "load_duration"
            case promptEvalCount = "prompt_eval_count"
            case promptEvalDuration = "prompt_eval_duration"
            case evalCount = "eval_count"
            case evalDuration = "eval_duration"
        }
    }

    /// Generates a response for a given prompt with a provided model.
    ///
    /// - Parameters:
    ///   - model: The name of the model to use for generation.
    ///   - prompt: The prompt to generate a response for.
    ///   - images: Optional list of base64-encoded images (for multimodal models).
    ///   - format: The format to return a response in. Currently, the only accepted value is "json".
    ///   - options: Additional model parameters as specified in the Modelfile documentation.
    ///   - system: System message to override what is defined in the Modelfile.
    ///   - template: The prompt template to use (overrides what is defined in the Modelfile).
    ///   - context: The context parameter returned from a previous request to keep a short conversational memory.
    ///   - stream: If false, the response will be returned as a single response object, rather than a stream of objects.
    ///   - raw: If true, no formatting will be applied to the prompt.
    /// - Returns: A `GenerateResponse` containing the generated text and additional information.
    /// - Throws: An error if the request fails or the response cannot be decoded.
    public func generate(
        model: Model.ID,
        prompt: String,
        images: [Data]? = nil,
        format: String? = nil,
        options: [String: Value]? = nil,
        system: String? = nil,
        template: String? = nil,
        context: [Int]? = nil,
        stream: Bool = true,
        raw: Bool = false
    )
        async throws -> GenerateResponse
    {
        var params: [String: Value] = [
            "model": .string(model.rawValue),
            "prompt": .string(prompt),
            "stream": .bool(stream),
            "raw": .bool(raw),
        ]

        if let images = images {
            params["images"] = .array(images.map { .string($0.base64EncodedString()) })
        }
        if let format = format {
            params["format"] = .string(format)
        }
        if let options = options {
            params["options"] = .object(options)
        }
        if let system = system {
            params["system"] = .string(system)
        }
        if let template = template {
            params["template"] = .string(template)
        }
        if let context = context {
            params["context"] = .array(context.map { .double(Double($0)) })
        }

        return try await fetch(.post, "/api/generate", params: params)
    }
}

// MARK: - Chat

extension Client {
    public struct ChatResponse: Hashable, Decodable {
        public let model: Model.ID
        public let createdAt: Date
        public let message: Chat.Message
        public let done: Bool

        public let totalDuration: TimeInterval?
        public let loadDuration: TimeInterval?
        public let promptEvalCount: Int?
        public let promptEvalDuration: TimeInterval?
        public let evalCount: Int?
        public let evalDuration: TimeInterval?

        private enum CodingKeys: String, CodingKey {
            case model
            case createdAt = "created_at"
            case message
            case done
            case totalDuration = "total_duration"
            case loadDuration = "load_duration"
            case promptEvalCount = "prompt_eval_count"
            case promptEvalDuration = "prompt_eval_duration"
            case evalCount = "eval_count"
            case evalDuration = "eval_duration"
        }
    }

    /// Generates the next message in a chat with a provided model.
    ///
    /// - Parameters:
    ///   - model: The name of the model to use for the chat.
    ///   - messages: The messages of the chat, used to keep a chat memory.
    ///   - options: Additional model parameters as specified in the Modelfile documentation.
    ///   - tools: Override the list of tools to include in this chat.
    ///   - template: The prompt template to use (overrides what is defined in the Modelfile).
    /// - Returns: A `ChatResponse` containing the generated message and additional information.
    /// - Throws: An error if the request fails or the response cannot be decoded.
    public func chat(
        model: Model.ID,
        messages: [Chat.Message],
        options: [String: Value]? = nil,
        tools: [Chat.ToolDefinition]? = nil,
        template: String? = nil
    )
        async throws -> ChatResponse
    {
        let toolDefinitions: [Chat.ToolDefinition] = tools ?? self.tools.map({ $0.definition })
        
        var params: [String: Value] = [
            "model": .string(model.rawValue),
            "messages": try Value(messages),
            "stream": false,
        ]

        if let options {
            params["options"] = .object(options)
        }

        if let template {
            params["template"] = .string(template)
        }
        
        if toolDefinitions.count > 0 {
            params["tools"] = try Value(toolDefinitions)
        }
        
        return try await fetch(.post, "/api/chat", params: params)
        
    }
    
    /// Generates the next message in a chat with a provided model.
    ///
    /// - Parameters:
    ///   - model: The name of the model to use for the chat.
    ///   - messages: The messages of the chat, used to keep a chat memory.
    ///   - options: Additional model parameters as specified in the Modelfile documentation.
    ///   - tools: Override the list of tools to include in this chat.
    ///   - template: The prompt template to use (overrides what is defined in the Modelfile).
    /// - Returns: A `ChatResponse` containing the generated message and additional information.
    /// - Throws: An error if the request fails or the response cannot be decoded.
    public func autoRunChat(
        model: Model.ID,
        messages: [Chat.Message],
        options: [String: Value]? = nil,
        tools: [Chat.ToolDefinition]? = nil,
        template: String? = nil
    )
    async throws -> ([Chat.Message], ChatResponse)
    {
        let response: ChatResponse = try await chat(
            model: model,
            messages: messages,
            options: options,
            tools: tools,
            template: template
        )
        
        if let toolCalls = response.message.tool_calls
        {
            let (_, replyMessage) = try self.processToolCalls(toolCalls)
            
            var newMessages: [Chat.Message] = messages
            newMessages.append(response.message)
            newMessages.append(replyMessage)
            
            let response: ChatResponse = try await chat(
                model: model,
                messages: newMessages,
                options: options,
                tools: tools,
                template: template
            )
            
            return (newMessages, response)
        }
        else {
            return (messages, response)
        }
    }
    
    /// Used to return the function call results back to the LLM
    public struct ToolCallResult: Encodable {
        /// The name of the function called
        let function: String
        /// The result of calling the function
        let result: Value
    }
    
    public func processToolCalls(_ toolCalls: [Chat.Message.ToolCall]) throws -> ([ToolCallResult], Chat.Message) {
        var responses: [ToolCallResult] = []
        
        for toolCall in toolCalls {
            if let matchingTool = self.tools.first(where: { $0.definition.function.name == toolCall.function.name })
            {
                let result: Value = matchingTool.action(toolCall.function.arguments)
                
                responses.append(ToolCallResult(
                    function: matchingTool.definition.function.name,
                    result: result
                ))
            }
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [ .sortedKeys ]
        
        let data = try encoder.encode(responses)
        let replyString = String(decoding: data, as: UTF8.self)
        
        return (responses, Chat.Message.tool(replyString))
    }
}

// MARK: - Embeddings

extension Client {
    public struct EmbedResponse: Decodable {
        public let model: Model.ID
        public let embeddings: Embeddings
        public let totalDuration: TimeInterval
        public let loadDuration: TimeInterval
        public let promptEvalCount: Int

        enum CodingKeys: String, CodingKey {
            case model
            case embeddings
            case totalDuration = "total_duration"
            case loadDuration = "load_duration"
            case promptEvalCount = "prompt_eval_count"
        }
    }

    /// Generates embeddings from a model for the given input.
    ///
    /// - Parameters:
    ///   - model: The name of the model to use for generating embeddings.
    ///   - input: The text to generate embeddings for.
    ///   - truncate: If true, truncates the end of each input to fit within context length. Returns error if false and context length is exceeded.
    ///   - options: Additional model parameters as specified in the Modelfile documentation.
    /// - Returns: An `EmbedResponse` containing the generated embeddings and additional information.
    /// - Throws: An error if the request fails or the response cannot be decoded.
    public func embed(
        model: Model.ID,
        input: String,
        truncate: Bool = true,
        options: [String: Value]? = nil
    )
        async throws -> EmbedResponse
    {
        var params: [String: Value] = [
            "model": .string(model.rawValue),
            "input": .string(input),
            "truncate": .bool(truncate),
        ]

        if let options = options {
            params["options"] = .object(options)
        }

        return try await fetch(.post, "/api/embed", params: params)
    }
}

// MARK: - List Models

extension Client {
    public struct ListModelsResponse: Decodable {
        public struct Model: Decodable {
            public let name: String
            public let modifiedAt: String
            public let size: Int64
            public let digest: String
            public let details: Ollama.Model.Details

            private enum CodingKeys: String, CodingKey {
                case name
                case modifiedAt = "modified_at"
                case size
                case digest
                case details
            }
        }

        public let models: [Model]
    }

    /// Lists models that are available locally.
    ///
    /// - Returns: A `ListModelsResponse` containing information about available models.
    /// - Throws: An error if the request fails or the response cannot be decoded.
    public func listModels() async throws -> ListModelsResponse {
        return try await fetch(.get, "/api/tags")
    }
}

// MARK: - List Running Models

extension Client {
    public struct ListRunningModelsResponse: Decodable {
        public struct Model: Decodable {
            public let name: String
            public let model: String
            public let size: Int64
            public let digest: String
            public let details: Ollama.Model.Details
            public let expiresAt: String
            public let sizeVRAM: Int64

            private enum CodingKeys: String, CodingKey {
                case name
                case model
                case size
                case digest
                case details
                case expiresAt = "expires_at"
                case sizeVRAM = "size_vram"
            }
        }

        public let models: [Model]
    }

    /// Lists models that are currently loaded into memory.
    ///
    /// - Returns: A `ListRunningModelsResponse` containing information about running models.
    /// - Throws: An error if the request fails or the response cannot be decoded.
    public func listRunningModels() async throws -> ListRunningModelsResponse {
        return try await fetch(.get, "/api/ps")
    }
}

// MARK: - Create Model

extension Client {
    /// Creates a model from a Modelfile.
    ///
    /// - Parameters:
    ///   - name: The name of the model to create.
    ///   - modelfile: The contents of the Modelfile.
    ///   - path: The path to the Modelfile.
    /// - Returns: `true` if the model was successfully created, otherwise `false`.
    /// - Throws: An error if the request fails.
    public func createModel(
        name: Model.ID,
        modelfile: String? = nil,
        path: String? = nil
    )
        async throws -> Bool
    {
        var params: [String: Value] = ["name": .string(name.rawValue)]
        if let modelfile = modelfile {
            params["modelfile"] = .string(modelfile)
        }
        if let path = path {
            params["path"] = .string(path)
        }
        return try await fetch(.post, "/api/create", params: params)
    }
}

// MARK: - Copy Model

extension Client {
    /// Copies a model.
    ///
    /// - Parameters:
    ///   - source: The name of the source model.
    ///   - destination: The name of the destination model.
    /// - Returns: `true` if the model was successfully copied, otherwise `false`.
    /// - Throws: An error if the request fails.
    public func copyModel(source: String, destination: String) async throws -> Bool {
        let params: [String: Value] = [
            "source": .string(source),
            "destination": .string(destination),
        ]
        return try await fetch(.post, "/api/copy", params: params)
    }
}

// MARK: - Delete Model

extension Client {
    /// Deletes a model and its data.
    ///
    /// - Parameter id: The name of the model to delete.
    /// - Returns: `true` if the model was successfully deleted, otherwise `false`.
    /// - Throws: An error if the operation fails.
    public func deleteModel(_ id: Model.ID) async throws -> Bool {
        return try await fetch(.delete, "/api/delete", params: ["name": .string(id.rawValue)])
    }
}

// MARK: - Pull Model

extension Client {
    /// Downloads a model from the Ollama library.
    ///
    /// - Parameters:
    ///   - id: The name of the model to pull.
    ///   - insecure: If true, allows insecure connections to the library. Only use this if you are pulling from your own library during development.
    /// - Returns: `true` if the model was successfully pulled, otherwise `false`.
    /// - Throws: An error if the operation fails.
    ///
    /// - Note: Cancelled pulls are resumed from where they left off, and multiple calls will share the same download progress.
    public func pullModel(
        _ id: Model.ID,
        insecure: Bool = false
    )
        async throws -> Bool
    {
        let params: [String: Value] = [
            "name": .string(id.rawValue),
            "insecure": .bool(insecure),
            "stream": false,
        ]
        return try await fetch(.post, "/api/pull", params: params)
    }
}

// MARK: - Push Model

extension Client {
    /// Uploads a model to a model library.
    ///
    /// - Parameters:
    ///   - id: The name of the model to push in the form of "namespace/model:tag".
    ///   - insecure: If true, allows insecure connections to the library. Only use this if you are pushing to your library during development.
    /// - Returns: `true` if the model was successfully pushed, otherwise `false`.
    /// - Throws: An error if the operation fails.
    ///
    /// - Note: Requires registering for ollama.ai and adding a public key first.
    public func pushModel(
        _ id: Model.ID,
        insecure: Bool = false
    )
        async throws -> Bool
    {
        let params: [String: Value] = [
            "name": .string(id.rawValue),
            "insecure": .bool(insecure),
            "stream": false,
        ]
        return try await fetch(.post, "/api/push", params: params)
    }
}

// MARK: - Show Model

extension Client {
    /// A response containing information about a model.
    public struct ShowModelResponse: Decodable {
        /// The contents of the Modelfile for the model.
        let modelfile: String

        /// The model parameters.
        let parameters: String

        /// The prompt template used by the model.
        let template: String

        /// Detailed information about the model.
        let details: Model.Details

        /// Additional model information.
        let info: [String: Value]

        private enum CodingKeys: String, CodingKey {
            case modelfile
            case parameters
            case template
            case details
            case info = "model_info"
        }
    }

    /// Shows information about a model.
    ///
    /// - Parameter id: The identifier of the model to show information for.
    /// - Returns: A `ShowModelResponse` containing details about the model.
    /// - Throws: An error if the request fails or the response cannot be decoded.
    public func showModel(_ id: Model.ID) async throws -> ShowModelResponse {
        let params: [String: Value] = [
            "name": .string(id.rawValue)
        ]

        return try await fetch(.post, "/api/show", params: params)
    }
}

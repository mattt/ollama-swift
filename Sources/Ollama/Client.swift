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
@MainActor
public final class Client: Sendable {
    /// The default host URL for the Ollama API.
    public static let defaultHost = URL(string: "http://localhost:11434")!

    /// A default client instance using the default host.
    public static let `default` = Client(host: defaultHost)

    /// The host URL for requests made by the client.
    public let host: URL

    /// The value for the `User-Agent` header sent in requests, if any.
    public let userAgent: String?

    /// The underlying client session.
    private let session: URLSession

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
    ) async throws -> T {
        let request = try createRequest(method, path, params: params)
        let (data, response) = try await session.data(for: request)
        let httpResponse = try validateResponse(response)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds

        switch httpResponse.statusCode {
        case 200..<300:
            if T.self == Bool.self {
                // If T is Bool, we return true for successful response
                return true as! T
            } else if data.isEmpty {
                throw Error.responseError(response: httpResponse, detail: "Empty response body")
            } else {
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

    func fetchStream<T: Decodable>(
        _ method: Method,
        _ path: String,
        params: [String: Value]? = nil
    ) -> AsyncThrowingStream<T, Swift.Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds

                do {
                    let request = try createRequest(method, path, params: params)
                    let (bytes, response) = try await session.bytes(for: request)
                    let httpResponse = try validateResponse(response)

                    guard (200..<300).contains(httpResponse.statusCode) else {
                        var errorData = Data()
                        for try await byte in bytes {
                            errorData.append(byte)
                        }

                        if let errorDetail = try? decoder.decode(
                            ErrorResponse.self, from: errorData)
                        {
                            throw Error.responseError(
                                response: httpResponse, detail: errorDetail.error)
                        }

                        if let string = String(data: errorData, encoding: .utf8) {
                            throw Error.responseError(response: httpResponse, detail: string)
                        }

                        throw Error.responseError(
                            response: httpResponse, detail: "Invalid response")
                    }

                    var buffer = Data()

                    for try await byte in bytes {
                        buffer.append(byte)

                        // Look for newline to separate JSON objects
                        while let newlineIndex = buffer.firstIndex(of: UInt8(ascii: "\n")) {
                            let chunk = buffer[..<newlineIndex]
                            buffer = buffer[buffer.index(after: newlineIndex)...]

                            if !chunk.isEmpty {
                                let decoded = try decoder.decode(T.self, from: chunk)
                                continuation.yield(decoded)
                            }
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private func createRequest(
        _ method: Method,
        _ path: String,
        params: [String: Value]? = nil
    ) throws -> URLRequest {
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

        return request
    }

    private func validateResponse(_ response: URLResponse) throws -> HTTPURLResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw Error.unexpectedError("Response is not HTTPURLResponse")
        }
        return httpResponse
    }
}

// MARK: - Generate

extension Client {
    public struct GenerateResponse: Hashable, Decodable, Sendable {
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
    ///   - format: Optional format specification. Can be either a string ("json") or a JSON schema to constrain the model's output.
    ///   - options: Additional model parameters as specified in the Modelfile documentation.
    ///   - system: System message to override what is defined in the Modelfile.
    ///   - template: The prompt template to use (overrides what is defined in the Modelfile).
    ///   - context: The context parameter returned from a previous request to keep a short conversational memory.
    ///   - raw: If true, no formatting will be applied to the prompt.
    /// - Returns: A `GenerateResponse` containing the generated text and additional information.
    /// - Throws: An error if the request fails or the response cannot be decoded.
    public func generate(
        model: Model.ID,
        prompt: String,
        images: [Data]? = nil,
        format: Value? = nil,
        options: [String: Value]? = nil,
        system: String? = nil,
        template: String? = nil,
        context: [Int]? = nil,
        raw: Bool = false
    ) async throws -> GenerateResponse {
        let params = createGenerateParams(
            model: model,
            prompt: prompt,
            images: images,
            format: format,
            options: options,
            system: system,
            template: template,
            context: context,
            raw: raw,
            stream: false
        )
        return try await fetch(.post, "/api/generate", params: params)
    }

    /// Generates a streaming response for a given prompt with a provided model.
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
    ///   - raw: If true, no formatting will be applied to the prompt.
    /// - Returns: An async throwing stream of `GenerateResponse` objects containing generated text chunks and additional information.
    /// - Throws: An error if the request fails or responses cannot be decoded.
    public func generateStream(
        model: Model.ID,
        prompt: String,
        images: [Data]? = nil,
        format: Value? = nil,
        options: [String: Value]? = nil,
        system: String? = nil,
        template: String? = nil,
        context: [Int]? = nil,
        raw: Bool = false
    ) -> AsyncThrowingStream<GenerateResponse, Swift.Error> {
        let params = createGenerateParams(
            model: model,
            prompt: prompt,
            images: images,
            format: format,
            options: options,
            system: system,
            template: template,
            context: context,
            raw: raw,
            stream: true
        )
        return fetchStream(.post, "/api/generate", params: params)
    }

    private func createGenerateParams(
        model: Model.ID,
        prompt: String,
        images: [Data]?,
        format: Value?,
        options: [String: Value]?,
        system: String?,
        template: String?,
        context: [Int]?,
        raw: Bool,
        stream: Bool
    ) -> [String: Value] {
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
            params["format"] = format
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

        return params
    }
}

// MARK: - Chat

extension Client {
    public struct ChatResponse: Hashable, Decodable, Sendable {
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
    ///   - template: The prompt template to use (overrides what is defined in the Modelfile).
    ///   - format: Optional format specification. Can be either a string ("json") or a JSON schema to constrain the model's output.
    ///   - tools: Optional array of tools that can be called by the model.
    /// - Returns: A `ChatResponse` containing the generated message and additional information.
    /// - Throws: An error if the request fails or the response cannot be decoded.
    public func chat(
        model: Model.ID,
        messages: [Chat.Message],
        options: [String: Value]? = nil,
        template: String? = nil,
        format: Value? = nil,
        tools: [any ToolProtocol]? = nil
    ) async throws -> ChatResponse {
        let params = try createChatParams(
            model: model,
            messages: messages,
            options: options,
            template: template,
            format: format,
            tools: tools,
            stream: false
        )
        return try await fetch(.post, "/api/chat", params: params)
    }

    /// Generates a streaming chat response with a provided model.
    ///
    /// - Parameters:
    ///   - model: The name of the model to use for the chat.
    ///   - messages: The messages of the chat, used to keep a chat memory.
    ///   - options: Additional model parameters as specified in the Modelfile documentation.
    ///   - template: The prompt template to use (overrides what is defined in the Modelfile).
    /// - Returns: An async throwing stream of `ChatResponse` objects containing generated message chunks and additional information.
    /// - Throws: An error if the request fails or responses cannot be decoded.
    public func chatStream(
        model: Model.ID,
        messages: [Chat.Message],
        options: [String: Value]? = nil,
        template: String? = nil,
        format: Value? = nil,
        tools: [any ToolProtocol]? = nil
    ) throws -> AsyncThrowingStream<ChatResponse, Swift.Error> {
        let params = try createChatParams(
            model: model,
            messages: messages,
            options: options,
            template: template,
            format: format,
            tools: tools,
            stream: true
        )
        return fetchStream(.post, "/api/chat", params: params)
    }

    private func createChatParams(
        model: Model.ID,
        messages: [Chat.Message],
        options: [String: Value]?,
        template: String?,
        format: Value?,
        tools: [any ToolProtocol]?,
        stream: Bool
    ) throws -> [String: Value] {
        var params: [String: Value] = [
            "model": .string(model.rawValue),
            "messages": try Value(messages),
            "stream": .bool(stream),
        ]

        if let options {
            params["options"] = .object(options)
        }

        if let template {
            params["template"] = .string(template)
        }

        if let format {
            params["format"] = format
        }

        if let tools {
            params["tools"] = .array(try tools.map { try Value($0.schema) })
        }

        return params
    }
}

// MARK: - Embeddings

extension Client {
    public struct EmbedResponse: Decodable, Sendable {
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
    public struct ListModelsResponse: Decodable, Sendable {
        public struct Model: Decodable, Sendable {
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
    public struct ListRunningModelsResponse: Decodable, Sendable {
        public struct Model: Decodable, Sendable {
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
    public struct ShowModelResponse: Decodable, Sendable {
        /// The contents of the Modelfile for the model.
        public let modelfile: String

        /// The model parameters.
        public let parameters: String

        /// The prompt template used by the model.
        public let template: String

        /// Detailed information about the model.
        public let details: Model.Details

        /// Additional model information.
        public let info: [String: Value]

        /// List of model capabilities.
        public let capabilities: [String]

        private enum CodingKeys: String, CodingKey {
            case modelfile
            case parameters
            case template
            case details
            case info = "model_info"
            case capabilities
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

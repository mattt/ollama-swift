import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif


/// An Ollama HTTP API client.
///
/// See https://github.com/ollama/ollama/blob/main/docs/api.md
public class Client {
    public static let defaultHost = URL(string: "http://localhost:11434")!
    
    public static let `default` = Client(host: Client.defaultHost)
    
    /// The host for requests made by the client.
    public let host: URL
    
    /// The value for the `User-Agent` header sent in requests, if any.
    public let userAgent: String?
    
    /// The underlying client session.
    internal var session = URLSession(configuration: .default)
    
    /// Creates a client with the specified API token.
    ///
    /// You can get an Replicate API token on your
    /// [account page](https://replicate.com/account).
    ///
    /// - Parameter token: The API token.
    public init(
        host: URL = Client.defaultHost,
        userAgent: String? = nil
    )
    {
        self.host = host
        self.userAgent = userAgent
    }
    
    /// Generate a chat completion
    public func chat(model: Model.ID,
                     messages: [Chat.Message],
                     options: [String: Value]? = nil,
                     template: String? = nil)
    async throws -> Chat.Response 
    {
        var params: [String: Value] = [
            "model": .string(model),
            "messages": try Value(messages),
            "stream": false
        ]
        
        if let options {
            params["options"] = .object(options)
        }
        
        if let template {
            params["template"] = .string(template)
        }
        
        return try await fetch(.post, "/api/chat", params: params)
    }
    
    // MARK: -
    
    private enum Method: String, Hashable {
        case get = "GET"
        case post = "POST"
    }
    
    private func fetch<T: Decodable>(_ method: Method,
                                     _ path: String,
                                     params: [String: Value]? = nil)
    async throws -> T {
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
        case .post:
            if let params {
                let encoder = JSONEncoder()
                httpBody = try encoder.encode(params)
            }
        }
        
        guard let url = urlComponents?.url else {
            throw Error(detail: #"unable to construct URL with host "\#(host)" and path "\#(path)""#)
        }
        var request = URLRequest(url: url)
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

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds

        switch (response as? HTTPURLResponse)?.statusCode {
        case (200..<300)?:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw Error(detail: #"error decoding response \#(response) "\#(String(data: data, encoding: .utf8) ?? ""): "\#(error)""#)
            }
        default:
            if let error = try? decoder.decode(Error.self, from: data) {
                throw error
            }

            if let string = String(data: data, encoding: .utf8) {
                throw Error(detail: "invalid response: \(response) \n \(string)")
            }

            throw Error(detail: "invalid response: \(response)")
        }
    }
}

// MARK: -

extension JSONDecoder.DateDecodingStrategy {
    static let iso8601WithFractionalSeconds = custom { decoder in
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime,
                                   .withFractionalSeconds]

        if let date = formatter.date(from: string) {
            return date
        }
        
        // Try again without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]

        guard let date = formatter.date(from: string) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
        }

        return date
    }
}

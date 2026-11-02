import Foundation
import Testing

@testable import Ollama

@MainActor
@Suite
struct StreamingResponseTests {
    @Test(arguments: ["lf", "crlf", "eof", "single", "chunked"])
    func preservesCompleteResponses(mode: String) async throws {
        for chat in [false, true] {
            let result = try await responses(mode: mode, chat: chat)
            #expect(result.text == (mode == "single" ? [" world 🦙"] : ["hello", " world 🦙"]))
            #expect(result.done.last == true)
            #expect(result.counts.last == 17)
        }
    }

    @Test
    func emptyResponseRemainsEmpty() async throws {
        for chat in [false, true] {
            let result = try await responses(mode: "empty", chat: chat)
            #expect(result.text.isEmpty)
        }
    }

    @Test(arguments: ["bad-tail", "bad-line"])
    func invalidJSONIsReported(mode: String) async {
        for chat in [false, true] {
            do {
                _ = try await responses(mode: mode, chat: chat)
                Issue.record("Expected invalid JSON to fail for \(mode), chat=\(chat)")
            } catch is DecodingError {
                // The ordinary JSON decoding failure must reach the caller.
            } catch {
                Issue.record("Unexpected error: \(error)")
            }
        }
    }

    @Test(arguments: ["network-error", "cancelled"])
    func transportFailureIsNotTreatedAsEOF(mode: String) async {
        for chat in [false, true] {
            do {
                _ = try await responses(mode: mode, chat: chat)
                Issue.record("Expected a transport failure for \(mode), chat=\(chat)")
            } catch let error as URLError {
                #expect(error.code == (mode == "cancelled" ? .cancelled : .networkConnectionLost))
            } catch {
                Issue.record("Unexpected error: \(error)")
            }
        }
    }

    @Test
    func HTTPErrorRemainsAResponseError() async {
        for chat in [false, true] {
            do {
                _ = try await responses(mode: "http-error", chat: chat)
                Issue.record("Expected the HTTP response error")
            } catch Client.Error.responseError(let response, let detail) {
                #expect(response.statusCode == 400)
                #expect(detail == "fixture failure")
            } catch {
                Issue.record("Unexpected error: \(error)")
            }
        }
    }

    private func responses(mode: String, chat: Bool) async throws -> (
        text: [String], done: [Bool], counts: [Int?]
    ) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StreamingFixtureProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let client = Client(session: session, host: URL(string: "https://\(mode).invalid")!)
        var text: [String] = []
        var done: [Bool] = []
        var counts: [Int?] = []
        if chat {
            for try await response in try client.chatStream(model: "fixture", messages: [.user("offline")]) {
                text.append(response.message.content)
                done.append(response.done)
                counts.append(response.evalCount)
            }
        } else {
            for try await response in client.generateStream(model: "fixture", prompt: "offline") {
                text.append(response.response)
                done.append(response.done)
                counts.append(response.evalCount)
            }
        }
        return (text, done, counts)
    }
}

private final class StreamingFixtureProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else { return }
        let mode = url.host!.replacingOccurrences(of: ".invalid", with: "")
        let chat = url.path == "/api/chat"
        func line(_ text: String, done: Bool) -> String {
            var value: [String: Any] = [
                "model": "fixture", "created_at": "2026-11-01T00:00:00Z", "done": done,
            ]
            if chat {
                value["message"] = ["role": "assistant", "content": text]
            } else {
                value["response"] = text
            }
            if done { value["eval_count"] = 17 }
            let data = try! JSONSerialization.data(withJSONObject: value)
            return String(decoding: data, as: UTF8.self)
        }
        let first = line("hello", done: false)
        let last = line(" world 🦙", done: true)
        let body: String
        switch mode {
        case "lf": body = first + "\n" + last + "\n"
        case "crlf": body = first + "\r\n" + last + "\r\n"
        case "single": body = last
        case "empty": body = ""
        case "http-error": body = #"{"error":"fixture failure"}"#
        case "bad-tail": body = first + "\n{broken}"
        case "bad-line": body = "{broken}\n"
        default: body = first + "\n" + last
        }
        let response = HTTPURLResponse(
            url: url, statusCode: mode == "http-error" ? 400 : 200, httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/x-ndjson"]
        )!
        client!.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if mode == "chunked" {
            for byte in body.utf8 { client!.urlProtocol(self, didLoad: Data([byte])) }
        } else {
            client!.urlProtocol(self, didLoad: Data(body.utf8))
        }
        if mode == "network-error" || mode == "cancelled" {
            let code: URLError.Code = mode == "cancelled" ? .cancelled : .networkConnectionLost
            client!.urlProtocol(self, didFailWithError: URLError(code))
        } else {
            client!.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {}
}

import Foundation
import Testing
@testable import Ollama

struct DataExtensionsTests {
    @Test
    func testIsDataURL() {
        #expect(Data.isDataURL(string: "data:,A%20brief%20note"))
        #expect(Data.isDataURL(string: "data:text/plain,Hello%2C%20World%21"))
        #expect(Data.isDataURL(string: "data:text/plain;charset=utf-8,Hello%2C%20World%21"))
        #expect(Data.isDataURL(string: "data:text/plain;base64,SGVsbG8sIFdvcmxkIQ=="))
        #expect(!Data.isDataURL(string: "https://example.com"))
    }

    @Test
    func testParseDataURLPlainText() {
        let url = "data:,A%20brief%20note"
        let result = Data.parseDataURL(url)
        #expect(result != nil)
        #expect(result?.mimeType == "text/plain")
        #expect(result?.data == "A brief note".data(using: .utf8))
    }

    @Test
    func testParseDataURLWithMimeType() {
        let url = "data:text/plain,Hello%2C%20World%21"
        let result = Data.parseDataURL(url)
        #expect(result != nil)
        #expect(result?.mimeType == "text/plain")
        #expect(result?.data == "Hello, World!".data(using: .utf8))
    }

    @Test
    func testParseDataURLWithCharset() {
        let url = "data:text/plain;charset=utf-8,Hello%2C%20World%21"
        let result = Data.parseDataURL(url)
        #expect(result != nil)
        #expect(result?.mimeType == "text/plain;charset=utf-8")
        #expect(result?.data == "Hello, World!".data(using: .utf8))
    }

    @Test
    func testParseDataURLBase64Encoded() {
        let url = "data:text/plain;base64,SGVsbG8sIFdvcmxkIQ=="
        let result = Data.parseDataURL(url)
        #expect(result != nil)
        #expect(result?.mimeType == "text/plain")
        #expect(result?.data == "Hello, World!".data(using: .utf8))
    }

    @Test
    func testParseDataURLInvalid() {
        let url = "invalid"
        let result = Data.parseDataURL(url)
        #expect(result == nil)
    }

    @Test
    func testParseDataURLImageGifBase64() {
        let url =
            "data:image/gif;base64,R0lGODdhMAAwAPAAAAAAAP///ywAAAAAMAAwAAAC8IyPqcvt3wCcDkiLc7C0qwyGHhSWpjQu5yqmCYsapyuvUUlvONmOZtfzgFzByTB10QgxOR0TqBQejhRNzOfkVJ+5YiUqrXF5Y5lKh/DeuNcP5yLWGsEbtLiOSpa/TPg7JpJHxyendzWTBfX0cxOnKPjgBzi4diinWGdkF8kjdfnycQZXZeYGejmJlZeGl9i2icVqaNVailT6F5iJ90m6mvuTS4OK05M0vDk0Q4XUtwvKOzrcd3iq9uisF81M1OIcR7lEewwcLp7tuNNkM3uNna3F2JQFo97Vriy/Xl4/f1cf5VWzXyym7PHhhx4dbgYKAAA7"
        let result = Data.parseDataURL(url)
        #expect(result != nil)
        #expect(result?.mimeType == "image/gif")
        #expect(result?.data.prefix(6) == Data([0x47, 0x49, 0x46, 0x38, 0x37, 0x61]))  // "GIF87a"
    }

    @Test
    func testDataURLEncoded() {
        let testData = "Hello, World!".data(using: .utf8)!
        let encoded = testData.dataURLEncoded(mimeType: "text/plain")
        #expect(encoded == "data:text/plain;base64,SGVsbG8sIFdvcmxkIQ==")
    }

    @Test
    func testDataURLEncodedDefaultMimeType() {
        let testData = "Hello, World!".data(using: .utf8)!
        let encoded = testData.dataURLEncoded()
        #expect(encoded == "data:text/plain;base64,SGVsbG8sIFdvcmxkIQ==")
    }
}

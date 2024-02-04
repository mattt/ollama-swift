import Foundation

private let dataURIPrefix = "data:"

public extension Data {
    static func isURIEncoded(string: String) -> Bool {
        return string.hasPrefix(dataURIPrefix)
    }

    static func decode(uriEncoded string: String) -> (mimeType: String, data: Data)? {
        guard isURIEncoded(string: string) else {
            return nil
        }

        let components = string.dropFirst(dataURIPrefix.count).components(separatedBy: ",")
        guard components.count == 2,
              let dataScheme = components.first,
              let dataBase64 = components.last
        else {
            return nil
        }

        let mimeType: String
        if dataScheme.contains(";") {
            mimeType = dataScheme.components(separatedBy: ";").first ?? ""
        } else {
            mimeType = dataScheme
        }

        guard let decodedData = Data(base64Encoded: dataBase64) else {
            return nil
        }

        return (mimeType: mimeType, data: decodedData)
    }

    func uriEncoded(mimeType: String?) -> String {
        return "data:\(mimeType ?? "");base64,\(base64EncodedString())"
    }
}

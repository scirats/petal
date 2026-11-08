import Foundation

public struct HTTPClient: Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func data(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw PetalError.downloadFailed("\(url.absoluteString) didn’t return an HTTP response.")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw PetalError.downloadFailed("\(url.absoluteString) answered \(http.statusCode).")
        }
        return data
    }

    public func text(from url: URL) async throws -> String {
        String(decoding: try await data(from: url), as: UTF8.self)
    }
}

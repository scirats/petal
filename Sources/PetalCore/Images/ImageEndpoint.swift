import Foundation

enum ImageEndpoint {
    static func url(_ string: String) throws -> URL {
        guard let url = URL(string: string) else {
            throw PetalError.downloadFailed("Invalid image address: \(string)")
        }
        return url
    }
}

import Foundation

public struct ResolvedImage: Equatable, Sendable {
    public let url: URL
    public let fileName: String
    public let checksum: Checksum?
    public let version: String

    public init(url: URL, fileName: String, checksum: Checksum?, version: String) {
        self.url = url
        self.fileName = fileName
        self.checksum = checksum
        self.version = version
    }
}

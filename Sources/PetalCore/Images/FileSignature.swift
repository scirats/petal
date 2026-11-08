import Foundation

enum FileSignature {
    static func hasPrefix(_ bytes: [UInt8], at url: URL) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return false }
        defer { try? handle.close() }
        return (try? handle.read(upToCount: bytes.count)).map { [UInt8]($0) } == bytes
    }
}

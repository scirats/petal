import CryptoKit
import Foundation

enum FileHasher {
    static func sha256(of url: URL) throws -> String {
        try digest(of: url, using: SHA256())
    }

    static func sha512(of url: URL) throws -> String {
        try digest(of: url, using: SHA512())
    }

    static func digest<H: HashFunction>(of url: URL, using hashFunction: H) throws -> String {
        var hasher = hashFunction
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        while let chunk = try handle.read(upToCount: 8 << 20), !chunk.isEmpty {
            hasher.update(data: chunk)
        }

        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}

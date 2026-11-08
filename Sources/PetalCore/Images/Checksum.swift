import Foundation

public enum Checksum: Equatable, Sendable {
    case sha256(String)
    case sha512(String)

    public var value: String {
        switch self {
        case .sha256(let value), .sha512(let value):
            value.lowercased()
        }
    }

    public var algorithmName: String {
        switch self {
        case .sha256: "SHA-256"
        case .sha512: "SHA-512"
        }
    }

    public func verify(_ file: URL) throws {
        let actual: String
        switch self {
        case .sha256:
            actual = try FileHasher.sha256(of: file)
        case .sha512:
            actual = try FileHasher.sha512(of: file)
        }

        guard actual == value else {
            throw PetalError.downloadFailed(
                "\(file.lastPathComponent) is corrupt (\(algorithmName.lowercased()) mismatch). Try again."
            )
        }
    }
}

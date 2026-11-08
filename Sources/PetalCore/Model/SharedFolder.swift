import Foundation

public struct SharedFolder: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: String { name }
    public var name: String
    public var hostPath: String
    public var readOnly: Bool

    public init(name: String, hostPath: String, readOnly: Bool = false) {
        self.name = name
        self.hostPath = hostPath
        self.readOnly = readOnly
    }
}

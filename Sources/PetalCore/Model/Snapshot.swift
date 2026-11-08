import Foundation

public struct Snapshot: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let label: String
    public let createdAt: Date
    public let config: MachineConfig

    public init(id: UUID = UUID(), label: String, createdAt: Date = Date(), config: MachineConfig) {
        self.id = id
        self.label = label
        self.createdAt = createdAt
        self.config = config
    }
}

import Foundation

public struct MachineResources: Codable, Equatable, Sendable {
    public var cpuCount: Int
    public var memoryBytes: UInt64
    public var diskBytes: UInt64

    public init(
        cpuCount: Int = MachineDefaults.cpuCount,
        memoryBytes: UInt64 = MachineDefaults.memoryBytes,
        diskBytes: UInt64 = .gibibytes(64)
    ) {
        self.cpuCount = cpuCount
        self.memoryBytes = memoryBytes
        self.diskBytes = diskBytes
    }
}

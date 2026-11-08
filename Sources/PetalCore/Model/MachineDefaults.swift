import Foundation

public enum MachineDefaults {
    public static var cpuCount: Int {
        min(8, max(2, hostCPUCount / 2))
    }

    public static var memoryBytes: UInt64 {
        let halfOfPhysicalMemory = ProcessInfo.processInfo.physicalMemory / 2
        let rounded = halfOfPhysicalMemory / (1 << 30) * (1 << 30)
        return min(.gibibytes(16), max(.gibibytes(4), rounded))
    }

    public static var hostCPUCount: Int {
        ProcessInfo.processInfo.processorCount
    }

    public static var maxMemoryGiB: Int {
        max(4, Int(ProcessInfo.processInfo.physicalMemory >> 30) - 2)
    }
}

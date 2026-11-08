import Virtualization

enum ResourceLimits {
    static func cpuCount(_ count: Int) -> Int {
        min(
            max(count, VZVirtualMachineConfiguration.minimumAllowedCPUCount),
            VZVirtualMachineConfiguration.maximumAllowedCPUCount
        )
    }

    static func memorySize(_ bytes: UInt64) -> UInt64 {
        let rounded = bytes / (1 << 20) * (1 << 20)
        return min(
            max(rounded, VZVirtualMachineConfiguration.minimumAllowedMemorySize),
            VZVirtualMachineConfiguration.maximumAllowedMemorySize
        )
    }
}

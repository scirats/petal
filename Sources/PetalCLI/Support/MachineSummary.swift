import Foundation
import PetalCore

enum MachineSummary {
    static func state(of bundle: MachineBundle) -> String {
        if bundle.isRunning { return "running" }
        if bundle.hasSavedState { return "suspended" }
        return "stopped"
    }

    static func describe(_ bundle: MachineBundle) throws -> String {
        let config = try bundle.loadConfig()
        let disk = bundle.diskURL(for: config)
        let allocated = ByteCountFormatter.string(
            fromByteCount: Int64(DiskImage.allocatedSize(of: disk)),
            countStyle: .file
        )

        var lines = [
            "Name:       \(config.name)",
            "Guest:      Linux",
            "State:      \(state(of: bundle))",
            "CPUs:       \(config.resources.cpuCount)",
            "Memory:     \(Int(config.resources.memoryBytes.gibibytes)) GiB",
            "Disk:       \(Int(config.resources.diskBytes.gibibytes)) GiB \(disk.pathExtension.uppercased()), \(allocated) used on host",
            "Display:    \(config.display.width)×\(config.display.height)",
            "MAC:        \(config.macAddress)",
            "Clipboard:  \(config.clipboardSharing ? "shared" : "off")",
            "Rosetta:    \(config.rosetta ? "on" : "off")",
            "Installer:  \(config.installerImagePath ?? "none")",
        ]

        for folder in config.sharedFolders {
            let suffix = folder.readOnly ? " (read-only)" : ""
            lines.append("Shared:     \(folder.name) → \(folder.hostPath)\(suffix)")
        }

        lines.append("Bundle:     \(bundle.url.path)")
        return lines.joined(separator: "\n")
    }
}

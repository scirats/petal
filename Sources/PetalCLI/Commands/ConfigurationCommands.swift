import Foundation
import PetalCore

struct SetCommand: CLICommand {
    let name = "set"
    let synopsis = "set <name> [--cpus N] [--memory GiB] [--disk GiB] [--iso PATH|none] [--rosetta on|off] [--clipboard on|off]"
    let summary = "Change a stopped machine’s hardware or options."

    func run(_ arguments: [String], context: CommandContext) async throws {
        let reader = try ArgumentReader(
            arguments,
            options: ["cpus", "memory", "disk", "iso", "rosetta", "clipboard"]
        )
        try reader.requirePositionals(1, maximum: 1)

        let bundle = try context.library.bundle(named: try reader.positional(0, named: "name"))
        try bundle.requireStopped()

        var config = try bundle.loadConfig()

        if let cpus = try reader.intOption("cpus") {
            config.resources.cpuCount = cpus
        }
        if let memory = try reader.intOption("memory") {
            config.resources.memoryBytes = .gibibytes(memory)
        }
        if let disk = try reader.intOption("disk") {
            let bytes = UInt64.gibibytes(disk)
            try DiskImage.grow(at: bundle.diskURL(for: config), to: bytes)
            config.resources.diskBytes = bytes
        }
        if let iso = reader.option("iso") {
            if iso == "none" {
                config.installerImagePath = nil
            } else {
                let path = ArgumentReader.absolutePath(iso)
                guard FileManager.default.fileExists(atPath: path) else {
                    throw CLIError("No file at \(path).")
                }
                config.installerImagePath = path
            }
        }
        if let rosetta = try reader.toggleOption("rosetta") {
            config.rosetta = rosetta
        }
        if let clipboard = try reader.toggleOption("clipboard") {
            config.clipboardSharing = clipboard
        }

        try bundle.saveConfig(config)
        let summary = try MachineSummary.describe(bundle)
        Console.line(summary)
    }
}

struct ShareCommand: CLICommand {
    let name = "share"
    let synopsis = "share <name> <folder-name> <host-path> [--read-only]"
    let summary = "Share a host folder with a stopped machine."

    func run(_ arguments: [String], context: CommandContext) async throws {
        let reader = try ArgumentReader(arguments, flags: ["read-only"])
        try reader.requirePositionals(3, maximum: 3)

        let bundle = try context.library.bundle(named: try reader.positional(0, named: "name"))
        try bundle.requireStopped()

        let folderName = try reader.positional(1, named: "folder-name")
        let hostPath = try reader.pathPositional(2, named: "host-path")

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: hostPath, isDirectory: &isDirectory),
              isDirectory.boolValue
        else {
            throw CLIError("Not a directory: \(hostPath).")
        }

        var config = try bundle.loadConfig()
        config.sharedFolders.removeAll { $0.name == folderName }
        config.sharedFolders.append(
            SharedFolder(
                name: folderName,
                hostPath: hostPath,
                readOnly: reader.hasFlag("read-only")
            )
        )
        try bundle.saveConfig(config)

        Console.line("Sharing \(hostPath) as “\(folderName)”. Takes effect at next start.")
    }
}

struct UnshareCommand: CLICommand {
    let name = "unshare"
    let synopsis = "unshare <name> <folder-name>"
    let summary = "Stop sharing a host folder with a stopped machine."

    func run(_ arguments: [String], context: CommandContext) async throws {
        let reader = try ArgumentReader(arguments)
        try reader.requirePositionals(2, maximum: 2)

        let bundle = try context.library.bundle(named: try reader.positional(0, named: "name"))
        try bundle.requireStopped()

        let folderName = try reader.positional(1, named: "folder-name")
        var config = try bundle.loadConfig()
        config.sharedFolders.removeAll { $0.name == folderName }
        try bundle.saveConfig(config)

        Console.line("Stopped sharing “\(folderName)”.")
    }
}

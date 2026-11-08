import PetalCore

@MainActor
struct CommandRegistry {
    let commands: [any CLICommand]

    static let `default` = CommandRegistry(commands: [
        ListCommand(),
        InfoCommand(),
        CheckCommand(),
        RunCommand(),
        ImagesCommand(),
        CreateLinuxCommand(),
        SetCommand(),
        ShareCommand(),
        UnshareCommand(),
        CloneCommand(),
        RenameCommand(),
        SnapshotCommand(),
        SnapshotsCommand(),
        RestoreCommand(),
        DeleteSnapshotCommand(),
        DiscardSuspendedCommand(),
        DeleteCommand(),
    ])

    func command(named name: String) -> (any CLICommand)? {
        commands.first { $0.name == name || $0.aliases.contains(name) }
    }

    var usage: String {
        let commandLines = commands.map { command in
            "  \(command.synopsis) — \(command.summary)"
        }

        return (["petalctl — manage Petal virtual machines", "", "Usage:"] + commandLines + [
            "",
            "Data lives in \(MachineLibrary.defaultDataRoot.path) (override with PETAL_HOME).",
            "Use the Petal app for a display; `run` is for servers and scripts.",
        ]).joined(separator: "\n")
    }
}

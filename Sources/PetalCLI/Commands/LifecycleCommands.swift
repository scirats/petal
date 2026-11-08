import PetalCore

struct RunCommand: CLICommand {
    let name = "run"
    let synopsis = "run <name> [--for SECONDS]"
    let summary = "Run a machine headless; Ctrl-C suspends or shuts down."

    func run(_ arguments: [String], context: CommandContext) async throws {
        let reader = try ArgumentReader(arguments, options: ["for"])
        try reader.requirePositionals(1, maximum: 1)

        let bundle = try context.library.bundle(named: try reader.positional(0, named: "name"))
        let seconds = try reader.intOption("for")
        try await HeadlessRunner(bundle: bundle).run(seconds: seconds)
    }
}

struct CloneCommand: CLICommand {
    let name = "clone"
    let synopsis = "clone <name> <new-name>"
    let summary = "Clone a stopped machine."

    func run(_ arguments: [String], context: CommandContext) async throws {
        let reader = try ArgumentReader(arguments)
        try reader.requirePositionals(2, maximum: 2)

        let source = try context.library.bundle(named: try reader.positional(0, named: "name"))
        let clone = try context.library.cloneMachine(
            source,
            as: try reader.positional(1, named: "new-name")
        )
        Console.line("Cloned to “\(clone.name)”.")
    }
}

struct RenameCommand: CLICommand {
    let name = "rename"
    let synopsis = "rename <name> <new-name>"
    let summary = "Rename a stopped machine."

    func run(_ arguments: [String], context: CommandContext) async throws {
        let reader = try ArgumentReader(arguments)
        try reader.requirePositionals(2, maximum: 2)

        let bundle = try context.library.bundle(named: try reader.positional(0, named: "name"))
        let renamed = try context.library.rename(
            bundle,
            to: try reader.positional(1, named: "new-name")
        )
        Console.line("Renamed to “\(renamed.name)”.")
    }
}

struct DeleteCommand: CLICommand {
    let name = "delete"
    let aliases = ["rm"]
    let synopsis = "delete <name>"
    let summary = "Move a stopped machine to the Trash."

    func run(_ arguments: [String], context: CommandContext) async throws {
        let reader = try ArgumentReader(arguments)
        try reader.requirePositionals(1, maximum: 1)

        let bundle = try context.library.bundle(named: try reader.positional(0, named: "name"))
        try context.library.trash(bundle)
        Console.line("Moved to the Trash.")
    }
}

struct DiscardSuspendedCommand: CLICommand {
    let name = "discard-suspended"
    let synopsis = "discard-suspended <name>"
    let summary = "Discard a machine’s suspended state."

    func run(_ arguments: [String], context: CommandContext) async throws {
        let reader = try ArgumentReader(arguments)
        try reader.requirePositionals(1, maximum: 1)

        let bundle = try context.library.bundle(named: try reader.positional(0, named: "name"))
        try bundle.requireNotRunning()

        if bundle.hasSavedState {
            bundle.discardSavedState()
            Console.line("Discarded the suspended state.")
        } else {
            Console.line("No suspended state to discard.")
        }
    }
}

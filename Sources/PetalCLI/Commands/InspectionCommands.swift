import PetalCore

struct ListCommand: CLICommand {
    let name = "list"
    let aliases = ["ls"]
    let summary = "List machines and their state."

    func run(_ arguments: [String], context: CommandContext) async throws {
        let reader = try ArgumentReader(arguments)
        try reader.requirePositionals(0, maximum: 0)

        let machines = try context.library.machines()
        guard !machines.isEmpty else {
            Console.line("No machines yet.")
            return
        }

        let rows = machines.map { ($0.name, MachineSummary.state(of: $0)) }
        let width = max(4, rows.map(\.0.count).max() ?? 0)
        Console.line("NAME".padding(toLength: width + 2, withPad: " ", startingAt: 0) + "STATE")
        for row in rows {
            Console.line(row.0.padding(toLength: width + 2, withPad: " ", startingAt: 0) + row.1)
        }
    }
}

struct InfoCommand: CLICommand {
    let name = "info"
    let synopsis = "info <name>"
    let summary = "Show a machine’s configuration."

    func run(_ arguments: [String], context: CommandContext) async throws {
        let reader = try ArgumentReader(arguments)
        try reader.requirePositionals(1, maximum: 1)
        let bundle = try context.library.bundle(named: try reader.positional(0, named: "name"))
        let summary = try MachineSummary.describe(bundle)
        Console.line(summary)
    }
}

struct CheckCommand: CLICommand {
    let name = "check"
    let synopsis = "check <name>"
    let summary = "Validate a machine’s virtual hardware."

    func run(_ arguments: [String], context: CommandContext) async throws {
        let reader = try ArgumentReader(arguments)
        try reader.requirePositionals(1, maximum: 1)
        let bundle = try context.library.bundle(named: try reader.positional(0, named: "name"))
        let configuration = try VirtualMachineFactory.validatedConfiguration(for: bundle)
        let suspend = VirtualMachineFactory.supportsSuspend(configuration) ? "supported" : "not supported"
        let memoryGiB = configuration.memorySize >> 30

        let summary = "OK: \(configuration.cpuCount) CPUs, \(memoryGiB) GiB, "
            + "\(configuration.storageDevices.count) storage, "
            + "\(configuration.directorySharingDevices.count) shares, suspend \(suspend)."
        Console.line(summary)
    }
}

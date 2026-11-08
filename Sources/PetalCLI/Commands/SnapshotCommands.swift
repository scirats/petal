import Foundation
import PetalCore

struct SnapshotCommand: CLICommand {
    let name = "snapshot"
    let synopsis = "snapshot <name> [label]"
    let summary = "Snapshot a stopped machine’s disk."

    func run(_ arguments: [String], context: CommandContext) async throws {
        let reader = try ArgumentReader(arguments)
        try reader.requirePositionals(1)

        let bundle = try context.library.bundle(named: try reader.positional(0, named: "name"))
        let label = reader.remainingPositionals(from: 1).joined(separator: " ")
        let snapshot = try SnapshotStore(bundle: bundle).take(
            label: label.isEmpty ? "Snapshot" : label
        )
        Console.line("Took snapshot \(snapshot.id.uuidString) “\(snapshot.label)”.")
    }
}

struct SnapshotsCommand: CLICommand {
    let name = "snapshots"
    let synopsis = "snapshots <name>"
    let summary = "List a machine’s snapshots."

    func run(_ arguments: [String], context: CommandContext) async throws {
        let reader = try ArgumentReader(arguments)
        try reader.requirePositionals(1, maximum: 1)

        let bundle = try context.library.bundle(named: try reader.positional(0, named: "name"))
        let snapshots = try SnapshotStore(bundle: bundle).list()
        guard !snapshots.isEmpty else {
            Console.line("No snapshots.")
            return
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        for snapshot in snapshots {
            Console.line(
                "\(snapshot.id.uuidString)  \(formatter.string(from: snapshot.createdAt))  \(snapshot.label)"
            )
        }
    }
}

struct RestoreCommand: CLICommand {
    let name = "restore"
    let synopsis = "restore <name> <snapshot-id>"
    let summary = "Restore a machine to a snapshot."

    func run(_ arguments: [String], context: CommandContext) async throws {
        let reader = try ArgumentReader(arguments)
        try reader.requirePositionals(2, maximum: 2)

        let bundle = try context.library.bundle(named: try reader.positional(0, named: "name"))
        let id = try snapshotID(reader.positional(1, named: "snapshot-id"))
        try SnapshotStore(bundle: bundle).restore(id)
        Console.line("Restored.")
    }
}

struct DeleteSnapshotCommand: CLICommand {
    let name = "delete-snapshot"
    let synopsis = "delete-snapshot <name> <snapshot-id>"
    let summary = "Delete a snapshot."

    func run(_ arguments: [String], context: CommandContext) async throws {
        let reader = try ArgumentReader(arguments)
        try reader.requirePositionals(2, maximum: 2)

        let bundle = try context.library.bundle(named: try reader.positional(0, named: "name"))
        let id = try snapshotID(reader.positional(1, named: "snapshot-id"))
        try SnapshotStore(bundle: bundle).delete(id)
        Console.line("Deleted.")
    }
}

private func snapshotID(_ text: String) throws -> UUID {
    guard let id = UUID(uuidString: text) else {
        throw CLIError("Not a snapshot ID: \(text).")
    }
    return id
}

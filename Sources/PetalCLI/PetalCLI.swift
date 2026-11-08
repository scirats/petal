import Darwin
import Foundation
import PetalCore

@MainActor
public enum PetalCLI {
    public static func run(_ arguments: [String] = Array(CommandLine.arguments.dropFirst())) async {
        let registry = CommandRegistry.default

        guard let commandName = arguments.first else {
            Console.line(registry.usage)
            return
        }

        guard commandName != "help", commandName != "--help", commandName != "-h" else {
            Console.line(registry.usage)
            return
        }

        guard let command = registry.command(named: commandName) else {
            Console.error("petalctl: Unknown command “\(commandName)”.\n\n\(registry.usage)")
            exit(1)
        }

        do {
            try await command.run(Array(arguments.dropFirst()), context: CommandContext())
        } catch {
            Console.error("petalctl: \(error.localizedDescription)")
            exit(1)
        }
    }
}

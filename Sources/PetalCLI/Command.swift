import Foundation
import PetalCore

public struct CLIError: LocalizedError, Sendable {
    public let errorDescription: String?

    public init(_ message: String) {
        errorDescription = message
    }
}

@MainActor
public protocol CLICommand: Sendable {
    var name: String { get }
    var aliases: [String] { get }
    var synopsis: String { get }
    var summary: String { get }
    func run(_ arguments: [String], context: CommandContext) async throws
}

public extension CLICommand {
    var aliases: [String] { [] }
    var synopsis: String { name }
}

public struct CommandContext: Sendable {
    public let library: MachineLibrary
    public let images: ImageService

    public init(library: MachineLibrary = MachineLibrary()) {
        self.library = library
        images = ImageService(directory: library.imagesDirectory)
    }
}

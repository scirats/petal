import Foundation
import PetalCore

struct CreateLinuxCommand: CLICommand {
    let name = "create-linux"
    let synopsis = "create-linux <name> [--distro ID | --iso PATH] [--user NAME] [--password PASS] [--cpus N] [--memory GiB] [--disk GiB]"
    let summary = "Create a Linux machine."

    func run(_ arguments: [String], context: CommandContext) async throws {
        let reader = try ArgumentReader(
            arguments,
            options: ["distro", "iso", "user", "password", "cpus", "memory", "disk"]
        )
        try reader.requirePositionals(1, maximum: 1)

        let name = try reader.positional(0, named: "name")
        try context.library.validate(name: name)
        guard !FileManager.default.fileExists(
            atPath: MachineNaming.bundleURL(for: name, in: context.library.rootURL).path
        ) else {
            throw PetalError.nameTaken(name)
        }

        let distroID = reader.option("distro")
        let isoPath = reader.pathOption("iso")

        guard !(distroID != nil && isoPath != nil) else {
            throw CLIError("Use either --distro or --iso, not both.")
        }

        let resources = try makeResources(reader)

        if let distroID {
            guard let image = ImageCatalog.image(id: distroID) else {
                throw CLIError("Unknown distro “\(distroID)”. Run `petalctl images` for the list.")
            }

            if image.isAutomatic {
                try await createCloud(image, name: name, reader: reader, resources: resources, context: context)
            } else {
                let installer = try await ImageDownload.download(image, context: context)
                try await createInstaller(name: name, installer: installer, resources: resources, context: context)
            }
            return
        }

        if let isoPath {
            guard FileManager.default.fileExists(atPath: isoPath) else {
                throw CLIError("No file at \(isoPath).")
            }
            let installer = URL(fileURLWithPath: isoPath)
            try await createInstaller(name: name, installer: installer, resources: resources, context: context)
            return
        }

        try await createInstaller(name: name, installer: nil, resources: resources, context: context)
    }

    private func makeResources(_ reader: ArgumentReader) throws -> MachineResources {
        var resources = MachineResources()
        if let cpus = try reader.intOption("cpus") {
            resources.cpuCount = cpus
        }
        if let memory = try reader.intOption("memory") {
            resources.memoryBytes = .gibibytes(memory)
        }
        if let disk = try reader.intOption("disk") {
            resources.diskBytes = .gibibytes(disk)
        }
        return resources
    }

    private func createCloud(
        _ image: CatalogImage,
        name: String,
        reader: ArgumentReader,
        resources: MachineResources,
        context: CommandContext
    ) async throws {
        guard case .cloudImage(let desktop) = image.kind else {
            throw CLIError("\(image.name) doesn’t support automatic setup.")
        }

        var account = GuestAccount.suggested()
        if let username = reader.option("user") {
            account.username = username
        }
        account.password = try reader.option("password") ?? PasswordPrompt.read(for: account.username)
        try account.validate()

        let archive = try await ImageDownload.download(image, context: context)
        Console.line("Setting up “\(name)”…")

        let guestAccount = account
        let library = context.library
        let bundle = try await Task.detached(priority: .userInitiated) {
            try library.createCloud(
                name: name,
                archive: archive,
                account: guestAccount,
                desktop: desktop,
                resources: resources
            )
        }.value

        Console.line("Created “\(name)”. It finishes setting itself up on first start; sign in as \(guestAccount.username).\n")
        let summary = try MachineSummary.describe(bundle)
        Console.line(summary)
    }

    private func createInstaller(
        name: String,
        installer: URL?,
        resources: MachineResources,
        context: CommandContext
    ) async throws {
        let library = context.library
        let bundle = try await Task.detached(priority: .userInitiated) {
            try library.createLinux(
                name: name,
                installerISO: installer,
                resources: resources
            )
        }.value

        Console.line("Created “\(name)”.\n")
        if installer == nil {
            Console.line("No installer attached. Add one in Settings before starting.\n")
        }
        let summary = try MachineSummary.describe(bundle)
        Console.line(summary)
    }
}

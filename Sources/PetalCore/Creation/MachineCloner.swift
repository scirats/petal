import Foundation

struct MachineCloner {
    let rootURL: URL

    func clone(_ source: MachineBundle, as name: String) throws -> MachineBundle {
        try MachineAvailability.requireNotRunning(source)
        try MachineNaming.validate(name)

        var config = try source.loadConfig()
        let destination = MachineBundle(url: MachineNaming.bundleURL(for: name, in: rootURL))
        guard !FileSystem.exists(destination.url) else {
            throw PetalError.nameTaken(name)
        }

        try FileSystem.createDirectory(destination.url, withIntermediateDirectories: false)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: destination.url.path)
        do {
            try copyContents(of: source, to: destination)
            try MachineIdentity.createIdentifier(at: destination.machineIdentifierURL)

            config.name = name
            config.macAddress = MachineIdentity.newMACAddress()
            try destination.saveConfig(config)
            return destination
        } catch {
            FileSystem.removeIfExists(destination.url)
            throw error
        }
    }

    private func copyContents(of source: MachineBundle, to destination: MachineBundle) throws {
        let excluded: Set<String> = [
            source.snapshotsURL.lastPathComponent,
            source.savedStateURL.lastPathComponent,
            source.runLockURL.lastPathComponent,
            source.consoleLogURL.lastPathComponent,
        ]
        let items = try FileManager.default.contentsOfDirectory(
            at: source.url,
            includingPropertiesForKeys: nil
        )

        for item in items where !excluded.contains(item.lastPathComponent) {
            try FileManager.default.copyItem(
                at: item,
                to: destination.url.appendingPathComponent(item.lastPathComponent)
            )
        }
    }
}

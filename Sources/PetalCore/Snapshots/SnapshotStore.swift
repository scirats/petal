import Foundation

public struct SnapshotStore: Sendable {
    private let bundle: MachineBundle

    public init(bundle: MachineBundle) {
        self.bundle = bundle
    }

    public func list() throws -> [Snapshot] {
        guard FileSystem.exists(bundle.snapshotsURL) else { return [] }

        return try FileManager.default
            .contentsOfDirectory(at: bundle.snapshotsURL, includingPropertiesForKeys: nil)
            .compactMap { directory -> Snapshot? in
                let metadataURL = directory.appendingPathComponent("snapshot.json")
                guard let data = try? Data(contentsOf: metadataURL) else { return nil }
                return try? SnapshotCodec.decode(data)
            }
            .sorted { $0.createdAt < $1.createdAt }
    }

    @discardableResult
    public func take(label: String) throws -> Snapshot {
        try MachineAvailability.requireStopped(bundle)
        let config = try bundle.loadConfig()

        let snapshot = Snapshot(label: label, config: config)
        let directory = directory(for: snapshot.id)
        try FileSystem.createDirectory(directory)
        do {
            try copyStateFiles(for: config, into: directory)
            let data = try SnapshotCodec.encode(snapshot)
            try data.write(to: directory.appendingPathComponent("snapshot.json"), options: .atomic)
            return snapshot
        } catch {
            FileSystem.removeIfExists(directory)
            throw error
        }
    }

    public func restore(_ id: UUID) throws {
        try MachineAvailability.requireStopped(bundle)
        let currentConfig = try bundle.loadConfig()
        guard let snapshot = try list().first(where: { $0.id == id }) else {
            throw PetalError.snapshotNotFound(id.uuidString)
        }

        let directory = directory(for: id)
        for file in stateFiles(for: snapshot.config) {
            try restore(file, from: directory)
        }

        var restoredConfig = snapshot.config
        restoredConfig.name = currentConfig.name
        try bundle.saveConfig(restoredConfig)

        if currentConfig.diskFileName != restoredConfig.diskFileName {
            FileSystem.removeIfExists(bundle.diskURL(for: currentConfig))
        }
        bundle.discardSavedState()
    }

    public func delete(_ id: UUID) throws {
        let directory = directory(for: id)
        guard FileSystem.exists(directory) else {
            throw PetalError.snapshotNotFound(id.uuidString)
        }
        try FileManager.default.removeItem(at: directory)
    }

    private func directory(for id: UUID) -> URL {
        bundle.snapshotsURL.appendingPathComponent(id.uuidString, isDirectory: true)
    }

    private func stateFiles(for config: MachineConfig) -> [URL] {
        [bundle.diskURL(for: config), bundle.efiVariableStoreURL]
    }

    private func copyStateFiles(for config: MachineConfig, into directory: URL) throws {
        for file in stateFiles(for: config) {
            guard FileSystem.exists(file) else {
                throw PetalError.missingFile(file.path)
            }
            try FileManager.default.copyItem(
                at: file,
                to: directory.appendingPathComponent(file.lastPathComponent)
            )
        }
    }

    private func restore(_ file: URL, from directory: URL) throws {
        let source = directory.appendingPathComponent(file.lastPathComponent)
        guard FileSystem.exists(source) else {
            throw PetalError.missingFile(source.path)
        }

        let staged = file.appendingPathExtension("restoring-\(UUID().uuidString)")
        FileSystem.removeIfExists(staged)
        try FileManager.default.copyItem(at: source, to: staged)
        do {
            try FileSystem.replace(file, with: staged)
        } catch {
            FileSystem.removeIfExists(staged)
            throw error
        }
    }
}

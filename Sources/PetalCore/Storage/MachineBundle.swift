import Foundation

public struct MachineBundle: Hashable, Sendable {
    public static let pathExtension = "petal"

    public let url: URL

    public init(url: URL) {
        let standardized = url.standardizedFileURL.resolvingSymlinksInPath()
        self.url = URL(filePath: standardized.path, directoryHint: .notDirectory)
    }

    public var name: String {
        url.deletingPathExtension().lastPathComponent
    }

    public var configURL: URL { url.appendingPathComponent("machine.json") }
    public var machineIdentifierURL: URL { url.appendingPathComponent("machine-identifier.bin") }
    public var efiVariableStoreURL: URL { url.appendingPathComponent("efi-variables.fd") }
    public var cloudInitSeedURL: URL { url.appendingPathComponent("cloud-init.iso") }
    public var savedStateURL: URL { url.appendingPathComponent("suspended.vzvmsave") }
    public var snapshotsURL: URL { url.appendingPathComponent("snapshots", isDirectory: true) }
    public var consoleLogURL: URL { url.appendingPathComponent("console.log") }
    public var runLockURL: URL { url.appendingPathComponent(".running") }

    public func diskURL(for config: MachineConfig) -> URL {
        url.appendingPathComponent(config.diskFileName)
    }

    public func loadConfig() throws -> MachineConfig {
        try MachineConfigStore.load(from: self)
    }

    public func saveConfig(_ config: MachineConfig) throws {
        try MachineConfigStore.save(config, to: self)
    }

    public var hasSavedState: Bool {
        FileSystem.exists(savedStateURL)
    }

    public func discardSavedState() {
        FileSystem.removeIfExists(savedStateURL)
    }

    public var isRunning: Bool {
        runLock.isHeld
    }

    public func resetConsoleLog() {
        FileSystem.removeIfExists(consoleLogURL)
    }

    public func acquireRunLock() throws {
        try runLock.acquire(ownerName: name)
    }

    public func releaseRunLock() {
        runLock.release()
    }

    public func requireNotRunning() throws {
        try MachineAvailability.requireNotRunning(self)
    }

    public func requireStopped() throws {
        try MachineAvailability.requireStopped(self)
    }

    private var runLock: RunLock {
        RunLock(fileURL: runLockURL)
    }
}

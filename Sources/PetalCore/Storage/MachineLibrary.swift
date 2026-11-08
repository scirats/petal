import Foundation

public struct MachineLibrary: Sendable {
    public let rootURL: URL

    public init(rootURL: URL = MachineLibrary.defaultRoot) {
        self.rootURL = rootURL
    }

    public static var defaultDataRoot: URL {
        if let override = ProcessInfo.processInfo.environment["PETAL_HOME"], !override.isEmpty {
            return URL(fileURLWithPath: override, isDirectory: true)
        }
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appendingPathComponent("Petal", isDirectory: true)
    }

    public static var defaultRoot: URL {
        defaultDataRoot.appendingPathComponent("Machines", isDirectory: true)
    }

    public var imagesDirectory: URL {
        rootURL.deletingLastPathComponent().appendingPathComponent("Images", isDirectory: true)
    }

    public func machines() throws -> [MachineBundle] {
        try ensureRoot()
        return try FileManager.default
            .contentsOfDirectory(at: rootURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            .filter { $0.pathExtension == MachineBundle.pathExtension }
            .map(MachineBundle.init(url:))
            .filter { FileSystem.exists($0.configURL) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    public func bundle(named name: String) throws -> MachineBundle {
        try MachineNaming.validate(name)
        let bundle = MachineBundle(url: MachineNaming.bundleURL(for: name, in: rootURL))
        guard FileSystem.exists(bundle.configURL) else {
            throw PetalError.machineNotFound(name)
        }
        return bundle
    }

    @discardableResult
    public func createLinux(
        name: String,
        installerISO: URL?,
        resources: MachineResources = MachineResources()
    ) throws -> MachineBundle {
        try MachineProvisioner(rootURL: rootURL).createLinux(
            name: name,
            installerISO: installerISO,
            resources: resources
        )
    }

    @discardableResult
    public func createCloud(
        name: String,
        archive: URL,
        account: GuestAccount,
        desktop: Bool,
        resources: MachineResources = MachineResources()
    ) throws -> MachineBundle {
        try MachineProvisioner(rootURL: rootURL).createCloud(
            name: name,
            archive: archive,
            account: account,
            desktop: desktop,
            resources: resources
        )
    }

    @discardableResult
    public func cloneMachine(_ source: MachineBundle, as name: String) throws -> MachineBundle {
        try MachineCloner(rootURL: rootURL).clone(source, as: name)
    }

    @discardableResult
    public func rename(_ bundle: MachineBundle, to name: String) throws -> MachineBundle {
        try MachineAvailability.requireNotRunning(bundle)
        try MachineNaming.validate(name)

        var config = try bundle.loadConfig()
        let destination = MachineBundle(url: MachineNaming.bundleURL(for: name, in: rootURL))
        guard !FileSystem.exists(destination.url) else {
            throw PetalError.nameTaken(name)
        }

        try FileManager.default.moveItem(at: bundle.url, to: destination.url)
        do {
            config.name = name
            try destination.saveConfig(config)
            return destination
        } catch {
            try? FileManager.default.moveItem(at: destination.url, to: bundle.url)
            throw error
        }
    }

    public func trash(_ bundle: MachineBundle) throws {
        try MachineAvailability.requireNotRunning(bundle)
        try FileManager.default.trashItem(at: bundle.url, resultingItemURL: nil)
    }

    public func validate(name: String) throws {
        try MachineNaming.validate(name)
    }

    public func uniqueName(base: String) -> String {
        MachineNaming.uniqueName(base: base, in: rootURL)
    }

    func ensureRoot() throws {
        try FileSystem.createDirectory(rootURL)
    }
}

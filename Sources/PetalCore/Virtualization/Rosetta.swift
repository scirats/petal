import Virtualization

public enum Rosetta {
    public static var isInstalled: Bool {
        VZLinuxRosettaDirectoryShare.availability == .installed
    }

    public static var isSupported: Bool {
        VZLinuxRosettaDirectoryShare.availability != .notSupported
    }

    public static func install() async throws {
        try await VZLinuxRosettaDirectoryShare.installRosetta()
    }
}

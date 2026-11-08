import Foundation

struct MachineScaffold {
    static func create(rootURL: URL, name: String) throws -> MachineBundle {
        try MachineNaming.validate(name)
        try FileSystem.createDirectory(rootURL)

        let bundle = MachineBundle(url: MachineNaming.bundleURL(for: name, in: rootURL))
        guard !FileSystem.exists(bundle.url) else {
            throw PetalError.nameTaken(name)
        }
        try FileSystem.createDirectory(bundle.url, withIntermediateDirectories: false)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: bundle.url.path)
        return bundle
    }

    static func discard(_ bundle: MachineBundle) {
        FileSystem.removeIfExists(bundle.url)
    }
}

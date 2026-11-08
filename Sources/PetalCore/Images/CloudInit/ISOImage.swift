import Foundation

enum ISOImage {
    static func create(from directory: URL, to destination: URL, volumeName: String) throws {
        FileSystem.removeIfExists(destination)
        let base = destination.deletingPathExtension()
        _ = try ProcessRunner.run("/usr/bin/hdiutil", [
            "makehybrid", "-quiet", "-iso", "-joliet",
            "-default-volume-name", volumeName,
            "-o", base.path, directory.path,
        ])

        let produced = base.appendingPathExtension("iso")
        if produced != destination {
            try FileManager.default.moveItem(at: produced, to: destination)
        }
    }
}

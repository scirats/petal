import Foundation

enum FileSystem {
    static var manager: FileManager { .default }

    static func exists(_ url: URL) -> Bool {
        manager.fileExists(atPath: url.path)
    }

    static func isDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = manager.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    static func removeIfExists(_ url: URL) {
        guard exists(url) else { return }
        try? manager.removeItem(at: url)
    }

    static func createDirectory(_ url: URL, withIntermediateDirectories: Bool = true) throws {
        try manager.createDirectory(at: url, withIntermediateDirectories: withIntermediateDirectories)
    }

    static func replace(_ destination: URL, with source: URL) throws {
        if exists(destination) {
            _ = try manager.replaceItemAt(destination, withItemAt: source)
        } else {
            try manager.moveItem(at: source, to: destination)
        }
    }
}

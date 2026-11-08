import Foundation

public enum MachineNaming {
    public static func validate(_ name: String) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              trimmed == name,
              !name.contains("/"),
              !name.contains(":"),
              !name.hasPrefix("."),
              name.count <= 100,
              !name.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains)
        else {
            throw PetalError.invalidName(name)
        }
    }

    public static func bundleURL(for name: String, in rootURL: URL) -> URL {
        rootURL
            .appendingPathComponent(name)
            .appendingPathExtension(MachineBundle.pathExtension)
    }

    public static func uniqueName(base: String, in rootURL: URL) -> String {
        var candidate = base
        var counter = 2
        while FileSystem.exists(bundleURL(for: candidate, in: rootURL)) {
            candidate = "\(base) \(counter)"
            counter += 1
        }
        return candidate
    }
}

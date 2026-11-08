import Foundation

enum ChecksumManifest {
    static func checksum(for file: String, in manifest: String) -> String? {
        for line in manifest.split(separator: "\n") {
            let parts = line.split(separator: " ", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let name = parts[1]
                .trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: CharacterSet(charactersIn: "*"))
            if name == file {
                return String(parts[0])
            }
        }
        return nil
    }
}

import Foundation

struct AlpineReleaseManifest {
    private let entries: [[String: String]]

    init(text: String) {
        entries = text.components(separatedBy: "\n-").map(Self.parseEntry)
    }

    func entry(flavor: String) -> [String: String]? {
        entries.first { $0["flavor"] == flavor }
    }

    private static func parseEntry(_ block: String) -> [String: String] {
        var fields: [String: String] = [:]
        for line in block.split(separator: "\n") {
            var trimmed = String(line).trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("-") {
                trimmed = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
            }
            guard let field = KeyValueLine(trimmed) else { continue }
            fields[field.key] = field.value
        }
        return fields
    }
}

struct AlpineImageResolver: Sendable {
    let client: HTTPClient

    func resolve() async throws -> ResolvedImage {
        let directory = try ImageEndpoint.url(
            "https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/aarch64/"
        )
        let metadata = try await client.text(from: directory.appendingPathComponent("latest-releases.yaml"))
        let manifest = AlpineReleaseManifest(text: metadata)

        guard let entry = manifest.entry(flavor: "alpine-virt"),
              let file = entry["file"],
              file.hasSuffix(".iso"),
              let checksum = entry["sha256"]
        else {
            throw PetalError.downloadFailed("Couldn’t find the current Alpine release.")
        }

        return ResolvedImage(
            url: directory.appendingPathComponent(file),
            fileName: file,
            checksum: .sha256(checksum),
            version: entry["version"] ?? ""
        )
    }
}

import Foundation

struct DebianRelease {
    let codename: String
    let version: String

    init(metadata: String) throws {
        var codename: String?
        var version: String?

        for line in metadata.split(separator: "\n") {
            guard let field = KeyValueLine(String(line)) else { continue }
            switch field.key {
            case "Codename":
                codename = field.value
            case "Version":
                version = field.value
            default:
                break
            }
        }

        guard let codename, let version else {
            throw PetalError.downloadFailed("Couldn’t find the current Debian release.")
        }
        self.codename = codename
        self.version = version
    }

    var majorVersion: String {
        version.split(separator: ".").first.map(String.init) ?? version
    }
}

struct DebianImageResolver: Sendable {
    let client: HTTPClient

    func resolve() async throws -> ResolvedImage {
        let metadata = try await client.text(
            from: ImageEndpoint.url("https://deb.debian.org/debian/dists/stable/Release")
        )
        let release = try DebianRelease(metadata: metadata)
        let directory = try ImageEndpoint.url(
            "https://cloud.debian.org/images/cloud/\(release.codename)/latest/"
        )
        let fileName = "debian-\(release.version)-generic-arm64.tar.xz"
        let downloadName = "debian-\(release.majorVersion)-generic-arm64.tar.xz"
        let manifest = try await client.text(from: directory.appendingPathComponent("SHA512SUMS"))

        guard let checksum = ChecksumManifest.checksum(for: downloadName, in: manifest) else {
            throw PetalError.downloadFailed("Debian \(release.majorVersion) has no ARM64 cloud image.")
        }

        return ResolvedImage(
            url: directory.appendingPathComponent(downloadName),
            fileName: fileName,
            checksum: .sha512(checksum),
            version: release.version
        )
    }
}

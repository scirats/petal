import Foundation

struct UbuntuImageResolver: Sendable {
    let client: HTTPClient

    func resolve() async throws -> ResolvedImage {
        let release = try await latestLTS()
        let series = release.split(separator: ".").prefix(2).joined(separator: ".")
        let directory = try ImageEndpoint.url("https://cloud-images.ubuntu.com/releases/\(series)/release/")
        let fileName = "ubuntu-\(series)-server-cloudimg-arm64.img"
        let manifest = try await client.text(from: directory.appendingPathComponent("SHA256SUMS"))

        guard let checksum = ChecksumManifest.checksum(for: fileName, in: manifest) else {
            throw PetalError.downloadFailed("Ubuntu \(series) has no ARM64 cloud image yet.")
        }

        return ResolvedImage(
            url: directory.appendingPathComponent(fileName),
            fileName: fileName,
            checksum: .sha256(checksum),
            version: series
        )
    }

    private func latestLTS() async throws -> String {
        let metadata = try await client.text(from: ImageEndpoint.url("https://changelogs.ubuntu.com/meta-release-lts"))
        var currentVersion: String?
        var latestVersion: String?

        for line in metadata.split(separator: "\n") {
            guard let field = KeyValueLine(String(line)) else { continue }
            switch field.key {
            case "Version":
                currentVersion = field.value.split(separator: " ").first.map(String.init)
            case "Supported" where field.value == "1":
                latestVersion = currentVersion
            default:
                break
            }
        }

        guard let latestVersion else {
            throw PetalError.downloadFailed("Couldn’t find the current Ubuntu release.")
        }
        return latestVersion
    }
}

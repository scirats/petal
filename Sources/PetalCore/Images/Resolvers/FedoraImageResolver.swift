import Foundation

struct FedoraImageResolver: Sendable {
    let client: HTTPClient

    func resolve() async throws -> ResolvedImage {
        let releases = try JSONDecoder().decode(
            [FedoraRelease].self,
            from: await client.data(from: ImageEndpoint.url("https://fedoraproject.org/releases.json"))
        )

        let candidate = releases
            .compactMap { release -> (release: FedoraRelease, number: Int)? in
                guard release.arch == "aarch64",
                      release.variant == "Workstation",
                      release.link.hasSuffix(".iso"),
                      let number = Int(release.version)
                else { return nil }
                return (release, number)
            }
            .max { $0.number < $1.number }

        guard let candidate, let url = URL(string: candidate.release.link) else {
            throw PetalError.downloadFailed("Couldn’t find the current Fedora release.")
        }

        return ResolvedImage(
            url: url,
            fileName: url.lastPathComponent,
            checksum: candidate.release.sha256.map(Checksum.sha256),
            version: candidate.release.version
        )
    }
}

private struct FedoraRelease: Decodable {
    let version: String
    let arch: String
    let link: String
    let variant: String
    let sha256: String?
}

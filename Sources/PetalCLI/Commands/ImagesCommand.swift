import PetalCore

struct ImagesCommand: CLICommand {
    let name = "images"
    let summary = "List the distributions Petal can download."

    func run(_ arguments: [String], context: CommandContext) async throws {
        let reader = try ArgumentReader(arguments)
        try reader.requirePositionals(0, maximum: 0)

        let images = ImageCatalog.linux
        let resolved = await resolveAll(images, context: context)

        for image in images {
            let detail = resolved[image.id].map { resolvedImage in
                "\(resolvedImage.fileName)\(checksumNote(resolvedImage.checksum))"
            } ?? "unavailable right now"
            let identifier = image.id.padding(toLength: 16, withPad: " ", startingAt: 0)
            Console.line(
                "\(identifier) \(image.name) (\(image.setupStyle)) \(image.approximateSize) — \(detail)"
            )
        }
    }

    private func resolveAll(
        _ images: [CatalogImage],
        context: CommandContext
    ) async -> [String: ResolvedImage] {
        await withTaskGroup(of: (String, ResolvedImage?).self) { group in
            for image in images {
                group.addTask {
                    (image.id, try? await context.images.resolve(image))
                }
            }

            var results: [String: ResolvedImage] = [:]
            for await (id, image) in group {
                if let image {
                    results[id] = image
                }
            }
            return results
        }
    }

    private func checksumNote(_ checksum: Checksum?) -> String {
        switch checksum {
        case .sha256:
            ", SHA-256 published"
        case .sha512:
            ", SHA-512 published"
        case nil:
            ""
        }
    }
}

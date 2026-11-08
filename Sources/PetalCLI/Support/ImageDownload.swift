import Foundation
import PetalCore

enum ImageDownload {
    static func download(_ image: CatalogImage, context: CommandContext) async throws -> URL {
        Console.line("Getting \(image.name)…")
        let resolved = try await context.images.resolve(image)
        Console.line("  \(resolved.fileName) (\(resolved.version))")
        let file = try await context.images.download(resolved, progress: ProgressPrinter.reporter)
        ProgressPrinter.finish(file)
        return file
    }
}

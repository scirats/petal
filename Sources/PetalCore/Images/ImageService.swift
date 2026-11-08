import Foundation

public struct ImageService: Sendable {
    private let resolver: ImageResolverService
    private let downloader: FileDownloader
    private let cache: ImageCache

    public init(directory: URL = MachineLibrary().imagesDirectory) {
        resolver = ImageResolverService(client: HTTPClient())
        downloader = FileDownloader()
        cache = ImageCache(directory: directory)
    }

    public func resolve(_ image: CatalogImage) async throws -> ResolvedImage {
        try await resolver.resolve(image)
    }

    public func download(
        _ image: ResolvedImage,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        if let cached = cache.existingFile(for: image) {
            progress(1)
            return cached
        }

        try FileSystem.createDirectory(cache.directory)
        let destination = cache.fileURL(for: image)
        try await downloader.download(
            from: image.url,
            to: destination,
            checksum: image.checksum,
            progress: progress
        )

        guard ImageFormat.isExpected(destination) else {
            FileSystem.removeIfExists(destination)
            throw PetalError.downloadFailed(
                "\(image.fileName) isn’t what was expected. The server may have sent an error page."
            )
        }

        try cache.record(image)
        return destination
    }
}

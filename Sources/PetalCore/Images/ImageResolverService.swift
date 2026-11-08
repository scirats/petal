import Foundation

struct ImageResolverService: Sendable {
    let client: HTTPClient

    func resolve(_ image: CatalogImage) async throws -> ResolvedImage {
        switch image.id {
        case ImageCatalog.ubuntuDesktop.id, ImageCatalog.ubuntuServer.id:
            try await UbuntuImageResolver(client: client).resolve()
        case ImageCatalog.debian.id:
            try await DebianImageResolver(client: client).resolve()
        case ImageCatalog.fedora.id:
            try await FedoraImageResolver(client: client).resolve()
        case ImageCatalog.alpine.id:
            try await AlpineImageResolver(client: client).resolve()
        default:
            throw PetalError.unsupported("Unknown image \(image.id).")
        }
    }
}

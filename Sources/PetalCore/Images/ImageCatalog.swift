import Foundation

public enum ImageCatalog {
    public static let ubuntuDesktop = CatalogImage(
        id: "ubuntu-desktop",
        name: "Ubuntu Desktop",
        summary: "Latest LTS with GNOME, set up for you",
        approximateSize: "≈ 900 MB + desktop on first boot",
        machineName: "Ubuntu",
        kind: .cloudImage(desktop: true)
    )

    public static let ubuntuServer = CatalogImage(
        id: "ubuntu-server",
        name: "Ubuntu Server",
        summary: "Latest LTS, ready in about a minute",
        approximateSize: "≈ 900 MB",
        machineName: "Ubuntu Server",
        kind: .cloudImage(desktop: false)
    )

    public static let debian = CatalogImage(
        id: "debian",
        name: "Debian",
        summary: "Stable, ready in about a minute",
        approximateSize: "≈ 400 MB",
        machineName: "Debian",
        kind: .cloudImage(desktop: false)
    )

    public static let fedora = CatalogImage(
        id: "fedora",
        name: "Fedora Workstation",
        summary: "Latest release, guided installer",
        approximateSize: "≈ 2.7 GB",
        machineName: "Fedora",
        kind: .installer
    )

    public static let alpine = CatalogImage(
        id: "alpine",
        name: "Alpine Linux",
        summary: "Tiny, guided installer",
        approximateSize: "≈ 90 MB",
        machineName: "Alpine",
        kind: .installer
    )

    public static let linux: [CatalogImage] = [
        ubuntuDesktop, ubuntuServer, debian, fedora, alpine,
    ]

    public static func image(id: String) -> CatalogImage? {
        linux.first { $0.id == id }
    }
}

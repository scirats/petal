import Foundation

public struct CatalogImage: Identifiable, Hashable, Sendable {
    public enum Kind: Hashable, Sendable {
        case cloudImage(desktop: Bool)
        case installer
    }

    public let id: String
    public let name: String
    public let summary: String
    public let approximateSize: String
    public let machineName: String
    public let kind: Kind

    public init(
        id: String,
        name: String,
        summary: String,
        approximateSize: String,
        machineName: String,
        kind: Kind
    ) {
        self.id = id
        self.name = name
        self.summary = summary
        self.approximateSize = approximateSize
        self.machineName = machineName
        self.kind = kind
    }

    public var isAutomatic: Bool {
        if case .cloudImage = kind { return true }
        return false
    }

    public var setupStyle: String {
        isAutomatic ? "automatic setup" : "installer"
    }
}

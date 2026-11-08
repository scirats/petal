import Foundation

public struct DisplaySpec: Codable, Hashable, Sendable {
    public var width: Int
    public var height: Int

    public init(width: Int = 1920, height: Int = 1200) {
        self.width = width
        self.height = height
    }

    public static let presets: [DisplaySpec] = [
        DisplaySpec(width: 1280, height: 800),
        DisplaySpec(width: 1440, height: 900),
        DisplaySpec(width: 1920, height: 1080),
        DisplaySpec(width: 1920, height: 1200),
        DisplaySpec(width: 2560, height: 1440),
        DisplaySpec(width: 2560, height: 1600),
        DisplaySpec(width: 3024, height: 1964),
        DisplaySpec(width: 3840, height: 2160),
    ]

    public var label: String {
        "\(width) × \(height)"
    }
}

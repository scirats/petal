import Foundation

enum ProgressPrinter {
    static let reporter: @Sendable (Double) -> Void = { fraction in
        let percent = min(100, max(0, Int(fraction * 100)))
        let filled = String(repeating: "█", count: percent / 4)
        let empty = String(repeating: "░", count: 25 - percent / 4)
        Console.write("\r  \(filled)\(empty) \(percent)%")
    }

    static func finish(_ file: URL) {
        Console.line("\r  Ready: \(file.lastPathComponent)")
    }
}

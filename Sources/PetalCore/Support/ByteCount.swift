import Foundation

public extension UInt64 {
    static func gibibytes(_ count: Int) -> UInt64 {
        UInt64(count) << 30
    }

    var gibibytes: Double {
        Double(self) / Double(1 << 30)
    }
}

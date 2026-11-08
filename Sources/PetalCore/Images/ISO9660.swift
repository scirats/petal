import Foundation

enum ISO9660 {
    static func isValidDiscImage(_ url: URL) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return false }
        defer { try? handle.close() }

        guard (try? handle.seek(toOffset: 0x8000)) != nil,
              let descriptor = try? handle.read(upToCount: 2048),
              descriptor.count == 2048
        else { return false }

        let bytes = [UInt8](descriptor)
        guard bytes[0] == 0 || bytes[0] == 1,
              bytes[1..<6].elementsEqual("CD001".utf8)
        else { return false }

        let blocks = UInt64(bytes[80])
            | UInt64(bytes[81]) << 8
            | UInt64(bytes[82]) << 16
            | UInt64(bytes[83]) << 24
        let blockSize = UInt64(bytes[128]) | UInt64(bytes[129]) << 8
        guard blocks > 0, blockSize > 0, let fileSize = try? handle.seekToEnd() else {
            return false
        }
        return fileSize >= blocks * blockSize
    }
}

import Foundation

enum PartitionTable {
    static func hasBootSignature(_ disk: URL) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: disk) else { return false }
        defer { try? handle.close() }
        guard let firstSector = try? handle.read(upToCount: 1024), firstSector.count == 1024 else {
            return false
        }
        return firstSector[510] == 0x55 && firstSector[511] == 0xAA
    }
}

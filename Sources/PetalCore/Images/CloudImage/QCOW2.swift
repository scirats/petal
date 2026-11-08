import Foundation

enum QCOW2 {
    static func isQCOW2(_ url: URL) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return false }
        defer { try? handle.close() }
        return (try? handle.read(upToCount: 4)) == Data([0x51, 0x46, 0x49, 0xFB])
    }

    static func convertToRaw(_ source: URL, destination: URL) throws {
        let input = try FileHandle(forReadingFrom: source)
        defer { try? input.close() }

        let header = try QCOW2Header(data: read(input, at: 0, count: 104))
        FileSystem.removeIfExists(destination)
        guard FileManager.default.createFile(atPath: destination.path, contents: nil) else {
            throw failure("can’t write \(destination.path)")
        }

        let output = try FileHandle(forWritingTo: destination)
        defer { try? output.close() }
        try output.truncate(atOffset: header.virtualSize)

        try QCOW2ClusterWriter(header: header, input: input, output: output).write()
    }

    static func read(_ handle: FileHandle, at offset: UInt64, count: Int) throws -> Data {
        try handle.seek(toOffset: offset)
        let data = try handle.read(upToCount: count) ?? Data()
        guard data.count == count else { throw failure("the image is truncated") }
        return data
    }

    static func failure(_ reason: String) -> PetalError {
        .diskCreationFailed("Couldn’t convert the cloud image: \(reason).")
    }
}

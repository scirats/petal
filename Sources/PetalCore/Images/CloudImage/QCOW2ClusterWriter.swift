import Compression
import Foundation

struct QCOW2ClusterWriter {
    let header: QCOW2Header
    let input: FileHandle
    let output: FileHandle

    private let offsetMask: UInt64 = 0x00FF_FFFF_FFFF_FE00
    private let compressedFlag: UInt64 = 1 << 62

    func write() throws {
        let l1 = try QCOW2.read(input, at: header.l1Offset, count: header.l1Size * 8)
        var clusterIndex = 0
        var buffer = [UInt8](repeating: 0, count: header.clusterSize)

        for l1Index in 0..<header.l1Size {
            let l2Offset = uint64(l1, at: l1Index * 8) & offsetMask
            guard l2Offset != 0 else {
                clusterIndex += header.l2EntryCount
                continue
            }

            let l2 = try QCOW2.read(input, at: l2Offset, count: header.clusterSize)
            for l2Index in 0..<header.l2EntryCount {
                let guestOffset = UInt64(clusterIndex) * UInt64(header.clusterSize)
                clusterIndex += 1
                guard guestOffset < header.virtualSize else { break }

                let entry = uint64(l2, at: l2Index * 8)
                if entry & compressedFlag != 0 {
                    try writeCompressedCluster(entry: entry, guestOffset: guestOffset, buffer: &buffer)
                } else {
                    try writePlainCluster(entry: entry, guestOffset: guestOffset)
                }
            }
        }
    }

    private func writeCompressedCluster(entry: UInt64, guestOffset: UInt64, buffer: inout [UInt8]) throws {
        let hostOffset = entry & compressedOffsetMask
        let sectorCount = ((entry >> compressedOffsetBits) & sectorCountMask) + 1
        let length = Int(sectorCount * 512 - (hostOffset & 511))
        guard length > 0 else { throw QCOW2.failure("a compressed cluster is damaged") }

        let compressed = try QCOW2.read(input, at: hostOffset, count: length)
        let produced = try compressed.withUnsafeBytes { raw -> Int in
            guard let source = raw.bindMemory(to: UInt8.self).baseAddress else {
                throw QCOW2.failure("a compressed cluster is damaged")
            }
            return compression_decode_buffer(
                &buffer,
                header.clusterSize,
                source,
                compressed.count,
                nil,
                COMPRESSION_ZLIB
            )
        }
        guard produced > 0 else { throw QCOW2.failure("a compressed cluster is damaged") }
        try write(Data(buffer[0..<min(produced, header.clusterSize)]), at: guestOffset)
    }

    private func writePlainCluster(entry: UInt64, guestOffset: UInt64) throws {
        let hostOffset = entry & offsetMask
        guard hostOffset != 0 else { return }

        let data = try QCOW2.read(input, at: hostOffset, count: header.clusterSize)
        guard data.contains(where: { $0 != 0 }) else { return }
        try write(data, at: guestOffset)
    }

    private func write(_ data: Data, at offset: UInt64) throws {
        try output.seek(toOffset: offset)
        try output.write(contentsOf: data)
    }

    private var compressedOffsetBits: UInt64 {
        62 - (UInt64(header.clusterBits) - 8)
    }

    private var compressedOffsetMask: UInt64 {
        (UInt64(1) << compressedOffsetBits) - 1
    }

    private var sectorCountMask: UInt64 {
        (UInt64(1) << (UInt64(header.clusterBits) - 8)) - 1
    }

    private func uint64(_ data: Data, at offset: Int) -> UInt64 {
        data[offset..<offset + 8].reduce(0) { $0 << 8 | UInt64($1) }
    }
}

import Foundation

struct QCOW2Header {
    let clusterBits: UInt32
    let virtualSize: UInt64
    let l1Size: Int
    let l1Offset: UInt64

    init(data: Data) throws {
        guard QCOW2Header.uint32(data, at: 0) == 0x5146_49FB else {
            throw QCOW2.failure("not a qcow2 image")
        }

        let version = QCOW2Header.uint32(data, at: 4)
        guard version == 2 || version == 3 else {
            throw QCOW2.failure("unsupported qcow2 version \(version)")
        }
        guard QCOW2Header.uint64(data, at: 8) == 0 else {
            throw QCOW2.failure("images with a backing file aren’t supported")
        }

        clusterBits = QCOW2Header.uint32(data, at: 20)
        guard (9...21).contains(clusterBits) else {
            throw QCOW2.failure("bad cluster size")
        }

        virtualSize = QCOW2Header.uint64(data, at: 24)
        guard QCOW2Header.uint32(data, at: 32) == 0 else {
            throw QCOW2.failure("encrypted images aren’t supported")
        }

        let rawL1Size = QCOW2Header.uint32(data, at: 36)
        guard rawL1Size > 0, rawL1Size <= 1 << 20 else {
            throw QCOW2.failure("bad cluster table")
        }
        l1Size = Int(rawL1Size)
        l1Offset = QCOW2Header.uint64(data, at: 40)

        if version == 3 {
            let incompatibleFeatures = QCOW2Header.uint64(data, at: 72)
            guard incompatibleFeatures == 0 else {
                throw QCOW2.failure("image uses qcow2 features Petal can’t read (\(incompatibleFeatures))")
            }
        }
    }

    var clusterSize: Int { 1 << Int(clusterBits) }
    var l2EntryCount: Int { clusterSize / 8 }

    private static func uint32(_ data: Data, at offset: Int) -> UInt32 {
        data[offset..<offset + 4].reduce(0) { $0 << 8 | UInt32($1) }
    }

    private static func uint64(_ data: Data, at offset: Int) -> UInt64 {
        data[offset..<offset + 8].reduce(0) { $0 << 8 | UInt64($1) }
    }
}

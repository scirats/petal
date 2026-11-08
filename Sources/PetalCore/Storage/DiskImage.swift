import Foundation

public enum DiskImageFormat: String, CaseIterable, Sendable {
    case asif
    case raw

    public var fileName: String {
        switch self {
        case .asif: "disk.asif"
        case .raw: "disk.img"
        }
    }

    public var fileExtension: String {
        switch self {
        case .asif: "asif"
        case .raw: "img"
        }
    }
}

public enum DiskImage {
    public static var preferredFormat: DiskImageFormat {
        FileManager.default.isExecutableFile(atPath: diskutilPath) && supportsASIF ? .asif : .raw
    }

    public static func create(at url: URL, bytes: UInt64, format: DiskImageFormat) throws -> DiskImageFormat {
        switch format {
        case .asif:
            do {
                try createASIF(at: url, bytes: bytes)
                return .asif
            } catch {
                FileSystem.removeIfExists(url)
                let rawURL = url.deletingLastPathComponent().appendingPathComponent(DiskImageFormat.raw.fileName)
                try createRaw(at: rawURL, bytes: bytes)
                return .raw
            }
        case .raw:
            try createRaw(at: url, bytes: bytes)
            return .raw
        }
    }

    public static func grow(at url: URL, to bytes: UInt64) throws {
        let current = try logicalSize(of: url)
        guard bytes != current else { return }
        guard bytes > current else {
            throw PetalError.unsupported("Disks can only grow (current size \(current) bytes).")
        }

        if url.pathExtension.lowercased() == DiskImageFormat.asif.fileExtension {
            _ = try ProcessRunner.run(diskutilPath, ["image", "resize", "--size", "\(bytes)B", url.path])
        } else {
            let handle = try FileHandle(forWritingTo: url)
            defer { try? handle.close() }
            try handle.truncate(atOffset: bytes)
        }
    }

    public static func logicalSize(of url: URL) throws -> UInt64 {
        guard url.pathExtension.lowercased() == DiskImageFormat.asif.fileExtension else {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return (attributes[.size] as? NSNumber)?.uint64Value ?? 0
        }

        let output = try ProcessRunner.run(diskutilPath, ["image", "info", "--plist", url.path])
        guard let plist = try PropertyListSerialization.propertyList(from: Data(output.utf8), format: nil) as? [String: Any],
              let sizeInfo = plist["Size Info"] as? [String: Any],
              let total = sizeInfo["Total Bytes"] as? NSNumber
        else {
            throw PetalError.unsupported("Couldn’t read the size of \(url.lastPathComponent).")
        }
        return total.uint64Value
    }

    public static func allocatedSize(of url: URL) -> UInt64 {
        let values = try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
        return UInt64(values?.totalFileAllocatedSize ?? 0)
    }

    private static func createASIF(at url: URL, bytes: UInt64) throws {
        _ = try ProcessRunner.run(diskutilPath, [
            "image", "create", "blank", "--fs", "none", "--format", "ASIF",
            "--size", "\(bytes)B", url.path,
        ])
    }

    private static func createRaw(at url: URL, bytes: UInt64) throws {
        guard FileManager.default.createFile(atPath: url.path, contents: nil) else {
            throw PetalError.diskCreationFailed("can’t write \(url.path)")
        }
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        try handle.truncate(atOffset: bytes)
    }

    private static var supportsASIF: Bool {
        ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 26
    }

    private static let diskutilPath = "/usr/sbin/diskutil"
}

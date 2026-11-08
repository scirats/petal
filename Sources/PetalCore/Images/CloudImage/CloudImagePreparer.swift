import Foundation

struct PreparedDisk {
    let url: URL
    let logicalSize: UInt64
}

enum CloudImagePreparer {
    static func prepare(archive: URL, bundle: MachineBundle, requestedBytes: UInt64) throws -> PreparedDisk {
        let diskURL = bundle.url.appendingPathComponent(DiskImageFormat.raw.fileName)

        if QCOW2.isQCOW2(archive) {
            try QCOW2.convertToRaw(archive, destination: diskURL)
        } else {
            let extracted = try extractLargestFile(from: archive, in: bundle)
            FileSystem.removeIfExists(diskURL)
            try FileManager.default.moveItem(at: extracted, to: diskURL)
        }

        guard PartitionTable.hasBootSignature(diskURL) else {
            throw PetalError.downloadFailed("The cloud image isn’t a bootable disk (no partition table).")
        }

        let sizeBeforeGrowing = try DiskImage.logicalSize(of: diskURL)
        if sizeBeforeGrowing < requestedBytes {
            try DiskImage.grow(at: diskURL, to: requestedBytes)
        }

        let finalSize = try DiskImage.logicalSize(of: diskURL)
        return PreparedDisk(url: diskURL, logicalSize: finalSize)
    }

    private static func extractLargestFile(from archive: URL, in bundle: MachineBundle) throws -> URL {
        let staging = bundle.url.appendingPathComponent(".unpacking-\(UUID().uuidString)", isDirectory: true)
        try FileSystem.createDirectory(staging, withIntermediateDirectories: false)
        defer { FileSystem.removeIfExists(staging) }

        _ = try ProcessRunner.run("/usr/bin/tar", ["-xf", archive.path, "-C", staging.path])

        let files = FileManager.default
            .enumerator(at: staging, includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey])?
            .compactMap { $0 as? URL } ?? []

        let candidates = files.compactMap { url -> (URL, Int)? in
            guard let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                  values.isRegularFile == true,
                  let size = values.fileSize,
                  size > 256 << 20
            else { return nil }
            return (url, size)
        }

        guard let largest = candidates.max(by: { $0.1 < $1.1 }) else {
            throw PetalError.downloadFailed("The cloud image archive has no disk inside.")
        }
        return largest.0
    }
}

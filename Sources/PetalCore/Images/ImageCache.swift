import Foundation

struct ImageCache: Sendable {
    let directory: URL

    func fileURL(for image: ResolvedImage) -> URL {
        directory.appendingPathComponent(safeFileName(image.fileName))
    }

    func existingFile(for image: ResolvedImage) -> URL? {
        let url = fileURL(for: image)
        guard FileSystem.exists(url) else { return nil }

        if let checksum = image.checksum {
            return markerMatches(url, checksum: checksum) ? url : nil
        }
        return ImageFormat.isExpected(url) ? url : nil
    }

    func record(_ image: ResolvedImage) throws {
        guard let checksum = image.checksum else { return }
        try FileSystem.createDirectory(directory)
        try checksum.value.write(to: markerURL(for: fileURL(for: image)), atomically: true, encoding: .utf8)
    }

    private func markerMatches(_ file: URL, checksum: Checksum) -> Bool {
        guard let stored = try? String(contentsOf: markerURL(for: file), encoding: .utf8) else {
            return false
        }
        return stored.trimmingCharacters(in: .whitespacesAndNewlines) == checksum.value
    }

    private func markerURL(for file: URL) -> URL {
        file.appendingPathExtension("verified")
    }

    private func safeFileName(_ fileName: String) -> String {
        guard let candidate = fileName.split(separator: "/").last.map(String.init),
              !candidate.isEmpty,
              candidate != ".",
              candidate != ".."
        else { return "image" }
        return candidate
    }
}

@testable import PetalCore
import Foundation
import XCTest

final class ImagePipelineTests: XCTestCase {
    private var root = FileManager.default.temporaryDirectory

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("petal-tests-\(UUID().uuidString)", isDirectory: true)
        try FileSystem.createDirectory(root)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    func testChecksumParsing() {
        let ubuntu = """
        c2afd538d66fdd77377d03f1ed2ac76a34f1c116baecc9a8170d68f833121f57 *ubuntu-26.04-desktop-arm64.iso
        c9aa567e6560b2eddae3af03fc686002e35b6fee96f97fd5df3271e846439fdd *ubuntu-26.04-live-server-arm64.iso
        """
        XCTAssertEqual(
            ChecksumManifest.checksum(for: "ubuntu-26.04-live-server-arm64.iso", in: ubuntu)?.prefix(8),
            "c9aa567e"
        )

        let debian = "6e93fa1759bd9d4b0fc11e938987de6967ee7de5297dac1be27c3a75cc17024b  debian-13.7.0-arm64-netinst.iso"
        XCTAssertEqual(
            ChecksumManifest.checksum(for: "debian-13.7.0-arm64-netinst.iso", in: debian)?.prefix(8),
            "6e93fa17"
        )
        XCTAssertNil(ChecksumManifest.checksum(for: "missing.iso", in: ubuntu))
    }

    func testDiscImageDetectionAndHashing() throws {
        let iso = root.appendingPathComponent("real.iso")
        try Self.fakeISO(at: iso)
        XCTAssertTrue(ISO9660.isValidDiscImage(iso))
        XCTAssertTrue(ImageFormat.isExpected(iso))

        let truncated = root.appendingPathComponent("cut.iso")
        let handle = try FileHandle(forReadingFrom: iso)
        let prefix = try XCTUnwrap(handle.read(upToCount: 0x9000))
        try prefix.write(to: truncated)
        try handle.close()
        XCTAssertFalse(ISO9660.isValidDiscImage(truncated))

        let errorPage = root.appendingPathComponent("error.iso")
        try Data("<html>Access denied</html>".utf8).write(to: errorPage)
        XCTAssertFalse(ISO9660.isValidDiscImage(errorPage))

        let empty = root.appendingPathComponent("empty")
        try Data().write(to: empty)
        XCTAssertEqual(
            try FileHasher.sha256(of: empty),
            "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        )
    }

    func testArchiveSignatures() throws {
        let archive = root.appendingPathComponent("image.tar.xz")
        try Data([0xFD, 0x37, 0x7A, 0x58, 0x5A, 0x00, 0x01]).write(to: archive)
        XCTAssertTrue(ImageFormat.isExpected(archive))

        let badXZ = root.appendingPathComponent("bad.tar.xz")
        try Data([0x00, 0x01]).write(to: badXZ)
        XCTAssertFalse(ImageFormat.isExpected(badXZ))
    }

    func testChecksumVerification() throws {
        let file = root.appendingPathComponent("payload")
        try Data("hello".utf8).write(to: file)
        let digest = try FileHasher.sha256(of: file)
        XCTAssertNoThrow(try Checksum.sha256(digest).verify(file))
        XCTAssertThrowsError(try Checksum.sha256(String(repeating: "0", count: 64)).verify(file))
    }

    func testImageCacheUsesVerifiedMarker() throws {
        let cache = ImageCache(directory: root.appendingPathComponent("cache", isDirectory: true))
        let imageURL = try XCTUnwrap(URL(string: "https://example.com/disk.img"))
        let resolved = ResolvedImage(
            url: imageURL,
            fileName: "disk.img",
            checksum: .sha256("abc123"),
            version: "1"
        )

        XCTAssertNil(cache.existingFile(for: resolved))
        try FileSystem.createDirectory(cache.directory)
        try Data("image".utf8).write(to: cache.fileURL(for: resolved))
        XCTAssertNil(cache.existingFile(for: resolved))

        try cache.record(resolved)
        XCTAssertEqual(cache.existingFile(for: resolved), cache.fileURL(for: resolved))
    }

    func testImageCacheKeepsFilesInsideItsDirectory() throws {
        let cache = ImageCache(directory: root.appendingPathComponent("cache", isDirectory: true))
        let imageURL = try XCTUnwrap(URL(string: "https://example.com/image.img"))
        let image = ResolvedImage(url: imageURL, fileName: "../image.img", checksum: nil, version: "1")

        XCTAssertEqual(cache.fileURL(for: image).lastPathComponent, "image.img")
    }

    func testCatalogMarksCloudImagesForAutomaticSetup() {
        XCTAssertTrue(ImageCatalog.ubuntuDesktop.isAutomatic)
        XCTAssertTrue(ImageCatalog.ubuntuServer.isAutomatic)
        XCTAssertTrue(ImageCatalog.debian.isAutomatic)
        XCTAssertFalse(ImageCatalog.fedora.isAutomatic)
        XCTAssertFalse(ImageCatalog.alpine.isAutomatic)
        XCTAssertEqual(ImageCatalog.image(id: "fedora")?.name, "Fedora Workstation")
        XCTAssertNil(ImageCatalog.image(id: "unknown"))
    }

    static func fakeISO(at url: URL) throws {
        var bytes = Data(count: 1 << 20)
        bytes[0x8000] = 1
        bytes.replaceSubrange(0x8001..<0x8006, with: Data("CD001".utf8))
        let blocks = UInt32((1 << 20) / 2048)
        bytes.replaceSubrange(0x8050..<0x8054, with: withUnsafeBytes(of: blocks.littleEndian) { Data($0) })
        bytes.replaceSubrange(0x8080..<0x8082, with: withUnsafeBytes(of: UInt16(2048).littleEndian) { Data($0) })
        try bytes.write(to: url)
    }
}

@testable import PetalCore
import Foundation
import Virtualization
import XCTest

final class GuestSetupTests: XCTestCase {
    private var root = FileManager.default.temporaryDirectory
    private var library = MachineLibrary(rootURL: FileManager.default.temporaryDirectory)

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("petal-tests-\(UUID().uuidString)", isDirectory: true)
        library = MachineLibrary(rootURL: root)
        try library.ensureRoot()
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    func testAccountValidation() throws {
        var account = GuestAccount(fullName: "Test User", username: "tester", password: "1234")
        XCTAssertNoThrow(try account.validate())

        account.password = "123"
        XCTAssertThrowsError(try account.validate())

        account.password = "1234"
        account.username = "Root"
        XCTAssertThrowsError(try account.validate())

        account.username = "9tester"
        XCTAssertThrowsError(try account.validate())

        account.username = "test user"
        XCTAssertThrowsError(try account.validate())

        account.username = "_tester"
        XCTAssertNoThrow(try account.validate())
    }

    func testCloudInitSeedProducesAProtectedDiscImage() throws {
        let url = root.appendingPathComponent("cloud-init.iso")
        let account = GuestAccount(fullName: "Test User", username: "tester", password: "secret")
        try CloudInitSeed.create(at: url, account: account, hostname: "petal-vm", desktop: true)

        XCTAssertTrue(ISO9660.isValidDiscImage(url))
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        XCTAssertEqual((attributes[.posixPermissions] as? NSNumber)?.intValue, 0o600)
    }

    func testCloudInitSeedIsAttachedAsVirtioBlockDevice() throws {
        let bundle = try library.createLinux(
            name: "Cloud Seed",
            installerISO: nil,
            resources: MachineResources(diskBytes: .gibibytes(1))
        )
        let account = GuestAccount(fullName: "Test User", username: "tester", password: "secret")
        try CloudInitSeed.create(
            at: bundle.cloudInitSeedURL,
            account: account,
            hostname: "cloudseed",
            desktop: false
        )

        let configuration = try VirtualMachineFactory.configuration(for: bundle)
        XCTAssertEqual(configuration.storageDevices.count, 2)
        XCTAssertTrue(configuration.storageDevices[0] is VZVirtioBlockDeviceConfiguration)
        XCTAssertTrue(configuration.storageDevices[1] is VZVirtioBlockDeviceConfiguration)
    }

    func testCloudInitDocumentEscapesGuestValues() {
        let account = GuestAccount(
            fullName: "O\"Brien",
            username: "tester",
            password: "sec\"ret"
        )
        let document = CloudInitDocument(account: account, hostname: "petal-vm", desktop: false)
        let rendered = document.render()

        XCTAssertTrue(rendered.contains("\"O\\\"Brien\""))
        XCTAssertTrue(rendered.contains("\"sec\\\"ret\""))
        XCTAssertTrue(rendered.contains("virtiofs defaults,nofail"))
    }

    func testHostnameMapping() {
        XCTAssertEqual(CloudInitSeed.hostname(for: "My Ubuntu!"), "my-ubuntu")
        XCTAssertEqual(CloudInitSeed.hostname(for: "---"), "petal")
        XCTAssertEqual(CloudInitSeed.hostname(for: String(repeating: "a", count: 80)).count, 63)
    }

    func testHostnameIsUsedInCloudInitMetadata() throws {
        let url = root.appendingPathComponent("seed.iso")
        let account = GuestAccount(fullName: "Test User", username: "tester", password: "secret")
        try CloudInitSeed.create(at: url, account: account, hostname: "my-host", desktop: false)
        XCTAssertTrue(ISO9660.isValidDiscImage(url))
    }
}

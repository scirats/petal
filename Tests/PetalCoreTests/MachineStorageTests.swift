@testable import PetalCore
import Foundation
import Virtualization
import XCTest

final class MachineStorageTests: XCTestCase {
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

    func testConfigRoundTrip() throws {
        let bundle = try library.createLinux(
            name: "Round Trip",
            installerISO: nil,
            resources: MachineResources(diskBytes: .gibibytes(1))
        )
        var config = try bundle.loadConfig()
        config.sharedFolders = [SharedFolder(name: "src", hostPath: "/tmp", readOnly: true)]
        config.resources.cpuCount = 3
        config.display = DisplaySpec(width: 2560, height: 1440)
        try bundle.saveConfig(config)

        XCTAssertEqual(try bundle.loadConfig(), config)
    }

    func testLinuxMachineLayout() throws {
        let resources = MachineResources(
            cpuCount: 2,
            memoryBytes: .gibibytes(2),
            diskBytes: .gibibytes(4)
        )
        let bundle = try library.createLinux(name: "Layout", installerISO: nil, resources: resources)
        let config = try bundle.loadConfig()

        XCTAssertEqual(config.resources, resources)
        for file in [
            bundle.configURL,
            bundle.efiVariableStoreURL,
            bundle.machineIdentifierURL,
            bundle.diskURL(for: config),
        ] {
            XCTAssertTrue(FileSystem.exists(file), file.lastPathComponent)
        }

        XCTAssertEqual(try DiskImage.logicalSize(of: bundle.diskURL(for: config)), .gibibytes(4))
        XCTAssertLessThan(DiskImage.allocatedSize(of: bundle.diskURL(for: config)), 64 << 20)
        let attributes = try FileManager.default.attributesOfItem(atPath: bundle.url.path)
        XCTAssertEqual((attributes[.posixPermissions] as? NSNumber)?.intValue, 0o700)
        XCTAssertEqual(try library.machines(), [bundle])
        XCTAssertEqual(try library.bundle(named: "Layout"), bundle)
    }

    func testBuildsVirtualizationConfiguration() throws {
        let bundle = try library.createLinux(
            name: "Valid",
            installerISO: nil,
            resources: MachineResources(diskBytes: .gibibytes(1))
        )
        var config = try bundle.loadConfig()
        config.sharedFolders = [SharedFolder(name: "tmp", hostPath: NSTemporaryDirectory())]
        config.rosetta = false
        try bundle.saveConfig(config)

        let configuration = try VirtualMachineFactory.configuration(for: bundle)
        XCTAssertEqual(configuration.cpuCount, config.resources.cpuCount)
        XCTAssertEqual(configuration.directorySharingDevices.count, 1)
        XCTAssertEqual(configuration.storageDevices.count, 1)
    }

    func testRejectsBadNamesAndDuplicates() throws {
        XCTAssertThrowsError(
            try library.createLinux(name: "a/b", installerISO: nil, resources: MachineResources())
        )
        XCTAssertThrowsError(
            try library.createLinux(name: " padded", installerISO: nil, resources: MachineResources())
        )
        XCTAssertThrowsError(
            try library.createLinux(name: "bad\nname", installerISO: nil, resources: MachineResources())
        )

        try library.createLinux(name: "Twin", installerISO: nil, resources: MachineResources())
        XCTAssertThrowsError(
            try library.createLinux(name: "Twin", installerISO: nil, resources: MachineResources())
        ) {
            XCTAssertEqual($0 as? PetalError, .nameTaken("Twin"))
        }
        XCTAssertEqual(library.uniqueName(base: "Twin"), "Twin 2")
    }

    func testBundleLookupRejectsTraversal() {
        XCTAssertThrowsError(try library.bundle(named: "../Escape")) {
            XCTAssertEqual($0 as? PetalError, .invalidName("../Escape"))
        }
    }

    func testRejectsInvalidNetworkAndFolderConfiguration() throws {
        let bundle = try library.createLinux(
            name: "Invalid",
            installerISO: nil,
            resources: MachineResources(diskBytes: .gibibytes(1))
        )

        var config = try bundle.loadConfig()
        config.macAddress = "not-a-mac"
        try bundle.saveConfig(config)
        XCTAssertThrowsError(try VirtualMachineFactory.configuration(for: bundle))

        config = try bundle.loadConfig()
        config.macAddress = MachineIdentity.newMACAddress()
        config.sharedFolders = [
            SharedFolder(name: "same", hostPath: NSTemporaryDirectory()),
            SharedFolder(name: "same", hostPath: NSTemporaryDirectory()),
        ]
        try bundle.saveConfig(config)
        XCTAssertThrowsError(try VirtualMachineFactory.configuration(for: bundle))
    }

    func testConfigurationKeepsExistingConsoleLog() throws {
        let bundle = try library.createLinux(
            name: "Console",
            installerISO: nil,
            resources: MachineResources(diskBytes: .gibibytes(1))
        )
        try Data("existing output".utf8).write(to: bundle.consoleLogURL)

        _ = try VirtualMachineFactory.configuration(for: bundle)
        XCTAssertEqual(try String(contentsOf: bundle.consoleLogURL, encoding: .utf8), "existing output")
    }

    func testCloneGetsNewIdentity() throws {
        let source = try library.createLinux(
            name: "Original",
            installerISO: nil,
            resources: MachineResources(diskBytes: .gibibytes(1))
        )
        let clone = try library.cloneMachine(source, as: "Copy")

        let original = try source.loadConfig()
        let copy = try clone.loadConfig()
        XCTAssertEqual(copy.name, "Copy")
        XCTAssertNotEqual(original.macAddress, copy.macAddress)
        XCTAssertNotEqual(
            try Data(contentsOf: source.machineIdentifierURL),
            try Data(contentsOf: clone.machineIdentifierURL)
        )
        XCTAssertEqual(original.resources, copy.resources)
        XCTAssertNoThrow(try VirtualMachineFactory.configuration(for: clone))
    }

    func testCloneExcludesRuntimeState() throws {
        let source = try library.createLinux(
            name: "Source",
            installerISO: nil,
            resources: MachineResources(diskBytes: .gibibytes(1))
        )
        let snapshot = try SnapshotStore(bundle: source).take(label: "clean")
        XCTAssertTrue(FileSystem.exists(source.snapshotsURL))
        try Data("state".utf8).write(to: source.savedStateURL)
        try Data("log".utf8).write(to: source.consoleLogURL)

        let clone = try library.cloneMachine(source, as: "Clone")
        XCTAssertFalse(FileSystem.exists(clone.snapshotsURL))
        XCTAssertFalse(FileSystem.exists(clone.savedStateURL))
        XCTAssertFalse(FileSystem.exists(clone.consoleLogURL))
        XCTAssertTrue(try SnapshotStore(bundle: clone).list().isEmpty)
        XCTAssertEqual(try SnapshotStore(bundle: source).list().map(\.id), [snapshot.id])
    }

    func testRenameUpdatesConfigAndPath() throws {
        let bundle = try library.createLinux(
            name: "Before",
            installerISO: nil,
            resources: MachineResources(diskBytes: .gibibytes(1))
        )
        let renamed = try library.rename(bundle, to: "After")

        XCTAssertFalse(FileSystem.exists(bundle.url))
        XCTAssertTrue(FileSystem.exists(renamed.url))
        XCTAssertEqual(try renamed.loadConfig().name, "After")
        XCTAssertEqual(try library.bundle(named: "After"), renamed)
    }

    func testMachinesAreSortedByName() throws {
        _ = try library.createLinux(name: "Zulu", installerISO: nil, resources: MachineResources())
        _ = try library.createLinux(name: "Alpha", installerISO: nil, resources: MachineResources())
        _ = try library.createLinux(name: "Mike", installerISO: nil, resources: MachineResources())

        XCTAssertEqual(try library.machines().map(\.name), ["Alpha", "Mike", "Zulu"])
    }

    func testDiskGrowsButNeverShrinks() throws {
        let disk = root.appendingPathComponent("raw.img")
        XCTAssertEqual(try DiskImage.create(at: disk, bytes: .gibibytes(1), format: .raw), .raw)
        XCTAssertEqual(try DiskImage.logicalSize(of: disk), .gibibytes(1))

        try DiskImage.grow(at: disk, to: .gibibytes(2))
        XCTAssertEqual(try DiskImage.logicalSize(of: disk), .gibibytes(2))
        XCTAssertThrowsError(try DiskImage.grow(at: disk, to: .gibibytes(1)))
    }

    func testQCOW2Signature() throws {
        let image = root.appendingPathComponent("disk.img")
        try Data([0x51, 0x46, 0x49, 0xFB]).write(to: image)
        XCTAssertTrue(QCOW2.isQCOW2(image))

        try Data([0x00, 0x01, 0x02, 0x03]).write(to: image)
        XCTAssertFalse(QCOW2.isQCOW2(image))
    }
}

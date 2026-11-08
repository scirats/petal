@testable import PetalCore
import Foundation
import XCTest

final class MachineLifecycleTests: XCTestCase {
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

    func testSnapshotRestoresDiskAndConfiguration() throws {
        let bundle = try library.createLinux(
            name: "Snappy",
            installerISO: nil,
            resources: MachineResources(diskBytes: .gibibytes(1))
        )
        let disk = bundle.diskURL(for: try bundle.loadConfig())
        try write("before", to: disk)

        let store = SnapshotStore(bundle: bundle)
        let snapshot = try store.take(label: "clean")

        try write("after!", to: disk)
        var config = try bundle.loadConfig()
        config.resources.cpuCount = 7
        try bundle.saveConfig(config)

        try store.restore(snapshot.id)
        XCTAssertEqual(try read(6, from: disk), "before")
        XCTAssertEqual(try bundle.loadConfig().resources.cpuCount, snapshot.config.resources.cpuCount)
        XCTAssertEqual(try store.list().map(\.id), [snapshot.id])

        try store.delete(snapshot.id)
        XCTAssertTrue(try store.list().isEmpty)
    }

    func testSnapshotRequiresStoppedMachine() throws {
        let bundle = try library.createLinux(
            name: "Busy",
            installerISO: nil,
            resources: MachineResources(diskBytes: .gibibytes(1))
        )
        try bundle.acquireRunLock()
        XCTAssertThrowsError(try SnapshotStore(bundle: bundle).take(label: "x"))

        bundle.releaseRunLock()
        try Data("state".utf8).write(to: bundle.savedStateURL)
        XCTAssertThrowsError(try SnapshotStore(bundle: bundle).take(label: "x")) {
            XCTAssertEqual($0 as? PetalError, .machineSuspended("Busy"))
        }
    }

    func testRunLockBlocksModification() throws {
        let bundle = try library.createLinux(
            name: "Locked",
            installerISO: nil,
            resources: MachineResources(diskBytes: .gibibytes(1))
        )
        try bundle.acquireRunLock()

        XCTAssertTrue(bundle.isRunning)
        XCTAssertThrowsError(try library.cloneMachine(bundle, as: "Nope"))
        XCTAssertNoThrow(try bundle.acquireRunLock())
        XCTAssertThrowsError(try bundle.requireStopped())

        bundle.releaseRunLock()
        XCTAssertFalse(bundle.isRunning)
    }

    func testStaleLockFileDoesNotBlock() throws {
        let bundle = try library.createLinux(
            name: "Stale",
            installerISO: nil,
            resources: MachineResources(diskBytes: .gibibytes(1))
        )
        try Data("12345".utf8).write(to: bundle.runLockURL)

        XCTAssertFalse(bundle.isRunning)
        XCTAssertNoThrow(try bundle.acquireRunLock())
        XCTAssertTrue(bundle.isRunning)
        bundle.releaseRunLock()
        XCTAssertFalse(bundle.isRunning)
    }

    func testRenameAndCloneRejectRunningMachine() throws {
        let bundle = try library.createLinux(
            name: "Running",
            installerISO: nil,
            resources: MachineResources(diskBytes: .gibibytes(1))
        )
        try bundle.acquireRunLock()

        XCTAssertThrowsError(try library.rename(bundle, to: "Other"))
        XCTAssertThrowsError(try library.cloneMachine(bundle, as: "Other"))
    }

    func testLockOwnerSurvivesForCurrentProcess() throws {
        let bundle = try library.createLinux(
            name: "Owner",
            installerISO: nil,
            resources: MachineResources(diskBytes: .gibibytes(1))
        )
        try bundle.acquireRunLock()
        try bundle.acquireRunLock()
        XCTAssertTrue(bundle.isRunning)
        bundle.releaseRunLock()
        XCTAssertFalse(bundle.isRunning)
    }

    private func write(_ text: String, to url: URL) throws {
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        try handle.seek(toOffset: 0)
        try handle.write(contentsOf: Data(text.utf8))
    }

    private func read(_ count: Int, from url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        return String(decoding: try handle.read(upToCount: count) ?? Data(), as: UTF8.self)
    }
}

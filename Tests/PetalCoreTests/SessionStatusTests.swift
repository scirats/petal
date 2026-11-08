@testable import PetalCore
import XCTest

@MainActor
final class SessionStatusTests: XCTestCase {
    func testActiveStates() {
        XCTAssertFalse(MachineStatus.stopped.isActive)
        XCTAssertTrue(MachineStatus.starting.isActive)
        XCTAssertTrue(MachineStatus.running.isActive)
        XCTAssertTrue(MachineStatus.paused.isActive)
        XCTAssertTrue(MachineStatus.suspending.isActive)
        XCTAssertTrue(MachineStatus.stopping.isActive)
        XCTAssertFalse(MachineStatus.failed("boom").isActive)
    }

    func testStatusLabels() {
        XCTAssertEqual(MachineStatus.running.label, "Running")
        XCTAssertEqual(MachineStatus.failed("boom").logLabel, "Error: boom")
        XCTAssertEqual(MachineStatus.stopped.logLabel, "Stopped")
    }

    func testBroadcasterYieldsCurrentStatusAndUpdates() async {
        let broadcaster = StatusBroadcaster()
        let stream = broadcaster.stream(startingWith: .stopped)
        var iterator = stream.makeAsyncIterator()

        let first = await iterator.next()
        XCTAssertEqual(first, .stopped)

        broadcaster.send(.starting)
        let second = await iterator.next()
        XCTAssertEqual(second, .starting)
    }
}

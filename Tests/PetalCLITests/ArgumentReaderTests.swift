@testable import PetalCLI
import Foundation
import PetalCore
import XCTest

@MainActor
final class ArgumentReaderTests: XCTestCase {
    func testParsesPositionalsOptionsAndFlags() throws {
        let reader = try ArgumentReader(
            ["Ubuntu", "--cpus", "4", "--read-only"],
            flags: ["read-only"],
            options: ["cpus"]
        )

        XCTAssertEqual(try reader.positional(0, named: "name"), "Ubuntu")
        XCTAssertEqual(try reader.intOption("cpus"), 4)
        XCTAssertTrue(reader.hasFlag("read-only"))
    }

    func testRejectsUnknownOption() {
        XCTAssertThrowsError(try ArgumentReader(["--unknown", "value"], options: ["known"]))
    }

    func testRejectsMissingOptionValue() {
        XCTAssertThrowsError(try ArgumentReader(["--cpus"], options: ["cpus"]))
    }

    func testValidatesNumericOptions() throws {
        let reader = try ArgumentReader(["--cpus", "0"], options: ["cpus"])
        XCTAssertThrowsError(try reader.intOption("cpus"))
    }

    func testParsesToggleOptions() throws {
        let enabled = try ArgumentReader(["--rosetta", "yes"], options: ["rosetta"])
        XCTAssertEqual(try enabled.toggleOption("rosetta"), true)

        let off = try ArgumentReader(["--rosetta", "off"], options: ["rosetta"])
        XCTAssertEqual(try off.toggleOption("rosetta"), false)

        let invalid = try ArgumentReader(["--rosetta", "maybe"], options: ["rosetta"])
        XCTAssertThrowsError(try invalid.toggleOption("rosetta"))
    }

    func testDoubleDashEndsOptions() throws {
        let reader = try ArgumentReader(["snapshot", "--", "--label"])
        XCTAssertEqual(reader.remainingPositionals(from: 1), ["--label"])
    }

    func testValidatesPositionalCounts() throws {
        let reader = try ArgumentReader(["one", "two"])

        XCTAssertEqual(reader.remainingPositionals(from: 1), ["two"])
        XCTAssertThrowsError(try reader.requirePositionals(3))
        XCTAssertThrowsError(try reader.requirePositionals(1, maximum: 1))
        XCTAssertNoThrow(try reader.requirePositionals(2, maximum: 2))
    }

    func testExpandsTildeInPaths() throws {
        let reader = try ArgumentReader(["~/Petal"], options: [])
        let path = try reader.pathPositional(0, named: "path")

        XCTAssertTrue(path.hasPrefix("/"))
        XCTAssertFalse(path.hasPrefix("~"))
    }
}

@MainActor
final class CommandRegistryTests: XCTestCase {
    func testResolvesNamesAndAliases() {
        let registry = CommandRegistry.default

        XCTAssertNotNil(registry.command(named: "list"))
        XCTAssertTrue(registry.command(named: "ls") is ListCommand)
        XCTAssertTrue(registry.command(named: "rm") is DeleteCommand)
        XCTAssertNil(registry.command(named: "unknown"))
    }

    func testUsageListsEveryCommand() {
        let registry = CommandRegistry.default
        let usage = registry.usage

        for command in registry.commands {
            XCTAssertTrue(usage.contains(command.synopsis), command.synopsis)
        }
        XCTAssertTrue(usage.contains("PETAL_HOME"))
    }

    func testMachineSummaryDescribesMachine() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("petal-cli-tests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }

        let library = MachineLibrary(rootURL: root)
        let bundle = try library.createLinux(
            name: "CLI",
            installerISO: nil,
            resources: MachineResources(cpuCount: 2, diskBytes: .gibibytes(1))
        )
        let summary = try MachineSummary.describe(bundle)

        XCTAssertTrue(summary.contains("Name:       CLI"))
        XCTAssertTrue(summary.contains("CPUs:       2"))
        XCTAssertTrue(summary.contains("Bundle:"))
        XCTAssertEqual(MachineSummary.state(of: bundle), "stopped")
    }
}

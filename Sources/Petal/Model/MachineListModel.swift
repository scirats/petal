import Foundation
import Observation
import PetalCore

@MainActor
@Observable
final class MachineListModel {
    @ObservationIgnored private let library: MachineLibrary
    private(set) var entries: [MachineEntry] = []

    init(library: MachineLibrary) {
        self.library = library
    }

    func reload() throws {
        entries = try library.machines().compactMap { bundle in
            guard let config = try? bundle.loadConfig() else { return nil }
            return MachineEntry(bundle: bundle, config: config)
        }
    }

    func entry(for id: URL) -> MachineEntry? {
        entries.first { $0.id == id }
    }
}

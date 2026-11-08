import Foundation
import Observation
import PetalCore

@MainActor
@Observable
final class SessionRegistry {
    @ObservationIgnored private var sessions: [URL: MachineSession] = [:]

    func session(for bundle: MachineBundle) -> MachineSession {
        if let existing = sessions[bundle.url] {
            return existing
        }
        let session = MachineSession(bundle: bundle)
        sessions[bundle.url] = session
        return session
    }

    var hasActiveMachines: Bool {
        sessions.values.contains { $0.status.isActive }
    }

    func prune(keeping entries: [MachineEntry]) {
        let liveURLs = Set(entries.map(\.id))
        sessions = sessions.filter { liveURLs.contains($0.key) || $0.value.status.isActive }
    }

    func remove(_ url: URL) {
        sessions[url] = nil
    }
}

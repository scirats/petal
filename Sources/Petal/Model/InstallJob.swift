import Foundation
import Observation

@MainActor
@Observable
final class InstallJob: Identifiable {
    let id = UUID()
    let name: String
    var status = "Starting…"
    var fraction: Double?
    var error: String?

    @ObservationIgnored var task: Task<Void, Never>?

    init(name: String) {
        self.name = name
    }

    var summary: String {
        error ?? status
    }

    func update(status: String, fraction: Double?) {
        self.fraction = fraction
        self.status = fraction.map { "\(status) \(Int($0 * 100))%" } ?? status
    }

    func reporter(for label: String) -> @Sendable (Double) -> Void {
        { [weak self] fraction in
            Task { @MainActor in
                self?.update(status: label, fraction: fraction)
            }
        }
    }
}

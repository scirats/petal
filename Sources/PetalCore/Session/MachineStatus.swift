import Foundation

public enum MachineStatus: Equatable, Sendable {
    case stopped
    case starting
    case running
    case paused
    case suspending
    case stopping
    case failed(String)

    public var isActive: Bool {
        switch self {
        case .starting, .running, .paused, .suspending, .stopping:
            true
        case .stopped, .failed:
            false
        }
    }

    public var label: String {
        switch self {
        case .stopped: "Stopped"
        case .starting: "Starting"
        case .running: "Running"
        case .paused: "Paused"
        case .suspending: "Suspending"
        case .stopping: "Shutting Down"
        case .failed: "Error"
        }
    }

    public var logLabel: String {
        if case .failed(let message) = self {
            return "Error: \(message)"
        }
        return label
    }
}

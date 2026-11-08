import Foundation

public enum PetalError: LocalizedError, Equatable, Sendable {
    case machineNotFound(String)
    case nameTaken(String)
    case invalidName(String)
    case machineRunning(String)
    case machineSuspended(String)
    case missingFile(String)
    case fileAccessFailed(String)
    case unsupported(String)
    case diskCreationFailed(String)
    case snapshotNotFound(String)
    case invalidConfiguration(String)
    case downloadFailed(String)
    case commandFailed(String)

    public var errorDescription: String? {
        switch self {
        case .machineNotFound(let name):
            "No machine named “\(name)”."
        case .nameTaken(let name):
            "A machine named “\(name)” already exists."
        case .invalidName(let name):
            "“\(name)” can’t be used as a machine name."
        case .machineRunning(let name):
            "“\(name)” is running. Shut it down first."
        case .machineSuspended(let name):
            "“\(name)” is suspended. Resume and shut it down, or discard the suspended state, first."
        case .missingFile(let path):
            "Required file is missing: \(path)"
        case .fileAccessFailed(let path):
            "Couldn’t write \(path)."
        case .unsupported(let reason):
            reason
        case .diskCreationFailed(let reason):
            "Couldn’t create the disk: \(reason)"
        case .snapshotNotFound(let id):
            "No snapshot with ID \(id)."
        case .invalidConfiguration(let reason):
            "Invalid machine configuration: \(reason)"
        case .downloadFailed(let reason):
            reason
        case .commandFailed(let reason):
            "A system command failed: \(reason)"
        }
    }
}

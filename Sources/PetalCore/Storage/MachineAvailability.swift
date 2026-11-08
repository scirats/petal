import Foundation

enum MachineAvailability {
    static func requireNotRunning(_ bundle: MachineBundle) throws {
        guard !bundle.isRunning else {
            throw PetalError.machineRunning(bundle.name)
        }
    }

    static func requireStopped(_ bundle: MachineBundle) throws {
        try requireNotRunning(bundle)
        guard !bundle.hasSavedState else {
            throw PetalError.machineSuspended(bundle.name)
        }
    }
}

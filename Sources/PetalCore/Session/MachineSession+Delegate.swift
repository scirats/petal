import Virtualization

extension MachineSession: VZVirtualMachineDelegate {
    nonisolated public func guestDidStop(_: VZVirtualMachine) {
        Task { @MainActor [weak self] in
            self?.guestStopped()
        }
    }

    nonisolated public func virtualMachine(_: VZVirtualMachine, didStopWithError error: Error) {
        let message = error.localizedDescription
        Task { @MainActor [weak self] in
            self?.fail(PetalError.unsupported(message))
        }
    }
}

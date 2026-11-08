import Foundation

@MainActor
final class StatusBroadcaster {
    private var observers: [UUID: AsyncStream<MachineStatus>.Continuation] = [:]

    func stream(startingWith status: MachineStatus) -> AsyncStream<MachineStatus> {
        AsyncStream { continuation in
            let id = UUID()
            continuation.yield(status)
            observers[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    self?.observers[id] = nil
                }
            }
        }
    }

    func send(_ status: MachineStatus) {
        for observer in observers.values {
            observer.yield(status)
        }
    }
}

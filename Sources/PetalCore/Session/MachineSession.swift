import Foundation
import Observation
import Virtualization

@MainActor
@Observable
public final class MachineSession: NSObject {
    public let bundle: MachineBundle
    public private(set) var status: MachineStatus = .stopped
    public private(set) var virtualMachine: VZVirtualMachine?
    public private(set) var canSuspend = false

    @ObservationIgnored public var onStop: (() -> Void)?
    @ObservationIgnored private var bootedAt: Date?
    @ObservationIgnored private var shutdownTimeout: Task<Void, Never>?
    @ObservationIgnored private let statusBroadcaster = StatusBroadcaster()

    public init(bundle: MachineBundle) {
        self.bundle = bundle
        super.init()
    }

    public func statusUpdates() -> AsyncStream<MachineStatus> {
        statusBroadcaster.stream(startingWith: status)
    }

    public func start() async {
        guard !status.isActive else { return }
        setStatus(.starting)

        do {
            try bundle.acquireRunLock()
            guard status == .starting else {
                bundle.releaseRunLock()
                return
            }
            bundle.resetConsoleLog()

            let configuration = try VirtualMachineFactory.validatedConfiguration(for: bundle)
            let machine = VZVirtualMachine(configuration: configuration)
            machine.delegate = self
            virtualMachine = machine
            canSuspend = VirtualMachineFactory.supportsSuspend(configuration)

            if bundle.hasSavedState {
                if canSuspend, await restoreState(on: machine) {
                    return
                }
                bundle.discardSavedState()
            }

            guard status == .starting else {
                virtualMachine = nil
                canSuspend = false
                return
            }
            try await machine.start()
            guard status == .starting else {
                if machine.canStop {
                    try? await machine.stop()
                }
                virtualMachine = nil
                canSuspend = false
                return
            }
            bootedAt = Date()
            setStatus(.running)
        } catch {
            fail(error)
        }
    }

    public func pause() async {
        guard status == .running, let machine = virtualMachine, machine.canPause else { return }
        do {
            try await machine.pause()
            setStatus(.paused)
        } catch {
            fail(error)
        }
    }

    public func resume() async {
        guard status == .paused, let machine = virtualMachine, machine.canResume else { return }
        do {
            try await machine.resume()
            setStatus(.running)
        } catch {
            fail(error)
        }
    }

    public func suspend() async {
        guard status == .running || status == .paused,
              let machine = virtualMachine,
              canSuspend
        else { return }
        setStatus(.suspending)

        do {
            if machine.state == .running {
                try await machine.pause()
            }
            try await machine.saveMachineStateTo(url: bundle.savedStateURL)
            try await machine.stop()
            finish()
        } catch {
            bundle.discardSavedState()
            fail(error)
        }
    }

    public func requestShutdown() {
        guard status == .running || status == .paused,
              let machine = virtualMachine,
              machine.canRequestStop
        else { return }
        do {
            try machine.requestStop()
            setStatus(.stopping)
            scheduleShutdownTimeout(for: machine)
        } catch {
            fail(error)
        }
    }

    public func forceStop() async {
        guard status.isActive, status != .suspending else { return }
        shutdownTimeout?.cancel()
        shutdownTimeout = nil

        guard let machine = virtualMachine, machine.canStop else {
            finish()
            return
        }

        do {
            try await machine.stop()
            finish()
        } catch {
            fail(error)
        }
    }

    private func restoreState(on machine: VZVirtualMachine) async -> Bool {
        do {
            try await machine.restoreMachineStateFrom(url: bundle.savedStateURL)
            bundle.discardSavedState()
            try await machine.resume()
            guard status == .starting else {
                if machine.canStop {
                    try? await machine.stop()
                }
                return false
            }
            setStatus(.running)
            return true
        } catch {
            bundle.discardSavedState()
            if machine.canStop {
                try? await machine.stop()
            }
            return false
        }
    }

    private func scheduleShutdownTimeout(for machine: VZVirtualMachine) {
        shutdownTimeout?.cancel()
        shutdownTimeout = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: .seconds(20))
            } catch {
                return
            }
            guard let self, self.virtualMachine === machine, self.status == .stopping else { return }
            await self.forceStop()
        }
    }

    func guestStopped() {
        if status == .starting {
            fail(PetalError.unsupported(Self.earlyBootMessage))
            return
        }
        if let bootedAt, Date().timeIntervalSince(bootedAt) < 5 {
            fail(PetalError.unsupported(Self.earlyBootMessage))
            return
        }
        finish()
    }

    private static let earlyBootMessage = "The machine turned off right after starting, so it probably found nothing to boot. "
        + "Attach an installer ISO in Settings, or check that the disk has an operating system."

    func finish() {
        guard status.isActive else { return }
        shutdownTimeout?.cancel()
        shutdownTimeout = nil
        bootedAt = nil
        virtualMachine = nil
        canSuspend = false
        setStatus(.stopped)
        bundle.releaseRunLock()
        onStop?()
    }

    func fail(_ error: Error) {
        guard status.isActive else { return }
        let machine = virtualMachine
        shutdownTimeout?.cancel()
        shutdownTimeout = nil
        bootedAt = nil
        virtualMachine = nil
        canSuspend = false
        setStatus(.failed(error.localizedDescription))
        terminate(machine)
    }

    private func terminate(_ machine: VZVirtualMachine?) {
        guard let machine, machine.canStop else {
            bundle.releaseRunLock()
            onStop?()
            return
        }

        Task { @MainActor in
            try? await machine.stop()
            self.bundle.releaseRunLock()
            self.onStop?()
        }
    }

    private func setStatus(_ newStatus: MachineStatus) {
        status = newStatus
        statusBroadcaster.send(newStatus)
    }
}

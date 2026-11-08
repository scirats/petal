import Darwin
import Foundation
import PetalCore

@MainActor
final class HeadlessRunner {
    private let session: MachineSession

    init(bundle: MachineBundle) {
        session = MachineSession(bundle: bundle)
    }

    func run(seconds: Int?) async throws {
        let session = self.session
        let previousHandler = signal(SIGINT, SIG_IGN)
        defer { signal(SIGINT, previousHandler) }
        let interrupt = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        interrupt.setEventHandler {
            Task { @MainActor in
                await self.stop()
            }
        }
        interrupt.resume()
        defer { interrupt.cancel() }

        let printer = Task { @MainActor in
            var isFirstUpdate = true
            for await status in session.statusUpdates() {
                if isFirstUpdate {
                    isFirstUpdate = false
                    if status == .stopped {
                        continue
                    }
                }
                Console.line("[\(Date().formatted(date: .omitted, time: .standard))] \(status.logLabel)")
            }
        }
        defer { printer.cancel() }

        let timeout = makeTimeout(seconds: seconds)
        defer { timeout?.cancel() }

        let failure: String? = await withCheckedContinuation { continuation in
            session.onStop = {
                if case .failed(let message) = session.status {
                    continuation.resume(returning: message)
                } else {
                    continuation.resume(returning: String?.none)
                }
            }
            Task { await session.start() }
        }

        if let failure {
            throw CLIError(failure)
        }
    }

    private func stop() async {
        if session.canSuspend, session.status == .running || session.status == .paused {
            await session.suspend()
        } else {
            await session.forceStop()
        }
    }

    private func makeTimeout(seconds: Int?) -> Task<Void, Never>? {
        guard let seconds else { return nil }
        return Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(seconds))
            } catch {
                return
            }
            await stop()
        }
    }
}

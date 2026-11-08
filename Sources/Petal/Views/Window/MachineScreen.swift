import PetalCore
import SwiftUI

struct MachineScreen: View {
    @Environment(AppModel.self) private var model
    let entry: MachineEntry
    let session: MachineSession
    @State private var capturesSystemKeys = false

    private var presentation: MachineStatusPresentation {
        MachineStatusPresentation(status: session.status, hasSavedState: entry.bundle.hasSavedState)
    }

    var body: some View {
        Group {
            if let machine = session.virtualMachine {
                VirtualMachineDisplay(machine: machine, capturesSystemKeys: capturesSystemKeys)
                    .overlay {
                        statusOverlay
                    }
            } else {
                IdleMachineView(entry: entry, session: session)
            }
        }
        .navigationTitle(entry.config.name)
        .navigationSubtitle(presentation.text)
        .toolbar {
            MachineToolbar(
                entry: entry,
                session: session,
                capturesSystemKeys: $capturesSystemKeys,
                onEjectInstaller: ejectInstaller
            )
        }
    }

    @ViewBuilder
    private var statusOverlay: some View {
        if session.status == .paused || session.status == .suspending {
            ZStack {
                Color.black.opacity(0.35)
                Text(session.status == .paused ? "Paused" : "Suspending…")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white)
            }
        }
    }

    private func ejectInstaller() {
        model.update(entry) {
            $0.installerImagePath = nil
        }
    }
}

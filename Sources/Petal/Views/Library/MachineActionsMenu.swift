import AppKit
import PetalCore
import SwiftUI

struct MachineActionsMenu: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow
    let entry: MachineEntry
    let session: MachineSession
    var includesRunAction = true
    var onSettings: (() -> Void)?

    private var isActive: Bool {
        session.status.isActive
    }

    var body: some View {
        if let onSettings {
            Button("Settings…", action: onSettings)
                .disabled(isActive)
        }

        if includesRunAction {
            if isActive {
                Button("Show Window") {
                    openWindow(id: "machine", value: entry.id)
                }

                Button("Force Stop", role: .destructive) {
                    Task { await session.forceStop() }
                }
                .disabled(session.status == .suspending)
            } else {
                Button(entry.bundle.hasSavedState ? "Resume" : "Start", action: start)
            }
        }

        Divider()

        Button("Clone") {
            model.clone(entry)
        }
        .disabled(isActive)

        Button("Show in Finder") {
            NSWorkspace.shared.activateFileViewerSelecting([entry.bundle.url])
        }

        if entry.bundle.hasSavedState && !isActive {
            Button("Discard Suspended State") {
                entry.bundle.discardSavedState()
                model.reload()
            }
        }

        Divider()

        Button("Move to Trash", role: .destructive) {
            model.trash(entry)
        }
        .disabled(isActive)
    }

    private func start() {
        openWindow(id: "machine", value: entry.id)
        Task { await session.start() }
    }
}

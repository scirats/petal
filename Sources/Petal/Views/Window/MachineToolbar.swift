import PetalCore
import SwiftUI

struct MachineToolbar: ToolbarContent {
    let entry: MachineEntry
    let session: MachineSession
    @Binding var capturesSystemKeys: Bool
    let onEjectInstaller: () -> Void

    var body: some ToolbarContent {
        ToolbarItemGroup {
            if !isIdle {
                statusButtons
                    .labelStyle(.iconOnly)
                moreMenu
                    .labelStyle(.iconOnly)
            }
        }
    }

    private var isIdle: Bool {
        session.virtualMachine == nil && !session.status.isActive
    }

    @ViewBuilder
    private var statusButtons: some View {
        switch session.status {
        case .running:
            Button {
                Task { await session.pause() }
            } label: {
                Label("Pause", systemImage: "pause.fill")
            }
            .help("Pause")

            if session.canSuspend {
                suspendButton
            }

            Button {
                session.requestShutdown()
            } label: {
                Label("Shut Down", systemImage: "power")
            }
            .help("Ask the guest to shut down")

        case .paused:
            Button {
                Task { await session.resume() }
            } label: {
                Label("Resume", systemImage: "play.fill")
            }
            .help("Resume")

            if session.canSuspend {
                suspendButton
            }

        case .stopped, .failed:
            Button {
                Task { await session.start() }
            } label: {
                Label(entry.bundle.hasSavedState ? "Resume" : "Start", systemImage: "play.fill")
            }
            .help(entry.bundle.hasSavedState ? "Resume" : "Start")

        case .stopping:
            ProgressView()
                .controlSize(.small)
            Button {
                Task { await session.forceStop() }
            } label: {
                Label("Force Stop", systemImage: "stop.fill")
            }
            .help("Cut power now — the guest isn't responding to Shut Down")

        case .starting, .suspending:
            ProgressView()
                .controlSize(.small)
        }
    }

    private var suspendButton: some View {
        Button {
            Task { await session.suspend() }
        } label: {
            Label("Suspend", systemImage: "moon.fill")
        }
        .help("Suspend to disk — resumes exactly where you left off")
    }

    private var moreMenu: some View {
        Menu {
            Toggle("Capture System Keys", isOn: $capturesSystemKeys)
                .help("Send shortcuts like ⌘Tab to the guest instead of this Mac")

            Divider()

            if entry.config.installerImagePath != nil {
                Button("Eject Installer at Next Start", action: onEjectInstaller)
            }
        } label: {
            Label("More", systemImage: "ellipsis.circle")
        }
    }
}

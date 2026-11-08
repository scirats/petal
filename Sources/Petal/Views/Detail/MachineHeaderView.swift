import Luminare
import PetalCore
import SwiftUI

struct MachineHeaderView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow
    let entry: MachineEntry
    let session: MachineSession
    @Binding var showingSettings: Bool
    @State private var newName = ""
    @State private var renaming = false

    private var isActive: Bool {
        session.status.isActive
    }

    private var presentation: MachineStatusPresentation {
        MachineStatusPresentation(status: session.status, hasSavedState: entry.bundle.hasSavedState)
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: PetalSpacing.large) {
            VStack(alignment: .leading, spacing: PetalSpacing.small) {
                nameField
                MachineStatusLabel(presentation: presentation)
            }

            Spacer(minLength: PetalSpacing.medium)
            actions
        }
    }

    @ViewBuilder
    private var nameField: some View {
        if renaming {
            PetalTitleField(
                text: $newName,
                prompt: entry.config.name,
                onSubmit: commitRename,
                onCancel: { renaming = false }
            )
            .frame(maxWidth: PetalMetrics.titleFieldWidth)
        } else {
            Text(entry.config.name)
                .font(PetalText.paneTitle)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .onTapGesture(count: 2) {
                    guard !isActive else { return }
                    newName = entry.config.name
                    renaming = true
                }
        }
    }

    private var actions: some View {
        HStack(spacing: PetalSpacing.small) {
            Button(action: openMachine) {
                Label(
                    isActive ? "Show" : (entry.bundle.hasSavedState ? "Resume" : "Start"),
                    systemImage: isActive ? "macwindow" : "play.fill"
                )
                .frame(minWidth: PetalMetrics.buttonMinWidth)
            }
            .buttonStyle(.luminare(tinted: true))
            .luminareContentSize(contentMode: .fit, hasFixedHeight: true)
            .fixedSize()

            moreMenu
        }
    }

    private var moreMenu: some View {
        Menu {
            MachineActionsMenu(
                entry: entry,
                session: session,
                includesRunAction: false,
                onSettings: { showingSettings = true }
            )
        } label: {
            Image(systemName: "ellipsis")
                .frame(width: PetalMetrics.iconButtonSize, height: PetalMetrics.iconSize)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .luminareContentSize(contentMode: .fit, hasFixedHeight: true)
        .luminareSurface(style: PetalSurface.field)
        .help("More")
    }

    private func openMachine() {
        openWindow(id: "machine", value: entry.id)
        guard !isActive else { return }
        Task { await session.start() }
    }

    private func commitRename() {
        renaming = false
        model.rename(entry, to: newName)
    }
}

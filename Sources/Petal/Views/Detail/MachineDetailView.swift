import PetalCore
import SwiftUI

struct MachineDetailView: View {
    let entry: MachineEntry
    let session: MachineSession
    @State private var showingSettings = false

    private var isActive: Bool {
        session.status.isActive
    }

    var body: some View {
        PetalPane {
            MachineHeaderView(
                entry: entry,
                session: session,
                showingSettings: $showingSettings
            )

            if case let .failed(message) = session.status {
                Text(message)
                    .font(PetalText.metadata)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }

            MachineOverviewView(entry: entry)
            SnapshotsPanel(
                entry: entry,
                isAvailable: !isActive && !entry.bundle.hasSavedState
            )
        }
        .sheet(isPresented: $showingSettings) {
            MachineSettingsView(entry: entry)
        }
    }
}

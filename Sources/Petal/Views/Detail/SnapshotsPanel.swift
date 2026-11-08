import Luminare
import PetalCore
import SwiftUI

struct SnapshotsPanel: View {
    @Environment(AppModel.self) private var model
    let entry: MachineEntry
    let isAvailable: Bool
    @State private var snapshots: [Snapshot] = []
    @State private var pendingRestore: Snapshot?

    var body: some View {
        LuminareSection(headerSpacing: PetalSpacing.small) {
            if snapshots.isEmpty {
                Text("No snapshots yet.")
                    .font(PetalText.metadata)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, PetalSpacing.medium)
                    .frame(minHeight: PetalMetrics.controlHeight)
            } else {
                ForEach(snapshots.reversed()) { snapshot in
                    snapshotRow(snapshot)
                }
            }
        } header: {
            HStack(spacing: PetalSpacing.small) {
                Text("Snapshots")
                    .font(PetalText.sectionHeader)
                Spacer(minLength: PetalSpacing.small)
                PetalActionButton(title: "Take Snapshot", action: takeSnapshot)
                    .disabled(!isAvailable)
                    .help(isAvailable ? "" : "Shut the machine down to take or restore snapshots")
            }
        }
        .onAppear(perform: loadSnapshots)
        .onChange(of: isAvailable) {
            loadSnapshots()
        }
        .confirmationDialog(
            "Restore snapshot?",
            isPresented: restoreConfirmation,
            titleVisibility: .visible,
            presenting: pendingRestore
        ) { snapshot in
            Button("Restore", role: .destructive) {
                restore(snapshot)
            }
            Button("Cancel", role: .cancel) {
                pendingRestore = nil
            }
        } message: { snapshot in
            Text("The current disk will be replaced with “\(snapshot.label)”.")
        }
    }

    private var restoreConfirmation: Binding<Bool> {
        Binding(
            get: { pendingRestore != nil },
            set: { if !$0 { pendingRestore = nil } }
        )
    }

    private func snapshotRow(_ snapshot: Snapshot) -> some View {
        LuminareCompose(alignment: .firstTextBaseline) {
            HStack(spacing: PetalSpacing.small) {
                PetalActionButton(title: "Restore") {
                    pendingRestore = snapshot
                }
                .disabled(!isAvailable)

                PetalIconButton(systemImage: "trash", help: "Delete Snapshot", role: .destructive) {
                    delete(snapshot)
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: PetalSpacing.hairline) {
                Text(snapshot.label)
                    .font(PetalText.metadata)
                Text(snapshot.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(PetalText.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func loadSnapshots() {
        snapshots = (try? SnapshotStore(bundle: entry.bundle).list()) ?? []
    }

    private func takeSnapshot() {
        let label = Date().formatted(date: .abbreviated, time: .shortened)
        model.attempt {
            try SnapshotStore(bundle: entry.bundle).take(label: label)
        }
        loadSnapshots()
    }

    private func restore(_ snapshot: Snapshot) {
        pendingRestore = nil
        model.attempt {
            try SnapshotStore(bundle: entry.bundle).restore(snapshot.id)
        }
        loadSnapshots()
    }

    private func delete(_ snapshot: Snapshot) {
        model.attempt {
            try SnapshotStore(bundle: entry.bundle).delete(snapshot.id)
        }
        loadSnapshots()
    }
}

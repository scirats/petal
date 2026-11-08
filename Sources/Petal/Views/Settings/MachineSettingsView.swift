import PetalCore
import SwiftUI

struct MachineSettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let entry: MachineEntry

    @State private var draft: MachineConfig
    @State private var memoryGiB: Double
    @State private var diskGiB: Double
    private let originalDiskGiB: Double

    init(entry: MachineEntry) {
        self.entry = entry
        _draft = State(initialValue: entry.config)
        _memoryGiB = State(initialValue: entry.config.resources.memoryBytes.gibibytes.rounded())
        let disk = entry.config.resources.diskBytes.gibibytes.rounded()
        _diskGiB = State(initialValue: disk)
        originalDiskGiB = disk
    }

    var body: some View {
        PetalSheet(entry.config.name) {
            if entry.bundle.hasSavedState {
                Text("Saving changes will discard the suspended state.")
                    .font(PetalText.metadata)
                    .foregroundStyle(.orange)
            }

            HardwareSettings(
                draft: $draft,
                memoryGiB: $memoryGiB,
                diskGiB: $diskGiB,
                originalDiskGiB: originalDiskGiB
            )
            IntegrationSettings(draft: $draft)
        } footer: {
            PetalActionButton(title: "Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)

            PetalActionButton(title: "Save", isTinted: true, action: save)
                .keyboardShortcut(.defaultAction)
        }
    }

    private func save() {
        var updated = draft
        updated.resources.memoryBytes = .gibibytes(Int(memoryGiB))
        updated.resources.diskBytes = max(.gibibytes(Int(diskGiB)), entry.config.resources.diskBytes)
        let changed = updated != entry.config

        let saved = model.update(entry) { config in
            if updated.resources.diskBytes > config.resources.diskBytes {
                try DiskImage.grow(
                    at: entry.bundle.diskURL(for: config),
                    to: updated.resources.diskBytes
                )
            }
            config = updated
        }

        guard saved else { return }
        if changed {
            entry.bundle.discardSavedState()
        }
        dismiss()
    }
}

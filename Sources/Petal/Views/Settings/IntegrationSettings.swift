import Luminare
import PetalCore
import SwiftUI

struct IntegrationSettings: View {
    @Environment(AppModel.self) private var model
    @Binding var draft: MachineConfig
    @State private var rosettaInstalled = Rosetta.isInstalled

    var body: some View {
        PetalSection("Integration") {
            LuminareToggle("Share clipboard", isOn: $draft.clipboardSharing)
            LuminareToggle("Allow microphone", isOn: $draft.audioInput)
            LuminareToggle("Rosetta for x86-64 binaries", isOn: $draft.rosetta)
                .disabled(!Rosetta.isSupported)

            if draft.rosetta && !rosettaInstalled {
                LuminareCompose("Rosetta") {
                    PetalActionButton(title: "Install", action: installRosetta)
                }
            }

            ForEach(draft.sharedFolders) { folder in
                folderRow(folder)
            }

            LuminareCompose("Folders") {
                PetalActionButton(title: "Add Folder…", action: addFolder)
            }

            PetalFileRow(
                title: "Installer",
                fileName: draft.installerImagePath.map { URL(fileURLWithPath: $0).lastPathComponent },
                chooseTitle: "Choose…",
                onRemove: { draft.installerImagePath = nil },
                onChoose: chooseISO
            )
        }
    }

    private func folderRow(_ folder: SharedFolder) -> some View {
        LuminareCompose {
            PetalIconButton(systemImage: "minus", help: "Remove Folder") {
                draft.sharedFolders.removeAll { $0.name == folder.name }
            }
        } label: {
            VStack(alignment: .leading, spacing: PetalSpacing.hairline) {
                Text(folder.name)
                Text(folder.hostPath)
                    .font(PetalText.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if folder.readOnly {
                    Text("Read-only")
                        .font(PetalText.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private func addFolder() {
        guard let url = FilePicker.directory(prompt: "Share") else { return }

        var name = url.lastPathComponent
        var counter = 2
        while draft.sharedFolders.contains(where: { $0.name == name }) {
            name = "\(url.lastPathComponent) \(counter)"
            counter += 1
        }
        draft.sharedFolders.append(SharedFolder(name: name, hostPath: url.path))
    }

    private func chooseISO() {
        guard let url = FilePicker.iso() else { return }
        draft.installerImagePath = url.path
    }

    private func installRosetta() {
        Task {
            do {
                try await Rosetta.install()
                rosettaInstalled = Rosetta.isInstalled
            } catch {
                model.alert = error.localizedDescription
            }
        }
    }
}

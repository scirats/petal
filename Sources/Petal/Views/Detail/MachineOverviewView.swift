import Luminare
import PetalCore
import SwiftUI

struct MachineOverviewView: View {
    let entry: MachineEntry

    private var config: MachineConfig {
        entry.config
    }

    var body: some View {
        PetalSection("Overview") {
            row("Processors", "\(config.resources.cpuCount)")
            row("Memory", "\(Int(config.resources.memoryBytes.gibibytes)) GB")
            row("Disk", "\(Int(config.resources.diskBytes.gibibytes)) GB")
            row("Display", config.display.label)

            if let integrationDescription {
                LuminareCompose("Integration") {
                    Text(integrationDescription)
                        .font(PetalText.metadata)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func row(_ title: String, _ value: String) -> some View {
        LuminareCompose(title) {
            Text(value)
                .font(PetalText.numeric)
        }
    }

    private var integrationDescription: String? {
        var items: [String] = []

        if !config.sharedFolders.isEmpty {
            items.append("Folders: \(config.sharedFolders.map(\.name).joined(separator: ", "))")
        }
        if config.rosetta && Rosetta.isInstalled {
            items.append("Rosetta")
        }
        if config.clipboardSharing {
            items.append("Clipboard")
        }
        if let installer = config.installerImagePath {
            items.append("Installer: \(URL(fileURLWithPath: installer).lastPathComponent)")
        }

        return items.isEmpty ? nil : items.joined(separator: " · ")
    }
}

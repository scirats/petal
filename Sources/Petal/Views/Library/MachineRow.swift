import PetalCore
import SwiftUI

struct MachineRow: View {
    let entry: MachineEntry
    let session: MachineSession

    private var presentation: MachineStatusPresentation {
        MachineStatusPresentation(status: session.status, hasSavedState: entry.bundle.hasSavedState)
    }

    var body: some View {
        HStack(spacing: PetalSpacing.medium) {
            Image(systemName: "desktopcomputer")
                .font(PetalText.sidebarIcon)
                .foregroundStyle(.secondary)
                .frame(width: PetalMetrics.iconSize)

            VStack(alignment: .leading, spacing: PetalSpacing.hairline) {
                Text(entry.config.name)
                    .lineLimit(1)

                MachineStatusLabel(presentation: presentation, font: PetalText.caption)
            }

            Spacer(minLength: 0)
        }
    }
}

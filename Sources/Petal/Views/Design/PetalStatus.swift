import SwiftUI

struct StatusDot: View {
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: PetalMetrics.statusDot, height: PetalMetrics.statusDot)
    }
}

struct MachineStatusLabel: View {
    let presentation: MachineStatusPresentation
    var font: Font = PetalText.metadata

    var body: some View {
        HStack(spacing: PetalSpacing.small) {
            StatusDot(color: presentation.color)
            Text(presentation.text)
                .font(font)
                .foregroundStyle(.secondary)
        }
    }
}

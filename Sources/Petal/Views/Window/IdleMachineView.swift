import Luminare
import PetalCore
import SwiftUI

struct IdleMachineView: View {
    let entry: MachineEntry
    let session: MachineSession

    var body: some View {
        VStack(spacing: PetalSpacing.large) {
            switch session.status {
            case .starting:
                ProgressView()
                    .controlSize(.small)
            case let .failed(message):
                Text(message)
                    .font(PetalText.metadata)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .textSelection(.enabled)
                    .frame(maxWidth: PetalMetrics.messageMaxWidth)
                startButton
            default:
                startButton
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .petalPaneBackground()
    }

    private var startButton: some View {
        Button {
            Task { await session.start() }
        } label: {
            Label(
                entry.bundle.hasSavedState ? "Resume" : "Start",
                systemImage: "play.fill"
            )
            .frame(minWidth: PetalMetrics.startButtonWidth)
        }
        .buttonStyle(.luminare(tinted: true))
        .luminareContentSize(contentMode: .fit, hasFixedHeight: true)
        .fixedSize()
        .keyboardShortcut(.defaultAction)
    }
}

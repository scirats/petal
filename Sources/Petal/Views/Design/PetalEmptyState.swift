import SwiftUI

struct PetalEmptyState<Actions>: View where Actions: View {
    let systemImage: String
    let title: String
    let message: String
    @ViewBuilder let actions: () -> Actions

    var body: some View {
        VStack(spacing: PetalSpacing.large) {
            Image(systemName: systemImage)
                .font(.system(size: PetalMetrics.emptyStateIcon, weight: .light))
                .foregroundStyle(.tertiary)

            VStack(spacing: PetalSpacing.xSmall) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Text(message)
                    .font(PetalText.metadata)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: PetalMetrics.messageMaxWidth)
            }

            actions()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(PetalMetrics.panePadding)
        .petalPaneBackground()
    }
}

extension PetalEmptyState where Actions == EmptyView {
    init(systemImage: String, title: String, message: String) {
        self.init(systemImage: systemImage, title: title, message: message) {
            EmptyView()
        }
    }
}

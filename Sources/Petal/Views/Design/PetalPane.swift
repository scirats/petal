import SwiftUI

struct PetalPane<Content>: View where Content: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PetalSpacing.xxLarge) {
                content()
            }
            .frame(maxWidth: PetalMetrics.paneMaxWidth, alignment: .leading)
            .padding(PetalMetrics.panePadding)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .petalPaneBackground()
    }
}

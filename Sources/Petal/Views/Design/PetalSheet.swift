import SwiftUI

struct PetalSheet<Content, Footer>: View where Content: View, Footer: View {
    private let title: String
    private let height: CGFloat
    @ViewBuilder private let content: () -> Content
    @ViewBuilder private let footer: () -> Footer

    init(
        _ title: String,
        height: CGFloat = PetalMetrics.sheetHeight,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder footer: @escaping () -> Footer
    ) {
        self.title = title
        self.height = height
        self.content = content
        self.footer = footer
    }

    var body: some View {
        PetalRoot {
            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: PetalSpacing.large) {
                        content()
                    }
                    .padding(PetalMetrics.panePadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                footerBar
            }
            .petalPaneBackground()
        }
        .frame(width: PetalMetrics.sheetWidth, height: height)
    }

    private var header: some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.top, PetalSpacing.large)
            .padding(.bottom, PetalSpacing.small)
    }

    private var footerBar: some View {
        HStack(spacing: PetalSpacing.small) {
            Spacer(minLength: 0)
            footer()
        }
        .padding(.horizontal, PetalMetrics.panePadding)
        .padding(.vertical, PetalSpacing.large)
    }
}

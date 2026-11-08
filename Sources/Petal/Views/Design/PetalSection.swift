import Luminare
import SwiftUI

struct PetalSection<Content, Footer>: View where Content: View, Footer: View {
    private let title: String
    @ViewBuilder private let content: () -> Content
    @ViewBuilder private let footer: () -> Footer

    init(
        _ title: String,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder footer: @escaping () -> Footer
    ) {
        self.title = title
        self.content = content
        self.footer = footer
    }

    var body: some View {
        LuminareSection(headerSpacing: PetalSpacing.xSmall) {
            content()
        } header: {
            Text(title)
                .font(PetalText.sectionHeader)
                .padding(.leading, PetalSpacing.small)
        } footer: {
            footer()
        }
    }
}

extension PetalSection where Footer == EmptyView {
    init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
        self.init(title, content: content) {
            EmptyView()
        }
    }
}

import Luminare
import SwiftUI

struct PetalRoot<Content>: View where Content: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .buttonStyle(.luminare)
            .petalDesign()
    }
}

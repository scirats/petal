import Luminare
import SwiftUI

struct PetalActionButton: View {
    let title: String
    var role: ButtonRole?
    var isTinted = false
    let action: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        Button(role: role, action: action) {
            Text(title)
                .padding(.horizontal, PetalSpacing.medium)
        }
        .buttonStyle(.luminare(tinted: isTinted))
        .luminareSurfaceStyle(PetalSurface.minimal)
        .luminareContentSize(contentMode: .fit, hasFixedHeight: true)
        .fixedSize()
        .focused($isFocused)
        .petalFocusRing(isFocused)
    }
}

struct PetalIconButton: View {
    let systemImage: String
    let help: String
    var role: ButtonRole?
    let action: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        Button(role: role, action: action) {
            Image(systemName: systemImage)
                .frame(width: PetalMetrics.iconButtonSize, height: PetalMetrics.iconSize)
        }
        .buttonStyle(.luminare)
        .luminareSurfaceStyle(PetalSurface.minimal)
        .luminareContentSize(contentMode: .fit, hasFixedHeight: true)
        .fixedSize()
        .focused($isFocused)
        .petalFocusRing(isFocused)
        .help(help)
    }
}

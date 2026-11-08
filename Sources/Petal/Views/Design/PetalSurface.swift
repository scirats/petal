import Luminare
import SwiftUI

enum PetalSurface {
    static let minimal = LuminareSurfaceStyle(
        lightStyle: .init(fillStyle: nil, borderStyle: nil, shadowStyle: nil),
        darkStyle: .init(fillStyle: nil, borderStyle: nil, shadowStyle: nil),
        buttonLightStyle: .init(fillStyle: buttonFill, shadowStyle: nil),
        buttonDarkStyle: .init(fillStyle: buttonFill, shadowStyle: nil)
    )

    static let field = LuminareSurfaceStyle(
        lightStyle: .init(fillStyle: fieldFill, borderStyle: nil, shadowStyle: nil),
        darkStyle: .init(fillStyle: fieldFill, borderStyle: nil, shadowStyle: nil)
    )

    private static var buttonFill: LuminareFillStyle<AnyShapeStyle, AnyShapeStyle, AnyShapeStyle> {
        .init(
            normal: AnyShapeStyle(.quinary),
            hovering: AnyShapeStyle(.quaternary),
            pressed: AnyShapeStyle(.tertiary)
        )
    }

    private static var fieldFill: LuminareFillStyle<AnyShapeStyle, AnyShapeStyle, AnyShapeStyle> {
        .init(
            normal: AnyShapeStyle(.quinary),
            hovering: AnyShapeStyle(.quaternary),
            pressed: AnyShapeStyle(.quaternary)
        )
    }
}

enum PetalColor {
    static let pane = Color(nsColor: .windowBackgroundColor)
    static let sidebar = Color(nsColor: .underPageBackgroundColor)
}

extension View {
    func petalPaneBackground() -> some View {
        background(PetalColor.pane.ignoresSafeArea())
    }

    func petalSidebarBackground() -> some View {
        background(PetalColor.sidebar.ignoresSafeArea())
    }

    func petalFocusRing(_ isFocused: Bool, cornerRadius: CGFloat = PetalMetrics.fieldCornerRadius) -> some View {
        overlay {
            if isFocused {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(.tint, lineWidth: 2)
            }
        }
    }
}

struct PetalFieldBackground: View {
    var isHovering = false

    var body: some View {
        RoundedRectangle(cornerRadius: PetalMetrics.fieldCornerRadius)
            .fill(AnyShapeStyle(isHovering ? .quaternary : .quinary))
    }
}

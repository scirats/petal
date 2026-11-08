import SwiftUI

struct PetalSidebarList<Item, Row>: View where Item: Identifiable, Row: View {
    let items: [Item]
    @Binding var selection: Item.ID?
    @ViewBuilder let row: (Item) -> Row

    var body: some View {
        ScrollView {
            LazyVStack(spacing: PetalSpacing.hairline) {
                ForEach(items) { item in
                    PetalSidebarRow(
                        isSelected: selection == item.id
                    ) {
                        selection = item.id
                    } content: {
                        row(item)
                    }
                }
            }
            .padding(PetalSpacing.small)
        }
        .scrollIndicators(.never)
    }
}

private struct PetalSidebarRow<Content>: View where Content: View {
    let isSelected: Bool
    let action: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var isHovering = false
    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: action) {
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, PetalSpacing.small)
                .frame(height: PetalMetrics.listRowHeight)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .background {
            RoundedRectangle(cornerRadius: PetalMetrics.listRowCornerRadius)
                .fill(fill)
        }
        .focused($isFocused)
        .petalFocusRing(isFocused, cornerRadius: PetalMetrics.listRowCornerRadius)
        .onHover { isHovering = $0 }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var fill: AnyShapeStyle {
        if isSelected {
            AnyShapeStyle(.quaternary)
        } else if isHovering {
            AnyShapeStyle(.quinary)
        } else {
            AnyShapeStyle(.clear)
        }
    }
}

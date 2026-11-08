import SwiftUI

struct PetalSegmentedPicker<Value>: View where Value: Hashable {
    @Binding var selection: Value
    let options: [Value]
    let title: (Value) -> String

    var body: some View {
        HStack(spacing: PetalSpacing.hairline) {
            ForEach(options, id: \.self) { option in
                Button {
                    selection = option
                } label: {
                    Text(title(option))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .frame(height: PetalMetrics.segmentHeight)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .background {
                    RoundedRectangle(cornerRadius: PetalMetrics.fieldCornerRadius - PetalSpacing.hairline)
                        .fill(selection == option ? AnyShapeStyle(.quaternary) : AnyShapeStyle(.clear))
                }
                .accessibilityAddTraits(selection == option ? .isSelected : [])
            }
        }
        .padding(PetalSpacing.hairline)
        .background(PetalFieldBackground())
        .frame(width: PetalMetrics.fieldWidth)
    }
}

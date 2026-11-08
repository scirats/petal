import Luminare
import SwiftUI

struct PetalTitleField: View {
    @Binding var text: String
    let prompt: String
    let onSubmit: () -> Void
    let onCancel: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("", text: $text, prompt: Text(prompt))
            .textFieldStyle(.plain)
            .font(PetalText.paneTitle)
            .focused($isFocused)
            .padding(.horizontal, PetalSpacing.small)
            .padding(.vertical, PetalSpacing.xSmall)
            .luminareSurface(style: PetalSurface.field)
            .petalFocusRing(isFocused)
            .onAppear {
                isFocused = true
            }
            .onSubmit(onSubmit)
            .onExitCommand(perform: onCancel)
    }
}

struct PetalTextField: View {
    @Binding var text: String
    var prompt = ""
    var autofocus = false

    @FocusState private var isFocused: Bool

    var body: some View {
        LuminareTextField(
            text: $text.optional,
            prompt: prompt.isEmpty ? nil : Text(prompt)
        ) {
            EmptyView()
        }
        .focused($isFocused)
        .frame(width: PetalMetrics.fieldWidth)
        .onAppear {
            if autofocus {
                isFocused = true
            }
        }
    }
}

struct PetalSecureField: View {
    @Binding var text: String
    var prompt = ""
    var autofocus = false

    @FocusState private var isFocused: Bool

    var body: some View {
        SecureField("", text: $text, prompt: prompt.isEmpty ? nil : Text(prompt))
            .textFieldStyle(.plain)
            .focused($isFocused)
            .padding(.horizontal, PetalSpacing.medium)
            .frame(width: PetalMetrics.fieldWidth, height: PetalMetrics.fieldHeight)
            .luminareSurface(style: PetalSurface.field)
            .petalFocusRing(isFocused)
            .onAppear {
                if autofocus {
                    isFocused = true
                }
            }
    }
}

struct PetalFileRow: View {
    let title: String
    let fileName: String?
    let chooseTitle: String
    var onRemove: (() -> Void)?
    let onChoose: () -> Void

    var body: some View {
        LuminareCompose(title) {
            HStack(spacing: PetalSpacing.small) {
                Text(fileName ?? "None")
                    .font(PetalText.metadata)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                PetalActionButton(title: chooseTitle, action: onChoose)

                if let onRemove, fileName != nil {
                    PetalIconButton(systemImage: "xmark", help: "Remove") {
                        onRemove()
                    }
                }
            }
        }
    }
}

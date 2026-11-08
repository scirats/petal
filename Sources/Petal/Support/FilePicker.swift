import AppKit
import UniformTypeIdentifiers

@MainActor
enum FilePicker {
    static func iso() -> URL? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            UTType(filenameExtension: "iso") ?? .diskImage,
            .diskImage,
        ]
        return panel.runModal() == .OK ? panel.url : nil
    }

    static func directory(prompt: String) -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.prompt = prompt
        return panel.runModal() == .OK ? panel.url : nil
    }
}

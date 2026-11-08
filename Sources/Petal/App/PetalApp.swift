import SwiftUI

@main
struct PetalApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = AppModel()

    var body: some Scene {
        Window("Petal", id: "library") {
            LibraryView()
                .environment(model)
                .frame(minWidth: PetalMetrics.libraryMinWidth, minHeight: PetalMetrics.libraryMinHeight)
                .onAppear {
                    appDelegate.model = model
                }
        }
        .defaultSize(width: PetalMetrics.libraryWidth, height: PetalMetrics.libraryHeight)
        .commands {
            CommandGroup(replacing: .newItem) {
                NewMachineCommand()
            }
        }

        WindowGroup("Machine", id: "machine", for: URL.self) { $url in
            if let url {
                MachineWindow(url: url)
                    .environment(model)
            }
        }
        .defaultSize(width: PetalMetrics.machineWidth, height: PetalMetrics.machineHeight)
        .windowToolbarStyle(.unifiedCompact)
    }
}

private struct NewMachineCommand: View {
    @FocusedValue(\.newMachineAction) private var newMachine

    var body: some View {
        Button("New Machine…") {
            newMachine?()
        }
        .keyboardShortcut("n")
        .disabled(newMachine == nil)
    }
}

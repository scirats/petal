import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    @MainActor weak var model: AppModel?

    func applicationDidFinishLaunching(_: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        false
    }

    @MainActor
    func applicationShouldTerminate(_: NSApplication) -> NSApplication.TerminateReply {
        guard model?.hasActiveMachines == true else { return .terminateNow }

        let alert = NSAlert()
        alert.messageText = "Machines are still running"
        alert.informativeText = "Quitting turns them off immediately, like pulling the power cord. "
            + "Suspend or shut them down first to keep their work."
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Quit Anyway")
        alert.alertStyle = .warning
        return alert.runModal() == .alertSecondButtonReturn ? .terminateNow : .terminateCancel
    }
}

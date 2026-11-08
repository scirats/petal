import SwiftUI
import Virtualization

struct VirtualMachineDisplay: NSViewRepresentable {
    let machine: VZVirtualMachine
    let capturesSystemKeys: Bool

    func makeNSView(context _: Context) -> VZVirtualMachineView {
        let view = FocusingVirtualMachineView()
        view.virtualMachine = machine
        view.capturesSystemKeys = capturesSystemKeys
        view.automaticallyReconfiguresDisplay = true
        return view
    }

    func updateNSView(_ view: VZVirtualMachineView, context _: Context) {
        if view.virtualMachine !== machine {
            view.virtualMachine = machine
        }
        view.capturesSystemKeys = capturesSystemKeys
    }
}

private final class FocusingVirtualMachineView: VZVirtualMachineView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }
}

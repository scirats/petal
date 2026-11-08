import PetalCore
import SwiftUI

struct MachineStatusPresentation {
    let status: MachineStatus
    let hasSavedState: Bool

    var text: String {
        if case .stopped = status, hasSavedState {
            return "Suspended"
        }
        return status.label
    }

    var color: Color {
        switch status {
        case .running:
            .green
        case .paused, .suspending, .starting, .stopping:
            .orange
        case .failed:
            .red
        case .stopped:
            hasSavedState ? .blue : .gray
        }
    }
}

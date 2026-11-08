import Foundation
import PetalCore
import SwiftUI

struct MachineWindow: View {
    @Environment(AppModel.self) private var model
    let url: URL

    var body: some View {
        PetalRoot {
            if let entry = model.entry(for: url) {
                MachineScreen(entry: entry, session: model.session(for: entry))
            } else {
                PetalEmptyState(
                    systemImage: "questionmark.square.dashed",
                    title: "Machine not found",
                    message: "It may have been renamed or moved to the Trash."
                )
            }
        }
    }
}

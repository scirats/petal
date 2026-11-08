import Foundation
import PetalCore

struct MachineEntry: Identifiable {
    let bundle: MachineBundle
    let config: MachineConfig

    var id: URL { bundle.url }
}

import Luminare
import PetalCore
import SwiftUI

struct NewMachineResourceSettings: View {
    @Binding var cpus: Int
    @Binding var memoryGiB: Double
    @Binding var diskGiB: Double

    var body: some View {
        PetalSection("Resources") {
            LuminarePickerMenu(
                "Processors",
                selection: $cpus,
                items: Array(1 ... MachineDefaults.hostCPUCount)
            ) { count in
                Text("\(count)")
            }

            LuminareSlider(
                "Memory",
                value: $memoryGiB.rounded,
                in: 2 ... Double(MachineDefaults.maxMemoryGiB),
                format: .number.precision(.fractionLength(0)),
                suffix: Text(" GB")
            )

            LuminareSlider(
                "Disk",
                value: $diskGiB.rounded,
                in: 16 ... 1024,
                format: .number.precision(.fractionLength(0)),
                suffix: Text(" GB")
            )
        }
    }
}

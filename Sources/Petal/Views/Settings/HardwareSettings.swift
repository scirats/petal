import Luminare
import PetalCore
import SwiftUI

struct HardwareSettings: View {
    @Binding var draft: MachineConfig
    @Binding var memoryGiB: Double
    @Binding var diskGiB: Double
    let originalDiskGiB: Double

    var body: some View {
        PetalSection("Hardware") {
            LuminarePickerMenu(
                "Processors",
                selection: $draft.resources.cpuCount,
                items: Array(1 ... max(MachineDefaults.hostCPUCount, draft.resources.cpuCount))
            ) { count in
                Text("\(count)")
            }

            LuminareSlider(
                "Memory",
                value: $memoryGiB.rounded,
                in: 2 ... max(Double(MachineDefaults.maxMemoryGiB), memoryGiB.rounded()),
                format: .number.precision(.fractionLength(0)),
                suffix: Text(" GB")
            )

            LuminareSlider(
                "Disk",
                value: $diskGiB.rounded,
                in: originalDiskGiB ... max(originalDiskGiB, 2048),
                format: .number.precision(.fractionLength(0)),
                suffix: Text(" GB")
            )

            LuminarePickerMenu(
                "Display",
                selection: $draft.display,
                items: displays
            ) { display in
                Text(display.label)
            }
        }
    }

    private var displays: [DisplaySpec] {
        DisplaySpec.presets.contains(draft.display)
            ? DisplaySpec.presets
            : DisplaySpec.presets + [draft.display]
    }
}

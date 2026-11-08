import Luminare
import PetalCore
import SwiftUI

struct NewMachineSettings: View {
    @Binding var source: NewMachineSource
    @Binding var name: String
    @Binding var distro: CatalogImage
    @Binding var isoURL: URL?
    let defaultName: String

    var body: some View {
        PetalSection("Machine") {
            LuminareCompose("Source") {
                PetalSegmentedPicker(
                    selection: $source,
                    options: NewMachineSource.allCases,
                    title: \.title
                )
            }

            LuminareCompose("Name") {
                PetalTextField(text: $name, prompt: defaultName)
            }

            if source == .download {
                LuminarePickerMenu(
                    "Distribution",
                    selection: $distro,
                    items: ImageCatalog.linux
                ) { image in
                    Text(image.name)
                }
            } else {
                PetalFileRow(
                    title: "ISO",
                    fileName: isoURL?.lastPathComponent,
                    chooseTitle: "Choose…",
                    onChoose: chooseISO
                )
            }
        } footer: {
            if source == .download {
                Text("\(distro.summary) · \(distro.approximateSize)")
                    .font(PetalText.caption)
            }
        }
    }

    private func chooseISO() {
        isoURL = FilePicker.iso()
    }
}

import Foundation
import PetalCore
import SwiftUI

struct NewMachineSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var source = NewMachineSource.download
    @State private var distro = ImageCatalog.ubuntuDesktop
    @State private var isoURL: URL?
    @State private var account = GuestAccount.suggested()
    @State private var confirmPassword = ""
    @State private var cpus = MachineDefaults.cpuCount
    @State private var memoryGiB = MachineDefaults.memoryBytes.gibibytes.rounded()
    @State private var diskGiB = 64.0

    var body: some View {
        PetalSheet("New Machine") {
            NewMachineSettings(
                source: $source,
                name: $name,
                distro: $distro,
                isoURL: $isoURL,
                defaultName: defaultName
            )

            if source == .download, distro.isAutomatic {
                NewMachineAccountSettings(account: $account, confirmPassword: $confirmPassword)
            }

            NewMachineResourceSettings(
                cpus: $cpus,
                memoryGiB: $memoryGiB,
                diskGiB: $diskGiB
            )
        } footer: {
            PetalActionButton(title: "Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)

            PetalActionButton(title: "Create", isTinted: true, action: create)
                .keyboardShortcut(.defaultAction)
                .disabled(!canCreate)
        }
    }

    private var defaultName: String {
        switch source {
        case .download:
            return model.library.uniqueName(base: distro.machineName)
        case .file:
            guard let isoURL else {
                return model.library.uniqueName(base: "Linux")
            }
            let base = isoURL.deletingPathExtension().lastPathComponent
            return model.library.uniqueName(base: base.isEmpty ? "Linux" : base)
        }
    }

    private var finalName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultName : trimmed
    }

    private var canCreate: Bool {
        switch source {
        case .download where distro.isAutomatic:
            return account.password == confirmPassword && (try? account.validate()) != nil
        case .download:
            return true
        case .file:
            return isoURL != nil
        }
    }

    private func create() {
        do {
            try model.library.validate(name: finalName)
        } catch {
            model.alert = error.localizedDescription
            return
        }

        let destination = MachineNaming.bundleURL(for: finalName, in: model.library.rootURL)
        guard !FileManager.default.fileExists(atPath: destination.path) else {
            model.alert = PetalError.nameTaken(finalName).localizedDescription
            return
        }

        let resources = MachineResources(
            cpuCount: cpus,
            memoryBytes: .gibibytes(Int(memoryGiB)),
            diskBytes: .gibibytes(Int(diskGiB))
        )

        switch source {
        case .download:
            if distro.isAutomatic {
                do {
                    try account.validate()
                } catch {
                    model.alert = error.localizedDescription
                    return
                }
            }
            model.install(
                distro,
                account: distro.isAutomatic ? account : nil,
                name: finalName,
                resources: resources
            )
            dismiss()

        case .file:
            guard let bundle = model.createLinux(
                name: finalName,
                iso: isoURL,
                resources: resources
            ) else { return }
            dismiss()
            model.launchRequest = bundle
        }
    }
}

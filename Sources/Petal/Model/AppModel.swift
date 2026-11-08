import Foundation
import Observation
import PetalCore

@MainActor
@Observable
final class AppModel {
    let library: MachineLibrary
    let catalog: MachineListModel
    let sessions: SessionRegistry
    let installs: InstallCenter

    var selection: URL?
    var alert: String?
    var launchRequest: MachineBundle?

    init(library: MachineLibrary = MachineLibrary()) {
        self.library = library
        catalog = MachineListModel(library: library)
        sessions = SessionRegistry()
        installs = InstallCenter(library: library)
        installs.onCompletion = { [weak self] bundle in
            self?.finishInstall(bundle)
        }
        reload()
    }

    var machines: [MachineEntry] {
        catalog.entries
    }

    var hasActiveMachines: Bool {
        sessions.hasActiveMachines
    }

    func reload() {
        do {
            try catalog.reload()
        } catch {
            alert = error.localizedDescription
            return
        }

        sessions.prune(keeping: catalog.entries)
        if let selection, catalog.entries.contains(where: { $0.id == selection }) {
            return
        }
        selection = catalog.entries.first?.id
    }

    func entry(for url: URL) -> MachineEntry? {
        catalog.entry(for: url)
    }

    func session(for entry: MachineEntry) -> MachineSession {
        sessions.session(for: entry.bundle)
    }

    @discardableResult
    func attempt(_ action: () throws -> Void) -> Bool {
        do {
            try action()
            reload()
            return true
        } catch {
            alert = error.localizedDescription
            reload()
            return false
        }
    }

    @discardableResult
    func update(_ entry: MachineEntry, _ change: (inout MachineConfig) throws -> Void) -> Bool {
        attempt {
            var config = try entry.bundle.loadConfig()
            try change(&config)
            try entry.bundle.saveConfig(config)
        }
    }

    func clone(_ entry: MachineEntry) {
        attempt {
            let name = library.uniqueName(base: "\(entry.config.name) Clone")
            let clone = try library.cloneMachine(entry.bundle, as: name)
            selection = clone.url
        }
    }

    func trash(_ entry: MachineEntry) {
        guard attempt({ try library.trash(entry.bundle) }) else { return }
        sessions.remove(entry.bundle.url)
    }

    func rename(_ entry: MachineEntry, to name: String) {
        guard name != entry.config.name else { return }
        attempt {
            let renamed = try library.rename(entry.bundle, to: name)
            sessions.remove(entry.bundle.url)
            selection = renamed.url
        }
    }

    @discardableResult
    func createLinux(name: String, iso: URL?, resources: MachineResources) -> MachineBundle? {
        var created: MachineBundle?
        attempt {
            created = try library.createLinux(
                name: name,
                installerISO: iso,
                resources: resources
            )
        }
        if let created {
            selection = created.url
        }
        return created
    }

    func install(_ image: CatalogImage, account: GuestAccount?, name: String, resources: MachineResources) {
        installs.start(image: image, account: account, name: name, resources: resources)
    }

    private func finishInstall(_ bundle: MachineBundle) {
        reload()
        selection = bundle.url
        launchRequest = bundle
    }
}

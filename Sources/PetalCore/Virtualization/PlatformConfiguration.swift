import Foundation
import Virtualization

enum PlatformConfiguration {
    static func make(bundle: MachineBundle) throws -> VZGenericPlatformConfiguration {
        guard FileSystem.exists(bundle.machineIdentifierURL) else {
            throw PetalError.missingFile(bundle.machineIdentifierURL.path)
        }
        let data = try Data(contentsOf: bundle.machineIdentifierURL)
        guard let identifier = VZGenericMachineIdentifier(dataRepresentation: data) else {
            throw PetalError.invalidConfiguration("The machine identifier is damaged.")
        }

        let platform = VZGenericPlatformConfiguration()
        platform.machineIdentifier = identifier
        return platform
    }
}

enum BootLoaderConfiguration {
    static func make(bundle: MachineBundle) throws -> VZEFIBootLoader {
        guard FileSystem.exists(bundle.efiVariableStoreURL) else {
            throw PetalError.missingFile(bundle.efiVariableStoreURL.path)
        }

        let bootLoader = VZEFIBootLoader()
        bootLoader.variableStore = VZEFIVariableStore(url: bundle.efiVariableStoreURL)
        return bootLoader
    }
}

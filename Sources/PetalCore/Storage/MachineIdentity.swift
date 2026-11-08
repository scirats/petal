import Foundation
import Virtualization

enum MachineIdentity {
    static func createEFIVariableStore(at url: URL) throws {
        _ = try VZEFIVariableStore(creatingVariableStoreAt: url, options: [])
    }

    static func createIdentifier(at url: URL) throws {
        try VZGenericMachineIdentifier().dataRepresentation.write(to: url)
    }

    static func newMACAddress() -> String {
        VZMACAddress.randomLocallyAdministered().string
    }
}

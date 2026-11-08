import Foundation
import Virtualization

enum StorageConfiguration {
    static func make(bundle: MachineBundle, config: MachineConfig) throws -> [VZStorageDeviceConfiguration] {
        var devices: [VZStorageDeviceConfiguration] = [try mainDisk(for: bundle, config: config)]

        if let installerPath = config.installerImagePath {
            devices.append(try removableDevice(at: URL(fileURLWithPath: installerPath)))
        }
        if FileSystem.exists(bundle.cloudInitSeedURL) {
            devices.append(try cloudInitDevice(at: bundle.cloudInitSeedURL))
        }
        return devices
    }

    private static func mainDisk(for bundle: MachineBundle, config: MachineConfig) throws -> VZStorageDeviceConfiguration {
        let diskURL = bundle.diskURL(for: config)
        guard FileSystem.exists(diskURL) else {
            throw PetalError.missingFile(diskURL.path)
        }

        let attachment = try VZDiskImageStorageDeviceAttachment(
            url: diskURL,
            readOnly: false,
            cachingMode: .automatic,
            synchronizationMode: .fsync
        )
        return VZVirtioBlockDeviceConfiguration(attachment: attachment)
    }

    private static func removableDevice(at url: URL) throws -> VZStorageDeviceConfiguration {
        guard FileSystem.exists(url) else {
            throw PetalError.missingFile(url.path)
        }
        let attachment = try VZDiskImageStorageDeviceAttachment(url: url, readOnly: true)
        return VZUSBMassStorageDeviceConfiguration(attachment: attachment)
    }

    private static func cloudInitDevice(at url: URL) throws -> VZStorageDeviceConfiguration {
        let attachment = try VZDiskImageStorageDeviceAttachment(url: url, readOnly: true)
        return VZVirtioBlockDeviceConfiguration(attachment: attachment)
    }
}

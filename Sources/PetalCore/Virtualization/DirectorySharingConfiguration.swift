import Foundation
import Virtualization

enum DirectorySharingConfiguration {
    static func make(config: MachineConfig) throws -> [VZVirtioFileSystemDeviceConfiguration] {
        var devices: [VZVirtioFileSystemDeviceConfiguration] = []

        if let share = try sharedFolders(config.sharedFolders) {
            let device = VZVirtioFileSystemDeviceConfiguration(tag: DirectoryShareTag.shared)
            device.share = share
            devices.append(device)
        }

        if config.rosetta && Rosetta.isInstalled {
            let device = VZVirtioFileSystemDeviceConfiguration(tag: DirectoryShareTag.rosetta)
            device.share = try VZLinuxRosettaDirectoryShare()
            devices.append(device)
        }

        return devices
    }

    private static func sharedFolders(_ folders: [SharedFolder]) throws -> VZDirectoryShare? {
        guard !folders.isEmpty else { return nil }

        var directories: [String: VZSharedDirectory] = [:]
        for folder in folders {
            let url = URL(fileURLWithPath: folder.hostPath)
            guard FileSystem.isDirectory(url) else {
                throw PetalError.missingFile(folder.hostPath)
            }
            guard directories[folder.name] == nil else {
                throw PetalError.invalidConfiguration("The folder name “\(folder.name)” is used twice.")
            }
            directories[folder.name] = VZSharedDirectory(url: url, readOnly: folder.readOnly)
        }
        return VZMultipleDirectoryShare(directories: directories)
    }
}

import Foundation

struct MachineProvisioner {
    let rootURL: URL

    func createLinux(name: String, installerISO: URL?, resources: MachineResources) throws -> MachineBundle {
        if let installerISO, !FileSystem.exists(installerISO) {
            throw PetalError.missingFile(installerISO.path)
        }
        let bundle = try MachineScaffold.create(rootURL: rootURL, name: name)
        do {
            let format = DiskImage.preferredFormat
            let diskURL = bundle.url.appendingPathComponent(format.fileName)
            let usedFormat = try DiskImage.create(at: diskURL, bytes: resources.diskBytes, format: format)

            try MachineIdentity.createEFIVariableStore(at: bundle.efiVariableStoreURL)
            try MachineIdentity.createIdentifier(at: bundle.machineIdentifierURL)

            let config = MachineConfig(
                name: name,
                resources: resources,
                diskFileName: usedFormat.fileName,
                macAddress: MachineIdentity.newMACAddress(),
                installerImagePath: installerISO?.path,
                rosetta: Rosetta.isInstalled
            )
            try bundle.saveConfig(config)
            return bundle
        } catch {
            MachineScaffold.discard(bundle)
            throw error
        }
    }

    func createCloud(
        name: String,
        archive: URL,
        account: GuestAccount,
        desktop: Bool,
        resources: MachineResources
    ) throws -> MachineBundle {
        try account.validate()
        guard FileSystem.exists(archive) else {
            throw PetalError.missingFile(archive.path)
        }
        let bundle = try MachineScaffold.create(rootURL: rootURL, name: name)
        do {
            let preparedDisk = try CloudImagePreparer.prepare(
                archive: archive,
                bundle: bundle,
                requestedBytes: resources.diskBytes
            )

            try MachineIdentity.createEFIVariableStore(at: bundle.efiVariableStoreURL)
            try MachineIdentity.createIdentifier(at: bundle.machineIdentifierURL)
            try CloudInitSeed.create(
                at: bundle.cloudInitSeedURL,
                account: account,
                hostname: CloudInitSeed.hostname(for: name),
                desktop: desktop
            )

            var cloudResources = resources
            cloudResources.diskBytes = max(resources.diskBytes, preparedDisk.logicalSize)
            let config = MachineConfig(
                name: name,
                resources: cloudResources,
                diskFileName: preparedDisk.url.lastPathComponent,
                macAddress: MachineIdentity.newMACAddress(),
                rosetta: Rosetta.isInstalled
            )
            try bundle.saveConfig(config)
            return bundle
        } catch {
            MachineScaffold.discard(bundle)
            throw error
        }
    }
}

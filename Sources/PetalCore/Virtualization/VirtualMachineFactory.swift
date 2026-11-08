import Foundation
import Virtualization

public enum VirtualMachineFactory {
    static func configuration(for bundle: MachineBundle) throws -> VZVirtualMachineConfiguration {
        let config = try bundle.loadConfig()
        let configuration = VZVirtualMachineConfiguration()
        configuration.cpuCount = ResourceLimits.cpuCount(config.resources.cpuCount)
        configuration.memorySize = ResourceLimits.memorySize(config.resources.memoryBytes)
        configuration.platform = try PlatformConfiguration.make(bundle: bundle)
        configuration.bootLoader = try BootLoaderConfiguration.make(bundle: bundle)
        configuration.graphicsDevices = [GraphicsConfiguration.make(display: config.display)]
        configuration.keyboards = [VZUSBKeyboardConfiguration()]
        configuration.pointingDevices = [VZUSBScreenCoordinatePointingDeviceConfiguration()]
        configuration.storageDevices = try StorageConfiguration.make(bundle: bundle, config: config)
        configuration.networkDevices = [try NetworkConfiguration.make(config: config)]
        configuration.audioDevices = [AudioConfiguration.make(input: config.audioInput)]
        configuration.entropyDevices = [VZVirtioEntropyDeviceConfiguration()]
        configuration.memoryBalloonDevices = [VZVirtioTraditionalMemoryBalloonDeviceConfiguration()]
        configuration.directorySharingDevices = try DirectorySharingConfiguration.make(config: config)
        configuration.serialPorts = try SerialPortConfiguration.make(logURL: bundle.consoleLogURL)
        configuration.consoleDevices = config.clipboardSharing ? [ClipboardConfiguration.make()] : []
        return configuration
    }

    public static func validatedConfiguration(for bundle: MachineBundle) throws -> VZVirtualMachineConfiguration {
        let configuration = try configuration(for: bundle)
        do {
            try configuration.validate()
        } catch {
            throw PetalError.invalidConfiguration(error.localizedDescription)
        }
        return configuration
    }

    public static func supportsSuspend(_ configuration: VZVirtualMachineConfiguration) -> Bool {
        (try? configuration.validateSaveRestoreSupport()) != nil
    }
}

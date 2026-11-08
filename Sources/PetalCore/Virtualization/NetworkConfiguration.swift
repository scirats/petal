import Virtualization

enum NetworkConfiguration {
    static func make(config: MachineConfig) throws -> VZVirtioNetworkDeviceConfiguration {
        guard let address = VZMACAddress(string: config.macAddress) else {
            throw PetalError.invalidConfiguration("“\(config.macAddress)” isn’t a valid MAC address.")
        }

        let network = VZVirtioNetworkDeviceConfiguration()
        network.attachment = VZNATNetworkDeviceAttachment()
        network.macAddress = address
        return network
    }
}

import Virtualization

enum ClipboardConfiguration {
    static func make() -> VZVirtioConsoleDeviceConfiguration {
        let console = VZVirtioConsoleDeviceConfiguration()
        let port = VZVirtioConsolePortConfiguration()
        port.name = VZSpiceAgentPortAttachment.spiceAgentPortName

        let agent = VZSpiceAgentPortAttachment()
        agent.sharesClipboard = true
        port.attachment = agent

        console.ports[0] = port
        return console
    }
}

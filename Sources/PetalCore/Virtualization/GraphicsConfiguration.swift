import Virtualization

enum GraphicsConfiguration {
    static func make(display: DisplaySpec) -> VZVirtioGraphicsDeviceConfiguration {
        let graphics = VZVirtioGraphicsDeviceConfiguration()
        graphics.scanouts = [
            VZVirtioGraphicsScanoutConfiguration(
                widthInPixels: display.width,
                heightInPixels: display.height
            ),
        ]
        return graphics
    }
}

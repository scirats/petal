import AppKit

func render(size: CGFloat) -> NSBitmapImageRep {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size),
        pixelsHigh: Int(size),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        exit(1)
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let inset = size * 0.1
    let tile = NSRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
    let background = drawBackground(in: tile)
    background.addClip()
    drawPetals(in: tile)
    drawCore(in: tile)

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func drawBackground(in tile: NSRect) -> NSBezierPath {
    let shape = NSBezierPath(roundedRect: tile, xRadius: tile.width * 0.225, yRadius: tile.width * 0.225)
    let gradient = NSGradient(colors: [
        NSColor(red: 0.16, green: 0.10, blue: 0.30, alpha: 1),
        NSColor(red: 0.38, green: 0.19, blue: 0.58, alpha: 1),
    ])
    gradient?.draw(in: shape, angle: 90)
    return shape
}

func drawPetals(in tile: NSRect) {
    let center = NSPoint(x: tile.midX, y: tile.midY)
    let petalWidth = tile.width * 0.32
    let petalHeight = tile.height * 0.34

    for index in 0..<6 {
        let petal = NSBezierPath(ovalIn: NSRect(
            x: -petalWidth / 2,
            y: tile.height * 0.10,
            width: petalWidth,
            height: petalHeight
        ))
        var transform = AffineTransform(translationByX: center.x, byY: center.y)
        transform.rotate(byDegrees: CGFloat(index) * 60)
        petal.transform(using: transform)
        let gradient = NSGradient(colors: [
            NSColor(red: 1.0, green: 0.61, blue: 0.72, alpha: 1),
            NSColor(red: 1.0, green: 0.82, blue: 0.60, alpha: 1),
        ])
        gradient?.draw(in: petal, angle: 90)
    }
}

func drawCore(in tile: NSRect) {
    let radius = tile.width * 0.115
    let core = NSBezierPath(ovalIn: NSRect(
        x: tile.midX - radius,
        y: tile.midY - radius,
        width: radius * 2,
        height: radius * 2
    ))
    let gradient = NSGradient(colors: [
        NSColor(red: 1.0, green: 0.90, blue: 0.51, alpha: 1),
        NSColor(red: 1.0, green: 0.72, blue: 0.22, alpha: 1),
    ])
    gradient?.draw(in: core, angle: 90)
}

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("Usage: make-icon <output.icns>\n".utf8))
    exit(64)
}

let output = URL(fileURLWithPath: CommandLine.arguments[1])
let iconset = FileManager.default.temporaryDirectory
    .appendingPathComponent("Petal-\(UUID().uuidString).iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
        guard let png = render(size: CGFloat(base * scale)).representation(using: .png, properties: [:]) else {
            exit(1)
        }
        try png.write(to: iconset.appendingPathComponent(name))
    }
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", output.path]
try iconutil.run()
iconutil.waitUntilExit()
try? FileManager.default.removeItem(at: iconset)
exit(iconutil.terminationStatus)

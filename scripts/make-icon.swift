// Draws the app icon (a white mug on a coffee-brown tile) into an .iconset folder.
// Usage: swift scripts/make-icon.swift build/AppIcon.iconset
import AppKit

let outDir = CommandLine.arguments[1]
try FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

let top = NSColor(srgbRed: 0.62, green: 0.40, blue: 0.24, alpha: 1)
let bottom = NSColor(srgbRed: 0.27, green: 0.15, blue: 0.09, alpha: 1)

for (points, scale) in [(16, 1), (16, 2), (32, 1), (32, 2), (128, 1), (128, 2), (256, 1), (256, 2), (512, 1), (512, 2)] {
    let pixels = points * scale
    let side = CGFloat(pixels)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    // Standard macOS icon grid: the tile fills ~80% of the canvas.
    let tile = NSRect(x: 0, y: 0, width: side, height: side).insetBy(dx: side * 0.1, dy: side * 0.1)
    let shape = NSBezierPath(roundedRect: tile, xRadius: tile.width * 0.225, yRadius: tile.width * 0.225)
    NSGradient(starting: top, ending: bottom)!.draw(in: shape, angle: -90)

    let config = NSImage.SymbolConfiguration(pointSize: side * 0.36, weight: .semibold)
        .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
    let mug = NSImage(systemSymbolName: "mug.fill", accessibilityDescription: nil)!
        .withSymbolConfiguration(config)!
    mug.draw(in: NSRect(
        x: (side - mug.size.width) / 2, y: (side - mug.size.height) / 2,
        width: mug.size.width, height: mug.size.height
    ))

    NSGraphicsContext.restoreGraphicsState()
    let name = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
    try rep.representation(using: .png, properties: [:])!
        .write(to: URL(fileURLWithPath: outDir).appendingPathComponent(name))
}

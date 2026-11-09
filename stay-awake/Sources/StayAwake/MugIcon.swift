import AppKit

/// The menu-bar glyph, drawn by hand so it needs no icon font: a full mug with
/// three wisps of steam when ON, an empty outline mug with no steam when OFF.
/// It is a template image, so macOS tints it for light and dark menu bars.
enum MugIcon {
    static let size = NSSize(width: 18, height: 18)

    static func image(steaming: Bool) -> NSImage {
        let image = NSImage(size: size, flipped: false) { _ in
            NSColor.black.set()
            if steaming {
                body().fill()
                steam().stroke()
            } else {
                let outline = body(inset: 0.65)
                outline.lineWidth = 1.3
                outline.stroke()
            }
            handle().stroke()
            return true
        }
        image.isTemplate = true
        return image
    }

    // Coordinates are in points on the 18x18 canvas, origin at bottom-left.
    // The mug sits in the same place in both states so only the steam changes.

    private static func body(inset d: CGFloat = 0) -> NSBezierPath {
        let left = 2.5 + d, right = 12 - d, top = 10.6 - d, bottom = 1 + d
        let path = NSBezierPath()
        path.move(to: NSPoint(x: left, y: top))
        path.line(to: NSPoint(x: right, y: top))
        path.appendArc(from: NSPoint(x: right, y: bottom), to: NSPoint(x: left, y: bottom), radius: 2.6 - d)
        path.appendArc(from: NSPoint(x: left, y: bottom), to: NSPoint(x: left, y: top), radius: 2.6 - d)
        path.close()
        path.lineJoinStyle = .round
        return path
    }

    private static func handle() -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 12, y: 8.5))
        path.appendArc(withCenter: NSPoint(x: 12.9, y: 6.2), radius: 2.3, startAngle: 90, endAngle: -90, clockwise: true)
        path.line(to: NSPoint(x: 12, y: 3.9))
        path.lineWidth = 1.4
        return path
    }

    private static func steam() -> NSBezierPath {
        let path = NSBezierPath()
        for x in [4.4, 7.25, 10.1] {
            path.move(to: NSPoint(x: x, y: 12.0))
            path.curve(
                to: NSPoint(x: x, y: 15.2),
                controlPoint1: NSPoint(x: x + 1.8, y: 13.05),
                controlPoint2: NSPoint(x: x - 1.8, y: 14.15)
            )
        }
        path.lineWidth = 1.2
        path.lineCapStyle = .round
        return path
    }
}

import AppKit
let output = CommandLine.arguments[1]
func render(_ size: Int, menu: Bool = false) -> Data {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let transform = NSAffineTransform()
    transform.scale(by: CGFloat(size) / 1024)
    transform.concat()
    if !menu {
        let plate = NSBezierPath(roundedRect: NSRect(x: 64, y: 64, width: 896, height: 896), xRadius: 200, yRadius: 200)
        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.20)
        shadow.shadowBlurRadius = 28
        shadow.shadowOffset = NSSize(width: 0, height: -12)
        shadow.set()
        NSColor(calibratedWhite: 0.97, alpha: 1).setFill()
        plate.fill()
        NSGraphicsContext.restoreGraphicsState()
        NSGradient(starting: NSColor.white, ending: NSColor(calibratedRed: 0.87, green: 0.92, blue: 0.98, alpha: 1))!.draw(in: plate, angle: -90)
        NSColor.white.withAlphaComponent(0.8).setStroke()
        plate.lineWidth = 3
        plate.stroke()
    }
    // An eye-shaped orbit around a node: watching remote machines at a glance.
    let ink = menu ? NSColor.black : NSColor(calibratedRed: 0.06, green: 0.38, blue: 0.89, alpha: 1)
    let orbit = NSBezierPath()
    orbit.move(to: NSPoint(x: 166, y: 512))
    orbit.curve(to: NSPoint(x: 858, y: 512), controlPoint1: NSPoint(x: 354, y: 796), controlPoint2: NSPoint(x: 670, y: 796))
    orbit.curve(to: NSPoint(x: 166, y: 512), controlPoint1: NSPoint(x: 670, y: 228), controlPoint2: NSPoint(x: 354, y: 228))
    orbit.close()
    orbit.lineWidth = menu ? 64 : 48
    orbit.lineJoinStyle = .round
    ink.setStroke()
    orbit.stroke()
    if !menu {
        ink.withAlphaComponent(0.09).setFill()
        NSBezierPath(ovalIn: NSRect(x: 356, y: 356, width: 312, height: 312)).fill()
    }
    let node = NSBezierPath(ovalIn: NSRect(x: 414, y: 414, width: 196, height: 196))
    ink.setFill()
    node.fill()
    if !menu {
        NSColor.white.withAlphaComponent(0.95).setFill()
        NSBezierPath(ovalIn: NSRect(x: 453, y: 516, width: 44, height: 44)).fill()
    }
    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])!
}
for size in [16,32,128,256,512] {
    try render(size).write(to: URL(fileURLWithPath: output + "/icon_\(size)x\(size).png"))
    try render(size*2).write(to: URL(fileURLWithPath: output + "/icon_\(size)x\(size)@2x.png"))
}
try render(36, menu: true).write(to: URL(fileURLWithPath: CommandLine.arguments[2]))

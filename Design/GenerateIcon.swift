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
        let bg = NSBezierPath(roundedRect: NSRect(x: 55, y: 55, width: 914, height: 914), xRadius: 210, yRadius: 210)
        NSGradient(starting: NSColor(calibratedRed: 0.10, green: 0.20, blue: 0.25, alpha: 1), ending: NSColor(calibratedRed: 0.025, green: 0.065, blue: 0.10, alpha: 1))!.draw(in: bg, angle: -75)
    }
    let mint = menu ? NSColor.black : NSColor(calibratedRed: 0.20, green: 0.91, blue: 0.75, alpha: 1)
    for row in 0..<3 {
        let y = CGFloat(235 + row * 195)
        let rect = NSRect(x: 205, y: y, width: 614, height: 150)
        mint.setStroke()
        let rack = NSBezierPath(roundedRect: rect, xRadius: 42, yRadius: 42)
        rack.lineWidth = menu ? 48 : 30
        rack.stroke()
        mint.setFill()
        NSBezierPath(ovalIn: NSRect(x: 258, y: y + 57, width: 36, height: 36)).fill()
        let line = NSBezierPath(roundedRect: NSRect(x: 600, y: y + 60, width: 140, height: 30), xRadius: 15, yRadius: 15)
        line.fill()
    }
    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])!
}
for size in [16,32,128,256,512] {
    try render(size).write(to: URL(fileURLWithPath: output + "/icon_\(size)x\(size).png"))
    try render(size*2).write(to: URL(fileURLWithPath: output + "/icon_\(size)x\(size)@2x.png"))
}
try render(36, menu: true).write(to: URL(fileURLWithPath: CommandLine.arguments[2]))

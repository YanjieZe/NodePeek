import SwiftUI
import AppKit
import Foundation
import ServiceManagement

let appLogo: NSImage = {
    guard let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"), let image = NSImage(contentsOf: url) else { return NSImage(systemSymbolName: "server.rack", accessibilityDescription: "NodePeek")! }
    return image
}()
let menuLogo: NSImage = {
    let image = Bundle.main.url(forResource: "MenuIcon", withExtension: "png").flatMap { NSImage(contentsOf: $0) } ?? NSImage(systemSymbolName: "server.rack", accessibilityDescription: "NodePeek")!
    image.size = NSSize(width: 18, height: 18)
    image.isTemplate = true
    image.accessibilityDescription = L("NodePeek 远程资源监控")
    return image
}()

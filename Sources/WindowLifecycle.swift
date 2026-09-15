import SwiftUI
import AppKit
import Foundation
import ServiceManagement

// Keep SwiftUI's window delegate intact; only replace the red button action.
struct HideOnClose: NSViewRepresentable {
    final class Hook: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let button = window?.standardWindowButton(.closeButton) else { return }
            button.target = self
            button.action = #selector(hideWindow(_:))
            button.toolTip = L("隐藏窗口，继续后台监控")
        }
        @objc func hideWindow(_ sender: Any?) {
            window?.orderOut(sender)
        }
    }
    func makeNSView(context: Context) -> Hook { Hook() }
    func updateNSView(_ nsView: Hook, context: Context) {}
}
func restoreMainWindow() {
    for window in NSApp.windows where window.identifier?.rawValue == "main" {
        if window.isMiniaturized { window.deminiaturize(nil) }
        window.makeKeyAndOrderFront(nil)
    }
}
final class AppLifecycle: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        restoreMainWindow()
        return true
    }
}

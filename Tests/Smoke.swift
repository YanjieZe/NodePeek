import SwiftUI
import AppKit
@main
struct Smoke {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        guard CommandLine.arguments.count >= 3 else { fatalError("Usage: Smoke OUTPUT_DIRECTORY SSH_ALIAS [SSH_ALIAS ...]") }
        let suite = "remotemeter-smoke-" + UUID().uuidString
        let prefs = UserDefaults(suiteName: suite)!
        prefs.set(Array(CommandLine.arguments.dropFirst(2)), forKey: "enabledHosts")
        let store = Store(defaults: prefs)
        // Run the actual Process/readability-handler pipeline, then render its real data.
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            let rows = store.monitors.map { host in ["host": host.id, "online": String(host.online), "status": host.status, "gpuCount": String(host.sample?.gpus.count ?? 0), "detail": host.detail] }
            if let data = try? JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted, .sortedKeys]) {
                try? data.write(to: URL(fileURLWithPath: CommandLine.arguments[1] + "/app-smoke.json"))
            }
            store.selected = store.monitors.first?.id ?? ""
            let view = NSHostingView(rootView: Panel(store: store).background(Color(nsColor: .windowBackgroundColor)).environment(\.colorScheme, .light))
            view.frame = NSRect(x: 0, y: 0, width: 390, height: 690)
            let window = NSWindow(contentRect: view.frame, styleMask: [.borderless], backing: .buffered, defer: false)
            window.contentView = view
            view.layoutSubtreeIfNeeded()
            if let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
                view.cacheDisplay(in: view.bounds, to: bitmap)
                try? bitmap.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: CommandLine.arguments[1] + "/panel-preview.png"))
            }
            store.monitors.forEach { $0.stop() }
            let passed = rows.count == CommandLine.arguments.count - 2 && rows.allSatisfy { $0["online"] == "true" }
            print(passed ? "PASS: all requested app SSH sessions delivered samples" : "FAIL: some sessions did not deliver samples")
            prefs.removePersistentDomain(forName: suite)
            exit(passed ? 0 : 1)
        }
        app.run()
    }
}

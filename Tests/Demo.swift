import SwiftUI
import AppKit
@main
struct Demo {
    static func render<V: View>(_ root: V, size: NSSize, dark: Bool = false, to url: URL) throws {
        let view = NSHostingView(rootView: root.environment(\.colorScheme, dark ? .dark : .light).background(Color(nsColor: .windowBackgroundColor)))
        view.frame = NSRect(origin: .zero, size: size)
        let window = NSWindow(contentRect: view.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        window.contentView = view
        view.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { fatalError("No bitmap") }
        view.cacheDisplay(in: view.bounds, to: bitmap)
        try bitmap.representation(using: .png, properties: [:])!.write(to: url)
    }
    static func main() throws {
        _ = NSApplication.shared
        NSApp.setActivationPolicy(.accessory)
        let output = URL(fileURLWithPath: CommandLine.arguments[1])
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        let config = temp.appendingPathComponent("config")
        try "Host training-cluster inference-box dev-workstation\n    HostName example.invalid\n".write(to: config, atomically: true, encoding: .utf8)
        let suite = "remotemeter-demo-" + UUID().uuidString
        let prefs = UserDefaults(suiteName: suite)!
        defer { prefs.removePersistentDomain(forName: suite); try? FileManager.default.removeItem(at: temp) }
        let store = Store(defaults: prefs, configPath: config.path, startMonitoring: false)
        store.configure(Set(store.hosts))
        for (index, host) in store.monitors.enumerated() {
            let gpuCount = [8, 2, 1][index]
            let gpus = (0..<gpuCount).map { gpu in GPU(index: String(gpu), name: ["NVIDIA H100", "NVIDIA L40S", "NVIDIA GeForce RTX 4090"][index], utilization: Double(96-index*24-gpu*3), used: Double(48_000-index*12_000+gpu*250), total: Double([81_920,49_152,24_576][index]), temperature: Double(58+gpu), power: Double(340-index*70)) }
            host.sample = Sample(cpu: Double(43-index*12), cores: [128,64,24][index], memoryUsed: Double([288,92,20][index]), memoryTotal: Double([1024,256,64][index]), gpus: gpus, gpuError: nil)
            host.online = true; host.status = L("已连接"); host.updated = Date(timeIntervalSince1970: 1788220800)
            host.history = (0..<60).map { Double(72 + (($0 * 7) % 24)) }
        }
        let language = Localization.language
        try render(DesktopView(store: store, previewToolbar: true), size: NSSize(width: 1100, height: 720), to: output.appendingPathComponent("overview-\(language).png"))
        store.overview = false
        try render(DesktopView(store: store, previewToolbar: true), size: NSSize(width: 1100, height: 720), to: output.appendingPathComponent("detail-\(language).png"))
        try render(DesktopView(store: store, previewToolbar: true), size: NSSize(width: 960, height: 640), dark: true, to: output.appendingPathComponent("detail-dark-\(language).png"))
        let failed = HostMonitor("example-server")
        failed.online = false; failed.status = L("离线 · {0} 秒后重试", 15)
        failed.issue = ConnectionIssue.classify("Permission denied (publickey).")
        try render(DiagnosticView(host: failed), size: NSSize(width: 555, height: 380), to: output.appendingPathComponent("diagnostics-\(language).png"))
        let fresh = Store(defaults: prefs, configPath: config.path, startMonitoring: false)
        fresh.monitors = []
        try render(SetupView(store: fresh), size: NSSize(width: 568, height: 530), to: output.appendingPathComponent("setup-\(language).png"))
        print("Rendered synthetic \(language) screenshots without SSH connections")
    }
}

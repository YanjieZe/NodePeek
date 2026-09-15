import SwiftUI
import AppKit
import Foundation
import ServiceManagement

final class Store: ObservableObject {
    @Published var hosts: [String] = []
    @Published var monitors: [HostMonitor] = []
    @Published var selected: String = ""
    @Published var showSetup = false
    @Published var overview = true
    @Published var diagnosticHost: HostMonitor?
    let defaults: UserDefaults
    let configPath: String
    @Published var showMenuBar = true {
        didSet { defaults.set(showMenuBar, forKey: "showMenuBar") }
    }
    @Published var showMenuMetrics = false {
        didSet { defaults.set(showMenuMetrics, forKey: "showMenuMetrics") }
    }
    @Published var paused = false
    @Published var launchAtLogin = SMAppService.mainApp.status == .enabled
    @Published var settingsError = ""
    private var timer: Timer?
    init(defaults: UserDefaults = .standard, configPath: String = NSHomeDirectory() + "/.ssh/config", startMonitoring: Bool = true) {
        self.defaults = defaults
        self.configPath = configPath
        selected = defaults.string(forKey: "selectedHost") ?? ""
        showMenuBar = defaults.object(forKey: "showMenuBar") as? Bool ?? true
        showMenuMetrics = defaults.bool(forKey: "showMenuMetrics")
        reload()
        let saved = defaults.stringArray(forKey: "enabledHosts")
        let initial = saved ?? []
        showSetup = saved == nil
        monitors = initial.filter { hosts.contains($0) }.map(HostMonitor.init)
        if !monitors.contains(where: { $0.id == selected }) { selected = monitors.first?.id ?? "" }
        guard startMonitoring else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.monitors.forEach { $0.tick() }
            self.objectWillChange.send()
        }
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            self?.monitors.forEach { $0.enabled = false; $0.stop(); $0.status = L("休眠中") }
        }
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            self.monitors.forEach { $0.enabled = !self.paused; $0.reconnect() }
        }
        NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in self?.monitors.forEach { $0.stop() } }
    }
    var current: HostMonitor? { monitors.first { $0.id == selected } }
    var title: String {
        if paused { return "RM ⏸" }
        guard let host = current else { return "NodePeek" }
        guard host.online, let s = host.sample else { return L("RM · 离线") }
        let short = host.id.count > 16 ? String(host.id.prefix(15)) + "…" : host.id
        let percent = s.gpus.compactMap(\.utilization).max()
        return "\(short)  \(percent == nil ? "CPU" : "GPU") \(Int(percent ?? s.cpu))%"
    }
    func reload() {
        var visited = Set<String>()
        var seen = Set<String>()
        hosts = aliases(at: configPath, visited: &visited).filter { seen.insert($0).inserted }
    }
    func configure(_ choices: Set<String>) {
        let retained = monitors.filter { choices.contains($0.id) && hosts.contains($0.id) }
        let retainedIDs = Set(retained.map(\.id))
        monitors.filter { !retainedIDs.contains($0.id) }.forEach { $0.stop() }
        let additions = hosts.filter { choices.contains($0) && !retainedIDs.contains($0) }.map { id in
            let monitor = HostMonitor(id); monitor.enabled = !paused; return monitor
        }
        monitors = retained + additions
        if !monitors.contains(where: { $0.id == selected }) { selected = monitors.first?.id ?? "" }
        defaults.set(monitors.map(\.id), forKey: "enabledHosts")
        defaults.set(selected, forKey: "selectedHost")
        showSetup = false
    }
    func toggle(_ host: String) {
        if let index = monitors.firstIndex(where: { $0.id == host }) { monitors[index].stop(); monitors.remove(at: index) }
        else { let monitor = HostMonitor(host); monitor.enabled = !paused; monitors.append(monitor) }
        if !monitors.contains(where: { $0.id == selected }) { selected = monitors.first?.id ?? "" }
        defaults.set(monitors.map(\.id), forKey: "enabledHosts")
        defaults.set(selected, forKey: "selectedHost")
    }
    func moveHosts(from source: IndexSet, to destination: Int) {
        monitors.move(fromOffsets: source, toOffset: destination)
        defaults.set(monitors.map(\.id), forKey: "enabledHosts")
    }
    func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
            else { try SMAppService.mainApp.register() }
            launchAtLogin = SMAppService.mainApp.status == .enabled
            settingsError = SMAppService.mainApp.status == .requiresApproval ? L("请在系统设置 → 通用 → 登录项中允许 NodePeek。") : ""
        } catch { settingsError = error.localizedDescription }
    }
    func pause() {
        paused.toggle()
        monitors.forEach { $0.enabled = !paused; if paused { $0.stop(); $0.status = L("已暂停") } else { $0.reconnect() } }
    }
}

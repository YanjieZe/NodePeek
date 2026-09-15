import AppKit
import SwiftUI
@main
struct CoreTests {
    static func main() throws {
        _ = NSApplication.shared
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let config = root.appendingPathComponent("config")
        try "Host alpha beta gamma delta\n  User tester\nHost *\n  ServerAliveInterval 20\nHost alpha\n  HostName localhost\n".write(to: config, atomically: true, encoding: .utf8)
        let suite = "remotemeter-tests-" + UUID().uuidString
        let prefs = UserDefaults(suiteName: suite)!
        defer { prefs.removePersistentDomain(forName: suite); try? FileManager.default.removeItem(at: root) }
        func store() -> Store { Store(defaults: prefs, configPath: config.path, startMonitoring: false) }
        let initial = store()
        precondition(initial.showSetup && initial.monitors.isEmpty, "First launch must not connect to any machine")
        precondition(initial.hosts == ["alpha", "beta", "gamma", "delta"], "Ignore patterns and deduplicate")
        initial.configure(Set(["alpha", "beta", "gamma", "delta", "unknown"]))
        precondition(!initial.showSetup && initial.monitors.count == 4)
        let lastSession = initial.monitors[3]
        initial.moveHosts(from: IndexSet(integer: 3), to: 0)
        precondition(initial.monitors.first === lastSession, "Reorder must preserve sessions")
        let reopened = store()
        precondition(!reopened.showSetup && reopened.monitors.map(\.id) == ["delta", "alpha", "beta", "gamma"])
        let retained = reopened.monitors[0]
        reopened.configure(Set(["delta", "beta"]))
        precondition(reopened.monitors.map(\.id) == ["delta", "beta"] && reopened.monitors[0] === retained)
        reopened.paused = true
        reopened.configure(Set(["delta", "beta", "gamma"]))
        precondition(reopened.monitors.last?.enabled == false)
        precondition(store().monitors.map(\.id) == ["delta", "beta", "gamma"])
        let missing = Store(defaults: prefs, configPath: root.appendingPathComponent("missing").path, startMonitoring: false)
        precondition(missing.hosts.isEmpty && missing.monitors.isEmpty)
        let coordinator = MachineList.Coordinator(reopened)
        let table = NSTableView()
        table.addTableColumn(NSTableColumn(identifier: .init("machine")))
        table.dataSource = coordinator; table.delegate = coordinator
        coordinator.refresh(table)
        let item = coordinator.tableView(table, pasteboardWriterForRow: 0) as! NSPasteboardItem
        precondition(item.string(forType: MachineList.Coordinator.dragType) == "delta")
        coordinator.dragging = true
        reopened.moveHosts(from: IndexSet(integer: 0), to: 3)
        coordinator.refresh(table)
        precondition(coordinator.rows.first?.id == "delta")
        coordinator.dragging = false
        coordinator.refresh(table)
        precondition(coordinator.rows.last?.id == "delta")
        let cases: [(String, String)] = [
            ("REMOTE HOST IDENTIFICATION HAS CHANGED! Host key verification failed.", "主机指纹发生变化"),
            ("Host key verification failed.", "主机身份尚未确认"),
            ("Permission denied (publickey).", "SSH 认证失败"),
            ("Access denied: no active jobs", "Slurm 节点访问受限"),
            ("Could not resolve hostname alpha", "主机名无法解析"),
            ("Connection refused", "SSH 端口拒绝连接"),
            ("Network is unreachable", "网络连接超时或不可达"),
            ("Connection timed out", "网络连接超时或不可达"),
            ("sh: python3: command not found", "远端缺少 Python 3"),
            ("FileNotFoundError: /proc/stat", "不支持的远端系统")
        ]
        for (raw, title) in cases { precondition(ConnectionIssue.classify(raw).title == L(title), raw) }
        precondition(shellQuote("a'b") == "'a'\\''b'")
        precondition(L("已选 {0} 台", 3) == (Localization.language == "en" ? "3 selected" : "已选 3 台"))
        precondition(!Localization.english.isEmpty)
        print("PASS: onboarding, config discovery, saved-order migration, session reuse, paused additions, missing config, native reorder and 10 diagnostic categories")
    }
}

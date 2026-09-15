import SwiftUI
import AppKit
import Foundation
import ServiceManagement

struct Panel: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject var store: Store
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(nsImage: appLogo).resizable().frame(width: 25, height: 25)
                Text("RemoteMeter").font(.system(size: 17, weight: .semibold))
                Spacer()
                Text("SSH MONITOR").font(.system(size: 9, weight: .medium, design: .monospaced)).foregroundStyle(.tertiary)
            }
            HStack {
                Picker(L("机器"), selection: $store.selected) {
                    if store.monitors.isEmpty { Text(L("未选择机器")).tag("") }
                    ForEach(store.monitors) { Text($0.id).tag($0.id) }
                }.labelsHidden().onChange(of: store.selected) { value in UserDefaults.standard.set(value, forKey: "selectedHost") }
                Menu {
                    ForEach(store.hosts, id: \.self) { host in
                        Button { store.toggle(host) } label: { if store.monitors.contains(where: { $0.id == host }) { Label(host, systemImage: "checkmark") } else { Text(host) } }
                    }
                    Divider()
                    Button(L("重新读取 SSH 配置")) { store.reload() }
                } label: { Image(systemName: "plus.circle") }.menuStyle(.borderlessButton).fixedSize().help(L("选择要监控的 SSH 机器"))
            }
            if !store.settingsError.isEmpty { Text(store.settingsError).font(.caption).foregroundStyle(.orange) }
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let host = store.current { HostDetail(host: host) }
                    else { Text(L("点击 +，从 SSH 配置中添加机器。")).foregroundStyle(.secondary).padding(.vertical, 30) }
                    if store.monitors.count > 1 {
                        Divider().padding(.vertical, 4)
                        Text(L("全部机器")).font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary)
                        ForEach(store.monitors) { host in
                            Button { store.selected = host.id } label: {
                                HStack { Circle().fill(host.online ? Color.mint : Color.orange).frame(width: 6, height: 6); Text(host.id).lineLimit(1); Spacer(); Text(host.online ? number(host.sample?.gpus.compactMap(\.utilization).max(), suffix: "% GPU") : host.status).foregroundStyle(.secondary).lineLimit(1) }.font(.system(size: 11)).padding(.vertical, 4).contentShape(Rectangle())
                            }.buttonStyle(.plain)
                        }
                    }
                }.padding(.trailing, 3)
            }.frame(maxHeight: 510)
            Divider()
            HStack {
                Text(L("每 5 秒更新")).font(.system(size: 10)).foregroundStyle(.secondary)
                Spacer()
                Button { store.current?.reconnect() } label: { Image(systemName: "arrow.clockwise") }.help(L("重新连接当前机器")).disabled(store.paused)
                Button { store.pause() } label: { Image(systemName: store.paused ? "play.fill" : "pause.fill") }.help(store.paused ? L("继续监控") : L("暂停全部监控"))
                Menu {
                    Toggle(L("菜单栏显示用量文字"), isOn: $store.showMenuMetrics)
                    Button(L("打开主窗口")) { openWindow(id: "main"); restoreMainWindow(); NSApp.activate(ignoringOtherApps: true) }
                    Button(store.launchAtLogin ? L("✓ 登录时启动") : L("登录时启动")) { store.toggleLogin() }
                    Button(L("在 Finder 中显示 SSH 配置")) { NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: NSHomeDirectory() + "/.ssh/config")]) }
                    Button(L("退出 RemoteMeter")) { NSApplication.shared.terminate(nil) }
                } label: { Image(systemName: "gearshape") }.menuStyle(.borderlessButton).fixedSize()
            }.buttonStyle(.borderless)
        }.padding(12).frame(width: 390)
    }
}

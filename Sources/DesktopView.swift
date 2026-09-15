import SwiftUI
import AppKit
import Foundation
import ServiceManagement

struct DesktopView: View {
    @ObservedObject var store: Store
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack { Image(nsImage: appLogo).resizable().frame(width: 30, height: 30); Text("NodePeek").font(.title2.bold()) }
                HStack { Text(L("远程机器")); Spacer(); Text(L("拖拽排序")).font(.caption2) }.font(.caption).foregroundStyle(.secondary)
                Button { store.overview = true } label: { Label(L("全部机器总览"), systemImage: "rectangle.grid.2x2").frame(maxWidth: .infinity, alignment: .leading) }.buttonStyle(.bordered)
                MachineList(store: store)

                Menu(L("管理监控机器")) {
                    Button(L("选择机器…")) { store.showSetup = true }
                    Divider()
                    ForEach(store.hosts, id: \.self) { host in
                        Button { store.toggle(host) } label: {
                            if store.monitors.contains(where: { $0.id == host }) { Label(host, systemImage: "checkmark") }
                            else { Text(host) }
                        }
                    }
                    Divider()
                    Button(L("重新读取 SSH 配置")) { store.reload() }
                }
                Toggle(L("显示菜单栏图标"), isOn: $store.showMenuBar).font(.caption)
                if store.showMenuBar {
                    Toggle(L("菜单栏显示用量文字"), isOn: $store.showMenuMetrics).font(.caption)
                }
                Text(L("使用本机 SSH 配置连接")).font(.caption2).foregroundStyle(.secondary)
            }.padding(12).frame(width: 230).background(Color(nsColor: .controlBackgroundColor))
            Divider()
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(store.overview ? L("全部机器总览") : (store.current?.id ?? L("添加一台远程机器"))).font(.title2.bold()).textSelection(.enabled)
                        Text(L("CPU、内存与 GPU 实时用量 · 每 5 秒更新")).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(store.paused ? L("继续") : L("暂停")) { store.pause() }
                    Button(L("连接诊断")) { store.diagnosticHost = store.current }.disabled(store.current == nil || store.overview)
                    Button(L("重新连接")) { if store.overview { store.monitors.forEach { $0.reconnect() } } else { store.current?.reconnect() } }.disabled(store.paused || store.monitors.isEmpty)
                }
                Divider()
                ScrollView {
                    if store.overview { OverviewView(store: store) }
                    else if let host = store.current { HostDetail(host: host).padding(.trailing, 8) }
                    else { Text(L("从左下角「管理监控机器」选择 SSH 别名。")).foregroundStyle(.secondary).padding(30) }
                }
                HStack {
                    Image(systemName: "menubar.rectangle")
                    Text(L("点击 × 隐藏窗口，后台监控继续；点击 Dock 图标恢复。"))
                    Spacer()
                }.font(.caption).foregroundStyle(.secondary)
            }.padding(16).frame(maxWidth: .infinity, maxHeight: .infinity)
        }.frame(minWidth: 960, minHeight: 580)
            .sheet(isPresented: $store.showSetup) { SetupView(store: store) }
            .sheet(item: $store.diagnosticHost) { host in DiagnosticView(host: host) }
    }
}

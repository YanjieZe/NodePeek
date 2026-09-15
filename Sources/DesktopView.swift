import SwiftUI
import AppKit

struct DesktopView: View {
    @ObservedObject var store: Store
    var previewToolbar = false
    private var title: String { store.overview ? L("全部机器总览") : (store.current?.id ?? L("添加一台远程机器")) }
    var body: some View {
        HSplitView {
            sidebar.frame(minWidth: 210, idealWidth: 230, maxWidth: 320)
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title).font(.system(size: 20, weight: .semibold)).textSelection(.enabled)
                        Text(L("CPU、内存与 GPU 实时用量 · 每 5 秒更新")).font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if previewToolbar { controls }
                }.padding(20)
                ScrollView {
                    Group {
                        if store.overview { OverviewView(store: store) }
                        else if let host = store.current { HostDetail(host: host) }
                        else {
                            VStack(spacing: 12) {
                                Image(systemName: "server.rack").font(.system(size: 32)).foregroundStyle(.secondary)
                                Text(L("选择 SSH 机器，开始监控")).font(.headline)
                                Button(L("选择机器")) { store.showSetup = true }
                            }.frame(maxWidth: .infinity).padding(40)
                        }
                    }.padding(.horizontal, 20).padding(.bottom, 20)
                }
                Divider()
                HStack(spacing: 6) {
                    Circle().fill(store.paused ? Color.orange : Color.green).frame(width: 5, height: 5)
                    Text(store.paused ? L("暂停") : L("{0} / {1} 台在线", store.monitors.filter(\.online).count, store.monitors.count))
                    Spacer()
                    Image(systemName: "menubar.rectangle").help(L("点击 × 隐藏窗口，后台监控继续；点击 Dock 图标恢复。"))
                }.font(.system(size: 10)).foregroundStyle(.secondary).padding(.horizontal, 20).padding(.vertical, 8)
            }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(nsColor: .textBackgroundColor))
        }
        .tint(.accentColor)
        .frame(minWidth: 960, minHeight: 580)
        .toolbar { ToolbarItemGroup(placement: .automatic) { controls } }
        .sheet(isPresented: $store.showSetup) { SetupView(store: store) }
        .sheet(item: $store.diagnosticHost) { host in DiagnosticView(host: host) }
    }
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(nsImage: appLogo).resizable().frame(width: 28, height: 28)
                Text("NodePeek").font(.system(size: 15, weight: .semibold))
            }.padding(.horizontal, 12).padding(.top, 16).padding(.bottom, 12)
            Button { store.overview = true } label: {
                Label(L("全部机器总览"), systemImage: "square.grid.2x2")
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 10).padding(.vertical, 8)
                    .foregroundStyle(store.overview ? Color.white : Color.primary)
                    .background(store.overview ? Color.accentColor : Color.clear, in: RoundedRectangle(cornerRadius: 6))
                    .contentShape(Rectangle())
            }.buttonStyle(.plain).padding(.horizontal, 8)
            HStack {
                Text(L("远程机器")).font(.system(size: 11, weight: .semibold))
                Spacer()
                Image(systemName: "line.3.horizontal").help(L("拖拽排序"))
            }.foregroundStyle(.secondary).padding(.horizontal, 18).padding(.top, 12)
            MachineList(store: store)
            Divider()
            HStack {
                Button { store.showSetup = true } label: { Label(L("选择机器…"), systemImage: "plus") }.buttonStyle(.borderless)
                Spacer()
                Menu {
                    Button(L("重新读取 SSH 配置")) { store.reload() }
                    Divider()
                    Toggle(L("显示菜单栏图标"), isOn: $store.showMenuBar)
                    Toggle(L("菜单栏显示用量文字"), isOn: $store.showMenuMetrics).disabled(!store.showMenuBar)
                } label: { Image(systemName: "gearshape") }.menuStyle(.borderlessButton).fixedSize().help(L("管理监控机器"))
            }.font(.system(size: 12)).padding(.horizontal, 14).padding(.bottom, 12).padding(.top, 4)
        }.background(SidebarMaterial())
    }
    private var controls: some View {
        HStack(spacing: 12) {
            Button { store.pause() } label: { Label(store.paused ? L("继续") : L("暂停"), systemImage: store.paused ? "play" : "pause") }
                .help(store.paused ? L("继续") : L("暂停"))
            Button { store.diagnosticHost = store.current } label: { Label(L("连接诊断"), systemImage: "stethoscope") }
                .disabled(store.current == nil || store.overview).help(L("连接诊断")).accessibilityLabel(L("连接诊断"))
            Button { if store.overview { store.monitors.forEach { $0.reconnect() } } else { store.current?.reconnect() } } label: { Label(L("重新连接"), systemImage: "arrow.clockwise") }
                .disabled(store.paused || store.monitors.isEmpty).help(L("重新连接")).accessibilityLabel(L("重新连接"))
        }.labelStyle(.iconOnly).buttonStyle(.borderless).controlSize(.regular)
    }
}

struct SidebarMaterial: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .followsWindowActiveState
        return view
    }
    func updateNSView(_ view: NSVisualEffectView, context: Context) {}
}

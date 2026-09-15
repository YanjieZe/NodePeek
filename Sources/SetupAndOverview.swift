import SwiftUI
import AppKit

struct SetupView: View {
    @ObservedObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var choices = Set<String>()
    @State private var search = ""
    var filtered: [String] { store.hosts.filter { search.isEmpty || $0.localizedCaseInsensitiveContains(search) } }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(store.monitors.isEmpty ? L("欢迎使用 NodePeek") : L("选择监控机器")).font(.title2.bold())
            Text(L("从本机 SSH 配置中选择 Linux 机器。仅连接选中的机器，复用现有密钥与跳板设置。")).font(.callout).foregroundStyle(.secondary)
            HStack {
                TextField(L("搜索 SSH 别名"), text: $search)
                Button(L("重新读取")) { store.reload(); choices.formIntersection(Set(store.hosts)) }
            }
            if store.hosts.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text(L("未找到可用 SSH 别名")).font(.headline)
                    Text(L("请先在 ~/.ssh/config 添加明确的 Host 别名，例如：")).font(.callout)
                    Text("Host training-server\n    HostName your-server.example.com\n    User your-user\n    IdentityFile ~/.ssh/id_ed25519").font(.system(size: 12, design: .default)).textSelection(.enabled)
                    Text(L("保存后点击「重新读取」。通配符 Host 不会作为机器列出。")).font(.caption).foregroundStyle(.secondary)
                }.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(filtered, id: \.self) { host in
                            Toggle(host, isOn: Binding(get: { choices.contains(host) }, set: { enabled in
                                if enabled { choices.insert(host) } else { choices.remove(host) }
                            })).font(.system(size: 12)).frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if filtered.isEmpty { Text(L("没有匹配的别名")).foregroundStyle(.secondary) }
                    }.padding(10)
                }.frame(height: 230)
            }
            Text(L("远端需要 Python 3；NVIDIA GPU 指标需要 nvidia-smi。首次使用请先在终端确认 SSH 能连接。")).font(.caption).foregroundStyle(.secondary)
            HStack {
                Text(L("已选 {0} 台", choices.count)).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button(L("取消")) { dismiss() }
                Button(L("开始监控")) { store.configure(choices); dismiss() }.buttonStyle(.borderedProminent).disabled(choices.isEmpty)
            }
        }.padding(24).frame(width: 520)
            .onAppear { choices = Set(store.monitors.map(\.id)) }
    }
}

struct OverviewView: View {
    @ObservedObject var store: Store
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 18) {
                Text(L("{0} / {1} 台在线", store.monitors.filter(\.online).count, store.monitors.count)).font(.headline)
                Text(L("{0} 张可见 GPU", store.monitors.filter(\.online).reduce(0) { $0 + ($1.sample?.gpus.count ?? 0) })).foregroundStyle(.secondary)
                Spacer()
            }
            HStack {
                Text(L("机器 / 状态")).frame(maxWidth: .infinity, alignment: .leading)
                Text("CPU").frame(width: 52, alignment: .trailing)
                Text(L("内存 GiB")).frame(width: 110, alignment: .trailing)
                Text(L("GPU 最高")).frame(width: 65, alignment: .trailing)
                Text(L("显存 GiB")).frame(width: 110, alignment: .trailing)
                Text(L("操作")).frame(width: 40)
            }.font(.system(size: 10)).foregroundStyle(.secondary).padding(.horizontal, 10)
            Divider()
            ForEach(store.monitors) { host in
                OverviewRow(store: store, host: host)
            }
            if store.monitors.isEmpty {
                VStack(spacing: 12) {
                    Text(L("选择 SSH 机器，开始监控")).font(.headline)
                    Button(L("选择机器")) { store.showSetup = true }.buttonStyle(.borderedProminent)
                }.frame(maxWidth: .infinity).padding(40)
            }
            Text(L("GPU 列显示该机最高利用率；显存为可见 GPU 合计。离线时不展示旧数值。")).font(.caption).foregroundStyle(.secondary)
        }
    }
}
private struct OverviewRow: View {
    @ObservedObject var store: Store
    @ObservedObject var host: HostMonitor
    var live: Sample? { host.online ? host.sample : nil }
    var memory: String { live.map { String(format: "%.0f / %.0f", $0.memoryUsed, $0.memoryTotal) } ?? "—" }
    var gpuMemory: String {
        guard let gpus = live?.gpus, !gpus.isEmpty, gpus.allSatisfy({ $0.used != nil && $0.total != nil }) else { return "—" }
        return String(format: "%.1f / %.1f", gpus.reduce(0) { $0 + $1.used! } / 1024, gpus.reduce(0) { $0 + $1.total! } / 1024)
    }
    var body: some View {
        HStack {
            Button { store.selected = host.id; store.overview = false } label: {
                VStack(alignment: .leading, spacing: 5) {
                    Text(host.id).font(.system(size: 12, weight: .semibold)).lineLimit(1).truncationMode(.middle)
                    HStack(spacing: 5) {
                        Circle().fill(host.online ? Color.green : Color.orange).frame(width: 5, height: 5)
                        Text(host.status).font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(1)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
            }.buttonStyle(.plain)
            Text(number(live?.cpu, suffix: "%")).frame(width: 52, alignment: .trailing)
            Text(memory).frame(width: 110, alignment: .trailing)
            Text(number(live?.gpus.compactMap(\.utilization).max(), suffix: "%")).frame(width: 65, alignment: .trailing)
            Text(gpuMemory).frame(width: 110, alignment: .trailing)
            Button { store.diagnosticHost = host } label: { Image(systemName: "stethoscope") }.frame(width: 40).help(L("连接诊断"))
        }.font(.system(size: 11, design: .default)).monospacedDigit().padding(10)
            .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 7))
    }
}

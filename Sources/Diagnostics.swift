import SwiftUI
import AppKit

struct ConnectionIssue: Equatable {
    let title: String
    let guidance: String
    static func classify(_ raw: String, code: Int32 = 255) -> ConnectionIssue {
        let text = raw.lowercased()
        if text.contains("remote host identification has changed") {
            return .init(title: L("主机指纹发生变化"), guidance: L("向管理员核实新指纹。确认是重装或更换机器后，再更新对应的 known_hosts 记录。应用不会自动忽略身份校验。"))
        }
        if text.contains("host key verification failed") {
            return .init(title: L("主机身份尚未确认"), guidance: L("在终端运行下面的 SSH 命令，核对主机指纹后完成首次连接。"))
        }
        if text.contains("permission denied") || text.contains("sign_and_send_pubkey") {
            return .init(title: L("SSH 认证失败"), guidance: L("检查 SSH 配置中的 User 和 IdentityFile。若密钥有口令，请在终端用 ssh-add 解锁密钥，再重新连接。应用使用非交互认证。"))
        }
        if text.contains("no active jobs") {
            return .init(title: L("Slurm 节点访问受限"), guidance: L("此节点要求你有正在运行的作业。先申请节点资源，或选择集群允许访问的登录节点。"))
        }
        if text.contains("could not resolve hostname") {
            return .init(title: L("主机名无法解析"), guidance: L("检查 SSH 别名和 HostName 拼写；若是内网域名，请先连接相应 VPN 或网络。"))
        }
        if text.contains("connection refused") {
            return .init(title: L("SSH 端口拒绝连接"), guidance: L("检查机器是否开机、SSH 服务是否运行，以及配置中的端口是否正确。"))
        }
        if text.contains("timed out") || text.contains("timeout") || text.contains("no route") || text.contains("network is unreachable") {
            return .init(title: L("网络连接超时或不可达"), guidance: L("确认机器在线，检查 VPN、跳板机、防火墙和 SSH 端口。应用会自动重试，也可以手动重新连接。"))
        }
        if text.contains("python3") && (text.contains("not found") || text.contains("no such file")) {
            return .init(title: L("远端缺少 Python 3"), guidance: L("请在远端安装 python3，并确保非交互 SSH 会话的 PATH 能找到它。不需要安装额外 Python 包。"))
        }
        if text.contains("/proc/") {
            return .init(title: L("不支持的远端系统"), guidance: L("当前 CPU 和内存采集需要 Linux 的 /proc 文件系统，请选择 Linux 机器。"))
        }
        return .init(title: L("SSH 或采集程序退出（{0}）", code), guidance: L("先在终端确认 SSH 可以连接，再检查远端 python3 和 nvidia-smi。下方保留本次错误输出供排查。"))
    }
}
func shellQuote(_ value: String) -> String { "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'" }

struct DiagnosticView: View {
    @ObservedObject var host: HostMonitor
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack { Text(L("连接诊断")).font(.title2.bold()); Spacer(); Button(L("完成")) { dismiss() } }
            Text(host.id).font(.headline).textSelection(.enabled)
            HStack {
                Circle().fill(host.online ? Color.mint : Color.orange).frame(width: 7, height: 7)
                Text(host.status)
                Spacer()
                Button(L("重新检查")) { host.reconnect() }.disabled(!host.enabled)
            }
            if !host.enabled { Text(L("当前监控已暂停，请先在主窗口继续监控。")).font(.caption).foregroundStyle(.secondary) }
            if host.online {
                Label(L("SSH、Python 3 与系统指标采集正常"), systemImage: "checkmark.circle.fill").foregroundStyle(.mint)
                if let message = host.sample?.gpuError {
                    Label(L("GPU 指标不可用"), systemImage: "exclamationmark.triangle").foregroundStyle(.orange)
                    Text(message).font(.callout).textSelection(.enabled)
                    Text(L("在远端运行 nvidia-smi 检查驱动。没有 NVIDIA GPU 的机器仍可监控 CPU 和内存。")).font(.callout).foregroundStyle(.secondary)
                } else { Text(L("已检测到 {0} 张 NVIDIA GPU。", host.sample?.gpus.count ?? 0)).font(.callout) }
            } else if let issue = host.issue {
                Text(issue.title).font(.headline).foregroundStyle(.orange)
                Text(issue.guidance).font(.callout).fixedSize(horizontal: false, vertical: true)
            } else {
                Text(host.detail.isEmpty ? L("正在等待连接结果。首次连接和跳板机认证可能需要几秒钟。") : host.detail).foregroundStyle(.secondary)
            }
            Divider()
            Text(L("终端检查命令")).font(.caption).foregroundStyle(.secondary)
            HStack {
                Text("ssh -- " + shellQuote(host.id)).font(.system(.callout, design: .monospaced)).textSelection(.enabled)
                Spacer()
                Button(copied ? L("已复制") : L("复制")) {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString("ssh -- " + shellQuote(host.id), forType: .string)
                    copied = true
                }
            }
            if !host.rawError.isEmpty {
                DisclosureGroup(L("本次错误输出（可能包含主机名或路径）")) {
                    ScrollView { Text(host.rawError).font(.system(size: 10, design: .monospaced)).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading) }.frame(maxHeight: 130)
                }
            }
        }.padding(22).frame(width: 510)
    }
}

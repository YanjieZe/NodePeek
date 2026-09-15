import SwiftUI
import AppKit
import Foundation
import ServiceManagement

struct Meter: View {
    let title: String
    let value: Double?
    let caption: String
    var color: Color = .mint
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack { Text(title).foregroundStyle(.secondary); Spacer(); Text(caption).monospacedDigit() }.font(.system(size: 12, weight: .medium))
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.07))
                    Capsule().fill(color).frame(width: proxy.size.width * min(1, max(0, (value ?? 0) / 100)))
                }
            }.frame(height: 5)
        }
    }
}
func number(_ value: Double?, suffix: String = "") -> String { value.map { String(format: "%.0f", $0) + suffix } ?? "—" }

struct HostDetail: View {
    @ObservedObject var host: HostMonitor
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Circle().fill(host.online ? Color.mint : Color.orange).frame(width: 6, height: 6)
                Text(host.status)
                Spacer()
                if let date = host.updated { Text(date, style: .time).foregroundStyle(.secondary) }
            }.font(.system(size: 11))
            if !host.detail.isEmpty {
                Text(host.detail).font(.system(size: 11)).foregroundStyle(.orange).textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
            }
            if let s = host.sample {
                if !host.online { Text(L("以下为上次采集数据")).font(.caption).foregroundStyle(.orange) }
                HStack(spacing: 8) {
                    summary(L("CPU · {0} 逻辑核", s.cores), value: number(s.cpu, suffix: "%"), percent: s.cpu, color: .mint)
                    summary(L("系统内存"), value: String(format: "%.1f / %.1f GiB", s.memoryUsed, s.memoryTotal), percent: s.memoryTotal > 0 ? s.memoryUsed / s.memoryTotal * 100 : 0, color: .cyan)
                }
                if !s.gpus.isEmpty {
                    Text(Array(Set(s.gpus.map { $0.name.replacingOccurrences(of: "NVIDIA ", with: "") })).sorted().joined(separator: " · ") + " · \(s.gpus.count) GPU")
                        .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                    VStack(spacing: 0) {
                        HStack(spacing: 6) {
                            Text("GPU").frame(width: 28, alignment: .leading)
                            Text(L("利用率")).frame(maxWidth: .infinity, alignment: .trailing)
                            Text(L("显存 GiB")).frame(width: 108, alignment: .trailing)
                            Text(L("温度")).frame(width: 38, alignment: .trailing)
                            Text(L("功耗")).frame(width: 44, alignment: .trailing)
                        }.font(.system(size: 10)).foregroundStyle(.secondary).padding(.horizontal, 8).padding(.vertical, 7)
                        Divider()
                        ForEach(s.gpus) { gpu in
                            HStack(spacing: 6) {
                                Text(gpu.index).foregroundStyle(.mint).frame(width: 28, alignment: .leading).help(gpu.name)
                                Text(number(gpu.utilization, suffix: "%"))
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .padding(.vertical, 4)
                                    .background(alignment: .leading) {
                                        GeometryReader { proxy in
                                            RoundedRectangle(cornerRadius: 3).fill(Color.mint.opacity(0.16))
                                                .frame(width: proxy.size.width * min(1, max(0, (gpu.utilization ?? 0) / 100)))
                                        }
                                    }
                                Text(gpu.used != nil && gpu.total != nil ? String(format: "%.1f / %.1f", gpu.used! / 1024, gpu.total! / 1024) : "—")
                                    .frame(width: 108, alignment: .trailing)
                                Text(number(gpu.temperature, suffix: "°")).frame(width: 38, alignment: .trailing)
                                Text(number(gpu.power, suffix: "W")).frame(width: 44, alignment: .trailing)
                            }.font(.system(size: 12, weight: .medium, design: .monospaced)).monospacedDigit()
                                .padding(.horizontal, 8).frame(height: 30)
                                .background((Int(gpu.index) ?? 0) % 2 == 0 ? Color.primary.opacity(0.025) : Color.clear)
                        }
                    }.background(Color.primary.opacity(0.025), in: RoundedRectangle(cornerRadius: 7))
                }
                if let error = s.gpuError { Text(error).font(.caption).foregroundStyle(.secondary) }
                if host.history.count > 1 {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(s.gpus.isEmpty ? L("最近 CPU 利用率") : L("最近最高 GPU 利用率")).font(.system(size: 10)).foregroundStyle(.secondary)
                        GeometryReader { proxy in
                            Path { path in
                                for (index, value) in host.history.enumerated() {
                                    let point = CGPoint(x: proxy.size.width * Double(index) / Double(max(1, host.history.count - 1)), y: proxy.size.height * (1 - value / 100))
                                    if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
                                }
                            }.stroke(Color.mint, style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
                        }.frame(height: 28)
                    }
                }
                Text(L("CPU / 内存为系统视角，可能包含同机其他任务。")).font(.system(size: 10)).foregroundStyle(.secondary)
            } else {
                Text(L("等待远程指标…")).font(.subheadline).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(.vertical, 20)
            }
        }
    }
    private func summary(_ title: String, value: String, percent: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 10)).foregroundStyle(.secondary)
            Text(value).font(.system(size: 13, weight: .semibold)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.85)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.07))
                    Capsule().fill(color).frame(width: proxy.size.width * min(1, max(0, percent / 100)))
                }
            }.frame(height: 3)
        }.padding(9).frame(maxWidth: .infinity, alignment: .leading).background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 7))
    }
}

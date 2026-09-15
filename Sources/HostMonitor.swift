import SwiftUI
import AppKit
import Foundation
import ServiceManagement

final class HostMonitor: ObservableObject, Identifiable {
    let id: String
    @Published var sample: Sample?
    @Published var updated: Date?
    @Published var status = L("等待连接")
    @Published var detail = ""
    @Published var issue: ConnectionIssue?
    @Published var rawError = ""
    @Published var online = false
    @Published var history: [Double] = []
    private var process: Process?
    private var inputPipe: Pipe?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    private var pending = Data()
    private var errors = Data()
    private var generation = UUID()
    private var started = Date.distantPast
    private var nextAttempt = Date.distantPast
    private var failures = 0
    var enabled = true
    init(_ host: String) { id = host }
    func tick() {
        guard enabled else { return }
        if process != nil {
            if Date().timeIntervalSince(max(updated ?? started, started)) > 25 {
                stop()
                status = L("连接超时 · 即将重试")
                detail = L("25 秒未收到指标，请检查网络、SSH 或远程 python3。")
                issue = .init(title: L("采集响应超时"), guidance: detail)
                nextAttempt = Date().addingTimeInterval(10)
            }
        } else if Date() >= nextAttempt { connect() }
    }
    func reconnect() {
        stop()
        failures = 0
        nextAttempt = .distantPast
        if enabled { connect() }
    }
    func stop() {
        generation = UUID()
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        errorPipe?.fileHandleForReading.readabilityHandler = nil
        if let process, process.isRunning { process.terminate() }
        process = nil
        inputPipe = nil
        outputPipe = nil
        errorPipe = nil
        online = false
    }
    private func connect() {
        guard let url = Bundle.main.url(forResource: "collector", withExtension: "py"), let source = try? String(contentsOf: url, encoding: .utf8) else {
            status = L("采集脚本缺失"); nextAttempt = .distantFuture; return
        }
        let token = UUID()
        generation = token
        pending = Data(); errors = Data()
        started = Date(); status = L("连接中…"); detail = ""; issue = nil; rawError = ""
        let p = Process(), out = Pipe(), err = Pipe(), input = Pipe()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
        let encoded = Data(source.utf8).base64EncodedString()
        let command = "python3 -u -c \"import base64;exec(base64.b64decode('\(encoded)'))\""
        p.arguments = ["-T", "-o", "BatchMode=yes", "-o", "StrictHostKeyChecking=yes", "-o", "ConnectTimeout=10", "-o", "ConnectionAttempts=1", "-o", "ServerAliveInterval=10", "-o", "ServerAliveCountMax=2", "-o", "ForwardAgent=no", "-o", "ForwardX11=no", id, command]
        p.standardOutput = out; p.standardError = err; p.standardInput = input
        process = p; outputPipe = out; errorPipe = err; inputPipe = input
        out.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { handle.readabilityHandler = nil; return }
            DispatchQueue.main.async { self?.receive(data, token: token) }
        }
        err.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { handle.readabilityHandler = nil; return }
            DispatchQueue.main.async {
                guard let self, self.generation == token else { return }
                self.errors.append(data)
                if self.errors.count > 8192 { self.errors = self.errors.suffix(8192) }
            }
        }
        p.terminationHandler = { [weak self] proc in
            DispatchQueue.main.async {
                guard let self, self.generation == token else { return }
                self.stop()
                self.failures += 1
                let delay = min(60, 5 * self.failures)
                self.status = L("离线 · {0} 秒后重试", delay)
                self.rawError = String(data: self.errors, encoding: .utf8) ?? ""
                self.issue = ConnectionIssue.classify(self.rawError, code: proc.terminationStatus)
                self.detail = self.issue!.title + "：" + self.issue!.guidance
                self.nextAttempt = Date().addingTimeInterval(Double(delay))
            }
        }
        do { try p.run(); try? input.fileHandleForWriting.close() }
        catch { stop(); status = L("SSH 启动失败"); detail = error.localizedDescription; nextAttempt = Date().addingTimeInterval(10) }
    }
    private func receive(_ data: Data, token: UUID) {
        guard generation == token else { return }
        pending.append(data)
        if pending.count > 1_048_576 { pending.removeAll(); return }
        while let newline = pending.firstIndex(of: 10) {
            let line = pending[..<newline]
            pending.removeSubrange(...newline)
            guard let value = try? JSONDecoder().decode(Sample.self, from: Data(line)) else { continue }
            sample = value; updated = Date(); online = true; issue = nil; rawError = ""; status = L("已连接"); detail = ""; failures = 0
            history.append(value.gpus.compactMap(\.utilization).max() ?? value.cpu)
            if history.count > 60 { history.removeFirst(history.count - 60) }
        }
    }

}

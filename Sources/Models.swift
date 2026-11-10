import SwiftUI
import AppKit
import Foundation
import ServiceManagement

struct GPU: Decodable, Identifiable {
    let index: String
    let name: String
    let utilization: Double?
    let used: Double?
    let total: Double?
    let temperature: Double?
    let power: Double?
    var procs: [GPUProc]? = nil
    var id: String { index }
}
// One process holding memory on a GPU. `command` is a short form that names the run; `full` is the whole command line.
struct GPUProc: Decodable, Identifiable {
    let pid: Int
    let user: String
    let used: Double?
    let command: String
    let full: String
    var id: Int { pid }
}
struct Sample: Decodable {
    let cpu: Double
    let cores: Int
    let memoryUsed: Double
    let memoryTotal: Double
    let gpus: [GPU]
    let gpuError: String?
}

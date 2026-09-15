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
    var id: String { index }
}
struct Sample: Decodable {
    let cpu: Double
    let cores: Int
    let memoryUsed: Double
    let memoryTotal: Double
    let gpus: [GPU]
    let gpuError: String?
}

import SwiftUI
import AppKit
import Foundation
import ServiceManagement

func aliases(at path: String, visited: inout Set<String>) -> [String] {
    let expanded = NSString(string: path).expandingTildeInPath
    guard visited.insert(expanded).inserted, let text = try? String(contentsOfFile: expanded, encoding: .utf8) else { return [] }
    var result: [String] = []
    for raw in text.components(separatedBy: .newlines) {
        let line = raw.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? ""
        let fields = line.replacingOccurrences(of: "=", with: " ").split(whereSeparator: { $0.isWhitespace }).map(String.init)
        guard let keyword = fields.first?.lowercased() else { continue }
        if keyword == "host" {
            result += fields.dropFirst().filter { value in
                !value.contains("*") && !value.contains("?") && !value.hasPrefix("!") && !value.hasPrefix("-")
            }
        } else if keyword == "include" {
            for pattern in fields.dropFirst() {
                var target = NSString(string: pattern.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))).expandingTildeInPath
                if !target.hasPrefix("/") { target = NSHomeDirectory() + "/.ssh/" + target }
                var paths = glob_t()
                if glob(target, 0, nil, &paths) == 0, let entries = paths.gl_pathv {
                    for index in 0..<Int(paths.gl_pathc) {
                        if let entry = entries[index] { result += aliases(at: String(cString: entry), visited: &visited) }
                    }
                }
                globfree(&paths)
            }
        }
    }
    return result
}

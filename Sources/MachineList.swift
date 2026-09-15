import SwiftUI
import AppKit
import Foundation
import ServiceManagement

final class MachineCell: NSTableCellView {
    private let nameLabel = NSTextField(labelWithString: "")
    private let statusLabel = NSTextField(labelWithString: "")
    private let metricsLabel = NSTextField(labelWithString: "")
    private let grip = NSTextField(labelWithString: "≡")
    var host: HostMonitor? {
        didSet {
            guard let host else { return }
            nameLabel.stringValue = host.id
            statusLabel.stringValue = "● " + host.status
            updateColors()
            if host.online, let sample = host.sample {
                metricsLabel.stringValue = "CPU " + number(sample.cpu, suffix: "%") + "   GPU " + number(sample.gpus.compactMap(\.utilization).max(), suffix: "%")
            } else { metricsLabel.stringValue = "" }
            setAccessibilityLabel(host.id + ", " + host.status)
        }
    }
    override var backgroundStyle: NSView.BackgroundStyle {
        didSet { updateColors() }
    }
    private func updateColors() {
        let selected = backgroundStyle == .emphasized
        statusLabel.textColor = selected ? .alternateSelectedControlTextColor : (host?.online == true ? .systemGreen : .systemOrange)
        metricsLabel.textColor = selected ? .alternateSelectedControlTextColor : .secondaryLabelColor
    }
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        nameLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        nameLabel.lineBreakMode = .byTruncatingMiddle
        statusLabel.font = .systemFont(ofSize: 10)
        metricsLabel.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        metricsLabel.textColor = .secondaryLabelColor
        grip.textColor = .tertiaryLabelColor
        for field in [nameLabel, statusLabel, metricsLabel, grip] {
            field.translatesAutoresizingMaskIntoConstraints = false
            addSubview(field)
        }
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: grip.leadingAnchor, constant: -4),
            grip.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            grip.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            grip.widthAnchor.constraint(equalToConstant: 12),
            statusLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            statusLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8),
            metricsLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            metricsLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 5),
            metricsLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8)
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}
struct MachineList: NSViewRepresentable {
    @ObservedObject var store: Store
    func makeCoordinator() -> Coordinator { Coordinator(store) }
    func makeNSView(context: Context) -> NSScrollView {
        let table = NSTableView()
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("machine"))
        column.resizingMask = .autoresizingMask
        table.addTableColumn(column)
        table.headerView = nil
        table.rowHeight = 64
        table.intercellSpacing = NSSize(width: 0, height: 4)
        table.style = .sourceList
        table.backgroundColor = .clear
        table.allowsMultipleSelection = false
        table.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        table.delegate = context.coordinator
        table.target = context.coordinator
        table.action = #selector(Coordinator.activateRow(_:))
        table.dataSource = context.coordinator
        table.registerForDraggedTypes([Coordinator.dragType])
        table.setDraggingSourceOperationMask(.move, forLocal: true)
        table.setDraggingSourceOperationMask([], forLocal: false)
        table.setAccessibilityLabel(L("远程机器，可拖拽排序"))
        let scroll = NSScrollView()
        scroll.documentView = table
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        context.coordinator.refresh(table)
        return scroll
    }
    func updateNSView(_ scroll: NSScrollView, context: Context) {
        context.coordinator.store = store
        guard let table = scroll.documentView as? NSTableView else { return }
        context.coordinator.refresh(table)
    }
    final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
        static let dragType = NSPasteboard.PasteboardType("local.remotemeter.machine-order")
        var store: Store
        var rows: [HostMonitor] = []
        var dragging = false
        var syncingSelection = false
        init(_ store: Store) { self.store = store }
        func refresh(_ table: NSTableView) {
            guard !dragging else { return }
            syncingSelection = true
            if rows.map(\.id) != store.monitors.map(\.id) {
                rows = store.monitors
                table.reloadData()
            } else {
                for index in rows.indices {
                    (table.view(atColumn: 0, row: index, makeIfNecessary: false) as? MachineCell)?.host = rows[index]
                }
            }
            if !store.overview, let index = rows.firstIndex(where: { $0.id == store.selected }) {
                table.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
            } else { table.deselectAll(nil) }
            syncingSelection = false
        }
        func numberOfRows(in tableView: NSTableView) -> Int { rows.count }
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            let id = NSUserInterfaceItemIdentifier("machine-cell")
            let cell = tableView.makeView(withIdentifier: id, owner: self) as? MachineCell ?? MachineCell()
            cell.identifier = id
            cell.host = rows[row]
            cell.setAccessibilityElement(true)
            cell.setAccessibilityLabel(rows[row].id + ", " + rows[row].status)
            return cell
        }
        @objc func activateRow(_ table: NSTableView) {
            guard !dragging, rows.indices.contains(table.clickedRow) else { return }
            store.selected = rows[table.clickedRow].id
            store.overview = false
            store.defaults.set(store.selected, forKey: "selectedHost")
        }
        func tableViewSelectionDidChange(_ notification: Notification) {
            guard !syncingSelection, !dragging, let table = notification.object as? NSTableView, rows.indices.contains(table.selectedRow) else { return }
            let host = rows[table.selectedRow].id
            store.selected = host
            store.overview = false
            store.defaults.set(host, forKey: "selectedHost")
        }
        func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
            guard rows.indices.contains(row) else { return nil }
            let item = NSPasteboardItem()
            item.setString(rows[row].id, forType: Self.dragType)
            return item
        }
        func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forRowIndexes rowIndexes: IndexSet) {
            dragging = true
        }
        func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation operation: NSTableView.DropOperation) -> NSDragOperation {
            guard let source = info.draggingSource as? NSTableView, source === tableView,
                  info.draggingPasteboard.string(forType: Self.dragType) != nil else { return [] }
            tableView.setDropRow(max(0, min(row, rows.count)), dropOperation: .above)
            return .move
        }
        func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
            guard let source = info.draggingSource as? NSTableView, source === tableView,
                  let id = info.draggingPasteboard.string(forType: Self.dragType),
                  let from = store.monitors.firstIndex(where: { $0.id == id }) else { return false }
            store.moveHosts(from: IndexSet(integer: from), to: max(0, min(row, store.monitors.count)))
            dragging = false
            refresh(tableView)
            return true
        }
        func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
            dragging = false
            refresh(tableView)
        }
    }
}

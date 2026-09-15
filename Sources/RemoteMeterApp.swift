import SwiftUI
import AppKit
import Foundation
import ServiceManagement

#if !SMOKE_TEST
@main
struct RemoteMeterApp: App {
    @NSApplicationDelegateAdaptor(AppLifecycle.self) private var lifecycle
    @StateObject private var store = Store()
    var body: some Scene {
        Window("RemoteMeter", id: "main") {
            DesktopView(store: store)
                .background(HideOnClose().frame(width: 0, height: 0))
                .onAppear { NSApp.activate(ignoringOtherApps: true) }
        }.defaultSize(width: 960, height: 720)
        MenuBarExtra(isInserted: Binding(get: { store.showMenuBar }, set: { value in if store.showMenuBar != value { store.showMenuBar = value } })) {
            Panel(store: store)
        } label: {
            Image(nsImage: menuLogo)
            if store.showMenuMetrics { Text(store.title) }
        }.menuBarExtraStyle(.window)
    }
}
#endif

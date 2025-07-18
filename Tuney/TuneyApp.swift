import SwiftUI
import AppKit
var globalProcess: Process?

@main
struct TuneyApp: App {
    init() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            globalProcess?.terminate()
        }
        
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

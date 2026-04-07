import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var tracker: ActivityTracker!
    private var statusBar: StatusBarController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        tracker  = ActivityTracker()
        statusBar = StatusBarController(tracker: tracker)
        tracker.start()
    }
}

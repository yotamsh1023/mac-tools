import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: ClockController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        controller = ClockController()
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller.stop()
    }
}

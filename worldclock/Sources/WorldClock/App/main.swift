import AppKit

let bundleID = Bundle.main.bundleIdentifier ?? "com.yotamsh.worldclock"
let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
if running.count > 1 {
    running.first?.activate(options: .activateIgnoringOtherApps)
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

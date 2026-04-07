import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var clipStore: ClipStore!
    private var clipboardMonitor: ClipboardMonitor!
    private var hotKeyManager: HotKeyManager!
    private var statusBarController: StatusBarController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        clipStore = ClipStore()
        clipboardMonitor = ClipboardMonitor()
        hotKeyManager = HotKeyManager()
        statusBarController = StatusBarController(clipStore: clipStore)

        clipboardMonitor.onNewClip = { [weak self] item in
            self?.clipStore.save(item)
            self?.statusBarController.refresh()
        }

        NotificationCenter.default.addObserver(
            forName: .clipboardDidWrite,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clipboardMonitor.syncChangeCount()
        }

        hotKeyManager.onTrigger = { [weak self] in
            self?.statusBarController.togglePopover()
        }

        clipboardMonitor.start()
        hotKeyManager.register()
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor.stop()
        hotKeyManager.unregister()
    }
}

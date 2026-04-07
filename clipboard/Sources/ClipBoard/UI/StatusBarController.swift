import AppKit
import SwiftUI

final class StatusBarController {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private let clipStore: ClipStore

    init(clipStore: ClipStore) {
        self.clipStore = clipStore

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 520)
        popover.behavior = .transient
        popover.animates = true

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "ClipBoard")
            button.action = #selector(handleClick)
            button.target = self
        }

        let rootView = PopoverView(store: clipStore)
        popover.contentViewController = NSHostingController(rootView: rootView)
    }

    func refresh() {
        // The store is @Published, so SwiftUI views update automatically.
        // This method exists for explicit refresh calls if needed.
    }

    @objc func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    @objc private func handleClick() {
        togglePopover()
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
    }
}

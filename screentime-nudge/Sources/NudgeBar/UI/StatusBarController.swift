import AppKit
import Combine

final class StatusBarController {
    private var statusItem: NSStatusItem
    private let tracker: ActivityTracker
    private let nudge = NudgeWindow()
    private var cancellables = Set<AnyCancellable>()

    init(tracker: ActivityTracker) {
        self.tracker = tracker
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)

        tracker.$elapsedSeconds
            .receive(on: RunLoop.main)
            .sink { [weak self] secs in self?.updateDisplay(secs: secs) }
            .store(in: &cancellables)

        tracker.$isActive
            .receive(on: RunLoop.main)
            .sink { [weak self] active in self?.updateDisplay(secs: self?.tracker.elapsedSeconds ?? 0, active: active) }
            .store(in: &cancellables)

        tracker.onHourElapsed = { [weak self] hour in
            self?.nudge.show(hour: hour)
        }

        buildMenu()
    }

    // MARK: - Display

    private func updateDisplay(secs: Int, active: Bool? = nil) {
        let isActive = active ?? tracker.isActive
        let formatted = formatTime(secs)
        statusItem.button?.title = isActive ? formatted : "⏸ \(formatted)"
        statusItem.button?.alphaValue = isActive ? 1.0 : 0.5
    }

    private func formatTime(_ secs: Int) -> String {
        let h = secs / 3600
        let m = (secs % 3600) / 60
        let s = secs % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%d:%02d", m, s)
        }
    }

    // MARK: - Menu

    private func buildMenu() {
        let menu = NSMenu()

        let header = NSMenuItem(title: "זמן פעיל בסשן", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        let reset = NSMenuItem(title: "אפס סשן", action: #selector(resetSession), keyEquivalent: "r")
        reset.target = self
        menu.addItem(reset)
        menu.addItem(.separator())

        let quit = NSMenuItem(title: "סגור NudgeBar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)

        statusItem.menu = menu
    }

    @objc private func resetSession() {
        tracker.reset()
        nudge.dismiss()
    }
}

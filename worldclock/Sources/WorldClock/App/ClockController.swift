import AppKit

final class ClockController {
    private var statusItem: NSStatusItem
    private var timer: Timer?
    private var selectedTimezone: TimeZone
    private var showLabel: Bool

    // Saved keys
    private let tzKey    = "selectedTimezone"
    private let lblKey   = "showLabel"
    private let fmtKey   = "use24h"
    private var use24h: Bool

    init() {
        let savedID = UserDefaults.standard.string(forKey: "selectedTimezone") ?? "America/New_York"
        selectedTimezone = TimeZone(identifier: savedID) ?? TimeZone(identifier: "America/New_York")!
        showLabel = UserDefaults.standard.object(forKey: "showLabel") as? Bool ?? true
        use24h    = UserDefaults.standard.object(forKey: "use24h")    as? Bool ?? false

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)

        buildMenu()
        tick()
        startTimer()
    }

    func stop() { timer?.invalidate() }

    // MARK: - Tick

    private func startTimer() {
        // Fire on the next whole minute, then every 60s
        let now = Date()
        let cal = Calendar.current
        let next = cal.nextDate(after: now, matching: DateComponents(second: 0), matchingPolicy: .nextTime)!
        let delay = next.timeIntervalSinceNow

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.tick()
            self?.timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
                self?.tick()
            }
        }
    }

    private func tick() {
        let fmt = DateFormatter()
        fmt.timeZone = selectedTimezone
        fmt.dateFormat = use24h ? "HH:mm" : "h:mm a"

        let timeStr = fmt.string(from: Date())

        if showLabel {
            let abbr = selectedTimezone.abbreviation() ?? selectedTimezone.identifier
            statusItem.button?.title = "\(abbr) \(timeStr)"
        } else {
            statusItem.button?.title = timeStr
        }
    }

    // MARK: - Menu

    private func buildMenu() {
        let menu = NSMenu()

        // ── Current time header ──────────────────────────────
        let headerItem = NSMenuItem(title: currentTimeString(), action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        menu.addItem(.separator())

        // ── Format ───────────────────────────────────────────
        let fmt24 = NSMenuItem(title: "24-hour format", action: #selector(toggle24h), keyEquivalent: "")
        fmt24.target = self
        fmt24.state = use24h ? .on : .off
        menu.addItem(fmt24)

        let lblItem = NSMenuItem(title: "Show timezone label", action: #selector(toggleLabel), keyEquivalent: "")
        lblItem.target = self
        lblItem.state = showLabel ? .on : .off
        menu.addItem(lblItem)
        menu.addItem(.separator())

        // ── Popular timezones ─────────────────────────────────
        let zones: [(String, String)] = [
            ("New York",  "America/New_York"),
            ("London",    "Europe/London"),
            ("Paris",     "Europe/Paris"),
            ("Tokyo",     "Asia/Tokyo"),
            ("Tel Aviv",  "Asia/Jerusalem"),
            ("Dubai",     "Asia/Dubai"),
            ("Sydney",    "Australia/Sydney"),
            ("Los Angeles","America/Los_Angeles"),
            ("Chicago",   "America/Chicago"),
            ("São Paulo", "America/Sao_Paulo"),
            ("Singapore", "Asia/Singapore"),
            ("Beijing",   "Asia/Shanghai"),
        ]

        let tzSubMenu = NSMenu()
        for (name, id) in zones {
            let item = NSMenuItem(title: localLabel(name: name, id: id),
                                  action: #selector(selectTimezone(_:)),
                                  keyEquivalent: "")
            item.representedObject = id
            item.target = self
            item.state = (id == selectedTimezone.identifier) ? .on : .off
            tzSubMenu.addItem(item)
        }

        let tzItem = NSMenuItem(title: "Timezone", action: nil, keyEquivalent: "")
        tzItem.submenu = tzSubMenu
        menu.addItem(tzItem)
        menu.addItem(.separator())

        // ── Quit ─────────────────────────────────────────────
        let quit = NSMenuItem(title: "Quit WorldClock", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)

        statusItem.menu = menu
    }

    private func currentTimeString() -> String {
        let fmt = DateFormatter()
        fmt.timeZone = selectedTimezone
        fmt.dateFormat = use24h ? "HH:mm" : "h:mm a"
        let name = selectedTimezone.localizedName(for: .standard, locale: .current)
                   ?? selectedTimezone.identifier
        return "\(name)  •  \(fmt.string(from: Date()))"
    }

    private func localLabel(name: String, id: String) -> String {
        guard let tz = TimeZone(identifier: id) else { return name }
        let offset = tz.secondsFromGMT() / 3600
        let sign = offset >= 0 ? "+" : ""
        return "\(name)  (GMT\(sign)\(offset))"
    }

    // MARK: - Actions

    @objc private func selectTimezone(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String,
              let tz = TimeZone(identifier: id) else { return }
        selectedTimezone = tz
        UserDefaults.standard.set(id, forKey: tzKey)
        tick()
        buildMenu()
    }

    @objc private func toggle24h() {
        use24h.toggle()
        UserDefaults.standard.set(use24h, forKey: fmtKey)
        tick()
        buildMenu()
    }

    @objc private func toggleLabel() {
        showLabel.toggle()
        UserDefaults.standard.set(showLabel, forKey: lblKey)
        tick()
        buildMenu()
    }
}

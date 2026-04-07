import AppKit

final class NudgeWindow {
    private var panel: NSPanel?
    private var dismissTimer: Timer?

    func show(hour: Int) {
        dismiss()  // close any previous

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 160),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.standardWindowButton(.closeButton)?.isHidden     = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden      = true
        panel.backgroundColor = NSColor(calibratedWhite: 0.15, alpha: 0.97)
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true

        let content = buildContent()
        panel.contentView = content

        // Center on screen
        if let screen = NSScreen.main {
            let sx = screen.visibleFrame.midX - 210
            let sy = screen.visibleFrame.midY - 80
            panel.setFrameOrigin(NSPoint(x: sx, y: sy))
        }

        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.panel = panel

        // Click anywhere on panel to dismiss
        let click = NSClickGestureRecognizer(target: self, action: #selector(dismiss))
        content.addGestureRecognizer(click)

        // Auto-dismiss after 12 seconds
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 12, repeats: false) { [weak self] _ in
            self?.dismiss()
        }
    }

    @objc func dismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        panel?.orderOut(nil)
        panel = nil
    }

    private func buildContent() -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.cornerRadius = 12
        view.layer?.masksToBounds = true

        // Funny message
        let funnyLabel = NSTextField(wrappingLabelWithString: Messages.randomFunny())
        funnyLabel.textColor     = .white
        funnyLabel.font          = .systemFont(ofSize: 15, weight: .medium)
        funnyLabel.alignment     = .center
        funnyLabel.backgroundColor = .clear
        funnyLabel.isBezeled     = false

        // Stretch tip
        let stretchLabel = NSTextField(wrappingLabelWithString: "💪  " + Messages.randomStretch())
        stretchLabel.textColor    = NSColor(calibratedRed: 0.6, green: 0.9, blue: 0.6, alpha: 1)
        stretchLabel.font         = .systemFont(ofSize: 13, weight: .regular)
        stretchLabel.alignment    = .center
        stretchLabel.backgroundColor = .clear
        stretchLabel.isBezeled    = false

        // Dismiss hint
        let hintLabel = NSTextField(labelWithString: "לחץ בכל מקום לסגירה")
        hintLabel.textColor  = NSColor(calibratedWhite: 0.5, alpha: 1)
        hintLabel.font       = .systemFont(ofSize: 11)
        hintLabel.alignment  = .center

        for sub in [funnyLabel, stretchLabel, hintLabel] {
            sub.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(sub)
        }

        NSLayoutConstraint.activate([
            funnyLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 22),
            funnyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            funnyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            stretchLabel.topAnchor.constraint(equalTo: funnyLabel.bottomAnchor, constant: 12),
            stretchLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stretchLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            hintLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
            hintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])

        return view
    }
}

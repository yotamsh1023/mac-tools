import AppKit
import WebKit

final class StatusBarController: NSObject {
    private var statusItem: NSStatusItem
    private var panel: NSPanel?
    private var webView: WKWebView?
    private var globalMonitor: Any?

    // Remember last used language pair across toggles
    private var lastURL = "https://translate.google.com/?sl=auto&tl=he&op=translate"

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "Translate")
            button.action = #selector(toggle)
            button.target = self
        }
    }

    @objc func toggle() {
        if let panel, panel.isVisible {
            close()
        } else {
            open()
        }
    }

    private func open() {
        if panel == nil { buildPanel() }

        guard let panel, let button = statusItem.button,
              let buttonWindow = button.window else { return }

        let btnRect = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        let w: CGFloat = 560
        let h: CGFloat = 380
        let x = max(0, btnRect.midX - w / 2)
        let y = btnRect.minY - h - 4

        panel.setFrame(NSRect(x: x, y: y, width: w, height: h), display: false)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        startGlobalMonitor()
    }

    private func close() {
        // Save current URL so language pair is remembered next time
        if let url = webView?.url?.absoluteString, url.contains("translate.google") {
            lastURL = url
        }
        panel?.orderOut(nil)
        stopGlobalMonitor()
    }

    private func buildPanel() {
        let p = NSPanel(
            contentRect: .zero,
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        p.level = .floating
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = true
        p.titlebarAppearsTransparent = true
        p.titleVisibility = .hidden
        p.standardWindowButton(.closeButton)?.isHidden = true
        p.standardWindowButton(.miniaturizeButton)?.isHidden = true
        p.standardWindowButton(.zoomButton)?.isHidden = true
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        config.mediaTypesRequiringUserActionForPlayback = []

        let wv = KeyableWebView(frame: .zero, configuration: config)
        wv.wantsLayer = true
        wv.layer?.cornerRadius = 14
        wv.layer?.masksToBounds = true
        wv.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

        let container = ContainerView(webView: wv, radius: 14)
        p.contentView = container

        wv.load(URLRequest(url: URL(string: lastURL)!))

        panel   = p
        webView = wv
    }

    // MARK: - Click outside to close

    private func startGlobalMonitor() {
        stopGlobalMonitor()
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, let panel = self.panel, panel.isVisible else { return }
            let loc = event.locationInWindow
            let screenLoc = event.window?.convertToScreen(NSRect(origin: loc, size: .zero)).origin ?? loc
            if !panel.frame.contains(screenLoc) {
                DispatchQueue.main.async { self.close() }
            }
        }
    }

    private func stopGlobalMonitor() {
        if let m = globalMonitor { NSEvent.removeMonitor(m); globalMonitor = nil }
    }
}

// WKWebView subclass that properly forwards Cmd+A/C/V/X/Z to the page
final class KeyableWebView: WKWebView {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.modifierFlags.contains(.command) else { return super.performKeyEquivalent(with: event) }
        switch event.characters {
        case "a": NSApp.sendAction(#selector(NSText.selectAll(_:)),  to: nil, from: self); return true
        case "c": NSApp.sendAction(#selector(NSText.copy(_:)),       to: nil, from: self); return true
        case "v": NSApp.sendAction(#selector(NSText.paste(_:)),      to: nil, from: self); return true
        case "x": NSApp.sendAction(#selector(NSText.cut(_:)),        to: nil, from: self); return true
        case "z": NSApp.sendAction(#selector(NSText.delete(_:)),     to: nil, from: self); return true
        default:  return super.performKeyEquivalent(with: event)
        }
    }
}

final class ContainerView: NSView {
    init(webView: WKWebView, radius: CGFloat) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = radius
        layer?.masksToBounds = true
        webView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}

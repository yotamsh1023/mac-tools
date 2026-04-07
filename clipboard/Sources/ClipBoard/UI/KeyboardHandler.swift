import SwiftUI
import AppKit

struct KeyboardHandler: NSViewRepresentable {
    let onUp: () -> Void
    let onDown: () -> Void
    let onActivate: () -> Void   // Enter or Ctrl+C
    let onEdit: () -> Void       // E key

    func makeNSView(context: Context) -> KeyView {
        let view = KeyView()
        view.onUp = onUp
        view.onDown = onDown
        view.onActivate = onActivate
        view.onEdit = onEdit
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ view: KeyView, context: Context) {
        view.onUp = onUp
        view.onDown = onDown
        view.onActivate = onActivate
        view.onEdit = onEdit
    }
}

final class KeyView: NSView {
    var onUp: (() -> Void)?
    var onDown: (() -> Void)?
    var onActivate: (() -> Void)?
    var onEdit: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 125: onDown?()          // Arrow Down
        case 126: onUp?()            // Arrow Up
        case 36, 76: onActivate?()   // Return / numpad Enter
        case 14:                     // E key
            if !event.modifierFlags.contains(.command) &&
               !event.modifierFlags.contains(.option) {
                onEdit?()
            } else {
                super.keyDown(with: event)
            }
        default:
            if event.modifierFlags.contains(.control),
               event.characters?.lowercased() == "c" {
                onActivate?()
            } else {
                super.keyDown(with: event)
            }
        }
    }
}

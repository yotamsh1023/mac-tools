import Carbon.HIToolbox
import AppKit

final class HotKeyManager {
    var onTrigger: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    // Default: Cmd+Shift+T
    func register(keyCode: UInt32 = 17,
                  modifiers: UInt32 = UInt32(cmdKey | shiftKey)) {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, _, userData) -> OSStatus in
                guard let userData else { return OSStatus(eventNotHandledErr) }
                let mgr = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async { mgr.onTrigger?() }
                return noErr
            },
            1, &eventType, selfPtr, &eventHandler
        )
        let hotKeyID = EventHotKeyID(signature: fourCharCode("TBAR"), id: 1)
        RegisterEventHotKey(keyCode, modifiers, hotKeyID,
                            GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func unregister() {
        if let ref = hotKeyRef   { UnregisterEventHotKey(ref); hotKeyRef    = nil }
        if let h   = eventHandler { RemoveEventHandler(h);     eventHandler = nil }
    }

    private func fourCharCode(_ s: String) -> FourCharCode {
        s.utf8.prefix(4).reduce(0) { $0 << 8 + FourCharCode($1) }
    }
}

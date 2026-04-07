import AppKit
import CoreGraphics
import Combine

final class ActivityTracker: ObservableObject {
    @Published private(set) var elapsedSeconds: Int = 0
    @Published private(set) var isActive: Bool = true

    var onHourElapsed: ((Int) -> Void)?   // called with hour number (1, 2, 3…)

    private let idleThreshold: TimeInterval = 5 * 60  // 5 minutes
    private var mainTimer: Timer?
    private var idleTimer: Timer?
    private var lastHourNudge: Int = 0

    // Pause reasons — we track all of them so resume only happens when ALL are clear
    private var pausedByIdle    = false
    private var pausedByLock    = false
    private var pausedBySleep   = false

    // MARK: - Start

    func start() {
        setupNotifications()
        startMainTimer()
        startIdleTimer()
    }

    func reset() {
        elapsedSeconds = 0
        lastHourNudge  = 0
    }

    // MARK: - Timers

    private func startMainTimer() {
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(t, forMode: .common)
        mainTimer = t
    }

    private func startIdleTimer() {
        let t = Timer(timeInterval: 5, repeats: true) { [weak self] _ in
            self?.checkIdle()
        }
        RunLoop.main.add(t, forMode: .common)
        idleTimer = t
    }

    private func tick() {
        guard isActive else { return }
        elapsedSeconds += 1

        // Fire nudge on each full hour
        let hour = elapsedSeconds / 3600
        if hour > lastHourNudge && elapsedSeconds % 3600 == 0 {
            lastHourNudge = hour
            onHourElapsed?(hour)
        }
    }

    private func checkIdle() {
        let idle = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: CGEventType(rawValue: UInt32.max)!
        )
        if idle > idleThreshold {
            pausedByIdle = true
        } else {
            pausedByIdle = false
        }
        updateActiveState()
    }

    private func updateActiveState() {
        let shouldPause = pausedByIdle || pausedByLock || pausedBySleep
        isActive = !shouldPause
    }

    // MARK: - Notifications

    private func setupNotifications() {
        let dnc = DistributedNotificationCenter.default()
        dnc.addObserver(forName: .init("com.apple.screenIsLocked"),   object: nil, queue: .main) { [weak self] _ in
            self?.pausedByLock = true;  self?.updateActiveState()
        }
        dnc.addObserver(forName: .init("com.apple.screenIsUnlocked"), object: nil, queue: .main) { [weak self] _ in
            self?.pausedByLock = false; self?.updateActiveState()
        }

        let ws = NSWorkspace.shared.notificationCenter
        ws.addObserver(forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: .main) { [weak self] _ in
            self?.pausedBySleep = true;  self?.updateActiveState()
        }
        ws.addObserver(forName: NSWorkspace.screensDidWakeNotification,  object: nil, queue: .main) { [weak self] _ in
            self?.pausedBySleep = false; self?.updateActiveState()
        }
        ws.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            self?.pausedBySleep = true;  self?.updateActiveState()
        }
        ws.addObserver(forName: NSWorkspace.didWakeNotification,   object: nil, queue: .main) { [weak self] _ in
            self?.pausedBySleep = false; self?.updateActiveState()
        }
    }
}

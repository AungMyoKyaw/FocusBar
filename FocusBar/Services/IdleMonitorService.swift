import Foundation
import CoreGraphics

final class IdleMonitorService {
    var onReturnFromIdle: ((Int) -> Void)?

    private var timer: Timer?
    private var wasIdleBeyondThreshold = false
    private var maxObservedIdleSeconds: TimeInterval = 0

    func startMonitoring(thresholdMinutes: Int) {
        stopMonitoring()
        let thresholdSeconds = TimeInterval(max(1, thresholdMinutes) * 60)
        wasIdleBeyondThreshold = false
        maxObservedIdleSeconds = 0

        timer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            self?.checkIdle(thresholdSeconds: thresholdSeconds)
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        wasIdleBeyondThreshold = false
        maxObservedIdleSeconds = 0
    }

    private func checkIdle(thresholdSeconds: TimeInterval) {
        let anyInput = CGEventType(rawValue: ~0) ?? .mouseMoved
        let idle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInput)
        if idle >= thresholdSeconds {
            wasIdleBeyondThreshold = true
            maxObservedIdleSeconds = max(maxObservedIdleSeconds, idle)
        } else if wasIdleBeyondThreshold {
            let awaySeconds = Int(maxObservedIdleSeconds)
            wasIdleBeyondThreshold = false
            maxObservedIdleSeconds = 0
            onReturnFromIdle?(awaySeconds)
        }
    }

    deinit {
        stopMonitoring()
    }
}
